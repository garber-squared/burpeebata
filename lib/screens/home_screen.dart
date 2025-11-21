import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/burpee_type.dart';
import '../models/workout_config.dart';
import 'timer_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkoutConfig _config = const WorkoutConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BurpeeBata'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBurpeeTypeSelector(),
            const SizedBox(height: 24),
            _buildConfigCard(),
            const SizedBox(height: 24),
            _buildWorkoutSummary(),
            const SizedBox(height: 32),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBurpeeTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Burpee Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<BurpeeType>(
              segments: BurpeeType.values.map((type) {
                return ButtonSegment<BurpeeType>(
                  value: type,
                  label: Text(
                    type == BurpeeType.militarySixCount ? '6-Count' : 'Navy Seal',
                  ),
                );
              }).toList(),
              selected: {_config.burpeeType},
              onSelectionChanged: (selection) {
                setState(() {
                  _config = _config.copyWith(burpeeType: selection.first);
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _config.burpeeType.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Reps per Set',
              value: _config.repsPerSet,
              min: 1,
              max: 30,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(repsPerSet: value);
                });
              },
            ),
            _buildNumberInput(
              label: 'Seconds per Set',
              value: _config.secondsPerSet,
              min: 1,
              max: 60,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(secondsPerSet: value);
                });
              },
            ),
            _buildNumberInput(
              label: 'Number of Sets',
              value: _config.numberOfSets,
              min: 1,
              max: 20,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(numberOfSets: value);
                });
              },
            ),
            _buildNumberInput(
              label: 'Rest Between Sets (sec)',
              value: _config.restBetweenSets,
              min: 0,
              max: 60,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(restBetweenSets: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min
                ? () => onChanged(value - 1)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: value > min
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextFormField(
              key: ValueKey('$label-$value'),
              initialValue: '$value',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null) {
                  final clamped = parsed.clamp(min, max);
                  onChanged(clamped);
                }
              },
              onFieldSubmitted: (text) {
                final parsed = int.tryParse(text);
                if (parsed == null || text.isEmpty) {
                  onChanged(value);
                } else {
                  onChanged(parsed.clamp(min, max));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max
                ? () => onChanged(value + 1)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: value < max
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummary() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Total Workout Time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _config.formattedDuration,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_config.numberOfSets} sets × ${_config.repsPerSet} reps = ${_config.numberOfSets * _config.repsPerSet} total reps',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TimerScreen(config: _config),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      child: const Text(
        'START WORKOUT',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
