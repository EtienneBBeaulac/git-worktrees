.PHONY: test test-fast test-full test-unit test-integration test-e2e test-performance test-regression
.PHONY: test-all test-quick lint coverage clean help install

# Default target
.DEFAULT_GOAL := help

#===============================================================================
# Help
#===============================================================================

help: ## Show this help message
	@echo "Git Worktrees - Make targets"
	@echo ""
	@echo "Test targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

#===============================================================================
# Test Targets
#===============================================================================

test: ## Run all tests (legacy + new framework)
	@echo "Running legacy test suite..."
	@bash tests/run.sh
	@echo ""
	@echo "Running new test framework..."
	@zsh tests/run_all.zsh all

test-fast: ## Run fast subset of tests (for pre-commit)
	@FAST_ONLY=1 bash tests/run.sh
	@zsh tests/run_all.zsh unit --filter quick

test-full: test ## Alias for 'test' (runs everything)

test-all: ## Run comprehensive test suite with new framework
	@zsh tests/run_all.zsh all

test-unit: ## Run unit tests only
	@zsh tests/run_all.zsh unit

test-integration: ## Run integration tests
	@zsh tests/run_all.zsh integration

test-integration-fast: ## Run fast integration tests (for pre-commit)
	@zsh tests/run_all.zsh integration --filter quick

test-e2e: ## Run end-to-end tests
	@zsh tests/run_all.zsh e2e

test-e2e-critical: ## Run critical E2E tests only
	@zsh tests/run_all.zsh e2e --filter critical

test-performance: ## Run performance benchmarks
	@zsh tests/run_all.zsh performance

test-regression: ## Run regression tests
	@zsh tests/run_all.zsh regression

test-regression-fast: ## Run fast regression tests (for pre-commit)
	@zsh tests/run_all.zsh regression --filter fast

#===============================================================================
# Code Quality
#===============================================================================

lint: ## Check code style and syntax
	@echo "Checking syntax..."
	@for script in scripts/wt scripts/wtnew scripts/wtrm scripts/wtopen scripts/wtls scripts/lib/*.zsh; do \
		if [ -f "$$script" ]; then \
			echo "  Checking $$script..."; \
			zsh -fn "$$script" || exit 1; \
		fi \
	done
	@echo "Syntax check passed ✓"
	@echo ""
	@echo "Running shellcheck (if available)..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find scripts tests -name "*.zsh" -o -name "*.sh" | xargs shellcheck -x || true; \
	else \
		echo "  shellcheck not installed, skipping"; \
	fi

#===============================================================================
# Coverage & Reporting
#===============================================================================

coverage: ## Generate test coverage report
	@echo "Generating coverage report..."
	@mkdir -p .coverage
	@zsh tests/run_all.zsh all -v > .coverage/test_output.txt 2>&1 || true
	@echo "Coverage report saved to .coverage/test_output.txt"
	@echo ""
	@echo "Test Summary:"
	@tail -20 .coverage/test_output.txt

#===============================================================================
# Utility
#===============================================================================

clean: ## Clean test artifacts and temporary files
	@echo "Cleaning test artifacts..."
	@rm -rf /tmp/wt-test-* /tmp/test.* || true
	@rm -rf .coverage/ || true
	@rm -rf tests/.cache/ || true
	@find tests -name "*.log" -delete || true
	@echo "Clean complete ✓"

watch: ## Watch for changes and run fast tests
	@echo "Watching for changes (requires fswatch)..."
	@if command -v fswatch >/dev/null 2>&1; then \
		fswatch -o scripts/ tests/ | xargs -n1 make test-fast; \
	else \
		echo "ERROR: fswatch not installed"; \
		echo "Install with: brew install fswatch"; \
		exit 1; \
	fi

#===============================================================================
# Installation
#===============================================================================

install: ## Install git-worktrees
	@echo "Installing..."
	@bash install.sh

install-dry: ## Dry-run installation (show what would be installed)
	@DRY_RUN=1 bash install.sh

#===============================================================================
# Development
#===============================================================================

dev-setup: ## Setup development environment
	@echo "Setting up development environment..."
	@chmod +x scripts/* tests/*.sh tests/*.zsh tests/run_all.zsh
	@chmod +x tests/lib/*.sh tests/lib/*.zsh
	@echo "Development environment ready ✓"

test-debug: ## Run tests with debug output
	@TEST_DEBUG=1 WT_DEBUG=1 zsh tests/run_all.zsh all -v

#===============================================================================
# CI/CD
#===============================================================================

ci-test: ## Run tests in CI environment
	@export CI=1; \
	export GIT_CONFIG_NOSYSTEM=1; \
	export GIT_CONFIG_GLOBAL=/dev/null; \
	zsh tests/run_all.zsh all

ci-lint: lint ## Lint code (for CI)

ci-all: ci-lint ci-test ## Run all CI checks

#===============================================================================
# Aliases (legacy compatibility)
#===============================================================================

# Keep legacy targets for backwards compatibility
test-quick: test-fast ## Alias for test-fast
