> 🇮🇹 [Versione italiana](../it/quick-start.md)

# Quick start

### `make` method (recommended)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
make init     # creates .env file if missing
make up       # starts services in background
```

For more available commands:

```bash
make help
```

### Manual method (without `make`)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
cp .env.example .env  # configure environment variables
docker compose up -d
````
