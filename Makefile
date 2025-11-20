# Frontend targets
up:
	docker compose up -d

up-build:
	docker compose up --build -d

build:
	docker compose build --no-cache

stop:
	docker compose stop

down:
	docker compose down

clean:
	docker compose down -v

restart:
	docker compose restart

logs:
	docker compose logs -f

ps:
	docker compose ps
