import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/metric_card.dart';
import '../utils/app_colors.dart';
import 'add_entry_screen.dart';
import 'records_screen.dart';
import 'profile_settings_screen.dart';
import '../../db/health_database.dart';
import '../health_records/health_entry.dart';
import 'package:healthmate/services/auth_service.dart';
import '../../main.dart';

// ----------------------- Providers -----------------------

// Profile State
final profileProvider = StateNotifierProvider<ProfileNotifier, Map<String, dynamic>>(
  (ref) => ProfileNotifier(),
);

// Health Summary State
final healthSummaryProvider = StateNotifierProvider<HealthSummaryNotifier, HealthSummary>(
  (ref) => HealthSummaryNotifier(),
);

// Search Results State
final searchResultsProvider =
    StateNotifierProvider<SearchResultsNotifier, List<HealthEntry>>(
        (ref) => SearchResultsNotifier());

// ----------------------- Models -----------------------
class HealthSummary {
  final int todaySteps;
  final int todayCalories;
  final int todayWater;
  final List<double> stepsWeek;
  final List<double> caloriesWeek;
  final List<double> waterWeek;
  final List<DateTime> weekDates;

  HealthSummary({
    this.todaySteps = 0,
    this.todayCalories = 0,
    this.todayWater = 0,
    this.stepsWeek = const [],
    this.caloriesWeek = const [],
    this.waterWeek = const [],
    this.weekDates = const [],
  });

  HealthSummary copyWith({
    int? todaySteps,
    int? todayCalories,
    int? todayWater,
    List<double>? stepsWeek,
    List<double>? caloriesWeek,
    List<double>? waterWeek,
    List<DateTime>? weekDates,
  }) {
    return HealthSummary(
      todaySteps: todaySteps ?? this.todaySteps,
      todayCalories: todayCalories ?? this.todayCalories,
      todayWater: todayWater ?? this.todayWater,
      stepsWeek: stepsWeek ?? this.stepsWeek,
      caloriesWeek: caloriesWeek ?? this.caloriesWeek,
      waterWeek: waterWeek ?? this.waterWeek,
      weekDates: weekDates ?? this.weekDates,
    );
  }
}

// ----------------------- Notifiers -----------------------
class ProfileNotifier extends StateNotifier<Map<String, dynamic>> {
  ProfileNotifier()
      : super({
          'image': 'assets/images/profile_placeholder.png',
          'name': 'Praveen',
          'email': 'praveen@example.com',
          'phone': '0771234567',
          'age': '25',
          'weight': '70',
          'height': '175',
        });

  void updateProfile(Map<String, dynamic> newProfile) {
    state = newProfile;
  }
}

class HealthSummaryNotifier extends StateNotifier<HealthSummary> {
  HealthSummaryNotifier() : super(HealthSummary());

  Future<void> loadSummary() async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final entriesToday = await HealthDatabase.instance.readByDate(todayStr);

      int totalSteps = 0;
      int totalCalories = 0;
      int totalWater = 0;

      for (var e in entriesToday) {
        totalSteps += e.steps;
        totalCalories += e.calories;
        totalWater += e.water;
      }

      final today = DateTime.now();
      List<DateTime> weekDates =
          List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

      List<double> stepsWeek = [];
      List<double> caloriesWeek = [];
      List<double> waterWeek = [];

      for (var date in weekDates) {
        final entries = await HealthDatabase.instance
            .readByDate(DateFormat('yyyy-MM-dd').format(date));
        int steps = 0, calories = 0, water = 0;
        for (var e in entries) {
          steps += e.steps;
          calories += e.calories;
          water += e.water;
        }
        stepsWeek.add(steps.toDouble());
        caloriesWeek.add(calories.toDouble());
        waterWeek.add(water.toDouble());
      }

      state = state.copyWith(
        todaySteps: totalSteps,
        todayCalories: totalCalories,
        todayWater: totalWater,
        stepsWeek: stepsWeek,
        caloriesWeek: caloriesWeek,
        waterWeek: waterWeek,
        weekDates: weekDates,
      );
    } catch (e) {
      // Handle error if needed
    }
  }
}

class SearchResultsNotifier extends StateNotifier<List<HealthEntry>> {
  SearchResultsNotifier() : super([]);

  Future<void> searchRecords(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }
    try {
      final results = await HealthDatabase.instance.readByDate(query);
      state = results;
    } catch (_) {
      state = [];
    }
  }

  void clear() {
    state = [];
  }
}

// ----------------------- HomeScreen -----------------------
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onToggleTheme;
  const HomeScreen({super.key, this.onToggleTheme});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    ref.read(healthSummaryProvider.notifier).loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateFromCalendar() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      _searchController.text = formattedDate;
      await ref.read(searchResultsProvider.notifier).searchRecords(formattedDate);
      setState(() => _isSearching = true);
    }
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login', (Route<dynamic> route) => false);
        }
      } catch (_) {}
    }
  }

  void _goToAddEntry([HealthEntry? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          existing: existing,
          onSaved: () =>
              ref.read(healthSummaryProvider.notifier).loadSummary(),
        ),
      ),
    );
  }

  void _goToRecords() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RecordsScreen(),
      ),
    ).then((_) => ref.read(healthSummaryProvider.notifier).loadSummary());
  }

  double _getSafeMaxY(List<double> values) {
    if (values.isEmpty) return 10.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal * 1.3 : 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final summary = ref.watch(healthSummaryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navIconColor = isDark ? Colors.purple[200] : Colors.deepPurple;
    final navBgColor = isDark ? Colors.grey[850] : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Healthmate'),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: widget.onToggleTheme ??
                () {
                  final themeNotifier = ref.read(themeModeProvider.notifier);
                  themeNotifier.state = themeNotifier.state == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(healthSummaryProvider.notifier).loadSummary(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(profile),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildMetricsRow(summary.todaySteps, summary.todayCalories),
            const SizedBox(height: 12),
            _buildWaterCard(summary.todayWater),
            const SizedBox(height: 20),
            if (!_isSearching) ...[
              const Text(
                'Weekly Activity Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildWeeklyCharts(
                  summary.stepsWeek,
                  summary.caloriesWeek,
                  summary.waterWeek,
                  summary.weekDates),
            ],
            if (_isSearching)
              _buildSearchResults(searchResults),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () => _goToAddEntry(),
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: navBgColor,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                  ref.read(searchResultsProvider.notifier).clear();
                  ref.read(healthSummaryProvider.notifier).loadSummary();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, color: navIconColor),
                    const SizedBox(height: 2),
                    Text(
                      'Home',
                      style: TextStyle(fontSize: 10, color: navIconColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 200),
              GestureDetector(
                onTap: _goToRecords,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list_alt, color: navIconColor),
                    const SizedBox(height: 2),
                    Text(
                      'Records',
                      style: TextStyle(fontSize: 10, color: navIconColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Widgets ------------------

  Widget _buildProfileHeader(Map<String, dynamic> profile) {
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Stack(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsScreen(
                      currentName: profile['name'],
                      currentEmail: profile['email'],
                      currentPhone: profile['phone'],
                      currentAge: profile['age'],
                      currentWeight: profile['weight'],
                      currentHeight: profile['height'],
                      currentProfileImage: profile['image'],
                    ),
                  ),
                );
                if (result != null) {
                  ref.read(profileProvider.notifier).updateProfile(result);
                }
              },
              child: Hero(
                tag: 'avatar',
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: profile['image'].startsWith('assets/')
                      ? AssetImage(profile['image'])
                      : FileImage(File(profile['image'])) as ImageProvider,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,',
                      style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color)),
                  Text(profile['name'],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: _searchController,
        readOnly: true,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          hintText: 'Search records',
          hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color),
          prefixIcon: Icon(Icons.search,
              size: 20, color: Theme.of(context).iconTheme.color),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today,
                size: 18, color: Theme.of(context).iconTheme.color),
            onPressed: _pickDateFromCalendar,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(255, 202, 202, 202).withOpacity(0.15)
              : const Color.fromARGB(255, 216, 216, 216),
        ),
        onTap: _pickDateFromCalendar,
      ),
    );
  }

  Widget _buildSearchResults(List<HealthEntry> results) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No records found for this date.',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results.map((entry) {
        DateTime entryDate;
        try {
          entryDate = DateTime.parse(entry.date);
        } catch (_) {
          entryDate = DateTime.now();
        }

        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(
              '${DateFormat('yyyy-MM-dd').format(entryDate)} - Steps: ${entry.steps}',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            subtitle: Text(
              'Calories: ${entry.calories}, Water: ${entry.water} ml',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
              onPressed: () => _goToAddEntry(entry),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsRow(int steps, int calories) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Steps',
            value: steps.toString(),
            icon: Icons.directions_walk,
            gradient: AppColors.stepsGradient,
            goal: 10000,
            progress: steps / 10000,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Calories',
            value: calories.toString(),
            icon: Icons.local_fire_department,
            gradient: AppColors.caloriesGradient,
            goal: 2500,
            progress: calories / 2500,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterCard(int water) {
    return MetricCard(
      label: 'Water (ml)',
      value: water.toString(),
      icon: Icons.water,
      gradient: AppColors.waterGradient,
      goal: 3000,
      progress: water / 3000,
    );
  }

  Widget _buildWeeklyCharts(List<double> steps, List<double> calories,
      List<double> water, List<DateTime> weekDates) {
    final activities = [
      {'label': 'Steps', 'values': steps, 'color': Colors.blueAccent},
      {'label': 'Calories', 'values': calories, 'color': Colors.redAccent},
      {'label': 'Water', 'values': water, 'color': Colors.lightBlue},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activities.map((activity) {
        final values = activity['values'] as List<double>;
        final safeMaxY = _getSafeMaxY(values);
        final Color lineColor = activity['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            color: Theme.of(context).cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity['label'] as String,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: safeMaxY,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                if (value < 0 || value > 6) return const SizedBox();
                                return Text(DateFormat('E').format(
                                    weekDates[value.toInt()]));
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                                values.length,
                                (index) => FlSpot(
                                    index.toDouble(), values[index])),
                            isCurved: true,
                            barWidth: 3,
                            color: lineColor,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
