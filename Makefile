.PHONY: help setup test build format coverage \
	java-test java-checkstyle java-build java-run \
	react-install react-test react-coverage react-build react-format react-run pnpm-upgrade \
	flutter-install flutter-upgrade flutter-sdk-upgrade flutter-client-upgrade flutter-app-upgrade \
	flutter-client-install flutter-app-install flutter-doctor flutter-emulators flutter-emulator-launch flutter-analyze \
	flutter-test flutter-client-test flutter-app-test \
	flutter-coverage flutter-client-coverage flutter-app-coverage flutter-format flutter-clean \
	flutter-run flutter-run-web flutter-run-android flutter-run-linux flutter-run-windows \
	flutter-build flutter-build-web flutter-build-android flutter-build-desktop flutter-build-linux flutter-build-windows \
	flutter-deploy flutter-deploy-web flutter-deploy-android flutter-deploy-desktop flutter-deploy-linux flutter-deploy-windows \
	flutter-docker-build flutter-docker-build-windows flutter-package-windows \
	docs-install docs-build docs-serve \
	presentation-install presentation-build presentation-format presentation-serve \
	docker-build docker-up docker-up-docs docker-up-java-site docker-up-presentation docker-up-postgres docker-up-api \
	docker-up-backend docker-down docker-logs

FLUTTER_APP_DIR := flutter/application
FLUTTER_CLIENT_DIR := flutter/dart-client
COMPOSE_FILES := -f docker/compose.yml -f docker/compose.local.yml
API_BASE_URL ?= http://localhost:8989
FLUTTER_DEFINES := --dart-define=API_BASE_URL=$(API_BASE_URL)
FLUTTER_ARTIFACTS_DIR := docker/flutter-artifacts
FLUTTER_WINDOWS_IMAGE := template-java-solution-flutter-windows
FLUTTER_WINDOWS_CONTAINER := template-java-solution-flutter-windows-artifacts

ifeq ($(OS),Windows_NT)
FLUTTER_DESKTOP_PLATFORM := windows
else
FLUTTER_DESKTOP_PLATFORM := linux
endif

help:
	@echo Available commands:
	@echo   make setup                 Install all project dependencies
	@echo   make test                  Run all test suites
	@echo   make coverage              Generate Java, React, and Dart coverage reports
	@echo   make build                 Build all components
	@echo   make format                Format React, Flutter, and presentation sources
	@echo === Flutter and Dart ===
	@echo   make flutter-install       Resolve Dart dependencies
	@echo   make flutter-upgrade       Upgrade Flutter and Dart dependencies
	@echo   make flutter-sdk-upgrade   Upgrade the Flutter SDK
	@echo   make flutter-client-upgrade Upgrade dart-client dependencies
	@echo   make flutter-app-upgrade   Upgrade application dependencies
	@echo   make flutter-doctor        Diagnose the Flutter environment
	@echo   make flutter-emulators     List available Flutter emulators
	@echo   make flutter-emulator-launch Launch the Medium_Phone emulator
	@echo   make flutter-analyze       Analyze the Flutter application
	@echo   make flutter-test          Run Dart tests
	@echo   make flutter-coverage      Generate Dart and Flutter coverage reports
	@echo   make flutter-format        Format Dart sources
	@echo   make flutter-run-web       Run the Flutter application on Web
	@echo   make flutter-run-android   Run the Flutter application on Android
	@echo   make flutter-run-linux     Run the Flutter application on Linux
	@echo   make flutter-run-windows   Run the Flutter application on Windows
	@echo   make flutter-build         Build debug artifacts for Web, Android, and the current desktop OS
	@echo   make flutter-build-web     Build the Web debug artifact
	@echo   make flutter-build-android Build the Android debug APK
	@echo   make flutter-build-linux   Build the Linux debug artifact on Linux
	@echo   make flutter-build-windows Build the Windows debug artifact on Windows
	@echo   make flutter-deploy        Build release artifacts for Web, Android, and the current desktop OS
	@echo   make flutter-deploy-web    Build the Web release artifact
	@echo   make flutter-deploy-android Build the Android release APK
	@echo   make flutter-deploy-linux  Build the Linux release artifact on Linux
	@echo   make flutter-deploy-windows Build the Windows release artifact on Windows
	@echo   make flutter-docker-build  Build Android and Linux release packages in Docker into docker/flutter-artifacts
	@echo   make flutter-docker-build-windows Build the Windows release package in a Windows container
	@echo   make flutter-package-windows Build the Windows release package on the host into docker/flutter-artifacts
	@echo   Release and package targets accept API_BASE_URL=https://api.example.com

setup: react-install flutter-install docs-install presentation-install

test: java-test react-test flutter-test

coverage: java-test react-coverage flutter-coverage

build: java-build react-build flutter-build docs-build presentation-build

format: react-format flutter-format presentation-format

pnpm-upgrade:
	winget upgrade --id pnpm.pnpm

flutter-install: flutter-client-install flutter-app-install

flutter-upgrade: flutter-sdk-upgrade flutter-client-upgrade flutter-app-upgrade

flutter-sdk-upgrade:
	flutter upgrade

flutter-client-upgrade:
	cd $(FLUTTER_CLIENT_DIR) && dart pub upgrade

flutter-app-upgrade:
	cd $(FLUTTER_APP_DIR) && flutter pub upgrade

flutter-client-install:
	cd $(FLUTTER_CLIENT_DIR) && dart pub get

flutter-app-install:
	cd $(FLUTTER_APP_DIR) && flutter pub get

flutter-doctor:
	flutter doctor -v

flutter-emulators:
	flutter emulators

flutter-emulator-launch:
	flutter emulators --launch Medium_Phone

flutter-analyze:
	cd $(FLUTTER_APP_DIR) && flutter analyze

flutter-test: flutter-client-test flutter-app-test

flutter-client-test:
	cd $(FLUTTER_CLIENT_DIR) && dart test

flutter-app-test:
	cd $(FLUTTER_APP_DIR) && flutter test

flutter-coverage: flutter-client-coverage flutter-app-coverage

flutter-client-coverage:
	cd $(FLUTTER_CLIENT_DIR) && dart run coverage:test_with_coverage

flutter-app-coverage:
	cd $(FLUTTER_APP_DIR) && flutter test --coverage

flutter-format:
	dart format $(FLUTTER_CLIENT_DIR)/lib $(FLUTTER_CLIENT_DIR)/test $(FLUTTER_APP_DIR)/lib $(FLUTTER_APP_DIR)/test

flutter-clean:
	cd $(FLUTTER_APP_DIR) && flutter clean

flutter-run: flutter-run-web

flutter-run-web:
	cd $(FLUTTER_APP_DIR) && flutter run -d chrome --web-port 7357

flutter-run-android:
	cd $(FLUTTER_APP_DIR) && flutter run

flutter-run-linux:
	cd $(FLUTTER_APP_DIR) && flutter run -d linux

flutter-run-windows:
	cd $(FLUTTER_APP_DIR) && flutter run -d windows

flutter-build: flutter-build-web flutter-build-android flutter-build-desktop

flutter-build-web:
	cd $(FLUTTER_APP_DIR) && flutter build web --debug

flutter-build-android:
	cd $(FLUTTER_APP_DIR) && flutter build apk --debug

flutter-build-desktop: flutter-build-$(FLUTTER_DESKTOP_PLATFORM)

flutter-build-linux:
	cd $(FLUTTER_APP_DIR) && flutter build linux --debug

flutter-build-windows:
	cd $(FLUTTER_APP_DIR) && flutter build windows --debug

flutter-deploy: flutter-deploy-web flutter-deploy-android flutter-deploy-desktop

flutter-deploy-web:
	cd $(FLUTTER_APP_DIR) && flutter build web --release $(FLUTTER_DEFINES)

flutter-deploy-android:
	cd $(FLUTTER_APP_DIR) && flutter build apk --release $(FLUTTER_DEFINES)

flutter-deploy-desktop: flutter-deploy-$(FLUTTER_DESKTOP_PLATFORM)

flutter-deploy-linux:
	cd $(FLUTTER_APP_DIR) && flutter build linux --release $(FLUTTER_DEFINES)

flutter-deploy-windows:
	cd $(FLUTTER_APP_DIR) && flutter build windows --release $(FLUTTER_DEFINES)

flutter-docker-build:
	docker build -f docker/flutter.Dockerfile --target artifacts --build-arg API_BASE_URL=$(API_BASE_URL) --output type=local,dest=$(FLUTTER_ARTIFACTS_DIR) .

flutter-docker-build-windows:
	docker build -f docker/flutter-windows.Dockerfile --build-arg API_BASE_URL=$(API_BASE_URL) -t $(FLUTTER_WINDOWS_IMAGE) .
	docker create --name $(FLUTTER_WINDOWS_CONTAINER) $(FLUTTER_WINDOWS_IMAGE)
	docker cp $(FLUTTER_WINDOWS_CONTAINER):C:/artifacts/windows/. $(FLUTTER_ARTIFACTS_DIR)/windows
	docker rm $(FLUTTER_WINDOWS_CONTAINER)

flutter-package-windows:
	powershell -NoProfile -ExecutionPolicy Bypass -File flutter/scripts/package-windows.ps1 -ApiBaseUrl $(API_BASE_URL) -OutputDir $(FLUTTER_ARTIFACTS_DIR)

vscode-install:
	winget install -e --id Microsoft.VisualStudioCode

dotnet-install:
	winget install -e --id Microsoft.DotNet.SDK.10
