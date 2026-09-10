import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/pwa_utils.dart';
import 'models/guidelines.dart';
import 'providers/chart_provider.dart';
import 'providers/edit_mode_provider.dart';
import 'providers/stitch_provider.dart';
import 'providers/locale_provider.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<VisualChartViewState> _chartKey = GlobalKey<VisualChartViewState>();
  bool _leftOpen = false;
  bool _rightOpen = false;

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

    final strings = ref.watch(stringsProvider);
    final tabItems = [
      {'label': strings.properties, 'widget': const PropertiesPanel()},
      {'label': strings.shape, 'widget': const ShapePanel()},
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
                final mediaQuery = MediaQuery.of(scaffoldContext);
                final isMobile = mediaQuery.size.width < 750;

                // Ensure proper top padding under notification / status bar
                double topPadding = math.max(mediaQuery.padding.top, mediaQuery.viewPadding.top);
                final isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS;
                if (topPadding == 0 && (isStandalonePwa() || (isMobile && isMobilePlatform))) {
                  topPadding = defaultTargetPlatform == TargetPlatform.iOS ? 44.0 : 28.0;
                }

                final effectiveMediaQuery = topPadding > mediaQuery.padding.top
                    ? mediaQuery.copyWith(
                        padding: mediaQuery.padding.copyWith(top: topPadding),
                        viewPadding: mediaQuery.viewPadding.copyWith(top: topPadding),
                      )
                    : mediaQuery;

                return MediaQuery(
                  data: effectiveMediaQuery,
                  child: Scaffold(
                    key: _scaffoldKey,
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
                            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                            onOpenEndDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
                            onTutorial: () => WelcomeTutorialDialog.show(scaffoldContext),
                          )
                        : null,
                    drawer: isMobile
                        ? Drawer(
                            width: 300,
                            child: SafeArea(
                              child: StitchPalette(
                                onClose: () => Navigator.of(scaffoldContext).pop(),
                              ),
                            ),
                          )
                        : null,
                    endDrawer: isMobile
                        ? Drawer(
                            width: 300,
                            child: SafeArea(
                              child: _RightPanel(
                                tabs: tabItems,
                                onClose: () => Navigator.of(scaffoldContext).pop(),
                              ),
                            ),
                          )
                        : null,
                    body: Column(
                      children: [
                        if (!isMobile)
                          SafeArea(
                            bottom: false,
                            child: AppToolbar(
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
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(6),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: () {
                                          if (isMobile) {
                                            _scaffoldKey.currentState?.openEndDrawer();
                                          } else {
                                            setState(() => _rightOpen = !_rightOpen);
                                          }
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _rightOpen && !isMobile
                                                ? const Color(0xFFEFF6FF)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _rightOpen && !isMobile
                                                  ? const Color(0xFF3B82F6)
                                                  : const Color(0xFFDDDDDD),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.tune,
                                            size: 20,
                                            color: _rightOpen && !isMobile
                                                ? const Color(0xFF3B82F6)
                                                : const Color(0xFF4B5563),
                                          ),
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
                            if (!isMobile && _rightOpen)
                              SizedBox(
                                width: 300,
                                child: _RightPanel(
                                  tabs: tabItems,
                                  onClose: () => setState(() => _rightOpen = false),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

class _RightPanel extends StatefulWidget {
  final List<Map<String, dynamic>> tabs;
  final VoidCallback onClose;

  const _RightPanel({
    required this.tabs,
    required this.onClose,
  });

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
              color: Color(0xFFF9FAFB),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    labelColor: const Color(0xFF1F2937),
                    unselectedLabelColor: const Color(0xFF6B7280),
                    indicatorColor: const Color(0xFF3B82F6),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      ...widget.tabs.map((t) => Tab(text: t['label'] as String)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                  tooltip: 'Kapat',
                  onPressed: widget.onClose,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ...widget.tabs.map((t) => SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: t['widget'] as Widget,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
