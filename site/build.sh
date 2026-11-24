#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
dart pub get
dart analyze
dart run jaspr_cli:jaspr build

output=../../../pkgs/liquify_pages/docs
cd build/jaspr
mkdir -p "$output"
cp styles.css "$output/"
while IFS= read -r -d '' page; do
  mkdir -p "$output/$(dirname "$page")"
  cp "$page" "$output/$page"
done < <(find . -name packages -prune -o -name .dart_tool -prune -o -name index.html -type f -print0)
