import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'models/savings_entry.dart';

const _entriesStorageKey = 'sparschwein.entries.v1';
const _goalStorageKey = 'sparschwein.monthly-goal.v1';
const _pageWidth = 1480.0;
const _defaultStores = ['Alle Läden', ...savingsStores];
const _typeFilters = ['Alle', ...savingsTypes];

const _freebieColor = Color(0xFF8C68A2);
const _foundColor = Color(0xFF5F8D83);
const _neutralIconColor = Color(0xFF829087);
const _cardShadow = [
  BoxShadow(
    color: Color(0x0C352831),
    blurRadius: 26,
    offset: Offset(0, 8),
  ),
];

enum _AppPage { overview, entries, goals }

class _MonthTotal {
  const _MonthTotal({
    required this.date,
    required this.amount,
    required this.isCurrent,
  });

  final DateTime date;
  final double amount;
  final bool isCurrent;
}

class _NavigationItem {
  const _NavigationItem({
    required this.page,
    required this.label,
    required this.icon,
  });

  final _AppPage page;
  final String label;
  final IconData icon;
}

const _navigationItems = [
  _NavigationItem(
    page: _AppPage.overview,
    label: 'Übersicht',
    icon: Icons.space_dashboard_outlined,
  ),
  _NavigationItem(
    page: _AppPage.entries,
    label: 'Meine Einträge',
    icon: Icons.receipt_long_outlined,
  ),
  _NavigationItem(
    page: _AppPage.goals,
    label: 'Sparziele',
    icon: Icons.track_changes_outlined,
  ),
];

class SparschweinApp extends StatefulWidget {
  const SparschweinApp({super.key});

  @override
  State<SparschweinApp> createState() => _SparschweinAppState();
}

class _SparschweinAppState extends State<SparschweinApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<SavingsEntry> _entries = [];
  double _goalTarget = 0;
  bool _isLoading = true;
  _AppPage _page = _AppPage.overview;
  String _activeTypeFilter = 'Alle';
  String _activeStoreFilter = 'Alle Läden';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rawEntries = preferences.getString(_entriesStorageKey);
      final decoded = rawEntries == null
          ? <dynamic>[]
          : jsonDecode(rawEntries) as List<dynamic>;
      final entries = decoded
          .map(
            (item) => SavingsEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final goal = preferences.getDouble(_goalStorageKey) ?? 0;
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _goalTarget = goal > 0 ? goal : 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _entriesStorageKey,
        jsonEncode(_entries.map((entry) => entry.toJson()).toList()),
      );
      await preferences.setDouble(_goalStorageKey, _goalTarget);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speichern fehlgeschlagen.')),
      );
    }
  }

  DateTime get _now => DateTime.now();

  double _monthTotal(DateTime date) => _entries
      .where((entry) => entry.date.year == date.year && entry.date.month == date.month)
      .fold<double>(0, (sum, entry) => sum + entry.amount);

  double get _totalSaved =>
      _entries.fold<double>(0, (sum, entry) => sum + entry.amount);

  double get _currentMonthTotal => _monthTotal(_now);

  double get _currentYearTotal => _entries
      .where((entry) => entry.date.year == _now.year)
      .fold<double>(0, (sum, entry) => sum + entry.amount);

  int get _currentYearCount =>
      _entries.where((entry) => entry.date.year == _now.year).length;

  int get _currentMonthCount => _entries
      .where((entry) => entry.date.year == _now.year && entry.date.month == _now.month)
      .length;

  double get _previousMonthTotal =>
      _monthTotal(DateTime(_now.year, _now.month - 1, 1));

  double get _goalProgress => _goalTarget > 0
      ? (_currentMonthTotal / _goalTarget).clamp(0.0, 1.0).toDouble()
      : 0;

  List<_MonthTotal> get _lastSixMonths {
    final firstMonth = DateTime(_now.year, _now.month - 5, 1);
    return List.generate(6, (index) {
      final date = DateTime(firstMonth.year, firstMonth.month + index, 1);
      return _MonthTotal(
        date: date,
        amount: _monthTotal(date),
        isCurrent: date.year == _now.year && date.month == _now.month,
      );
    });
  }

  List<SavingsEntry> get _filteredEntries {
    final query = _searchText.trim().toLowerCase();
    return _entries.where((entry) {
      final matchesType = _activeTypeFilter == 'Alle' || entry.type == _activeTypeFilter;
      final matchesStore = _activeStoreFilter == 'Alle Läden' ||
          entry.store == _activeStoreFilter;
      final matchesSearch = query.isEmpty ||
          entry.title.toLowerCase().contains(query) ||
          entry.store.toLowerCase().contains(query) ||
          entry.type.toLowerCase().contains(query) ||
          entry.note.toLowerCase().contains(query);
      return matchesType && matchesStore && matchesSearch;
    }).toList();
  }

  Future<void> _openEntryForm() async {
    final isCompact = MediaQuery.sizeOf(context).width < 720;
    final SavingsEntry? entry;
    if (isCompact) {
      entry = await showModalBottomSheet<SavingsEntry>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _EntryForm(
            onCancel: () => Navigator.of(sheetContext).pop(),
            onSave: (value) => Navigator.of(sheetContext).pop(value),
          ),
        ),
      );
    } else {
      entry = await showDialog<SavingsEntry>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 540,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.92,
            ),
            child: _EntryForm(
              onCancel: () => Navigator.of(dialogContext).pop(),
              onSave: (value) => Navigator.of(dialogContext).pop(value),
            ),
          ),
        ),
      );
    }

    if (entry == null || !mounted) return;
    final savedEntry = entry;
    setState(() {
      _entries = [..._entries, savedEntry]..sort((a, b) => b.date.compareTo(a.date));
    });
    await _saveData();
  }

  Future<void> _removeEntry(SavingsEntry entry) async {
    setState(() => _entries.removeWhere((item) => item.id == entry.id));
    await _saveData();
  }

  Future<void> _editGoal() async {
    final controller = TextEditingController(
      text: _goalTarget > 0
          ? NumberFormat('0.##', 'de_DE').format(_goalTarget)
          : '',
    );
    String? errorText;
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_goalTarget > 0 ? 'Monatsziel ändern' : 'Monatsziel festlegen'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Betrag pro Monat',
              prefixText: '€ ',
              errorText: errorText,
            ),
            onChanged: (_) => setDialogState(() => errorText = null),
            onSubmitted: (_) {
              final value = _parseAmount(controller.text);
              if (value == null || value <= 0) {
                setDialogState(() => errorText = 'Bitte einen Betrag größer als 0 € eingeben.');
              } else {
                Navigator.of(dialogContext).pop(value);
              }
            },
          ),
          actions: [
            if (_goalTarget > 0)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(0.0),
                child: const Text('Ziel entfernen'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final value = _parseAmount(controller.text);
                if (value == null || value <= 0) {
                  setDialogState(() => errorText = 'Bitte einen Betrag größer als 0 € eingeben.');
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() => _goalTarget = result);
    await _saveData();
  }

  void _navigate(_AppPage page, {bool closeDrawer = false}) {
    if (closeDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 920;
        if (isDesktop) {
          return Scaffold(
            backgroundColor: canvasColor,
            body: SafeArea(
              child: Row(
                children: [
                  _buildNavigation(isDrawer: false),
                  Expanded(child: _buildContentPane(isDesktop: true)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: canvasColor,
          drawer: Drawer(
            width: math.min(MediaQuery.sizeOf(context).width * 0.86, 330.0).toDouble(),
            backgroundColor: const Color(0xFFFBFCFA),
            child: SafeArea(child: _buildNavigation(isDrawer: true)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildMobileBrandBar(),
                Expanded(child: _buildContentPane(isDesktop: false)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileBrandBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menü öffnen',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded),
            style: IconButton.styleFrom(
              foregroundColor: pinkStrongColor,
              backgroundColor: Colors.white.withValues(alpha: 0.86),
              side: const BorderSide(color: Color(0xFFEFE0E6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              fixedSize: const Size(42, 42),
            ),
          ),
          const SizedBox(width: 11),
          const _BrandLockup(compact: true),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFECDFBC), Color(0xFFF0DCE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              'S',
              style: TextStyle(
                color: pinkStrongColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation({required bool isDrawer}) {
    return Container(
      width: isDrawer ? null : 256,
      padding: EdgeInsets.fromLTRB(18, isDrawer ? 18 : 28, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: Color(0xFFE8ECE5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandLockup(),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 11),
            child: Text(
              'MENÜ',
              style: TextStyle(
                color: mutedColor.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          ..._navigationItems.map((item) => _navigationButton(item, isDrawer)),
          const Spacer(),
          if (!isDrawer) ...[
            const Divider(color: Color(0xFFEDEFEA)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFECDFBC), Color(0xFFF0DCE5)],
                    ),
                  ),
                  child: const Text(
                    'S',
                    style: TextStyle(
                      color: pinkStrongColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dein Sparbuch',
                        style: TextStyle(
                          color: inkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Persönliche Übersicht',
                        style: TextStyle(color: mutedColor, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFCE86A0)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _navigationButton(_NavigationItem item, bool isDrawer) {
    final selected = _page == item.page;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _navigate(item.page, closeDrawer: isDrawer),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 47),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: selected ? pinkLightColor : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: selected ? pinkStrongColor : const Color(0xFF78857B),
                ),
                const SizedBox(width: 13),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? pinkStrongColor : const Color(0xFF78857B),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: pinkColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPane({required bool isDesktop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 880;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 42 : 16,
            isDesktop ? 38 : 20,
            isDesktop ? 42 : 16,
            26,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _pageWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeader(isCompact: constraints.maxWidth < 1050),
                  const SizedBox(height: 23),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.025),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_page),
                      child: _buildPageContents(isWide: isWide),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: lineColor),
                  const SizedBox(height: 10),
                  Text(
                    'Sparschwein · Dein persönliches Sparbuch',
                    style: TextStyle(
                      color: mutedColor.withValues(alpha: 0.8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader({required bool isCompact}) {
    final now = _now;
    final subtitle = switch (_page) {
      _AppPage.overview => 'Deine Ersparnisse im Überblick.',
      _AppPage.entries => 'Alle Einträge in deinem Sparbuch.',
      _AppPage.goals => 'Monatsziel und Fortschritt.',
    };

    final titleStyle = TextStyle(
      color: inkColor,
      fontFamily: 'Cormorant Garamond',
      fontSize: isCompact ? 37 : 49,
      fontWeight: FontWeight.w600,
      height: 1.02,
      letterSpacing: -0.5,
    );
    final title = _page == _AppPage.overview
        ? Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${_greeting(now.hour)}, ', style: titleStyle),
                TextSpan(
                  text: 'Sparschwein!',
                  style: titleStyle.copyWith(color: pinkStrongColor),
                ),
              ],
            ),
            maxLines: isCompact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          )
        : Text(
            switch (_page) {
              _AppPage.entries => 'Meine Einträge',
              _AppPage.goals => 'Deine Sparziele',
              _AppPage.overview => '',
            },
            style: titleStyle,
          );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: pinkColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: pinkLightColor, blurRadius: 0, spreadRadius: 3),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Text(
              _page == _AppPage.overview
                  ? 'DEIN PERSÖNLICHES SPAR-COCKPIT'
                  : switch (_page) {
                      _AppPage.entries => 'DEIN SPARBUCH',
                      _AppPage.goals => 'MONATSZIEL & FORTSCHRITT',
                      _AppPage.overview => '',
                    },
              style: const TextStyle(
                color: Color(0xFF88958B),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        title,
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Color(0xFF89948B), fontSize: 13)),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DatePill(date: now, compact: isCompact),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: _openEntryForm,
          style: FilledButton.styleFrom(
            backgroundColor: pinkColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(isCompact ? 'Eintragen' : 'Sparbetrag eintragen'),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: actions),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 22),
        actions,
      ],
    );
  }

  Widget _buildPageContents({required bool isWide}) {
    return switch (_page) {
      _AppPage.overview => _buildOverview(isWide: isWide),
      _AppPage.entries => _buildEntriesPage(),
      _AppPage.goals => _buildGoalsPage(isWide: isWide),
    };
  }

  Widget _buildOverview({required bool isWide}) {
    final previousTotal = _previousMonthTotal;
    final monthNote = previousTotal > 0
        ? '${_currentMonthTotal >= previousTotal ? '+' : ''}${(((_currentMonthTotal - previousTotal) / previousTotal) * 100).round()}% zum Vormonat'
        : _currentMonthTotal > 0
            ? 'Erster Sparmonat'
            : 'Noch keine Ersparnisse';

    final totalCard = _TotalSavingsCard(
      total: _totalSaved,
      monthlyValues: _lastSixMonths.map((month) => month.amount).toList(),
    );
    final monthCard = _StatCard(
      icon: Icons.calendar_month_outlined,
      label: 'DIESEN ${DateFormat('MMMM', 'de_DE').format(_now).toUpperCase()}',
      value: formatMoney(_currentMonthTotal),
      note: monthNote,
      progress: _goalTarget > 0 ? _goalProgress : null,
    );
    final yearCard = _StatCard(
      icon: Icons.trending_up_rounded,
      label: 'SEIT JAHRESBEGINN',
      value: formatMoney(_currentYearTotal),
      note: '$_currentYearCount ${_currentYearCount == 1 ? 'Eintrag' : 'Einträge'} in ${_now.year}',
    );

    final summary = isWide
        ? SizedBox(
            height: 228,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 15, child: totalCard),
                const SizedBox(width: 15),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      Expanded(child: monthCard),
                      const SizedBox(height: 12),
                      Expanded(child: yearCard),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              totalCard,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 104, child: monthCard)),
                  const SizedBox(width: 10),
                  Expanded(child: SizedBox(height: 104, child: yearCard)),
                ],
              ),
            ],
          );

    final insights = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 13, child: _buildChartPanel()),
              const SizedBox(width: 15),
              Expanded(flex: 9, child: _buildGoalPanel()),
            ],
          )
        : Column(
            children: [
              _buildChartPanel(),
              const SizedBox(height: 14),
              _buildGoalPanel(),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        summary,
        const SizedBox(height: 15),
        insights,
        const SizedBox(height: 15),
        _buildActivityPanel(recentOnly: true),
      ],
    );
  }

  Widget _buildChartPanel() {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeading(
            eyebrow: 'DEIN SPARVERLAUF',
            title: 'Monatsverlauf',
            description: 'Deine Ersparnisse der letzten sechs Monate',
            icon: Icons.bar_chart_rounded,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Letzte 6 Monate',
                style: TextStyle(
                  color: Color(0xFF89948B),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _MonthChart(months: _lastSixMonths),
        ],
      ),
    );
  }

  Widget _buildGoalPanel() {
    final ratio = _goalProgress;
    final encouragement = _goalTarget <= 0
        ? 'Lege ein Monatsziel fest.'
        : ratio >= 1
            ? 'Monatsziel erreicht.'
            : 'Noch ${formatMoney((_goalTarget - _currentMonthTotal).clamp(0, _goalTarget))} bis zum Ziel.';

    return SizedBox(
      height: 305,
      child: _PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelHeading(
              eyebrow: 'MONATSZIEL',
              title: 'Dein Monatsziel',
              icon: Icons.track_changes_outlined,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _ProgressRing(progress: ratio, label: '${(ratio * 100).round()}%'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM', 'de_DE').format(_now).toUpperCase(),
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatMoney(_currentMonthTotal),
                        style: const TextStyle(
                          color: inkColor,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _goalTarget > 0 ? 'von ${formatMoney(_goalTarget)}' : 'Noch kein Ziel gesetzt',
                        style: const TextStyle(color: mutedColor, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 19),
            _ProgressBar(progress: ratio),
            const SizedBox(height: 11),
            Text(
              encouragement,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF75636B), fontSize: 10),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _editGoal,
                style: TextButton.styleFrom(foregroundColor: pinkStrongColor),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(_goalTarget > 0 ? 'Ziel anpassen' : 'Ziel festlegen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionIntro(
          icon: Icons.receipt_long_outlined,
          label: 'DEIN SPARBUCH',
          title: 'Alle Einträge',
          description: 'Hier sind deine eingetragenen Sparbeträge.',
        ),
        const SizedBox(height: 16),
        _buildActivityPanel(recentOnly: false),
      ],
    );
  }

  Widget _buildGoalsPage({required bool isWide}) {
    final details = _buildGoalDetailsPanel();
    final milestones = _buildMilestonesPanel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionIntro(
          icon: Icons.track_changes_outlined,
          label: 'MONATSZIEL & FORTSCHRITT',
          title: 'Deine Sparziele',
          description: 'Dein Monatsziel und dein aktueller Fortschritt.',
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 12, child: details),
              const SizedBox(width: 15),
              Expanded(flex: 9, child: milestones),
            ],
          )
        else ...[
          details,
          const SizedBox(height: 14),
          milestones,
        ],
      ],
    );
  }

  Widget _buildGoalDetailsPanel() {
    final progress = _goalProgress;
    final goalLabel = _goalTarget > 0 ? formatMoney(_goalTarget) : 'Noch offen';
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeading(
            eyebrow: 'DEIN FOKUS FÜR ${DateFormat('MMMM', 'de_DE').format(_now).toUpperCase()}',
            title: _goalTarget > 0 ? 'Monatsziel' : 'Monatsziel festlegen',
            description: 'Dein Sparstand und dein Zielbetrag.',
            icon: Icons.track_changes_outlined,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E5E9)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GoalNumber(label: 'Bisher gespart', value: formatMoney(_currentMonthTotal)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('von', style: TextStyle(color: mutedColor, fontSize: 10)),
                    ),
                    Expanded(
                      child: _GoalNumber(label: 'Dein Monatsziel', value: goalLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProgressBar(progress: progress, height: 8),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(progress * 100).round()}% geschafft', style: const TextStyle(color: pinkStrongColor, fontSize: 9, fontWeight: FontWeight.w700)),
                    Text('$_currentMonthCount ${_currentMonthCount == 1 ? 'Eintrag' : 'Einträge'} in diesem Monat', style: const TextStyle(color: mutedColor, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: _editGoal,
            style: OutlinedButton.styleFrom(
              foregroundColor: pinkStrongColor,
              side: const BorderSide(color: Color(0xFFECD3DD)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: Text(_goalTarget > 0 ? 'Monatsziel anpassen' : 'Monatsziel festlegen'),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesPanel() {
    const milestones = [
      (10.0, 'Erster Zehner'),
      (50.0, 'Kleine Schritte'),
      (100.0, 'Sparschwein-Monat'),
      (250.0, 'Richtig stark'),
    ];
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeading(
            eyebrow: 'MONATSZIEL',
            title: 'Meilensteine',
            description: 'Beträge im aktuellen Monat.',
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 12),
          ...milestones.map((milestone) {
            final amount = milestone.$1;
            final label = milestone.$2;
            final reached = _currentMonthTotal >= amount;
            return _MilestoneRow(
              amount: amount,
              label: label,
              reached: reached,
              remaining: math.max(0.0, amount - _currentMonthTotal).toDouble(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityPanel({required bool recentOnly}) {
    final matching = recentOnly ? _entries : _filteredEntries;
    final visibleEntries = recentOnly ? matching.take(5).toList() : matching;
    final empty = visibleEntries.isEmpty;
    final hasAnyEntries = _entries.isNotEmpty;

    return _PanelCard(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeading(
            eyebrow: recentOnly ? 'DEIN SPARBUCH' : 'ALLE EINTRÄGE',
            title: recentOnly ? 'Letzte Einträge' : 'Einträge im Überblick',
            description: recentOnly ? 'Deine zuletzt erfassten Sparbeträge.' : null,
            icon: Icons.receipt_long_outlined,
            trailing: recentOnly && _entries.isNotEmpty
                ? TextButton.icon(
                    onPressed: () => _navigate(_AppPage.entries),
                    style: TextButton.styleFrom(foregroundColor: pinkStrongColor),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                    label: const Text('Alle ansehen'),
                  )
                : null,
          ),
          if (!recentOnly) ...[
            const SizedBox(height: 13),
            _buildEntryFilters(),
          ],
          const SizedBox(height: 8),
          if (empty)
            _EmptyEntries(
              hasAnyEntries: hasAnyEntries,
              onAdd: _openEntryForm,
              onReset: () {
                setState(() {
                  _activeTypeFilter = 'Alle';
                  _activeStoreFilter = 'Alle Läden';
                  _searchText = '';
                  _searchController.clear();
                });
              },
            )
          else
            ...visibleEntries.map(
              (entry) => _SavingsEntryTile(
                entry: entry,
                onDelete: () => _removeEntry(entry),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _typeFilters.map((filter) {
            final selected = filter == _activeTypeFilter;
            return ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              selectedColor: pinkLightColor,
              backgroundColor: const Color(0xFFF7F8F6),
              side: BorderSide(color: selected ? const Color(0xFFEFD6E0) : Colors.transparent),
              labelStyle: TextStyle(
                color: selected ? pinkStrongColor : const Color(0xFF89958B),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _activeTypeFilter = filter),
            );
          }).toList(),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          alignment: WrapAlignment.end,
          children: [
            SizedBox(
              width: 210,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: const InputDecoration(
                  hintText: 'Einträge durchsuchen',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                value: _activeStoreFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Laden',
                  isDense: true,
                ),
                items: _defaultStores
                    .map((store) => DropdownMenuItem(value: store, child: Text(store)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _activeStoreFilter = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final ValueChanged<SavingsEntry> onSave;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _store;
  String? _type;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      locale: const Locale('de', 'DE'),
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (chosen != null && mounted) setState(() => _date = chosen);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_amountController.text);
    final type = _type;
    if (amount == null || type == null) return;
    widget.onSave(
      SavingsEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        title: _titleController.text.trim(),
        store: _store ?? 'Sonstiges',
        type: type,
        date: DateTime(_date.year, _date.month, _date.day),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 21, 22, 23),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: pinkLightColor,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.savings_outlined, color: pinkStrongColor),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onCancel,
                      tooltip: 'Schließen',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'NEUER EINTRAG',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Was hast du gespart?',
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Betrag, Sparart und Datum eintragen.',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                const SizedBox(height: 17),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Betrag',
                    hintText: '0,00',
                    prefixText: '€ ',
                  ),
                  validator: (value) {
                    final amount = _parseAmount(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Bitte einen Betrag größer als 0 € eingeben.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Bezeichnung',
                    hintText: 'Eintrag benennen',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bitte eine Bezeichnung eingeben.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  hint: const Text('Sparart wählen'),
                  decoration: const InputDecoration(labelText: 'Sparart'),
                  items: savingsTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  validator: (value) => value == null ? 'Bitte eine Sparart wählen.' : null,
                  onChanged: (value) => setState(() => _type = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _store,
                  hint: const Text('Optional auswählen'),
                  decoration: const InputDecoration(labelText: 'Laden / Ort (optional)'),
                  items: savingsStores
                      .map((store) => DropdownMenuItem(value: store, child: Text(store)))
                      .toList(),
                  onChanged: (value) => setState(() => _store = value),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _chooseDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(_date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 70,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                    hintText: 'Zusätzliche Notiz',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: pinkColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Betrag eintragen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date, required this.compact});

  final DateTime date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 160 : 225),
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFFA36C81)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              DateFormat(compact ? 'EEE, d. MMM' : 'EEEE, d. MMMM', 'de_DE').format(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF78867B), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 38.0 : 42.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFD45B87), pinkStrongColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30983257),
                blurRadius: 13,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.savings_outlined,
            color: Colors.white,
            size: compact ? 20 : 22,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Color(0xFF352831),
                  fontFamily: 'Manrope',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
                children: [
                  TextSpan(text: 'sparschwein'),
                  TextSpan(text: '.', style: TextStyle(color: pinkColor)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DEIN SPAR-COCKPIT',
              style: TextStyle(
                color: const Color(0xFF98A49B),
                fontSize: compact ? 6.5 : 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.description,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: pinkLightColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: pinkStrongColor, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mutedColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: inkColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedColor, fontSize: 9),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

class _TotalSavingsCard extends StatelessWidget {
  const _TotalSavingsCard({required this.total, required this.monthlyValues});

  final double total;
  final List<double> monthlyValues;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      padding: const EdgeInsets.fromLTRB(23, 22, 23, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(
          colors: [pinkDarkColor, Color(0xFF6B2A47), Color(0xFF7C3452)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26502037),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -96,
            right: -25,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFDDEB).withValues(alpha: 0.04),
                    blurRadius: 0,
                    spreadRadius: 23,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: const Icon(Icons.savings_outlined, color: Color(0xFFF4CADA), size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GESAMT GESPART',
                          style: TextStyle(
                            color: Color(0xFFF0C3D4),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Alle Einträge',
                          style: TextStyle(color: Color(0xFFFFE4EE), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFFF3C0D5)),
                        SizedBox(width: 5),
                        Text('Gesamt', style: TextStyle(color: Color(0xFFF5D4E0), fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                formatMoney(total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 41,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'Summe aller eingetragenen Sparbeträge.',
                      style: TextStyle(color: Color(0xFFFFE5EF), fontSize: 9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 118,
                    height: 36,
                    child: CustomPaint(painter: _SparklinePainter(monthlyValues)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    double maximum = values.fold<double>(0, (value, next) => value > next ? value : next);
    final minimum = values.fold<double>(0, (value, next) => value < next ? value : next);
    if (maximum == minimum) maximum = minimum + 1;
    final range = maximum - minimum;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1 ? size.width / 2 : size.width * index / (values.length - 1);
      final y = size.height - 4 - ((values[index] - minimum) / range) * (size.height - 10);
      points.add(Offset(x, y));
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFFF4C7D8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      points.last,
      3,
      Paint()..color = const Color(0xFFF8E5ED),
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(17),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: pinkLightColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: pinkStrongColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: inkColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF98A39A), fontSize: 9),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: _ProgressBar(progress: progress!, height: 4),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: pinkLightColor,
              color: pinkColor,
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: pinkStrongColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, this.height = 6});

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: progress,
          minHeight: height,
          backgroundColor: const Color(0xFFF0E6EB),
          color: pinkColor,
        ),
      ),
    );
  }
}

class _MonthChart extends StatelessWidget {
  const _MonthChart({required this.months});

  final List<_MonthTotal> months;

  @override
  Widget build(BuildContext context) {
    final maximum = months.fold<double>(
      0,
      (value, month) => value > month.amount ? value : month.amount,
    );
    final hasValues = maximum > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 166,
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _ChartGridPainter())),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: months.map((month) {
                  return Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = math.max(3.0, constraints.maxHeight - 42).toDouble();
                        final barHeight = month.amount > 0 && maximum > 0
                            ? math.max(6.0, availableHeight * month.amount / maximum).toDouble()
                            : 3.0;
                        return Column(
                          children: [
                            SizedBox(
                              height: 21,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  month.amount > 0 ? formatShortMoney(month.amount) : '',
                                  style: TextStyle(
                                    color: month.isCurrent ? pinkStrongColor : mutedColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 440),
                                  curve: Curves.easeOutCubic,
                                  width: 23,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: month.isCurrent
                                          ? const [Color(0xFFCD5682), pinkStrongColor]
                                          : const [Color(0xFFEFD8E3), Color(0xFFF6E8EE)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 21,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  formatMonthShort(month.date),
                                  style: TextStyle(
                                    color: month.isCurrent ? pinkStrongColor : mutedColor,
                                    fontSize: 9,
                                    fontWeight: month.isCurrent ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: pinkColor, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                hasValues ? 'Ersparnisse pro Monat' : 'Keine Einträge in diesem Zeitraum',
                style: const TextStyle(color: mutedColor, fontSize: 9),
              ),
            ),
            const Text('Letzte sechs Monate', style: TextStyle(color: mutedColor, fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  const _ChartGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEDEFEF)
      ..strokeWidth = 1;
    for (final fraction in const [0.24, 0.49, 0.74]) {
      final y = size.height * fraction;
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width).toDouble(), y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartGridPainter oldDelegate) => false;
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: pinkLightColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFF0DCE4)),
          ),
          child: Icon(icon, color: pinkStrongColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: mutedColor, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: inkColor, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Text(description, style: const TextStyle(color: mutedColor, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalNumber extends StatelessWidget {
  const _GoalNumber({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedColor, fontSize: 9)),
        const SizedBox(height: 4),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: inkColor, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.amount,
    required this.label,
    required this.reached,
    required this.remaining,
  });

  final double amount;
  final String label;
  final bool reached;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2EF))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: reached ? pinkLightColor : const Color(0xFFF5F6F1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              reached ? Icons.check_rounded : Icons.flag_outlined,
              size: 17,
              color: reached ? pinkStrongColor : const Color(0xFF9DA58E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: inkColor, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${formatMoney(amount)} in einem Monat', style: const TextStyle(color: mutedColor, fontSize: 8)),
              ],
            ),
          ),
          Text(
            reached ? 'Geschafft' : '${formatMoney(remaining)} übrig',
            style: TextStyle(
              color: reached ? pinkStrongColor : mutedColor,
              fontSize: 8,
              fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsEntryTile extends StatelessWidget {
  const _SavingsEntryTile({required this.entry, required this.onDelete});

  final SavingsEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _entryColor(entry.type);
    final icon = _entryIcon(entry.type);
    final metadata = [
      _relativeDate(entry.date),
      entry.store,
      entry.type,
    ].where((value) => value.isNotEmpty).join('  ·  ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2EF))),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: inkColor, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(metadata, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedColor, fontSize: 8)),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(entry.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedColor, fontSize: 8)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${formatMoney(entry.amount)}',
            style: const TextStyle(color: pinkStrongColor, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Eintrag entfernen',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFB1A8AC)),
          ),
        ],
      ),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries({
    required this.hasAnyEntries,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasAnyEntries;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 27, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(color: pinkLightColor, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.receipt_long_outlined, color: pinkStrongColor),
          ),
          const SizedBox(height: 10),
          Text(
            hasAnyEntries ? 'Keine passenden Einträge' : 'Noch keine Einträge',
            style: const TextStyle(color: inkColor, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            hasAnyEntries
                ? 'Ändere Suche oder Filter.'
                : 'Trage deinen ersten Sparbetrag ein.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),
          const SizedBox(height: 13),
          if (hasAnyEntries)
            TextButton(onPressed: onReset, child: const Text('Filter zurücksetzen'))
          else
            OutlinedButton.icon(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: pinkStrongColor,
                side: const BorderSide(color: Color(0xFFECD3DD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Sparbetrag eintragen'),
            ),
        ],
      ),
    );
  }
}

Color _entryColor(String type) => switch (type) {
      'Cashback' => pinkStrongColor,
      'Rabatt' => goldColor,
      'Gratisartikel' => _freebieColor,
      'Fundstück' => _foundColor,
      _ => _neutralIconColor,
    };

IconData _entryIcon(String type) => switch (type) {
      'Cashback' => Icons.currency_exchange_rounded,
      'Rabatt' => Icons.percent_rounded,
      'Gratisartikel' => Icons.redeem_outlined,
      'Fundstück' => Icons.auto_awesome_outlined,
      _ => Icons.account_balance_wallet_outlined,
    };

String _relativeDate(DateTime date) {
  final today = DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  if (dateOnly == todayOnly) return 'Heute';
  if (dateOnly == todayOnly.subtract(const Duration(days: 1))) return 'Gestern';
  return formatEntryDate(date);
}

String _greeting(int hour) {
  if (hour >= 5 && hour < 11) return 'Guten Morgen';
  if (hour >= 11 && hour < 14) return 'Guten Mittag';
  if (hour >= 14 && hour < 18) return 'Guten Nachmittag';
  return 'Guten Abend';
}

double? _parseAmount(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final normalized = value.contains(',')
      ? value.replaceAll('.', '').replaceAll(',', '.')
      : value;
  return double.tryParse(normalized);
}
