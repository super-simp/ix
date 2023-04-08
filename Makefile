DOCKER_COMPOSE=docker-compose.yml
DOCKERFILE=Dockerfile
DOCKER_REGISTRY=ghcr.io
DOCKER_REPOSITORY=${DOCKER_REGISTRY}/ix
PYTHON_DEPENDENCIES=requirements*.txt
IMAGE_TAG=$(shell cat $(DOCKERFILE) $(PYTHON_DEPENDENCIES) | md5sum | cut -d ' ' -f 1)
IMAGE_URL=$(DOCKER_REPOSITORY):$(IMAGE_TAG)
IMAGE_SENTINEL=.sentinel/image

DOCKER_COMPOSE_RUN=docker-compose run -p 8000:8000 --rm sandbox

NO_IMAGE_BUILD?=0


.PHONY: image-tag
image-tag:
	@echo ${IMAGE_TAG}

.PHONY: image-url
image-url:
	@echo ${IMAGE_URL}


.sentinel:
	mkdir -p .sentinel

${IMAGE_SENTINEL}: .sentinel $(DOCKERFILE) $(PYTHON_DEPENDENCIES)
ifneq (${NO_IMAGE_BUILD}, 1)
	echo building ${IMAGE_URL}
	docker build -t ${IMAGE_URL} -f $(DOCKERFILE) .
	docker tag ${IMAGE_URL} ${DOCKER_REPOSITORY}:latest
	touch $@
endif

.PHONY: image
image: ${IMAGE_SENTINEL}

.PHONY: compose
compose: image

.PHONY: shell
shell: compose
	${DOCKER_COMPOSE_RUN} /bin/bash

.PHONY: test
test: compose pytest

.PHONY: lint
test: compose flake8 black-check

.PHONY: format
format: black isort

.PHONY: black
black: compose
	${DOCKER_COMPOSE_RUN} black .

.PHONY: black-check
black-check: compose
	${DOCKER_COMPOSE_RUN} black --check .

.PHONY: flake8
flake8: compose
	${DOCKER_COMPOSE_RUN} flake8 .

.PHONY: isort
isort: compose
	${DOCKER_COMPOSE_RUN} isort .

.PHONY: pytest
pytest: compose
	${DOCKER_COMPOSE_RUN} pytest

.PHONY: pyright
pyright: compose
	${DOCKER_COMPOSE_RUN} pyright


.PHONY: webpack
webpack: compose
	docker-compose run --rm sandbox /bin/bash


.PHONY: webpack-watch
webpack-watch: compose
	${DOCKER_COMPOSE_RUN} webpack --watch


.PHONY: clean
clean:
	rm -rf .sentinel