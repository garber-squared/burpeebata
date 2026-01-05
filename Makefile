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
	@echo "Building PRODUCTION APK with production Firebase (burpeebata)..."
	docker compose exec flutter flutter build apk --release --dart-define=PRODUCTION=true --verbose

apk-dev:
	@echo "Building DEVELOPMENT APK with dev Firebase (burpeebata-dev)..."
	docker compose exec flutter flutter build apk --release --verbose

test:
	docker compose exec flutter flutter test

mocks:
	docker compose exec flutter flutter pub run build_runner build

build-web:
	@echo "Building PRODUCTION web app with production Firebase (burpeebata)..."
	docker compose exec flutter flutter build web --release --dart-define=PRODUCTION=true --verbose

build-web-dev:
	@echo "Building DEVELOPMENT web app with dev Firebase (burpeebata-dev)..."
	docker compose exec flutter flutter build web --release --verbose

pub-get:
	docker compose exec flutter flutter pub get

build-android:
	@echo "Building PRODUCTION APK with production Firebase (burpeebata)..."
	docker compose exec flutter flutter build apk --release --dart-define=PRODUCTION=true --verbose

adb-install:
	adb install -r build/app/outputs/flutter-apk/app-release.apk
