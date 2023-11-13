SHELL:=/usr/bin/env bash

.PHONY: testnet-up
testnet-up:
	docker compose -f ./docker/testnet/docker-compose.yml up --build

.PHONY: testnet-down
testnet-down:
	docker compose -f ./docker/testnet/docker-compose.yml down -v --remove-orphans
