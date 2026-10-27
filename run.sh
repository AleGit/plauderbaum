#!/bin/sh
# Starts Plauderbaum on macOS (and other Unix systems). Mirrors run.bat.
# Pass --with-cursor once to install the optional Cursor agent provider.
set -eu
cd "$(dirname "$0")"

WITH_CURSOR=0
for arg in "$@"; do
    case "$arg" in
        --with-cursor) WITH_CURSOR=1 ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: ./run.sh [--with-cursor]"
            exit 1
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3.12 or newer is required."
    echo "Install it from https://www.python.org/downloads/"
    exit 1
fi

if ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 12) else 1)'; then
    echo "Python 3.12 or newer is required. This machine has $(python3 --version)."
    exit 1
fi

if [ ! -x .venv/bin/python ]; then
    echo "First start: setting up. This takes a minute..."
    python3 -m venv .venv || {
        echo
        echo "Setup failed. Delete the .venv folder and try again."
        exit 1
    }
fi

# Install the dependencies on first start and whenever requirements.txt has changed.
if ! cmp -s requirements.txt .venv/requirements.installed 2>/dev/null; then
    echo "Installing dependencies..."
    .venv/bin/python -m pip install --quiet --disable-pip-version-check --require-hashes -r requirements.txt || {
        echo
        echo "Setup failed. Delete the .venv folder and try again."
        exit 1
    }
    cp requirements.txt .venv/requirements.installed
fi

if [ "$WITH_CURSOR" = 1 ]; then
    mkdir -p .venv
    touch .venv/cursor.enabled
fi

# Optional Cursor agent: installed only when enabled, never by the default start.
if [ -f .venv/cursor.enabled ]; then
    if ! cmp -s requirements-cursor.txt .venv/requirements-cursor.installed 2>/dev/null; then
        echo "Installing optional Cursor support..."
        .venv/bin/python -m pip install --quiet --disable-pip-version-check --require-hashes \
            -r requirements.txt -r requirements-cursor.txt || {
            echo
            echo "Could not install Cursor support. Delete the .venv folder and try again,"
            echo "or start without --with-cursor."
            exit 1
        }
        cp requirements-cursor.txt .venv/requirements-cursor.installed
    fi
fi

exec .venv/bin/python -m tutor
