if command -v /usr/local/bin/starship > /dev/null 2>&1; then
    export STARSHIP_CONFIG=/etc/starship.toml
    eval "$(/usr/local/bin/starship init bash)"
fi