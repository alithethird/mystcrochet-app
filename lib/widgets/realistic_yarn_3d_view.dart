import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chart.dart';
import '../models/yarn_render_config.dart';
import '../services/procedural_yarn_3d_engine.dart';
import '../services/procedural_yarn_2d_engine.dart';
import '../services/export_service.dart';

class RealisticYarn3DView extends ConsumerStatefulWidget {
  final Chart chart;
  final VoidCallback onClose;

  const RealisticYarn3DView({
    super.key,
    required this.chart,
    required this.onClose,
  });

  @override
  ConsumerState<RealisticYarn3DView> createState() => _RealisticYarn3DViewState();
}

class _RealisticYarn3DViewState extends ConsumerState<RealisticYarn3DView> {
  late YarnRenderConfig _config;
  bool _showSettings = false;
  bool _isExporting = false;
  double _baseScaleZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _config = const YarnRenderConfig();
  }

  void _resetCamera() {
    setState(() {
      _config = _config.copyWith(
        cameraPitch: 0.35,
        cameraYaw: -0.25,
        cameraZoom: 1.0,
      );
    });
  }

  void _onPresetChanged(YarnMaterialPreset preset) {
    setState(() {
      _config = _config.copyWith(
        materialPreset: preset,
        thickness: preset.defaultThickness,
        fuzziness: preset.defaultFuzziness,
      );
    });
  }

  Future<void> _exportPng() async {
    setState(() => _isExporting = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const exportSize = Size(1920, 1920);

      // Render motif on high-res canvas (2D or 3D engine)
      if (_config.renderDimension == RenderDimensionMode.mode2D) {
        ProceduralYarn2DEngine.render(
          canvas,
          exportSize,
          widget.chart,
          _config.copyWith(cameraZoom: 1.4),
        );
      } else {
        ProceduralYarn3DEngine.render(
          canvas,
          exportSize,
          widget.chart,
          _config.copyWith(cameraZoom: 1.4),
        );
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(1920, 1920);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final filename = '${widget.chart.name.replaceAll(' ', '_')}_${_config.renderDimension == RenderDimensionMode.mode2D ? "2d" : "3d"}_render.png';
        final success = await ExportService.savePng(bytes, filename);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$filename başarıyla kaydedildi.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Render aktarılırken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate theme for high contrast 3D
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Interactive 3D/2D Orbit & Pan Gesture Detector
          GestureDetector(
            onScaleStart: (details) {
              _baseScaleZoom = _config.cameraZoom;
            },
            onScaleUpdate: (details) {
              setState(() {
                final newYaw = _config.cameraYaw + details.focalPointDelta.dx * 0.008;
                final newPitch = (_config.cameraPitch + details.focalPointDelta.dy * 0.008)
                    .clamp(-math.pi / 2.2, math.pi / 2.2);
                final newZoom = (_baseScaleZoom * details.scale).clamp(0.4, 3.5);
                _config = _config.copyWith(
                  cameraYaw: newYaw,
                  cameraPitch: newPitch,
                  cameraZoom: newZoom,
                );
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _Yarn3DPainter(
                chart: widget.chart,
                config: _config,
              ),
            ),
          ),

          // Header Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeTabButton(
                        label: '3D Simülasyon',
                        icon: Icons.view_in_ar,
                        isSelected: _config.renderDimension == RenderDimensionMode.mode3D,
                        onTap: () => setState(() => _config = _config.copyWith(renderDimension: RenderDimensionMode.mode3D)),
                      ),
                      const SizedBox(width: 4),
                      _ModeTabButton(
                        label: '2D Realistik İplik',
                        icon: Icons.texture,
                        isSelected: _config.renderDimension == RenderDimensionMode.mode2D,
                        onTap: () => setState(() => _config = _config.copyWith(renderDimension: RenderDimensionMode.mode2D)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _IconButtonBadge(
                  icon: Icons.refresh,
                  tooltip: 'Kamerayı Sıfırla',
                  onTap: _resetCamera,
                ),
                const SizedBox(width: 8),
                _IconButtonBadge(
                  icon: Icons.tune,
                  tooltip: 'İplik & Işık Ayarları',
                  onTap: () => setState(() => _showSettings = !_showSettings),
                ),
                const SizedBox(width: 8),
                _IconButtonBadge(
                  icon: Icons.download,
                  tooltip: 'PNG İndir',
                  isLoading: _isExporting,
                  onTap: _exportPng,
                ),
                const SizedBox(width: 8),
                _IconButtonBadge(
                  icon: Icons.close,
                  tooltip: 'Kapat',
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),

          // Collapsible Settings Overlay Panel
          if (_showSettings)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSettingsCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'İplik & Render Özelleştirme',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => setState(() => _showSettings = false),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets selector
          const Text('İplik Türü (Preset):', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: YarnMaterialPreset.values.map((preset) {
              final isSelected = _config.materialPreset == preset;
              return ChoiceChip(
                label: Text(preset.label),
                selected: isSelected,
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFF334155),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => _onPresetChanged(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sliders
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kalınlık: ${_config.thickness.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Slider(
                      value: _config.thickness,
                      min: 0.8,
                      max: 4.0,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (v) => setState(() => _config = _config.copyWith(thickness: v)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tüylülük: ${(_config.fuzziness * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Slider(
                      value: _config.fuzziness,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (v) => setState(() => _config = _config.copyWith(fuzziness: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButtonBadge extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isLoading;

  const _IconButtonBadge({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Yarn3DPainter extends CustomPainter {
  final Chart chart;
  final YarnRenderConfig config;

  _Yarn3DPainter({
    required this.chart,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (config.renderDimension == RenderDimensionMode.mode2D) {
      ProceduralYarn2DEngine.render(canvas, size, chart, config);
    } else {
      ProceduralYarn3DEngine.render(canvas, size, chart, config);
    }
  }

  @override
  bool shouldRepaint(covariant _Yarn3DPainter oldDelegate) {
    return oldDelegate.chart != chart || oldDelegate.config != config;
  }
}
