.PHONY: help build push deploy test analyze clean run up down

IMAGE_TAG ?= forgejo.home/ali/mystcrochet-app:latest
PLATFORM ?= linux/arm64

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build Flutter web bundle
	flutter build web --base-href /

push: ## Build docker image with buildx for arm64 and push to registry
	docker buildx build --platform $(PLATFORM) -t $(IMAGE_TAG) --push .

deploy: build push ## Build web bundle and push docker image

test: ## Run Flutter tests
	flutter test

analyze: ## Run Flutter static analysis
	flutter analyze

run: ## Run Flutter web locally in Chrome
	flutter run -d chrome

up: ## Start docker compose container
	docker compose up -d

down: ## Stop docker compose container
	docker compose down

clean: ## Clean Flutter build cache
	flutter clean
