#!/usr/bin/env bash

set -xeuo pipefail

source /usr/local/greengage-db-devel/greengage_path.sh
source /home/gpadmin/gpdb_src/gpAux/gpdemo/gpdemo-env.sh

errors=0

make installcheck || errors=$(( errors + $? ))

tar --dereference -czf "/logs/result.tar.gz" results
cp regression.diffs /logs/regression.diffs || true

if (( errors > 0 )); then
  cat regression.diffs || true
  exit 1
fi
exit 0
