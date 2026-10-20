#!/usr/bin/env bash
# Run with: source scripts/host-env.sh
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_PARENT="$(cd "${LAB_ROOT}/.." && pwd)"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    export PATH="${LAB_PARENT}/trivy_0.76.0_windows-64bit:/c/Program Files/Oracle/VirtualBox:${PATH}"
    if [[ -f "${LAB_ROOT}/.venv/Scripts/activate" ]]; then
      source "${LAB_ROOT}/.venv/Scripts/activate"
    fi
    ;;
  *)
    printf 'host-env.sh is intended for Git Bash on Windows.\n' >&2
    ;;
esac

