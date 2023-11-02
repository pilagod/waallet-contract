SHELL:=/usr/bin/env bash

.PHONY: testnet
testnet:
	docker compose -f ./docker/testnet/docker-compose.yml up --build
