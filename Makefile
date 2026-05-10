.PHONY: install dev test lint format build clean

install:
	pip install -e .

dev:
	pip install -e ".[dev]" || pip install -e .
	pip install -r requirements-dev.txt

test:
	pytest -v --cov=neo_stopmotion --cov-report=term-missing

lint:
	ruff check src tests
	mypy src

format:
	ruff format src tests
	ruff check --fix src tests

run:
	python -m neo_stopmotion

run-sim:
	NEO_STOPMOTION_UART=simulator python -m neo_stopmotion

build:
	python -m build

clean:
	rm -rf build dist *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
