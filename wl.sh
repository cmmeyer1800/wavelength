#!/bin/bash

# TODO: make this configurable
BASE_DIR="$HOME/.wavelength"
ENV_DIR="$BASE_DIR/environments"
CONFIG_FILE="$BASE_DIR/config"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

###
# Wavelength help command, display usage information
wl_help () {
    echo "Usage: wl COMMAND [ARGS...]

Wavelength, the thin UV environment manager

Commands:
  activate            Activate the UV environment
  init                Initialize wavelength environment management
  help                Display this help message
  create              Create a new UV environment
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

    touch $CONFIG_FILE
    echo "Created blank config file at $CONFIG_FILE"
}


###
# Wavelength create command, create a new uv python virtual environment
wl_create() {
    if [ $# -le 0 ]; then
        echo "Usage: wl create ENV_NAME [--python=PYTHON_VERSION]"
        return 1
    fi

    ENV_NAME="$1"
    shift

    ENV_PATH="$ENV_DIR/$ENV_NAME"

    if [ -d "$ENV_PATH" ]; then
        echo "Error: Environment '$ENV_NAME' already exists in $ENV_DIR"
        return 1
    fi

    uv venv "$ENV_PATH" $@
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
        touch $CONFIG_FILE
    fi

    # Check if base env config var exists, if so update it, if not add it
    if grep -q "^WL_BASE_ENV=" "$CONFIG_FILE"; then
        sed -i.bak "s|^WL_BASE_ENV=.*|WL_BASE_ENV=$ENV_NAME|" "$CONFIG_FILE"
        echo "Updated WL_BASE_ENV to $ENV_NAME in $CONFIG_FILE"
    else
        echo "export WL_BASE_ENV=$ENV_NAME" >> "$CONFIG_FILE"
        echo "Set WL_BASE_ENV to $ENV_NAME in $CONFIG_FILE"
    fi
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
            wl_activate $@
            ;;
        create)
            shift
            wl_create $@
            ;;
        delete)
            shift
            wl_delete $@
            ;;
        base)
            shift
            wl_set_base $@
            ;;
        init)
            wl_init
            ;;
        *)
            wl_help
            ;;
    esac
}


# Source the default base environment if set
if [[ -n "$WL_BASE_ENV" ]]; then
    wl_activate "$WL_BASE_ENV"
fi
