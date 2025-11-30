import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import 'add_entry_screen.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      setState(() {});
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(healthEntryProvider.notifier).delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {

    final allEntries = ref.watch(healthEntryProvider);

    final sortedEntries = [...allEntries]..sort((a, b) => b.date.compareTo(a.date));

    final entriesToShow = _searchController.text.isEmpty
        ? sortedEntries
        : sortedEntries
            .where((e) => e.date.startsWith(_searchController.text))
            .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: Column(
        children: [
          // --------------------- SEARCH BOX -----------------------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Search records by date',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateFromCalendar,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[200],
              ),
              onTap: _pickDateFromCalendar,
            ),
          ),

          Expanded(
            child: entriesToShow.isEmpty
                ? const Center(child: Text('No records found.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: entriesToShow.length,
                    itemBuilder: (context, index) {
                      final e = entriesToShow[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color.fromARGB(255, 46, 38, 56), const Color.fromARGB(255, 46, 38, 56)]
                                : [Colors.white, const Color.fromARGB(255, 241, 227, 253)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.4)
                                  : const Color.fromARGB(255, 149, 68, 255).withOpacity(0.15),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(DateTime.parse(e.date)),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black54),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddEntryScreen(
                                              existing: e,
                                              onSaved: () {
                                                ref
                                                    .read(
                                                        healthEntryProvider
                                                            .notifier)
                                                    .refresh();
                                              },
                                            ),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        _confirmDelete(e.id!);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.directions_walk,
                                    label: "Steps",
                                    value: e.steps.toString(),
                                    color: Colors.green,
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.local_fire_department,
                                    label: "Calories",
                                    value: e.calories.toString(),
                                    color: Colors.red,
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.waves,
                                    label: "Water",
                                    value: "${e.water} ml",
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 26, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}