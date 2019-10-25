.DEFAULT_GOAL := help
REGISTRY = atsip
APP_SRC = src
MONI = monitoring
#COMPOSE = ./docker/docker-compose.yml
help:
  @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

login: ## Login to docker hub
	docker login -u $(REGISTRY) --password-stdin $(DOCKER_PASSWORD)

build-app: app asterisk kamailio rtpproxy voice

build-monit: prometheus alertmanager

build-log: fluentd

fluentd:
	docker build -f logging/fluentd/Dockerfile -t $(REGISTRY)/fluentd logging/fluentd

app: ## Создание docker-образа для контейнера app
	docker build -f $(APP_SRC)/app/Dockerfile -t $(REGISTRY)/app $(APP_SRC)/app

asterisk: ## Создание  docker-образа для контейнера asterisk
	docker build -f $(APP_SRC)/asterisk/Dockerfile -t $(REGISTRY)/asterisk $(APP_SRC)/asterisk

kamailio: ## Создание docker-образа для контейнера kamailio
	docker build -f $(APP_SRC)/kamailio/Dockerfile -t $(REGISTRY)/kamailio $(APP_SRC)/kamailio
#/bin/bash $(APP_SRC)/kamailio/docker_build.sh

prometheus: ## Создание docker-образа для контейнера prometheus
	docker build -f $(MONI)/prometheus/Dockerfile -t $(REGISTRY)/prometheus $(MONI)/prometheus

alertmanager: ## Создание docker-образа для контейнера alertmanager
	docker build -f $(MONI)/alertmanager/Dockerfile -t $(REGISTRY)/alertmanager $(MONI)/alertmanager

rtpproxy: ## Создание docker-образа для контейнера rtpproxy
	docker build -f $(APP_SRC)/rtpproxy/Dockerfile -t $(REGISTRY)/rtpproxy $(MONI)/rtpproxy

voice: ## Создание docker-образа для контейнера voice
	docker build -f $(APP_SRC)/voice/Dockerfile -t $(REGISTRY)/voice $(MONI)/voice

push-images: ## Пуш созданных docker-образов в docker-registry
	docker push $(REGISTRY)/app
	docker push $(REGISTRY)/asterisk
	docker push $(REGISTRY)/kamailio
#	docker push $(REGISTRY)/prometheus
#	docker push $(REGISTRY)/alertmanager
	docker push $(REGISTRY)/rtpproxy
#	docker push $(REGISTRY)/cloudprober
	docker push $(REGISTRY)/voice

deploy: build-app build-log push-images ###Сборка и пуш всех образов

####################################################################################################
# Управление контейнерами с помощью docker-compose (dc)
####################################################################################################
dc-build: ## Сборка docker-образов согласно инструкциям из docker-compose.yml
	docker-compose -f $(COMPOSE) build

dc-up: ## Создание и запуск docker-контейнеров, описанных в docker-compose.yml
	docker-compose -f $(COMPOSE) up -d

dc-down: ## Остановка и УДАЛЕНИЕ docker-контейнеров, описанных в docker-compose.yml
	docker-compose -f $(COMPOSE) down

dc-stop: ## Остановка docker-контейнеров, описанных в docker-compose.yml
	docker-compose -f $(COMPOSE) stop

dc-start: ## Запуск docker-контейнеров, описанных в docker-compose.yml
	docker-compose -f $(COMPOSE) start
