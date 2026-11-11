import 'package:fc_color_picker/fc_color_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF111318);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF61C72E),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'fc_color_picker example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
      ),
      home: const ColorPickerDemoPage(),
    );
  }
}

class ColorPickerDemoPage extends StatefulWidget {
  const ColorPickerDemoPage({super.key});

  @override
  State<ColorPickerDemoPage> createState() => _ColorPickerDemoPageState();
}

class _ColorPickerDemoPageState extends State<ColorPickerDemoPage> {
  Color _selectedColor = const Color(0xFF61C72E);

  String get _hex {
    final rgb = _selectedColor.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _pickColor() async {
    final picked = await fcPickColor(context, initialColor: _selectedColor);
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _selectedColor = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -1),
            radius: 1.5,
            colors: [
              colorScheme.primary.withValues(alpha: 0.18),
              const Color(0xFF111318),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'FLUTTER PACKAGE DEMO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'fc_color_picker',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A polished Material color picker, exposed through a '
                      'single fcPickColor() call.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: 140,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedColor.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _hex,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Selected color',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _pickColor,
                              icon: const Icon(Icons.palette_outlined),
                              label: const Text('Pick a color'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Cancelling the dialog returns null.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
