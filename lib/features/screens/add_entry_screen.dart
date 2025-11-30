import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../health_records/health_entry.dart';
import '../providers/app_providers.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final HealthEntry? existing;
  final VoidCallback? onSaved;

  const AddEntryScreen({super.key, this.existing, this.onSaved});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _waterController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _stepsController.text = widget.existing!.steps.toString();
      _caloriesController.text = widget.existing!.calories.toString();
      _waterController.text = widget.existing!.water.toString();
      _selectedDate = DateTime.parse(widget.existing!.date);
    }
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final steps = _stepsController.text.trim();
    final calories = _caloriesController.text.trim();
    final water = _waterController.text.trim();

    if (steps.isEmpty || calories.isEmpty || water.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all activities'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final numberRegex = RegExp(r'^\d+$');
    if (!numberRegex.hasMatch(steps) ||
        !numberRegex.hasMatch(calories) ||
        !numberRegex.hasMatch(water)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only numbers are allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveEntry() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    final steps = int.parse(_stepsController.text.trim());
    final calories = int.parse(_caloriesController.text.trim());
    final water = int.parse(_waterController.text.trim());
    final dateStr = _selectedDate.toIso8601String().split('T').first;

    final entry = HealthEntry(
      id: widget.existing?.id,
      date: dateStr,
      steps: steps,
      calories: calories,
      water: water,
    );

    final notifier = ref.read(healthEntryProvider.notifier);
    if (widget.existing != null) {
      await notifier.update(entry);
    } else {
      await notifier.create(entry);
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    widget.onSaved?.call();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Entry' : 'Add Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Date Display ---
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 24, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Steps',
                prefixIcon: Icon(Icons.directions_walk, color: Colors.green),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories',
                prefixIcon: Icon(Icons.local_fire_department, color: Colors.red),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _waterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Water (ml)',
                prefixIcon: Icon(Icons.water, color: Colors.blueAccent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveEntry,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}