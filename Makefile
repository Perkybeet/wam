.PHONY: help install dev-install build clean test lint format debian

help:
	@echo "WASM Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make install       Install WASM system-wide"
	@echo "  make dev-install   Install WASM in development mode"
	@echo "  make build         Build the package"
	@echo "  make clean         Remove build artifacts"
	@echo "  make test          Run tests"
	@echo "  make lint          Run linters"
	@echo "  make format        Format code"
	@echo "  make debian        Build Debian package"
	@echo ""

install:
	pip install .

dev-install:
	pip install -e ".[dev]"

build:
	python -m build

clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	rm -rf src/*.egg-info/
	rm -rf .pytest_cache/
	rm -rf .mypy_cache/
	rm -rf .coverage
	rm -rf htmlcov/
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete

test:
	pytest

test-cov:
	pytest --cov=wasm --cov-report=html
	@echo "Coverage report: htmlcov/index.html"

lint:
	ruff check src/wasm tests
	mypy src/wasm

format:
	black src/wasm tests
	isort src/wasm tests
	ruff check --fix src/wasm tests

debian: clean
	dpkg-buildpackage -us -uc -b
	@echo "Debian package built in parent directory"

debian-source: clean
	dpkg-buildpackage -us -uc -S
	@echo "Source package built in parent directory"
