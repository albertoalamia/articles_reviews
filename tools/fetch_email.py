#!/usr/bin/env python3
"""Fetch replies from the authors through the Gmail API and file them in an article folder.

Usage (inside nix-shell, from the repo root):

    # every message in the thread of the data request we sent (the usual case)
    python3 tools/fetch_email.py --article SciRep_emotions_in_working_donkeys_Bukhari_2026 \
        --sent-file SciRep_emotions_in_working_donkeys_Bukhari_2026/correspondence/2026-10-25_data_request_SENT.md

    # the same, giving the Gmail id of any message in the thread
    python3 tools/fetch_email.py --article <dir> --thread-of 1a1748c4d68d2a1a

    # or a free Gmail search (same syntax as the Gmail search box)
    python3 tools/fetch_email.py --article <dir> --query 'from:cityu.edu.hk newer_than:30d'

    # preview without writing anything
    python3 tools/fetch_email.py --article <dir> --thread-of <id> --dry-run

What it writes, for every message not already filed (dedup by Gmail id):

    <article>/correspondence/<YYYY-MM-DD>_reply_<sender>_RECEIVED.md
        header block (From, To, Cc, Date, Subject, Gmail-id, Thread-id, Attachments), a rule,
        the plain-text body as received, a rule, a "Retrieved:" line.  -> committed to git
    <article>/data/raw/authors/<YYYY-MM-DD>_<original filename>
        every attachment, unchanged, plus a row in data/raw/authors/RECEIVED_LOG.md with its
        sha256 and the Gmail id it came from.                            -> committed to git
    <article>/correspondence/eml/<Gmail id>.eml      only with --save-eml  -> gitignored
    a row appended to <article>/correspondence/contacts.md (the Log table must be the last
    table in that file), unless --no-log.

Messages sent from SENDER are skipped unless --include-own is given.

Credentials: the same OAuth client secret and token as tools/send_email.py, in
$GMAIL_CREDENTIALS_DIR (default ~/.config/gmail_sender/). Reading needs the gmail.readonly
scope, which the compose-only token does not have: the first run opens the browser once for
consent and rewrites token.json with both scopes, so send_email.py keeps working.
"""
import argparse
import base64
import datetime as dt
import glob
import hashlib
import html
import os
import re
import sys
from email.utils import parseaddr, parsedate_to_datetime
from pathlib import Path

SENDER = "alberto.alamia@telepsichiatria.org"
SCOPES = [
    "https://www.googleapis.com/auth/gmail.compose",
    "https://www.googleapis.com/auth/gmail.readonly",
]


# ----------------------------------------------------------------------------- Gmail access
def gmail_service(cred_dir: Path):
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build

    import json
    from google.auth.exceptions import RefreshError

    token_path = cred_dir / "token.json"
    creds = None
    if token_path.exists():
        # The scopes actually granted are in the file; the loader would otherwise report the
        # scopes we ask for, and a refresh with widened scopes fails with invalid_scope.
        granted = set(json.loads(token_path.read_text()).get("scopes", []))
        if set(SCOPES) <= granted:
            creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
        else:
            print("token lacks gmail.readonly: re-authorising with both scopes (browser)")
    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
        except RefreshError as e:
            print(f"token refresh failed ({e}); re-authorising (browser)")
            creds = None
    if not creds or not creds.valid:
        secrets = glob.glob(str(cred_dir / "client_secret*.json"))
        if not secrets:
            sys.exit(f"no client_secret*.json in {cred_dir} (see docstring).")
        flow = InstalledAppFlow.from_client_secrets_file(secrets[0], SCOPES)
        creds = flow.run_local_server(port=8080)
    token_path.write_text(creds.to_json())
    os.chmod(token_path, 0o600)
    return build("gmail", "v1", credentials=creds)


def b64(data: str) -> bytes:
    return base64.urlsafe_b64decode(data + "=" * (-len(data) % 4))


def header(msg, name, default=""):
    for h in msg["payload"].get("headers", []):
        if h["name"].lower() == name.lower():
            return h["value"]
    return default


def walk_parts(part):
    """Yield every leaf part of a MIME tree."""
    if "parts" in part:
        for p in part["parts"]:
            yield from walk_parts(p)
    else:
        yield part


def html_to_text(s: str) -> str:
    s = re.sub(r"(?is)<(script|style).*?</\1>", "", s)
    s = re.sub(r"(?i)<br\s*/?>|</p>|</div>|</tr>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    return html.unescape(s)


def extract(service, msg):
    """Return (body_text, [(filename, bytes)]) for a full-format message."""
    text_plain, text_html, attachments = [], [], []
    for part in walk_parts(msg["payload"]):
        mime = part.get("mimeType", "")
        body = part.get("body", {})
        filename = part.get("filename") or ""
        data = body.get("data")
        if filename:                                   # attachment (inline or not)
            if data is None and body.get("attachmentId"):
                att = service.users().messages().attachments().get(
                    userId="me", messageId=msg["id"], id=body["attachmentId"]).execute()
                data = att.get("data")
            if data is not None:
                attachments.append((filename, b64(data)))
        elif data is not None and mime == "text/plain":
            text_plain.append(b64(data).decode("utf-8", errors="replace"))
        elif data is not None and mime == "text/html":
            text_html.append(b64(data).decode("utf-8", errors="replace"))
    if text_plain:
        return "\n".join(text_plain), attachments
    if text_html:
        return html_to_text("\n".join(text_html)), attachments
    return msg.get("snippet", ""), attachments


# ----------------------------------------------------------------------------- filing
def slug(s: str) -> str:
    s = re.sub(r"[^A-Za-z0-9]+", "-", s).strip("-").lower()
    return s or "unknown"


def sender_slug(from_header: str) -> str:
    name, addr = parseaddr(from_header)
    if name:
        return slug(name.split()[-1])              # surname
    return slug(addr.split("@")[0])


def already_filed(corr_dir: Path, gmail_id: str) -> bool:
    for f in corr_dir.glob("*.md"):
        if f"Gmail-id: {gmail_id}" in f.read_text(encoding="utf-8", errors="replace"):
            return True
    return False


def unique_path(p: Path) -> Path:
    if not p.exists():
        return p
    stem, suf, k = p.stem, p.suffix, 2
    while (q := p.with_name(f"{stem}_{k}{suf}")).exists():
        k += 1
    return q


def file_message(service, msg, article: Path, dry_run: bool, save_eml: bool, no_log: bool):
    corr_dir = article / "correspondence"
    att_dir = article / "data" / "raw" / "authors"
    gmail_id, thread_id = msg["id"], msg["threadId"]
    date_hdr = header(msg, "Date")
    try:
        when = parsedate_to_datetime(date_hdr).astimezone()
    except Exception:
        when = dt.datetime.fromtimestamp(int(msg["internalDate"]) / 1000).astimezone()
    day = when.strftime("%Y-%m-%d")
    frm, to, cc, subj = (header(msg, k) for k in ("From", "To", "Cc", "Subject"))
    body, attachments = extract(service, msg)

    md_path = unique_path(corr_dir / f"{day}_reply_{sender_slug(frm)}_RECEIVED.md")
    stored = []
    for filename, blob in attachments:
        target = unique_path(att_dir / f"{day}_{Path(filename).name}")
        stored.append((target, filename, blob))

    name, addr = parseaddr(frm)
    lines = [
        f"# Reply from {name or addr} — RECEIVED",
        "",
        f"From: {frm}",
        f"To: {to}",
    ]
    if cc:
        lines.append(f"Cc: {cc}")
    lines += [
        f"Date: {when.isoformat(timespec='minutes')}  (header: {date_hdr})",
        f"Subject: {subj}",
        f"Gmail-id: {gmail_id}",
        f"Thread-id: {thread_id}",
    ]
    if header(msg, "In-Reply-To"):
        lines.append(f"In-reply-to: {header(msg, 'In-Reply-To')}")
    if stored:
        lines.append("Attachments: " + "; ".join(
            f"{orig} -> {t.relative_to(article)} ({len(b)} bytes)" for t, orig, b in stored))
    else:
        lines.append("Attachments: none")
    lines += ["", "---", "", body.rstrip("\n"), "", "---", "",
              f"Retrieved: {dt.datetime.now().astimezone().isoformat(timespec='minutes')} "
              f"by tools/fetch_email.py, verbatim, not edited."]
    md_text = "\n".join(lines) + "\n"

    print(f"\n=== {day}  {frm}\n    subject: {subj}\n    -> {md_path.relative_to(article.parent)}")
    for t, orig, b in stored:
        print(f"    attachment {orig} -> {t.relative_to(article.parent)} ({len(b)} bytes)")
    if dry_run:
        print("    (dry run: nothing written)")
        print("    --- body preview ---")
        print("    " + "\n    ".join(body.strip().splitlines()[:15]))
        return

    corr_dir.mkdir(parents=True, exist_ok=True)
    md_path.write_text(md_text, encoding="utf-8")

    if stored:
        att_dir.mkdir(parents=True, exist_ok=True)
        log = att_dir / "RECEIVED_LOG.md"
        if not log.exists():
            log.write_text("# Files received from the authors\n\nUnchanged as received; "
                           "sha256 recorded at filing. Derived versions go to data/derived/.\n\n"
                           "| Date | From | Stored as | Original name | Bytes | sha256 | Gmail id |\n"
                           "|---|---|---|---|---|---|---|\n", encoding="utf-8")
        with log.open("a", encoding="utf-8") as fh:
            for t, orig, b in stored:
                t.write_bytes(b)
                fh.write(f"| {day} | {addr} | {t.name} | {orig} | {len(b)} | "
                         f"{hashlib.sha256(b).hexdigest()} | {gmail_id} |\n")

    if save_eml:
        raw = service.users().messages().get(userId="me", id=gmail_id, format="raw").execute()
        eml_dir = corr_dir / "eml"
        eml_dir.mkdir(exist_ok=True)
        (eml_dir / f"{gmail_id}.eml").write_bytes(b64(raw["raw"]))

    if not no_log:
        contacts = corr_dir / "contacts.md"
        if contacts.exists():
            summary = re.sub(r"\s+", " ", subj)[:80]
            att_note = f"; {len(stored)} attachment(s) in data/raw/authors/" if stored else ""
            row = (f"| {day} | received | {name or addr} | email | "
                   f"{summary}{att_note} | {md_path.name} |\n")
            text = contacts.read_text(encoding="utf-8")
            contacts.write_text(text.rstrip("\n") + "\n" + row, encoding="utf-8")


# ----------------------------------------------------------------------------- main
def gmail_id_from_sent_file(path: Path) -> str:
    m = re.search(r"gmail-id\s+([0-9a-f]+)", path.read_text(encoding="utf-8"))
    if not m:
        sys.exit(f"no 'gmail-id <id>' line in {path}")
    return m.group(1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--article", type=Path, required=True, help="article folder (relative to repo root)")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--thread-of", metavar="GMAIL_ID", help="fetch the whole thread containing this message")
    src.add_argument("--sent-file", type=Path, metavar="FILE", help="a *_SENT.md with a 'gmail-id' line; its thread is fetched")
    src.add_argument("--query", metavar="Q", help="Gmail search query; every matching message is fetched")
    ap.add_argument("--include-own", action="store_true", help=f"also file messages sent from {SENDER}")
    ap.add_argument("--save-eml", action="store_true", help="also keep the raw .eml under correspondence/eml/ (gitignored)")
    ap.add_argument("--no-log", action="store_true", help="do not append a row to correspondence/contacts.md")
    ap.add_argument("--dry-run", action="store_true", help="list what would be filed and exit")
    ap.add_argument("--max", type=int, default=50, help="max messages for --query (default 50)")
    args = ap.parse_args()

    article = args.article.resolve()
    if not (article / "correspondence").is_dir():
        sys.exit(f"{article} has no correspondence/ folder; is --article right?")

    service = gmail_service(Path(os.environ.get("GMAIL_CREDENTIALS_DIR", "~/.config/gmail_sender")).expanduser())

    if args.query:
        res = service.users().messages().list(userId="me", q=args.query, maxResults=args.max).execute()
        ids = [m["id"] for m in res.get("messages", [])]
    else:
        seed = args.thread_of or gmail_id_from_sent_file(args.sent_file)
        thread_id = service.users().messages().get(userId="me", id=seed, format="minimal").execute()["threadId"]
        thread = service.users().threads().get(userId="me", id=thread_id, format="minimal").execute()
        ids = [m["id"] for m in thread["messages"]]

    if not ids:
        print("no messages found")
        return

    filed = skipped_own = skipped_dup = 0
    for mid in ids:
        msg = service.users().messages().get(userId="me", id=mid, format="full").execute()
        frm = header(msg, "From")
        if SENDER in frm and not args.include_own:
            skipped_own += 1
            continue
        if already_filed(article / "correspondence", mid):
            skipped_dup += 1
            continue
        file_message(service, msg, article, args.dry_run, args.save_eml, args.no_log)
        filed += 1

    print(f"\n{len(ids)} message(s) in scope: {filed} filed, {skipped_own} own skipped, {skipped_dup} already filed.")


if __name__ == "__main__":
    main()
