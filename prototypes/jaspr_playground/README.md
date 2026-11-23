# Jaspr playground prototype

This client-mode Jaspr app uses the local Liquify package. Run these commands
from this directory to build and serve the static site.

```sh
dart pub get
dart run build_runner build --release -o web:build/site
python3 -m http.server 8081 --bind 127.0.0.1 --directory build/site
```

Open `http://127.0.0.1:8081`. To open a workspace from the other playground,
append its `#workspace=v1.…` fragment to the prototype URL.

The Jaspr Playground workflow runs the same build and uploads the resulting
static site as the `jaspr-playground` artifact.
