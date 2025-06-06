> 🇬🇧 [English version](../en/quick-start.md)

# Avvio rapido

### Metodo con `make` (consigliato)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
make init     # crea il file .env se non esiste
make up       # avvia i servizi in background
```

Per altri comandi disponibili:

```bash
make help
```

### Metodo manuale (senza `make`)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
cp .env.example .env  # configura le variabili d'ambiente
docker compose up -d
````
