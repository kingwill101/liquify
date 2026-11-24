# Liquify documentation site

The static Jaspr Content build reads the Markdown in `pkgs/liquify/doc`.
The docs and playground use the same GitHub Pages base path.

From the repository root:

```sh
(cd pkgs/liquify && dart pub get && dart run build_runner build --release -o web:../liquify_pages)
bash site/build.sh
preview=$(mktemp -d)
mkdir -p "$preview/liquify"
cp -R pkgs/liquify_pages/. "$preview/liquify/"
python3 -m http.server 8083 --bind 127.0.0.1 --directory "$preview"
```

Open `http://127.0.0.1:8083/liquify/docs/` for the documentation or
`http://127.0.0.1:8083/liquify/` for the playground.

## Add an inline example

Use a `liquid-live` code fence. Put an optional `json-live` fence immediately
after it to supply the data. Without it, the example starts with `{}`.
Keep syntax diagrams and non-runnable snippets in ordinary `liquid` fences.
The live example builds with the playground and runs against the same
Liquify checkout in the browser.

For examples that use other templates, add a `files-live` fence after the
Liquid and optional data fences. Supply a JSON object mapping template
paths to source strings. Each file gets its own editor tab and travels with
the example when opened in the playground. The main template is
`index.liquid`.
