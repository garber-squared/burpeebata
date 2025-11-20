import 'package:flutter/material.dart';
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
        title: const Text('Burbata'),
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
            _buildSlider(
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
            _buildSlider(
              label: 'Seconds per Set',
              value: _config.secondsPerSet,
              min: 10,
              max: 60,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(secondsPerSet: value);
                });
              },
            ),
            _buildSlider(
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
            _buildSlider(
              label: 'Rest Between Sets (sec)',
              value: _config.restBetweenSets,
              min: 5,
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

  Widget _buildSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
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
