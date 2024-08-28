
# Load environment variables from given file to be used within
# docker image build process.
load_env() {
    if [ -z "$1" ]; then
        echo "Usage: load_env <path_to_env_file>"
        return 1
    fi

    if [ ! -f "$1" ]; then
        echo "Error: File '$1' not found."
        return 1
    fi

    export $(grep -v '^#' "$1" | xargs) && echo "Environment variables loaded from $1"
}
