> 🇮🇹 [Versione italiana](../it/makefile.md)

# Makefile commands

The Makefile provides handy shortcuts to manage the container. Run `make help` to see the available targets.

| Command | Description |
| ------- | ----------- |
| `check-env` | Ensure that the `.env` file exists and that root or sudo is available |
| `ps` | Show the status of Docker Compose services |
| `status` | Alias for `ps` |
| `up` | Start Docker Compose services in background |
| `down` | Stop and remove Docker Compose services |
| `start` | Start existing Docker Compose containers |
| `stop` | Stop running containers without removing them |
| `restart` | Restart Docker Compose services (full rebuild) |
| `restart-soft` | Restart services without recreating containers |
| `logs` | Show logs from all services |
| `logs-<service>` | Show logs from a specific service |
| `pull` | Pull latest Docker images |
| `update` | Pull and restart all services |
| `init` | Initialize `.env` from `.env.example` |
| `shell` | Enter the container shell as the application user |
| `chcodpw` | Change Code-Server password |
| `chdempw` | Change Semaphore UI password |
| `root-shell` | Enter the root shell of the `core` container |
| `help` | Show available commands |

Additional targets can be defined in a local `Makefile.local` and will appear at the end of `make help`.
