# Shared development environment for articles_reviews.
# Pinned to a specific nixos-25.05 commit so every review renders in the same environment.
# Per-article shell.nix files import this one and extend `rlibs` when a paper needs more.
#
#   nix-shell                 # from the repo root
#   nvim                      # launch nvim from inside the shell so R.nvim finds this R
#   make -C $CMDSTAN $PWD/<article>/stan/<model>   # compile a Stan model with CmdStan
let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ac62194c3917d5f474c1a844b6fd6da2db95077d.tar.gz";
    # nixos-25.05 as of 2026-10-25. To update: fetch a new commit hash and leave sha256 empty;
    # nix will print the right hash in the error message.
  };
  pkgs = import nixpkgs { config = {}; overlays = []; };

  # cmdstanr is not in nixpkgs. Used ONLY to read CmdStan CSV output (read_cmdstan_csv), never to fit.
  cmdstanr = pkgs.rPackages.buildRPackage {
    name = "cmdstanr-0.9.0";
    src = pkgs.fetchzip {
      url = "https://github.com/stan-dev/cmdstanr/archive/refs/tags/v0.9.0.tar.gz";
      sha256 = "14j2bxadxnpqhsbsy6nb2i97p9xzmbp37hpvvpyf57mi2z2cwxy1";
    };
    propagatedBuildInputs = with pkgs.rPackages; [ checkmate data_table jsonlite posterior processx R6 withr rlang ];
  };

  rlibs = with pkgs.rPackages; [
    cmdstanr
    # data handling and reporting
    tidyverse
    readxl
    jsonlite        # write Stan data as JSON
    here
    knitr
    rmarkdown
    gt
    # Bayesian post-processing of CmdStan CSV output (no fitting from R)
    posterior       # draws objects, summaries, rhat, ess (cmdstanr::read_cmdstan_csv reads the files)
    bayesplot
    loo
    tidybayes
    ggdist
    # consistency checks and tests of lib/
    testthat
    # editor support (R.nvim / LSP)
    languageserver
  ];

  # Python only for tools/send_email.py (Gmail API). Credentials live outside the repo.
  myPython = pkgs.python3.withPackages (p: [ p.google-api-python-client p.google-auth-oauthlib p.google-auth-httplib2 ]);

  myR = pkgs.rWrapper.override { packages = rlibs; };
  myQuarto = pkgs.quarto.override { extraRPackages = rlibs; };
in
# mkShell (not mkShellNoCC): models must be compiled with the same gcc that built the
# nixpkgs CmdStan and its precompiled header, otherwise make tries to rebuild it in the store.
pkgs.mkShell {
  packages = [
    myR
    myQuarto
    myPython
    pkgs.cmdstan          # 2.36.0: stanc, makefiles, prebuilt libs; sets $CMDSTAN
    pkgs.texliveMedium
    pkgs.poppler-utils    # pdftotext for extracting tables from papers
    pkgs.git
  ];

  env.LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  # Force the pinned CmdStan even if the user profile exports another CMDSTAN.
  env.CMDSTAN = "${pkgs.cmdstan}/opt/cmdstan";
  env.cmdstanr_no_ver_check = "TRUE";   # cmdstanr only reads CSVs; the pinned CmdStan is intentional
  shellHook = ''
    # Draws are large; they never live inside the (encrypted, small) project tree.
    # Default to the archive disk, but respect a FITS_DIR set by the caller (tests, other machines).
    export FITS_DIR="''${FITS_DIR:-/media/alberto/Archive/bayesian/articles_reviews}"
    if [ ! -d "$FITS_DIR" ]; then
      echo "WARNING: $FITS_DIR not found. Mount the archive disk before sampling." >&2
    fi
    echo "articles_reviews shell: R $(R --version | head -1 | cut -d' ' -f3), CmdStan at $CMDSTAN, FITS_DIR=$FITS_DIR"
  '';
}
