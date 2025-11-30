import 'package:flutter/material.dart';
import '../health_records/health_entry.dart';

class EntryCard extends StatelessWidget {
  final HealthEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const EntryCard({super.key, required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Hero(tag: 'date-${entry.id}', child: CircleAvatar(child: Text(entry.date.split('-').last))),
        title: Text(entry.date),
        subtitle: Text('Steps: ${entry.steps} • Calories: ${entry.calories} • Water: ${entry.water}ml'),
        trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') {
          onEdit();

        } else if (v == 'delete') onDelete(); }, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
      ),
    );
  }
}