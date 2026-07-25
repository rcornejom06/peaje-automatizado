.PHONY: help version clean pub-get build-env build-apk
SHELL := /bin/bash

# Comandos para generar las APK de mobile_user_app (ViaSmart).
# Solo lo necesario: generar el env (envied) y compilar APK dev/prod.

help:
	@echo 'make build-env             -> genera lib/env/env.g.dart desde .env (envied)'
	@echo 'make build-apk flavor=dev  -> APK con entorno de desarrollo'
	@echo 'make build-apk flavor=prod -> APK con entorno de produccion'

version:
	fvm use 3.41.9

clean:
	rm -rf ./build ./android/app/build/
	rm -rf .dart_tool .flutter-plugins .flutter-plugins-dependencies
	rm -rf pubspec.lock
	fvm flutter clean

pub-get:
	fvm flutter pub get

build-env: version clean pub-get
	fvm flutter pub run build_runner build

build-apk:
	if [ "$(flavor)" == "dev" ]; then \
		fvm flutter build apk -t lib/main/main_dev.dart --flavor dev --obfuscate --split-debug-info=debug; \
	elif [ "$(flavor)" == "prod" ]; then \
		fvm flutter build apk -t lib/main/main_prod.dart --flavor prod --obfuscate --split-debug-info=debug; \
	else \
		echo "Uso: make build-apk flavor=dev  |  make build-apk flavor=prod"; \
	fi
