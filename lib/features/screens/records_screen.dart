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
      setState(() {}); // Trigger rebuild with new search query
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
    // Watch the provider so UI rebuilds automatically when entries change
    final allEntries = ref.watch(healthEntryProvider);

    // Sort entries by date descending
    final sortedEntries = [...allEntries]..sort((a, b) => b.date.compareTo(a.date));

    // Filter entries based on search query
    final entriesToShow = _searchController.text.isEmpty
        ? sortedEntries
        : sortedEntries
            .where((e) => e.date.startsWith(_searchController.text))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: Column(
        children: [
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
                fillColor: Theme.of(context).brightness == Brightness.dark
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
                    itemCount: entriesToShow.length,
                    itemBuilder: (context, index) {
                      final e = entriesToShow[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text('Date: ${e.date.split('T')[0]}'),
                          subtitle: Text(
                              'Steps: ${e.steps}, Calories: ${e.calories}, Water: ${e.water} ml'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEntryScreen(
                                        existing: e,
                                        onSaved: () {
                                          ref
                                              .read(
                                                  healthEntryProvider.notifier)
                                              .refresh();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDelete(e.id!),
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
}