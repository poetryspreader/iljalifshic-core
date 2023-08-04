#!/usr/bin/make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

docker_bin := $(shell command -v docker 2> /dev/null)
dc_bin := $(shell command -v docker-compose 2> /dev/null)
dc_app_name = console
cwd = $(shell pwd)

SHELL = /bin/bash
CURRENT_USER = $(shell id -u):$(shell id -g)
RUN_APP_ARGS = --rm --user "$(CURRENT_USER)" "$(dc_app_name)"

define print
	printf " \033[33m[%s]\033[0m \033[32m%s\033[0m\n" $1 $2
endef
define print_block
	printf " \e[30;48;5;82m  %s  \033[0m\n" $1
endef

.PHONY : help \
		 install init shell test test-cover \
		 up down restart logs clean git-hooks pull
.SILENT : help install up down shell
.DEFAULT_GOAL : help

# This will output the help for each task. thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install all app dependencies
	$(dc_bin) run $(RUN_APP_ARGS) composer install --no-interaction --ansi --prefer-dist --no-scripts

image:
	#docker login
	#docker pull php:8.1

init: image install db-create db-migrate ## Make full application initialization (install, seed, build assets, etc)

shell: ## Start shell into app container
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) bash

start: ## Create and start containers
	CURRENT_USER=$(CURRENT_USER) $(dc_bin) up -d
	$(call print_block, 'Navigate your browser to         ⇒ http://api.local.joolpay.com')


stop: ## Stop and remove containers, networks, images, and volumes
	$(dc_bin) down -t 5

restart: down up ## Restart all containers

logs: ## Show docker logs
	$(dc_bin) logs --follow

clean: ## Make some clean
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) composer clear
	$(dc_bin) down -v -t 5

git-hooks: ## Install (reinstall) git hooks (required after repository cloning)
	-rm -f "$(cwd)/.git/hooks/pre-push" "$(cwd)/.git/hooks/pre-commit" "$(cwd)/.git/hooks/post-merge"
# 	ln -s "$(cwd)/.gitlab/git-hooks/pre-push.sh" "$(cwd)/.git/hooks/pre-push"
# 	ln -s "$(cwd)/.gitlab/git-hooks/pre-commit.sh" "$(cwd)/.git/hooks/pre-commit"
	ln -s "$(cwd)/.gitlab/git-hooks/post-merge.sh" "$(cwd)/.git/hooks/post-merge"

pull: ## Pulling newer versions of used docker images
	$(dc_bin) pull

ecs-fix:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) vendor/bin/ecs check src tests migrations --fix --clear-cache

rector:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) vendor/bin/rector process src/ --ansi --dry-run

rector-fix:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) vendor/bin/rector process src/ --ansi

phpstan:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) ./vendor/bin/phpstan analyse -c .phpstan.neon

consume:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) bin/console messenger:consume async -vv

db-create:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) bin/console doctrine:database:create -n --if-not-exists

db-diff:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) bin/console doctrine:migration:diff -n

db-migrate:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) bin/console d:m:m -n --allow-no-migration

db-migrate-test:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e APP_ENV=test $(RUN_APP_ARGS) bin/console d:m:m -n --allow-no-migration

fixtures:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e APP_ENV=test $(RUN_APP_ARGS) bin/console doctrine:fixtures:load -n

db-create-testing:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e APP_ENV=test $(RUN_APP_ARGS) ./bin/console --env=test doctrine:database:create --if-not-exists

run-test:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e APP_ENV=test $(RUN_APP_ARGS) vendor/bin/phpunit

run-unit-test:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false $(RUN_APP_ARGS) vendor/bin/phpunit --testsuite "Unit Test Suite"

compile-openapi:
	npx @redocly/openapi-cli bundle docs/openapi-client/openapi.yaml > docs/openapi.client.bundle.yaml

compile-operator-openapi:
	npx @redocly/openapi-cli bundle docs/openapi-operator/openapi.yaml > docs/openapi.operator.bundle.yaml

test: db-create-testing db-migrate-test fixtures run-test

unit-test: run-unit-test

db-drop-testing:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e APP_ENV=test $(RUN_APP_ARGS) bin/console doctrine:schema:drop --full-database --force -n

db-drop:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e $(RUN_APP_ARGS) bin/console doctrine:schema:drop --full-database --force -n

db-validate:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e $(RUN_APP_ARGS) bin/console doctrine:schema:validate -n

consumer:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e $(RUN_APP_ARGS) bin/console messenger:consume async -vv

operator-add:
	$(dc_bin) run -e STARTUP_WAIT_FOR_SERVICES=false -e $(RUN_APP_ARGS) bin/console operator:add $(username) $(password)