#!/usr/bin/env python3
"""Send an email written as a Markdown draft, through the Gmail API.

Usage (inside nix-shell, from the repo root):

    python3 tools/send_email.py path/to/2026-10-25_data_request_DRAFT.md            # preview, confirm, send
    python3 tools/send_email.py path/to/draft.md --dry-run                           # preview only
    python3 tools/send_email.py path/to/draft.md --attach review.pdf --attach x.zip  # with attachments

Draft format (what correspondence/*.md already look like):

    # anything                      <- lines before the header block are ignored
    To: a@x.org, b@y.org
    Cc: c@z.org                     <- optional; Bcc: also accepted
    Subject: ...
    ---                             <- first rule: body starts
    Dear ...                        <- body (plain text, sent as-is)
    ---                             <- second rule (optional): everything after it is notes, not sent

Header lines are matched case-insensitively. The "(optional)" word in a Cc line is dropped.

Credentials: an OAuth client secret and a token with the gmail.compose scope, in the directory
$GMAIL_CREDENTIALS_DIR (default ~/.config/gmail_sender/): client_secret*.json and token.json.
The first run (or an expired token) opens a browser for Google login and rewrites token.json.
These files are gitignored and must never be put in the repository.

After a successful send the script, unless --no-mark is given, renames a *_DRAFT.md file to
*_SENT.md and appends a "Sent: <timestamp> <gmail message id>" line to it.
"""
import argparse
import base64
import datetime as dt
import glob
import mimetypes
import os
import re
import sys
from email.message import EmailMessage
from pathlib import Path

SENDER = "alberto.alamia@telepsichiatria.org"
SCOPES = ["https://www.googleapis.com/auth/gmail.compose"]
HEADER_KEYS = ("to", "cc", "bcc", "subject")


def parse_draft(path: Path):
    text = path.read_text(encoding="utf-8")
    parts = re.split(r"^\s*---\s*$", text, flags=re.M)
    if len(parts) < 2:
        sys.exit(f"{path}: no '---' rule found; cannot tell header from body")
    header_block, body = parts[0], parts[1].strip("\n")
    headers = {}
    for line in header_block.splitlines():
        m = re.match(r"^\s*(To|Cc|Bcc|Subject)\s*:\s*(.*)$", line, flags=re.I)
        if m:
            key, val = m.group(1).lower(), m.group(2).strip()
            val = re.sub(r"\(optional\)", "", val, flags=re.I).strip()
            headers[key] = val
    missing = [k for k in ("to", "subject") if not headers.get(k)]
    if missing:
        sys.exit(f"{path}: missing header line(s): {', '.join(missing)}")
    if not body.strip():
        sys.exit(f"{path}: empty body")
    return headers, body


def build_message(headers, body, attachments):
    msg = EmailMessage()
    msg["From"] = SENDER
    msg["To"] = headers["to"]
    if headers.get("cc"):
        msg["Cc"] = headers["cc"]
    if headers.get("bcc"):
        msg["Bcc"] = headers["bcc"]
    msg["Subject"] = headers["subject"]
    msg.set_content(body)
    for a in attachments:
        p = Path(a)
        if not p.is_file():
            sys.exit(f"attachment not found: {a}")
        ctype, _ = mimetypes.guess_type(p.name)
        maintype, subtype = (ctype or "application/octet-stream").split("/", 1)
        msg.add_attachment(p.read_bytes(), maintype=maintype, subtype=subtype, filename=p.name)
    return msg


def gmail_service(cred_dir: Path):
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build

    token_path = cred_dir / "token.json"
    creds = None
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    if not creds or not creds.valid:
        secrets = glob.glob(str(cred_dir / "client_secret*.json"))
        if not secrets:
            sys.exit(f"no client_secret*.json in {cred_dir}. Copy it there (see docstring).")
        flow = InstalledAppFlow.from_client_secrets_file(secrets[0], SCOPES)
        creds = flow.run_local_server(port=8080)
    token_path.write_text(creds.to_json())
    os.chmod(token_path, 0o600)
    return build("gmail", "v1", credentials=creds)


def mark_sent(path: Path, message_id: str):
    stamp = dt.datetime.now().astimezone().isoformat(timespec="minutes")
    text = path.read_text(encoding="utf-8").rstrip("\n")
    text += f"\n\nSent: {stamp}  gmail-id {message_id}\n"
    new_path = path
    if "_DRAFT" in path.name:
        new_path = path.with_name(path.name.replace("_DRAFT", "_SENT"))
    new_path.write_text(text, encoding="utf-8")
    if new_path != path:
        path.unlink()
    return new_path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("draft", type=Path)
    ap.add_argument("--attach", action="append", default=[], metavar="FILE")
    ap.add_argument("--dry-run", action="store_true", help="show the message and exit without sending")
    ap.add_argument("--no-mark", action="store_true", help="do not rename/annotate the draft after sending")
    ap.add_argument("--yes", action="store_true", help="skip the confirmation prompt")
    args = ap.parse_args()

    headers, body = parse_draft(args.draft)
    msg = build_message(headers, body, args.attach)

    print("=" * 72)
    for k in ("From", "To", "Cc", "Bcc", "Subject"):
        if msg.get(k):
            print(f"{k}: {msg[k]}")
    if args.attach:
        print("Attachments:", ", ".join(Path(a).name for a in args.attach))
    print("-" * 72)
    print(body)
    print("=" * 72)
    if args.dry_run:
        print("dry run: nothing sent")
        return
    if not args.yes and input("Send this email? (y/N): ").strip().lower() != "y":
        print("not sent")
        return

    cred_dir = Path(os.environ.get("GMAIL_CREDENTIALS_DIR", "~/.config/gmail_sender")).expanduser()
    service = gmail_service(cred_dir)
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    sent = service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"sent, gmail id {sent['id']}")
    if not args.no_mark:
        new_path = mark_sent(args.draft, sent["id"])
        print(f"draft marked as sent: {new_path}")
        print("remember to add a row to correspondence/contacts.md → Log")


if __name__ == "__main__":
    main()
