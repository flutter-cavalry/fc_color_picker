import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The color shown when [fcPickColor] is called without an initial color.
const Color _kDefaultColor = Color(0xFF61C72E);

/// Every visible string and tooltip used by the color picker dialog.
///
/// All fields are required so that a localized app never falls back to
/// English text. Pass an instance to [fcPickColor] through its `strings`
/// parameter to translate the dialog.
///
/// ```dart
/// const strings = FcColorPickerStrings(
///   title: 'Choose a color',
///   cancel: 'Cancel',
///   select: 'Select',
///   copy: 'Copy',
/// );
/// ```
@immutable
class FcColorPickerStrings {
  const FcColorPickerStrings({
    required this.title,
    required this.cancel,
    required this.select,
    required this.copy,
  });

  /// The dialog headline.
  final String title;

  /// The label of the cancel action.
  final String cancel;

  /// The label of the confirm action.
  final String select;

  /// The tooltip of the copy button next to the hex field.
  final String copy;

  /// The English strings used when [fcPickColor] receives no `strings`.
  static const FcColorPickerStrings english = FcColorPickerStrings(
    title: 'Pick a color',
    cancel: 'Cancel',
    select: 'Select',
    copy: 'Copy',
  );
}

/// Opens a Material color picker dialog and returns the selected color.
///
/// The dialog shows a saturation/value panel, a hue slider, a read-only hex
/// field with a copy button, and cancel / select actions. It is fully themed
/// by the surrounding [Theme], including light and dark themes.
///
/// Returns the chosen color when the user confirms, or `null` when the user
/// cancels or dismisses the dialog.
///
/// [initialColor] is preselected when the dialog opens. Its alpha channel is
/// preserved in the returned color; the picker itself edits only hue,
/// saturation and value. When omitted, a fresh green is used.
///
/// [strings] supplies every visible string and tooltip in the dialog.
/// It defaults to [FcColorPickerStrings.english]. Set [barrierDismissible] to
/// `false` to require an explicit action.
///
/// ```dart
/// final color = await fcPickColor(context, initialColor: Colors.green);
/// if (color != null) {
///   setState(() => _selectedColor = color);
/// }
/// ```
Future<Color?> fcPickColor(
  BuildContext context, {
  Color? initialColor,
  FcColorPickerStrings strings = FcColorPickerStrings.english,
  bool barrierDismissible = true,
}) {
  return showDialog<Color>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => _ColorPickerDialog(
      initialColor: initialColor ?? _kDefaultColor,
      strings: strings,
    ),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor, required this.strings});

  final Color initialColor;
  final FcColorPickerStrings strings;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;
  late Color _selectedColor;
  late final TextEditingController _hexController;
  Timer? _copiedResetTimer;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hsv = HSVColor.fromColor(_selectedColor);
    _hexController = TextEditingController(text: _hex);
  }

  @override
  void dispose() {
    _copiedResetTimer?.cancel();
    _hexController.dispose();
    super.dispose();
  }

  Color get _color => _selectedColor;

  String get _hex {
    final rgb = _color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _setHue(double fraction) {
    // Keep the hue just below 360 so the marker stays at the right edge
    // instead of wrapping back to the start of the spectrum.
    final hue = (fraction.clamp(0.0, 1.0) * 360.0)
        .clamp(0.0, 359.999)
        .toDouble();
    _updateColor(_hsv.withHue(hue));
  }

  void _setSaturationValue(double saturation, double value) {
    _updateColor(
      _hsv
          .withSaturation(saturation.clamp(0.0, 1.0).toDouble())
          .withValue(value.clamp(0.0, 1.0).toDouble()),
    );
  }

  void _updateColor(HSVColor next) {
    if (_copiedResetTimer != null) {
      _copiedResetTimer!.cancel();
      _copiedResetTimer = null;
    }
    setState(() {
      _hsv = next;
      _selectedColor = next.toColor();
      _copied = false;
    });
    _hexController.text = _hex;
  }

  Future<void> _copyHex() async {
    await Clipboard.setData(ClipboardData(text: _hex));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _copiedResetTimer?.cancel();
    _copiedResetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = math.min(480.0, math.max(0.0, screenWidth - 40));

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: widget.strings.title,
      child: Dialog(
        key: const Key('fc-color-picker-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        clipBehavior: Clip.antiAlias,
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      widget.strings.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SaturationValuePanel(
                    hue: _hsv.hue,
                    saturation: _hsv.saturation,
                    value: _hsv.value,
                    onChanged: _setSaturationValue,
                  ),
                  const SizedBox(height: 16),
                  _HueSlider(hue: _hsv.hue, onChanged: _setHue),
                  const SizedBox(height: 20),
                  _HexField(
                    color: _color,
                    controller: _hexController,
                    copied: _copied,
                    copyTooltip: widget.strings.copy,
                    onCopy: _copyHex,
                  ),
                  const SizedBox(height: 16),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: [
                      TextButton(
                        key: const Key('fc-color-picker-cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(widget.strings.cancel),
                      ),
                      FilledButton.icon(
                        key: const Key('fc-color-picker-select'),
                        onPressed: () => Navigator.of(context).pop(_color),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(widget.strings.select),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaturationValuePanel extends StatelessWidget {
  const _SaturationValuePanel({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            void update(Offset position) {
              if (size.width <= 0 || size.height <= 0) {
                return;
              }
              onChanged(
                position.dx / size.width,
                1 - (position.dy / size.height),
              );
            }

            // Keep the whole thumb inside the panel, even at the extremes.
            const thumbRadius = 16.0;
            final thumbX = (saturation * size.width)
                .clamp(
                  math.min(thumbRadius, size.width / 2),
                  math.max(size.width - thumbRadius, size.width / 2),
                )
                .toDouble();
            final thumbY = ((1 - value) * size.height)
                .clamp(
                  math.min(thumbRadius, size.height / 2),
                  math.max(size.height - thumbRadius, size.height / 2),
                )
                .toDouble();

            return MouseRegion(
              cursor: SystemMouseCursors.precise,
              child: GestureDetector(
                key: const Key('fc-color-picker-sv-panel'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => update(details.localPosition),
                onPanDown: (details) => update(details.localPosition),
                onPanUpdate: (details) => update(details.localPosition),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SaturationValuePainter(hue: hue),
                      ),
                    ),
                    Positioned(
                      left: thumbX - thumbRadius,
                      top: thumbY - thumbRadius,
                      child: const IgnorePointer(child: _PickerThumb()),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          void update(Offset position) {
            if (width <= 0) {
              return;
            }
            onChanged((position.dx / width).clamp(0.0, 1.0).toDouble());
          }

          final fraction = (hue / 360).clamp(0.0, 1.0);
          final markerLeft = (fraction * width - 3)
              .clamp(0.0, math.max(0.0, width - 6))
              .toDouble();

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const Key('fc-color-picker-hue-slider'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => update(details.localPosition),
              onPanDown: (details) => update(details.localPosition),
              onPanUpdate: (details) => update(details.localPosition),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 5,
                    height: 26,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: const CustomPaint(painter: _HuePainter()),
                    ),
                  ),
                  Positioned(
                    left: markerLeft,
                    top: 0,
                    bottom: 0,
                    width: 6,
                    child: const IgnorePointer(child: _HueThumb()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HexField extends StatelessWidget {
  const _HexField({
    required this.color,
    required this.controller,
    required this.copied,
    required this.copyTooltip,
    required this.onCopy,
  });

  final Color color;
  final TextEditingController controller;
  final bool copied;
  final String copyTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const Key('fc-color-picker-hex-field'),
              controller: controller,
              readOnly: true,
              showCursor: false,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            key: const Key('fc-color-picker-copy'),
            onPressed: onCopy,
            tooltip: copyTooltip,
            visualDensity: VisualDensity.compact,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                copied ? Icons.check_rounded : Icons.content_copy_rounded,
                key: ValueKey(copied),
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerThumb extends StatelessWidget {
  const _PickerThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}

class _HueThumb extends StatelessWidget {
  const _HueThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

class _HuePainter extends CustomPainter {
  const _HuePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = <Color>[
      for (var i = 0; i <= 36; i++)
        HSVColor.fromAHSV(1, (i * 10.0) % 360.0, 1, 1).toColor(),
    ];

    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) => false;
}
