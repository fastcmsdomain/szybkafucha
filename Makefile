SHELL := /bin/bash

.PHONY: hooks-install mobile-quality mobile-platform mobile-check mobile-check-last-commit mobile-check-all mobile-check-staged

MOBILE_QUALITY_SCRIPT := mobile/scripts/flutter_quality_gate.sh
MOBILE_PLATFORM_SCRIPT := mobile/scripts/platform_compliance_gate.sh

hooks-install:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit
	@echo "Git hooks installed (.githooks/pre-commit)."

mobile-quality:
	$(MOBILE_QUALITY_SCRIPT) --scope changed

mobile-platform:
	$(MOBILE_PLATFORM_SCRIPT) --scope changed --skip-analyze

mobile-check: mobile-quality mobile-platform

mobile-check-last-commit:
	$(MOBILE_QUALITY_SCRIPT) --scope last-commit
	$(MOBILE_PLATFORM_SCRIPT) --scope last-commit --skip-analyze

mobile-check-all:
	$(MOBILE_QUALITY_SCRIPT) --scope all
	$(MOBILE_PLATFORM_SCRIPT) --scope all --skip-analyze

mobile-check-staged:
	@set -euo pipefail; \
	staged_files="$$(git diff --cached --name-only --diff-filter=ACMRTUXB -- mobile/lib | rg '\.dart$$' || true)"; \
	if [ -z "$$staged_files" ]; then \
		echo "No staged mobile Dart files. Skipping quality gates."; \
		exit 0; \
	fi; \
	echo "Running Flutter quality gate on staged files..."; \
	printf '%s\n' "$$staged_files" | xargs $(MOBILE_QUALITY_SCRIPT); \
	screen_files="$$(printf '%s\n' "$$staged_files" | rg '^mobile/lib/features/.*/screens/.*\.dart$$' || true)"; \
	if [ -z "$$screen_files" ]; then \
		echo "No staged screen files. Skipping platform compliance gate."; \
		exit 0; \
	fi; \
	echo "Running platform compliance gate on staged screen files..."; \
	printf '%s\n' "$$screen_files" | xargs $(MOBILE_PLATFORM_SCRIPT) --skip-analyze
