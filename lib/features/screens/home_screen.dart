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

// Providers for HomeScreen state
final todayStepsProvider = StateProvider<int>((ref) => 0);
final todayCaloriesProvider = StateProvider<int>((ref) => 0);
final todayWaterProvider = StateProvider<int>((ref) => 0);

final stepsWeekProvider = StateProvider<List<double>>((ref) => []);
final caloriesWeekProvider = StateProvider<List<double>>((ref) => []);
final waterWeekProvider = StateProvider<List<double>>((ref) => []);
final weekDatesProvider = StateProvider<List<DateTime>>((ref) => []);

final profileProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'image': 'assets/images/profile_placeholder.png',
      'name': 'Praveen',
      'email': 'praveen@example.com',
      'phone': '0771234567',
      'age': '25',
      'weight': '70',
      'height': '175',
    });

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onToggleTheme;
  const HomeScreen({super.key, this.onToggleTheme});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<HealthEntry> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load daily summary and weekly stats
  Future<void> _loadSummary() async {
    try {
      setState(() => _isLoading = true);

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

      if (mounted) {
        ref.read(todayStepsProvider.notifier).state = totalSteps;
        ref.read(todayCaloriesProvider.notifier).state = totalCalories;
        ref.read(todayWaterProvider.notifier).state = totalWater;
        ref.read(weekDatesProvider.notifier).state = weekDates;
        ref.read(stepsWeekProvider.notifier).state = stepsWeek;
        ref.read(caloriesWeekProvider.notifier).state = caloriesWeek;
        ref.read(waterWeekProvider.notifier).state = waterWeek;
      }
    } catch (e) {
      _showError('Failed to load summary: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigate to AddEntryScreen and refresh summary after save
  void _goToAddEntry([HealthEntry? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          existing: existing,
          onSaved: _loadSummary,
        ),
      ),
    );
  }

  /// Navigate to RecordsScreen and refresh summary automatically via Riverpod
  void _goToRecords() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RecordsScreen(),
      ),
    ).then((_) => _loadSummary());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double _getSafeMaxY(List<double> values) {
    if (values.isEmpty) return 10.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal * 1.3 : 10.0;
  }

  Future<void> _searchRecords(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    try {
      setState(() => _isSearching = true);
      final results = await HealthDatabase.instance.readByDate(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      _showError('Failed to search records: $e');
    }
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
      _searchRecords(formattedDate);
    }
  }

  /// --- FIXED LOGOUT ---
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final todaySteps = ref.watch(todayStepsProvider);
    final todayCalories = ref.watch(todayCaloriesProvider);
    final todayWater = ref.watch(todayWaterProvider);
    final stepsWeek = ref.watch(stepsWeekProvider);
    final caloriesWeek = ref.watch(caloriesWeekProvider);
    final waterWeek = ref.watch(waterWeekProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // <-- removed back arrow
        title: const Text('Healthmate'),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nights_stay,
            ),
            onPressed: widget.onToggleTheme ?? () {
              final themeNotifier = ref.read(themeModeProvider.notifier);
              themeNotifier.state =
                  themeNotifier.state == ThemeMode.light
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildMetricsRow(todaySteps, todayCalories),
                  const SizedBox(height: 12),
                  _buildWaterCard(todayWater),
                  const SizedBox(height: 20),
                  if (!_isSearching)
                    _buildWeeklyCharts(stepsWeek, caloriesWeek, waterWeek),
                  if (_isSearching) _buildSearchResults(),
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
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = false;
                    _searchResults = [];
                    _searchController.clear();
                  });
                  _loadSummary();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 2),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
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
                    Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 2),
                    Text(
                      'Records',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
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

  // --- Widgets: Profile, Search, Metrics, Charts ---
  Widget _buildProfileHeader(Map<String, dynamic> profile) {
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    return Row(
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
            if (result != null) ref.read(profileProvider.notifier).state = result;
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
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              Text(profile['name'],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(dateStr,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
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
          hintStyle:
              TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
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
      children: _searchResults.map((entry) {
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

  Widget _buildWeeklyCharts(List<double> steps, List<double> calories, List<double> water) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity['label'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: safeMaxY,
                        lineTouchData: LineTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= 7) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - index))),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).textTheme.bodySmall?.color),
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              values.length,
                              (index) => FlSpot(index.toDouble(), values[index]),
                            ),
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
