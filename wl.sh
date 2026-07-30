#!/bin/bash

BASE_DIR="${WL_BASE_DIR:-$HOME/.wavelength}"
ENV_DIR="$BASE_DIR/environments"
CONFIG_FILE="$BASE_DIR/config"
VERSION="0.2.0"


if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

###
# Wavelength help command, display usage information
wl_help () {
    echo "Usage: wl COMMAND [ARGS...]

Wavelength, the thin UV environment manager

Commands:
  activate            Activate a UV environment
  base                Set a default environment for new shells
  init                Initialize wavelength environment management
  help                Display this help message
  create              Create a new UV environment
  delete              Delete an existing UV environment
  list                List existing UV environments
  version             Display the version of Wavelength
  update              Check for and install updates
"
}


###
# Wavelength activate command, activate the uv python virtual environment
wl_activate() {
    if [ $# -ne 1 ]; then
        echo "Usage: wl activate ENV_NAME"
        return 1
    fi

    if [ ! -d "$ENV_DIR" ]; then
        echo "Error: Wavelength environment directory does not exist. Please run 'wl init' first."
        return 1
    fi

    ENV_NAME="$1"

    ENV_PATH="$ENV_DIR/$ENV_NAME"
    if [ ! -d "$ENV_PATH" ]; then
        echo "Error: Environment '$ENV_NAME' does not exist in $ENV_DIR"
        return 1
    fi

    # Activate the virtual environment
    source "$ENV_PATH/bin/activate"
}

###
# Initialize wavelength
wl_init() {
    if [ ! -d "$ENV_DIR" ]; then
        mkdir -p "$ENV_DIR"
        echo "Initialized wavelength environment directory at $ENV_DIR"
    else
        echo "Wavelength environment directory already exists at $ENV_DIR"
    fi

    touch "$CONFIG_FILE"
    echo "Created blank config file at $CONFIG_FILE"
}


###
# Wavelength create command, create a new uv python virtual environment
wl_create() {
    if ! command -v uv >/dev/null 2>&1; then
        echo "Error: uv is required but not found on PATH. See https://docs.astral.sh/uv/getting-started/installation/"
        return 1
    fi

    if [ $# -le 0 ]; then
        echo "Usage: wl create ENV_NAME [--python=PYTHON_VERSION]"
        return 1
    fi

    ENV_NAME="$1"
    shift

    case "$ENV_NAME" in
        ""|.|..|*/*|-*)
            echo "Error: Invalid environment name '$ENV_NAME'. Names cannot be empty, '.', '..', contain '/', or start with '-'."
            return 1
            ;;
    esac

    ENV_PATH="$ENV_DIR/$ENV_NAME"

    if [ -d "$ENV_PATH" ]; then
        echo "Error: Environment '$ENV_NAME' already exists in $ENV_DIR"
        return 1
    fi

    uv venv "$ENV_PATH" "$@"
}

###
# Wavelength delete command, delete an existing uv python virtual environment
wl_delete() {
    if [ $# -ne 1 ]; then
        echo "Usage: wl delete ENV_NAME"
        return 1
    fi

    ENV_NAME="$1"
    ENV_PATH="$ENV_DIR/$ENV_NAME"

    if [ ! -d "$ENV_PATH" ]; then
        echo "Error: Environment '$ENV_NAME' does not exist in $ENV_DIR"
        return 1
    fi

    rm -rf "$ENV_PATH"
    echo "Deleted environment '$ENV_NAME' from $ENV_DIR"
}


###
# Wavelength set the base environment that is source in new shells
wl_set_base() {
    if [ $# -ne 1 ]; then
        echo "Usage: wl base ENV_NAME"
        return 1
    fi

    ENV_NAME="$1"
    ENV_PATH="$ENV_DIR/$ENV_NAME"

    if [ ! -d "$ENV_PATH" ]; then
        echo "Error: Environment '$ENV_NAME' does not exist, cannot set as base"
        return 1
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE"
    fi

    # Check if base env config var exists, if so update it, if not add it
    if grep -q '^\(export \)\{0,1\}WL_BASE_ENV=' "$CONFIG_FILE"; then
        sed -i.bak 's|^\(export \)\{0,1\}WL_BASE_ENV=.*|\1WL_BASE_ENV='"$ENV_NAME"'|' "$CONFIG_FILE"
        rm -f "$CONFIG_FILE.bak"
        echo "Updated WL_BASE_ENV to $ENV_NAME in $CONFIG_FILE"
    else
        echo "export WL_BASE_ENV=$ENV_NAME" >> "$CONFIG_FILE"
        echo "Set WL_BASE_ENV to $ENV_NAME in $CONFIG_FILE"
    fi
}


###
# Return 0 if the first semver-style version is greater than the second
_wl_version_higher() {
    awk -F. -v v1="$1" -v v2="$2" 'BEGIN {
        n = split(v1, a, "."); m = split(v2, b, ".");
        for (i = 1; i <= n || i <= m; i++) {
            ai = (i <= n ? a[i] : 0);
            bi = (i <= m ? b[i] : 0);
            if (ai + 0 > bi + 0) { exit 0 }
            if (ai + 0 < bi + 0) { exit 1 }
        }
        exit 1
    }'
}

###
# Check for and install updates from GitHub releases
wl_update() {
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo "Error: curl or wget is required to check for updates. Please install one of these tools."
        return 1
    fi

    REPO="cmmeyer1800/wavelength"
    API_URL="https://api.github.com/repos/$REPO/releases/latest"

    if command -v curl >/dev/null 2>&1; then
        RELEASE_JSON=$(curl -fsSL "$API_URL" 2>/dev/null)
    else
        RELEASE_JSON=$(wget -qO- "$API_URL" 2>/dev/null)
    fi

    if [ -z "$RELEASE_JSON" ]; then
        echo "Error: Could not fetch release information from GitHub."
        return 1
    fi

    # Parse tag_name (e.g. "v0.2.0") from the release JSON
    TAG_NAME=$(printf '%s\n' "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | head -n1 | cut -d'"' -f4)
    if [ -z "$TAG_NAME" ]; then
        echo "Error: Could not parse latest release version."
        return 1
    fi

    LATEST_VERSION="${TAG_NAME#v}"
    CURRENT_VERSION="$VERSION"

    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo "Already up to date (v$CURRENT_VERSION)."
        return 0
    fi

    if _wl_version_higher "$CURRENT_VERSION" "$LATEST_VERSION"; then
        echo "Current version ($CURRENT_VERSION) is newer than latest release ($LATEST_VERSION). No update needed."
        return 0
    fi

    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG_NAME/wl.sh"
    TMP_FILE=$(mktemp)

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"; then
            echo "Error: Failed to download update."
            rm -f "$TMP_FILE"
            return 1
        fi
    else
        if ! wget -q "$DOWNLOAD_URL" -O "$TMP_FILE"; then
            echo "Error: Failed to download update."
            rm -f "$TMP_FILE"
            return 1
        fi
    fi

    chmod +x "$TMP_FILE"

    if ! grep -q '^VERSION=' "$TMP_FILE"; then
        echo "Error: Downloaded update does not appear to be a valid wavelength script."
        rm -f "$TMP_FILE"
        return 1
    fi

    if [ -f "$BASE_DIR/wl.sh" ]; then
        cp "$BASE_DIR/wl.sh" "$BASE_DIR/wl.sh.bak"
    fi

    mv "$TMP_FILE" "$BASE_DIR/wl.sh"
    echo "Successfully updated to v$LATEST_VERSION. Restart your shell or run 'source $BASE_DIR/wl.sh' to use the new version."
}

wl () {
    if [ $# -eq 0 ]; then
        wl_help
        return 1
    fi

    case "$1" in
        help)
            wl_help
            ;;
        activate)
            shift
            wl_activate "$@"
            ;;
        create)
            shift
            wl_create "$@"
            ;;
        delete)
            shift
            wl_delete "$@"
            ;;
        list)
            if [ ! -d "$ENV_DIR" ]; then
                echo "No environments found. Run 'wl init' first."
                return 1
            fi
            ls "$ENV_DIR"
            ;;
        version)
            echo "Wavelength version $VERSION"
            ;;
        base)
            shift
            wl_set_base "$@"
            ;;
        init)
            wl_init
            ;;
        update)
            wl_update
            ;;
        *)
            wl_help
            return 1
            ;;
    esac
}


# Source the default base environment if set
if [[ -n "$WL_BASE_ENV" ]]; then
    wl_activate "$WL_BASE_ENV"
fi
