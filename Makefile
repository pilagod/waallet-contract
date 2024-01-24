SHELL:=/usr/bin/env bash

.PHONY: testnet-up
testnet-up:
	docker compose -f ./docker/testnet/docker-compose.yml --env-file .env.testnet up --build

.PHONY: testnet-down
testnet-down:
	docker compose -f ./docker/testnet/docker-compose.yml --env-file .env.testnet down -v --remove-orphans
