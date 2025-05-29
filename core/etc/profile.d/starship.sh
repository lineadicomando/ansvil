if command -v /usr/local/bin/starship > /dev/null 2>&1; then
    # Prefer user config if it exists
    if [ -f "$HOME/.config/starship.toml" ]; then
        export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    else
        export STARSHIP_CONFIG="/etc/starship.toml"
    fi

    eval "$(/usr/local/bin/starship init bash)"
fi