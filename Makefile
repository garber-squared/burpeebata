.PHONY: up up-build build stop down clean restart logs ps doctor apk test start build-android adb-install

start:
	/bin/bash bin/startup.sh

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
	docker compose restart && docker compose logs -f

logs:
	docker compose logs -f

ps:
	docker compose ps

doctor:
	docker compose exec flutter flutter doctor

apk:
	docker compose exec flutter flutter build apk --release --verbose

test:
	docker compose exec flutter flutter test

mocks:
	docker compose exec flutter flutter pub run build_runner build

build-web:
	docker compose exec flutter flutter build web --release --verbose

pub-get:
	docker compose exec flutter flutter pub get

build-android:
	docker compose exec flutter flutter build apk --release --verbose

adb-install:
	adb install -r build/app/outputs/flutter-apk/app-release.apk
