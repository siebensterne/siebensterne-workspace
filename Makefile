.PHONY: help bootstrap status check-fieldbook-static check-nirnay-static check-nirnay check-all ci-report consistency audit package-review

WORKSPACE_DIR ?= $(CURDIR)

help:
	@printf '%s\n' \
	  'bootstrap             Clone or verify both pinned repositories' \
	  'status                Show heads, branches, dirt, remotes and CI runs' \
	  'check-fieldbook-static Run Fieldbook static gates (no fixture/e2e suite)' \
	  'check-nirnay-static   Run Nirnay static gates (no tests)' \
	  'check-nirnay          Run Nirnay full make check' \
	  'check-all             Run both static gate surfaces' \
	  'ci-report             Show latest hosted CI conclusion per repository' \
	  'consistency           Read-only tool, lock and shared-file audit' \
	  'audit                 status + consistency + all static gates' \
	  'package-review        build deterministic review ZIPs with manifests and bundles'

bootstrap:
	bash scripts/bootstrap.sh "$(WORKSPACE_DIR)"

status:
	bash scripts/status.sh "$(WORKSPACE_DIR)"

check-fieldbook-static:
	bash scripts/gates.sh fieldbook-static "$(WORKSPACE_DIR)"

check-nirnay-static:
	bash scripts/gates.sh nirnay-static "$(WORKSPACE_DIR)"

check-nirnay:
	bash scripts/gates.sh nirnay "$(WORKSPACE_DIR)"

check-all: check-fieldbook-static check-nirnay-static

ci-report:
	bash scripts/ci_report.sh "$(WORKSPACE_DIR)"

consistency:
	bash scripts/consistency.sh "$(WORKSPACE_DIR)"

audit: status consistency check-all

package-review:
	bash scripts/package_review.sh "$(WORKSPACE_DIR)" "$(WORKSPACE_DIR)/../siebensterne-review-packages"
