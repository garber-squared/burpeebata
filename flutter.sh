#!/bin/bash
# Helper script to run Flutter commands via Docker

docker-compose run --rm flutter "$@"
