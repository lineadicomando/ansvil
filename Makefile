.PHONY: default check-env status ps up down start stop restart restart-soft logs logs-% pull update init shell help root-shell

DOCKER := $(shell command -v sudo >/dev/null 2>&1 && echo "sudo docker" || echo "docker")
ANSVIL_USER := $(shell grep 'ARG ANSVIL_USER=' ./core/Dockerfile | cut -d'=' -f2)

# Optional: include development-only targets from Makefile.local
-include Makefile.local

default: up

check-env: ## Ensure that the .env file exists and root or sudo is available
	@test -f .env || { echo "> Missing .env file. Please create it from .env.example"; exit 1; }
	@{ [ "$$(id -u)" -eq 0 ] || command -v sudo >/dev/null 2>&1; } || \
		{ echo "> This command requires root privileges or 'sudo' to be available."; exit 1; }

ps: ## Show the status of Docker Compose services
	@echo "> Checking Docker Compose services status..."
	@$(DOCKER) compose ps

status: ps ## Alias for ps

up: check-env ## Start Docker Compose services in background
	@echo "> Starting Docker Compose services..."
	@$(DOCKER) compose up -d

down: ## Stop and remove Docker Compose services
	@echo "> Stopping Docker Compose services..."
	@$(DOCKER) compose down

start: check-env ## Start existing Docker Compose containers
	@echo "> Starting existing Docker Compose services..."
	@$(DOCKER) compose start

stop: check-env ## Stop running Docker Compose containers without removing them
	@echo "> Stopping Docker Compose services..."
	@$(DOCKER) compose stop

restart: down up ## Restart Docker Compose services (full rebuild)

restart-soft: stop start ## Restart services without recreating containers

logs: ## Show logs from all services
	@echo "> Showing logs from all services..."
	@$(DOCKER) compose logs -f

logs-%: ## Show logs from a specific service
	@echo "> Showing logs for service '$*'..."
	@$(DOCKER) compose logs $ -f

pull: check-env ## Pull latest Docker images
	@echo "> Pulling Docker Compose images..."
	@$(DOCKER) compose pull

update: pull restart ## Pull and restart all services

init: ## Initialize .env file from .env.example
	@if [ ! -f .env.example ]; then \
		echo "> Error: .env.example not found."; \
		exit 1; \
	fi
	@if [ -f .env ]; then \
		echo "> .env file already exists. No action taken."; \
	else \
		cp .env.example .env && echo "> .env file created from .env.example."; \
		default1=$$(grep "^SEMAPHORE_ADMIN_DEFAULT_PASSWORD=" .env.example | cut -d= -f2- | cut -d"'" -f2); \
		default2=$$(grep "^CODE_SERVER_DEFAULT_PASSWORD=" .env.example | cut -d= -f2- | cut -d"'" -f2); \
		read -p "Enter SEMAPHORE_ADMIN_DEFAULT_PASSWORD [$$default1]: " input1; \
		SEMAPHORE_PASSWORD=$${input1:-$$default1}; \
		read -p "Enter CODE_SERVER_DEFAULT_PASSWORD [$$default2]: " input2; \
		CODE_PASSWORD=$${input2:-$$default2}; \
		sed -i "s/^SEMAPHORE_ADMIN_DEFAULT_PASSWORD=.*/SEMAPHORE_ADMIN_DEFAULT_PASSWORD='$$SEMAPHORE_PASSWORD'/" .env; \
		sed -i "s/^CODE_SERVER_DEFAULT_PASSWORD=.*/CODE_SERVER_DEFAULT_PASSWORD='$$CODE_PASSWORD'/" .env; \
		echo "> Passwords set. You can further customize settings by editing the .env file."; \
	fi


shell: check-env ## Enter the container shell as the application user
	@echo "> Opening container shell as user '$(ANSVIL_USER)'..."
	@$(DOCKER) compose exec core sudo -u $(ANSVIL_USER) -i bash

root-shell: check-env ## Enter the root shell of the 'core' container
	@echo "> Opening container shell..."
	@$(DOCKER) compose exec core sudo -i

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(firstword $(MAKEFILE_LIST)) | sed -n 's/^\([^:]*\):.*## \(.*\)/\1|\2/p' | while IFS='|' read -r target desc; do \
		printf "  %-17s %s\n" "$$target" "$$desc"; \
	done
	@if [ "$(firstword $(MAKEFILE_LIST))" != "$(lastword $(MAKEFILE_LIST))" ]; then \
		echo ""; \
		echo "Additional local commands:"; \
		grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(lastword $(MAKEFILE_LIST)) | sed -n 's/^\([^:]*\):.*## \(.*\)/\1|\2/p' | while IFS='|' read -r target desc; do \
			printf "  %-17s %s\n" "$$target" "$$desc"; \
		done \
	fi
