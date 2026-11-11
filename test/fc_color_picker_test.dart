import 'package:fc_color_picker/fc_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _svPanelKey = Key('fc-color-picker-sv-panel');
const _hueSliderKey = Key('fc-color-picker-hue-slider');
const _hexFieldKey = Key('fc-color-picker-hex-field');
const _copyButtonKey = Key('fc-color-picker-copy');
const _selectButtonKey = Key('fc-color-picker-select');
const _cancelButtonKey = Key('fc-color-picker-cancel');

void main() {
  Widget buildApp({
    required ValueChanged<Color?> onResult,
    Color? initialColor,
    FcColorPickerStrings strings = FcColorPickerStrings.english,
    bool barrierDismissible = true,
  }) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await fcPickColor(
                  context,
                  initialColor: initialColor,
                  strings: strings,
                  barrierDismissible: barrierDismissible,
                );
                onResult(result);
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
  }

  String displayedHex(WidgetTester tester) {
    final field = tester.widget<TextField>(find.byKey(_hexFieldKey));
    return field.controller!.text;
  }

  testWidgets('opens with the initial color and returns it on select', (
    tester,
  ) async {
    Color? result;
    await tester.pumpWidget(
      buildApp(
        initialColor: const Color(0xFF123456),
        onResult: (color) => result = color,
      ),
    );

    await openPicker(tester);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Pick a color'), findsOneWidget);
    expect(displayedHex(tester), '#123456');

    await tester.tap(find.byKey(_selectButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(result, const Color(0xFF123456));
  });

  testWidgets('uses the default green when no initial color is provided', (
    tester,
  ) async {
    Color? result;
    await tester.pumpWidget(buildApp(onResult: (color) => result = color));

    await openPicker(tester);

    expect(displayedHex(tester), '#61C72E');

    await tester.tap(find.byKey(_selectButtonKey));
    await tester.pumpAndSettle();

    expect(result, const Color(0xFF61C72E));
  });

  testWidgets('preserves the alpha channel of the initial color', (
    tester,
  ) async {
    Color? result;
    await tester.pumpWidget(
      buildApp(
        initialColor: const Color(0x80123456),
        onResult: (color) => result = color,
      ),
    );

    await openPicker(tester);
    expect(displayedHex(tester), '#123456');

    await tester.tap(find.byKey(_selectButtonKey));
    await tester.pumpAndSettle();

    expect(result, const Color(0x80123456));
  });

  testWidgets('returns null when the user cancels', (tester) async {
    Color? result;
    var completed = false;
    await tester.pumpWidget(
      buildApp(
        onResult: (color) {
          result = color;
          completed = true;
        },
      ),
    );

    await openPicker(tester);
    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('returns null when the barrier is tapped', (tester) async {
    Color? result;
    var completed = false;
    await tester.pumpWidget(
      buildApp(
        onResult: (color) {
          result = color;
          completed = true;
        },
      ),
    );

    await openPicker(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('stays open when the barrier is not dismissible', (tester) async {
    await tester.pumpWidget(
      buildApp(barrierDismissible: false, onResult: (_) {}),
    );

    await openPicker(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();
  });

  testWidgets('changes hue when the hue slider is tapped', (tester) async {
    await tester.pumpWidget(
      buildApp(initialColor: const Color(0xFFFF0000), onResult: (_) {}),
    );

    await openPicker(tester);
    expect(displayedHex(tester), '#FF0000');

    final hueCenter = tester.getCenter(find.byKey(_hueSliderKey));
    await tester.tapAt(hueCenter);
    await tester.pump();

    // The middle of the hue spectrum is cyan.
    expect(displayedHex(tester), '#00FFFF');

    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();
  });

  testWidgets('changes brightness when the saturation/value panel is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(initialColor: const Color(0xFFFF0000), onResult: (_) {}),
    );

    await openPicker(tester);

    final panel = find.byKey(_svPanelKey);
    final panelRect = tester.getRect(panel);
    await tester.tapAt(Offset(panelRect.left + 4, panelRect.bottom - 4));
    await tester.pump();

    final bottomLeft = displayedHex(tester);
    expect(bottomLeft, isNot('#FF0000'));
    expect(bottomLeft, startsWith('#'));

    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();
  });

  testWidgets('fits on a narrow phone screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(onResult: (_) {}));
    await openPicker(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(_hexFieldKey), findsOneWidget);
    expect(find.byKey(_copyButtonKey), findsOneWidget);
    expect(find.byKey(_selectButtonKey), findsOneWidget);

    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();
  });

  testWidgets('uses custom strings for every label and tooltip', (
    tester,
  ) async {
    const strings = FcColorPickerStrings(
      title: 'Farbe wählen',
      cancel: 'Abbrechen',
      select: 'Übernehmen',
      copy: 'Kopieren',
    );

    await tester.pumpWidget(buildApp(strings: strings, onResult: (_) {}));
    await openPicker(tester);

    expect(find.text('Farbe wählen'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Übernehmen'), findsOneWidget);
    expect(find.byTooltip('Kopieren'), findsOneWidget);
    expect(find.text('Pick a color'), findsNothing);

    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();
  });

  testWidgets('copies the hex value and shows a confirmation', (tester) async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      buildApp(initialColor: const Color(0xFF61C72E), onResult: (_) {}),
    );

    await openPicker(tester);
    await tester.tap(find.byKey(_copyButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final clipboardCalls = calls.where(
      (call) => call.method == 'Clipboard.setData',
    );
    expect(clipboardCalls, hasLength(1));
    expect(
      (clipboardCalls.single.arguments as Map<Object?, Object?>)['text'],
      '#61C72E',
    );
    final copyButton = find.byKey(_copyButtonKey);
    expect(
      find.descendant(
        of: copyButton,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Copy'), findsOneWidget);

    // Let the confirmation timer expire before closing the dialog.
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.descendant(
        of: copyButton,
        matching: find.byIcon(Icons.content_copy_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(_cancelButtonKey));
    await tester.pumpAndSettle();
  });
}
