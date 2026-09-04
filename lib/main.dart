import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/guidelines.dart';
import 'models/pattern.dart';
import 'providers/chart_provider.dart';
import 'providers/stitch_provider.dart';
import 'widgets/toolbar.dart';
import 'widgets/stitch_palette.dart';
import 'widgets/visual_chart_view.dart';
import 'widgets/panels.dart';
import 'dialogs/new_chart_dialog.dart';
import 'dialogs/text_view_dialog.dart';

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
  bool _leftOpen = false;
  bool _rightOpen = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(stitchStoreProvider.notifier).load());
  }

  void _handleNew(int style) {
    final styleEnum = GuidelinesType.fromValue(style);
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    notifier.setChart(chart.copyWith(
      name: 'Untitled',
      style: styleEnum,
      guidelines: chart.guidelines.copyWith(type: styleEnum),
      patternRounds: [],
      visualStitches: [],
    ));
  }

  void _handlePatternParse(List<dynamic> roundsRaw) {
    final rounds = roundsRaw
        .map((e) => PatternRound.fromJson(e as Map<String, dynamic>))
        .toList();
    final connected = assignConnections(rounds);
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    notifier.setChart(chart.copyWith(
      style: GuidelinesType.visual,
      guidelines: chart.guidelines.copyWith(type: GuidelinesType.visual),
      patternRounds: connected,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tabItems = [
      {'label': 'Properties', 'widget': const PropertiesPanel()},
      {'label': 'Shape', 'widget': const ShapePanel()},
    ];

    return MaterialApp(
      title: 'Crochet Charts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B82F6),
        useMaterial3: true,
        fontFamily: 'system-ui, sans-serif',
      ),
      home: Builder(
        builder: (innerContext) => Scaffold(
          body: Column(
            children: [
              AppToolbar(
                onNew: () => showDialog(
                  context: innerContext,
                  builder: (_) => NewChartDialog(onCreated: _handleNew),
                ),
                onOpen: () {},
                onSave: () {},
                onTextView: () => showDialog(
                  context: innerContext,
                  builder: (_) => ProviderScope(
                    overrides: [],
                    child: Builder(
                      builder: (ctx) => TextViewDialog(onClose: () => Navigator.pop(ctx)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (_leftOpen)
                      SizedBox(
                        width: 240,
                        child: StitchPalette(onClose: () => setState(() => _leftOpen = false)),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: VisualChartView(),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => setState(() => _leftOpen = !_leftOpen),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFDDDDDD)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('\u2630', style: TextStyle(fontSize: 18)),
                                ),
                              ),
                            ),
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
                onPatternParse: _handlePatternParse,
              ),
            ],
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
  final void Function(List<dynamic>) onPatternParse;

  const _BottomPanel({
    required this.isOpen,
    required this.tabs,
    required this.onToggle,
    required this.onPatternParse,
  });

  @override
  State<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<_BottomPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length + 1, vsync: this);
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
                            const Tab(text: 'Pattern'),
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
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          child: PatternPanel(
                            onParse: (rounds) => widget.onPatternParse(rounds),
                          ),
                        ),
                      ),
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
