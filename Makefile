.PHONY: test test-fast test-full

test:
	bash tests/run.sh

test-fast:
	FAST_ONLY=1 bash tests/run.sh

# Alias for clarity
test-full: test


