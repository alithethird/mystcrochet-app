import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/guidelines.dart';
import 'providers/chart_provider.dart';
import 'providers/edit_mode_provider.dart';
import 'providers/stitch_provider.dart';
import 'widgets/toolbar.dart';
import 'widgets/stitch_palette.dart';
import 'widgets/visual_chart_view.dart';
import 'widgets/panels.dart';
import 'dialogs/new_chart_dialog.dart';
import 'dialogs/text_view_dialog.dart';
import 'dialogs/export_dialog.dart';
import 'dialogs/save_chart_dialog.dart';
import 'services/export_service.dart';
import 'services/chart_file_service.dart';
import 'services/local_design_service.dart';
import 'widgets/build_version_badge.dart';
import 'widgets/saved_designs_dialog.dart';
import 'widgets/mobile_app_bar.dart';
import 'dialogs/welcome_tutorial_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CrochetChartsApp()));
}

class CrochetChartsApp extends ConsumerStatefulWidget {
  const CrochetChartsApp({super.key});

  @override
  ConsumerState<CrochetChartsApp> createState() => _CrochetChartsAppState();
}

class _CrochetChartsAppState extends ConsumerState<CrochetChartsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<VisualChartViewState> _chartKey = GlobalKey<VisualChartViewState>();
  bool _leftOpen = false;
  bool _rightOpen = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(stitchStoreProvider.notifier).load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navContext = _navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        WelcomeTutorialDialog.showIfFirstTime(navContext);
      }
    });
  }

  void _handleNew(int style) {
    final styleEnum = GuidelinesType.fromValue(style);
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    notifier.loadChart(chart.copyWith(
      name: 'Untitled',
      style: styleEnum,
      guidelines: chart.guidelines.copyWith(type: styleEnum),
      patternRounds: [],
      visualStitches: [],
    ));
  }

  Future<void> _handleExportPng(BuildContext context) async {
    final chartState = ref.read(chartProvider);
    final chart = chartState.chart;

    final hasContent = chart.starterStitchName != null ||
        chart.patternRounds.any((r) => r.stitches.isNotEmpty);
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grafikte dışa aktarılacak ilmek bulunmuyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final initialName = chart.name.isNotEmpty ? chart.name : 'crochet_chart';

    await showDialog(
      context: context,
      builder: (dialogCtx) => ExportDialog(
        initialName: initialName,
        onExport: (options) async {
          final chartView = _chartKey.currentState;
          if (chartView == null) return;

          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('PNG oluşturuluyor...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );

          final bytes = await chartView.capturePng(
            pixelRatio: options.pixelRatio,
            includeGuidelines: options.includeGuidelines,
            transparent: options.transparent,
          );

          if (bytes == null || bytes.isEmpty) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Görüntü oluşturulamadı. Lütfen tekrar deneyin.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final success = await ExportService.savePng(bytes, options.fileName);
          if (success) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('${options.fileName} dışa aktarıldı.'),
                backgroundColor: const Color(0xFF16A34A),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final chartState = ref.read(chartProvider);
    final chart = chartState.chart;

    await showDialog(
      context: context,
      builder: (dialogCtx) => SaveChartDialog(
        initialName: chart.name,
        onSave: (fileName, updatedChartName) async {
          if (updatedChartName != null && updatedChartName != chart.name) {
            ref.read(chartProvider.notifier).setChart(
                  chart.copyWith(name: updatedChartName),
                  recordUndo: false,
                );
          }

          final currentChart = ref.read(chartProvider).chart;
          final messenger = ScaffoldMessenger.of(context);

          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Grafik kaydediliyor...'),
                ],
              ),
              duration: Duration(milliseconds: 800),
            ),
          );

          final stitchStore = ref.read(stitchStoreProvider);
          final success = await ChartFileService.saveChart(currentChart, fileName, stitchStore: stitchStore);
          if (success) {
            await LocalDesignService.saveDesign(currentChart, name: updatedChartName ?? currentChart.name);
            messenger.showSnackBar(
              SnackBar(
                content: Text('$fileName başarıyla kaydedildi.'),
                backgroundColor: const Color(0xFF16A34A),
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Kayıt işlemi tamamlanamadı veya iptal edildi.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _handleSavedDesigns(BuildContext context) async {
    final currentChart = ref.read(chartProvider).chart;
    await showDialog(
      context: context,
      builder: (dialogCtx) => SavedDesignsDialog(
        currentChart: currentChart,
        onSelect: (selectedChart) {
          ref.read(chartProvider.notifier).loadChart(selectedChart);
          if (selectedChart.embeddedStitches != null && selectedChart.embeddedStitches!.isNotEmpty) {
            ref.read(stitchStoreProvider).registerStitches(selectedChart.embeddedStitches!);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${selectedChart.name.isNotEmpty ? selectedChart.name : "Tasarım"}" başarıyla yüklendi.'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleOpen(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    debugPrint('[OPEN_CHART] Kullanıcı dosya açma işlemini başlattı.');
    try {
      final result = await ChartFileService.openChart();
      if (result == null) {
        debugPrint('[OPEN_CHART] Dosya seçilmedi veya iptal edildi.');
        return;
      }
      debugPrint('[OPEN_CHART] Dosya okundu: ${result.fileName}, tur sayısı: ${result.chart.patternRounds.length}, başlangıç: ${result.chart.starterStitchName}');

      ref.read(chartProvider.notifier).loadChart(result.chart);
      if (result.chart.embeddedStitches != null && result.chart.embeddedStitches!.isNotEmpty) {
        ref.read(stitchStoreProvider).registerStitches(result.chart.embeddedStitches!);
      }
      debugPrint('[OPEN_CHART] Grafik başarıyla yüklendi ve tuval kamerasını sıfırladı.');

      messenger.showSnackBar(
        SnackBar(
          content: Text('${result.fileName} başarıyla açıldı.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (e, st) {
      debugPrint('[OPEN_CHART] HATA: $e\n$st');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Dosya açılamadı: ${e is FormatException ? e.message : "Geçersiz veya bozuk grafik dosyası."}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditModeState>(editModeProvider, (previous, next) {
      if ((next.mode == EditMode.replace || next.mode == EditMode.select || next.selectedStitchKeys.isNotEmpty) && !_leftOpen) {
        setState(() => _leftOpen = true);
      }
    });

    final tabItems = [
      {'label': 'Özellikler', 'widget': const PropertiesPanel()},
      {'label': 'Şekil', 'widget': const ShapePanel()},
    ];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Crochet Charts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B82F6),
        useMaterial3: true,
        fontFamily: 'system-ui, sans-serif',
      ),
      home: Builder(
        builder: (innerContext) => CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                _handleSave(innerContext),
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
                _handleSave(innerContext),
            const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
                _handleOpen(innerContext),
            const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
                _handleOpen(innerContext),
            const SingleActivator(LogicalKeyboardKey.delete): () {
              if (ref.read(editModeProvider).selectedStitchKeys.isNotEmpty) {
                _chartKey.currentState?.deleteSelectedStitches();
              } else {
                _chartKey.currentState?.deleteSelectedStitch();
              }
            },
            const SingleActivator(LogicalKeyboardKey.backspace): () {
              if (ref.read(editModeProvider).selectedStitchKeys.isNotEmpty) {
                _chartKey.currentState?.deleteSelectedStitches();
              } else {
                _chartKey.currentState?.deleteSelectedStitch();
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Builder(
              builder: (scaffoldContext) {
                final isMobile = MediaQuery.sizeOf(scaffoldContext).width < 750;
                return Scaffold(
                  appBar: isMobile
                      ? MobileAppBar(
                          onNew: () => showDialog(
                            context: scaffoldContext,
                            builder: (_) => NewChartDialog(onCreated: _handleNew),
                          ),
                          onOpen: () => _handleOpen(scaffoldContext),
                          onSave: () => _handleSave(scaffoldContext),
                          onSavedDesigns: () => _handleSavedDesigns(scaffoldContext),
                          onTextView: () => showDialog(
                            context: scaffoldContext,
                            builder: (_) => ProviderScope(
                              overrides: const [],
                              child: Builder(
                                builder: (ctx) => TextViewDialog(
                                  onClose: () => Navigator.pop(ctx),
                                  onOpenFile: () => _handleOpen(scaffoldContext),
                                ),
                              ),
                            ),
                          ),
                          onExportPng: () => _handleExportPng(scaffoldContext),
                          onOpenDrawer: () => Scaffold.of(scaffoldContext).openDrawer(),
                          onTutorial: () => WelcomeTutorialDialog.show(scaffoldContext),
                        )
                      : null,
                  drawer: isMobile
                      ? Drawer(
                          width: 280,
                          child: SafeArea(
                            child: StitchPalette(
                              onClose: () => Navigator.of(scaffoldContext).pop(),
                            ),
                          ),
                        )
                      : null,
                  body: Column(
                    children: [
                      if (!isMobile)
                        AppToolbar(
                          onNew: () => showDialog(
                            context: scaffoldContext,
                            builder: (_) => NewChartDialog(onCreated: _handleNew),
                          ),
                          onOpen: () => _handleOpen(scaffoldContext),
                          onSave: () => _handleSave(scaffoldContext),
                          onSavedDesigns: () => _handleSavedDesigns(scaffoldContext),
                          onTextView: () => showDialog(
                            context: scaffoldContext,
                            builder: (_) => ProviderScope(
                              overrides: const [],
                              child: Builder(
                                builder: (ctx) => TextViewDialog(
                                  onClose: () => Navigator.pop(ctx),
                                  onOpenFile: () => _handleOpen(scaffoldContext),
                                ),
                              ),
                            ),
                          ),
                          onExportPng: () => _handleExportPng(scaffoldContext),
                          onTutorial: () => WelcomeTutorialDialog.show(scaffoldContext),
                        ),
                      Expanded(
                        child: Row(
                          children: [
                            if (!isMobile && _leftOpen)
                              SizedBox(
                                width: 240,
                                child: StitchPalette(
                                    onClose: () => setState(() => _leftOpen = false)),
                              ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: VisualChartView(key: _chartKey),
                                    ),
                                  ),
                                  if (!isMobile)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Material(
                                        elevation: 2,
                                        borderRadius: BorderRadius.circular(6),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () =>
                                              setState(() => _leftOpen = !_leftOpen),
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: const Color(0xFFDDDDDD)),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Text('\u2630',
                                                style: TextStyle(fontSize: 18)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: BuildVersionBadge(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _BottomPanel(
                        isOpen: _rightOpen,
                        tabs: tabItems,
                        onToggle: () => setState(() => _rightOpen = !_rightOpen),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    ),
  ),
);
  }
}

class _BottomPanel extends StatefulWidget {
  final bool isOpen;
  final List<Map<String, dynamic>> tabs;
  final VoidCallback onToggle;

  const _BottomPanel({
    required this.isOpen,
    required this.tabs,
    required this.onToggle,
  });

  @override
  State<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<_BottomPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (widget.isOpen == false) widget.onToggle();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.isOpen ? MediaQuery.of(context).size.height * 0.35 : 32,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
        color: Colors.white,
      ),
      child: widget.isOpen
          ? Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          labelColor: const Color(0xFF1A1A1A),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF3B82F6),
                          tabs: [
                            ...widget.tabs.map((t) => Tab(text: t['label'] as String)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: widget.onToggle,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: const Text('\u25BC', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ...widget.tabs.map((t) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(child: t['widget'] as Widget),
                      )),
                    ],
                  ),
                ),
              ],
            )
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
                color: Color(0xFFF5F5F5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onToggle,
                    child: Container(
                      width: 36,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Text('\u25B2', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
