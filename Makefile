.PHONY: test lint backup verify monitor demo
test:    ; bash tests/run_tests.sh
lint:    ; shellcheck -S warning -x -e SC1090,SC1091 scripts/*.sh tests/*.sh
backup:  ; bash scripts/backup.sh
verify:  ; bash scripts/verify_backup.sh
monitor: ; bash scripts/monitor.sh
demo:    ; bash demo/demo.sh
