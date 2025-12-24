.DEFAULT_GOAL := help

.PHONY: help lint test install uninstall package

help:
	@echo "Targets:"
	@echo "  lint       Run shellcheck on scripts"
	@echo "  test       Run the test suite"
	@echo "  install    Run the installer (requires sudo)"
	@echo "  uninstall  Run the uninstaller (requires sudo)"
	@echo "  package    Build a versioned tarball in dist/"

lint:
	shellcheck bin/nvidia-run scripts/install.sh scripts/uninstall.sh tests/*.sh

test:
	./tests/run-tests.sh

install:
	sudo ./scripts/install.sh

uninstall:
	sudo ./scripts/uninstall.sh

package:
	./scripts/package.sh
