.PHONY: help install upgrade doctor emulators emulator-launch analyze test coverage format clean \
	run run-web run-android run-linux run-windows \
	build build-web build-android build-desktop build-linux build-windows \
	deploy deploy-web deploy-android deploy-desktop deploy-linux deploy-windows \
	package package-windows docker-build-windows

CLIENT_DIR := ../template-flutter-api-client
API_BASE_URL ?= http://localhost:8989
FLUTTER_DEFINES := --dart-define=API_BASE_URL=$(API_BASE_URL)
RELEASES_DIR := build/releases
WINDOWS_IMAGE := template-flutter-windows
WINDOWS_CONTAINER := template-flutter-windows-artifacts

ifeq ($(OS),Windows_NT)
DESKTOP_PLATFORM := windows
else
DESKTOP_PLATFORM := linux
endif

help:
	@echo Available commands:
	@echo   make install               Resolve application and client dependencies
	@echo   make upgrade               Upgrade application dependencies
	@echo   make doctor                Diagnose the Flutter environment
	@echo   make emulators             List available Flutter emulators
	@echo   make emulator-launch       Launch the Medium_Phone emulator
	@echo   make analyze               Analyze the application
	@echo   make test                  Run application and client tests
	@echo   make coverage              Generate application coverage
	@echo   make format                Format Dart sources
	@echo   make run-web/android/linux/windows  Run the application
	@echo   make build                 Build debug artifacts for Web, Android and the current desktop OS
	@echo   make deploy                Build release artifacts for Web, Android and the current desktop OS
	@echo   make package               Package Android and Linux releases into build/releases (Linux host)
	@echo   make package-windows       Package the Windows release into build/releases (Windows host)
	@echo   make docker-build-windows  Package the Windows release in a Windows container
	@echo   Release and package targets accept API_BASE_URL=https://api.example.com

install:
	cd $(CLIENT_DIR) && dart pub get
	flutter pub get

upgrade:
	flutter pub upgrade

doctor:
	flutter doctor -v

emulators:
	flutter emulators

emulator-launch:
	flutter emulators --launch Medium_Phone

analyze:
	flutter analyze

test:
	cd $(CLIENT_DIR) && dart test
	flutter test

coverage:
	flutter test --coverage

format:
	dart format lib test

clean:
	flutter clean

run: run-web

run-web:
	flutter run -d chrome --web-port 7357

run-android:
	flutter run

run-linux:
	flutter run -d linux

run-windows:
	flutter run -d windows

build: build-web build-android build-desktop

build-web:
	flutter build web --debug

build-android:
	flutter build apk --debug

build-desktop: build-$(DESKTOP_PLATFORM)

build-linux:
	flutter build linux --debug

build-windows:
	flutter build windows --debug

deploy: deploy-web deploy-android deploy-desktop

deploy-web:
	flutter build web --release $(FLUTTER_DEFINES)

deploy-android:
	flutter build apk --release $(FLUTTER_DEFINES)

deploy-desktop: deploy-$(DESKTOP_PLATFORM)

deploy-linux:
	flutter build linux --release $(FLUTTER_DEFINES)

deploy-windows:
	flutter build windows --release $(FLUTTER_DEFINES)

package:
	API_BASE_URL=$(API_BASE_URL) OUTPUT_DIR=$(RELEASES_DIR) bash scripts/package-release.sh android linux

package-windows:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/package-windows.ps1 -ApiBaseUrl $(API_BASE_URL) -OutputDir $(RELEASES_DIR)

docker-build-windows:
	docker build -f Dockerfile --build-arg API_BASE_URL=$(API_BASE_URL) -t $(WINDOWS_IMAGE) ..
	docker create --name $(WINDOWS_CONTAINER) $(WINDOWS_IMAGE)
	docker cp $(WINDOWS_CONTAINER):C:/artifacts/windows/. $(RELEASES_DIR)/windows
	docker rm $(WINDOWS_CONTAINER)
