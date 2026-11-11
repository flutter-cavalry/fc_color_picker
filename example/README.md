# fc_color_picker example

A small Flutter app that demonstrates the `fc_color_picker` package.

## Run

From this directory:

```sh
flutter pub get
flutter run -d chrome   # web
flutter run -d macos    # macOS
```

The example ships web and macOS runners. Other platform runners can be added
with `flutter create .`.

Tap **Pick a color** to open the Material color picker dialog. Cancelling the
dialog returns `null`, so the example keeps its previous selection.
