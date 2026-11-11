# fc_color_picker

[![pub package](https://img.shields.io/pub/v/fc_color_picker.svg)](https://pub.dev/packages/fc_color_picker)

A Material-based color picker for Flutter.

![The fc_color_picker dialog in the example app](doc/color_picker.webp)

## Usage

Call `fcPickColor` from any widget and use the returned `Color?`:

```dart
Future<void> _chooseColor() async {
  final color = await fcPickColor(
    context,
    initialColor: _selectedColor,
  );

  if (!mounted || color == null) {
    return; // The user cancelled or dismissed the dialog.
  }

  setState(() => _selectedColor = color);
}
```

### API

```dart
Future<Color?> fcPickColor(
  BuildContext context, {
  Color? initialColor,
  FcColorPickerStrings strings = FcColorPickerStrings.english,
  bool barrierDismissible = true,
})
```

| Parameter            | Default                        | Description                                        |
| -------------------- | ------------------------------ | -------------------------------------------------- |
| `initialColor`       | fresh green                    | The color selected when the dialog opens.          |
| `strings`            | `FcColorPickerStrings.english` | All visible UI strings and tooltips in the dialog. |
| `barrierDismissible` | `true`                         | Whether tapping outside the dialog closes it.      |

### Localization

```dart
final color = await fcPickColor(
  context,
  initialColor: _selectedColor,
  strings: const FcColorPickerStrings(
    title: 'Farbe wählen',
    cancel: 'Abbrechen',
    select: 'Übernehmen',
    copy: 'Kopieren',
  ),
);
```
