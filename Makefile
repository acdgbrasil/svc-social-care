SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help

.PHONY: help run deps build build-release dev test coverage coverage-report ci clean

help: ## Lista os comandos disponíveis
	@echo "Uso:"
	@echo "  make <target>"
	@echo "  make run <target>   # exemplo: make run dev"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

run: ## Alvo utilitário para usar no formato "make run <target>"
	@true

deps: ## Resolve dependências do SwiftPM
	swift package resolve

build: ## Build de debug
	swift build

build-release: ## Build de release
	swift build -c release --product social-care-s

dev: ## Executa o serviço localmente
	swift run social-care-s

test: ## Executa os testes
	swift test

coverage: ## Executa testes + gate de cobertura (95%)
	./scripts/check_coverage.sh 95

coverage-report: ## Gera cobertura e imprime caminho do relatório JSON
	swift test --enable-code-coverage
	@echo "Coverage JSON:"
	@swift test --show-codecov-path

ci: deps build-release coverage ## Pipeline local semelhante ao CI

clean: ## Limpa artefatos de build
	swift package clean
