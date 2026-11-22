#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: compare.sh [FIXTURE.json ...]"
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi

harness_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_dir="$(cd -- "$harness_dir/../.." && pwd)"
if (( $# == 0 )); then
  set -- "$harness_dir/issue_42.json" "$harness_dir/rendering.json"
fi

for fixture in "$@"; do
  if [[ ! -f $fixture || ! -r $fixture ]]; then
    printf 'Cannot read fixture file: %s\n' "$fixture" >&2
    exit 2
  fi
done

reference_output="$(mktemp)"
trap 'rm -f -- "$reference_output"' EXIT

image=liquify-shopify-liquid:15a2e32
docker build --tag "$image" "$harness_dir"

status=0
for fixture in "$@"; do
  case "$fixture" in
    /*) ;;
    *) fixture="$PWD/$fixture" ;;
  esac
  printf '\nComparing %s\n' "$fixture"
  docker run --rm --network none -i "$image" < "$fixture" > "$reference_output"
  (cd -- "$package_dir" && dart run tool/liquid_compat/compare.dart "$fixture" "$reference_output") || {
    result=$?
    if (( result != 1 )); then
      exit "$result"
    fi
    status=1
  }
done
exit "$status"
