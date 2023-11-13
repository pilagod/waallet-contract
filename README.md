# Waallet Contract

## Setup

```bash
git clone git@github.com:alchemyplatform/rundler.git vendor/rundler
```

Build `rundler` docker image:

```bash
cd vendor/rundler
docker buildx build . -t rundler
```

Run testnet:

```bash
make testnet-up
```

Clean resources for testnet:

```bash
make testnet-down
```
