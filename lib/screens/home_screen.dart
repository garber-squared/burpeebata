import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/burpee_type.dart';
import '../models/workout_config.dart';
import '../models/workout_template.dart';
import '../providers/auth_provider.dart';
import 'timer_screen.dart';
import 'history_screen.dart';
import 'saved_workouts_screen.dart';
import 'workout_builder_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<BurpeeType, WorkoutConfig> _configs = {
    BurpeeType.militarySixCount:
        WorkoutConfig.forBurpeeType(BurpeeType.militarySixCount),
    BurpeeType.navySeal: WorkoutConfig.forBurpeeType(BurpeeType.navySeal),
  };
  BurpeeType _selectedType = BurpeeType.militarySixCount;
  WorkoutTemplate? _loadedTemplate;

  WorkoutConfig get _config => _configs[_selectedType]!;

  void _updateConfig(WorkoutConfig newConfig) {
    setState(() {
      _configs[_selectedType] = newConfig;
    });
  }

  Future<void> _loadSavedWorkout() async {
    final template = await Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(builder: (_) => const SavedWorkoutsScreen()),
    );

    if (template != null) {
      setState(() {
        _loadedTemplate = template;
        _selectedType = template.burpeeType;
        _configs[_selectedType] = template.toConfig();
      });
    }
  }

  Future<void> _createNewWorkout() async {
    final template = await Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutBuilderScreen(
          existingTemplate: _loadedTemplate != null
              ? WorkoutTemplate.fromConfig(
                  name: _loadedTemplate!.name,
                  config: _config,
                )
              : null,
        ),
      ),
    );

    if (template != null) {
      setState(() {
        _loadedTemplate = template;
        _selectedType = template.burpeeType;
        _configs[_selectedType] = template.toConfig();
      });
    }
  }

  void _clearLoadedTemplate() {
    setState(() {
      _loadedTemplate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              'v1.1.0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ),
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
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Account',
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                      break;
                    case 'signout':
                      await authProvider.signOut();
                      break;
                  }
                },
                itemBuilder: (context) {
                  return [
                    if (!authProvider.isAnonymous)
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person),
                            SizedBox(width: 8),
                            Text('Profile'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout),
                          const SizedBox(width: 8),
                          Text(authProvider.isAnonymous
                              ? 'Sign In'
                              : 'Sign Out'),
                        ],
                      ),
                    ),
                  ];
                },
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
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAnonymous) {
                  return Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You\'re in guest mode. Sign up to save your data!',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await authProvider.signOut();
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildWorkoutTemplateSection(),
            const SizedBox(height: 24),
            if (_loadedTemplate != null) _buildLoadedTemplateInfo(),
            if (_loadedTemplate != null) const SizedBox(height: 24),
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

  Widget _buildWorkoutTemplateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Workout Templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadSavedWorkout,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Load Saved'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createNewWorkout,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedTemplateInfo() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loaded Template',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _loadedTemplate!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _clearLoadedTemplate,
              icon: const Icon(Icons.close),
              tooltip: 'Clear template',
            ),
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
            selected: {_selectedType},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedType = selection.first;
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
              label: 'Initial Countdown (sec)',
              value: _config.initialCountdown,
              min: 3,
              max: 30,
              buttonColor: Colors.blue,
              onChanged: (value) {
                _updateConfig(_config.copyWith(initialCountdown: value));
              },
            ),
            _buildNumberInput(
              label: 'Number of Sets',
              value: _config.numberOfSets,
              min: 1,
              max: 20,
              buttonColor: Colors.purple,
              onChanged: (value) {
                _updateConfig(_config.copyWith(numberOfSets: value));
              },
            ),
            _buildNumberInput(
              label: 'Seconds per Set',
              value: _config.secondsPerSet,
              min: 1,
              max: 60,
              buttonColor: Colors.orange,
              onChanged: (value) {
                _updateConfig(_config.copyWith(secondsPerSet: value));
              },
            ),
            _buildNumberInput(
              label: 'Reps per Set',
              value: _config.repsPerSet,
              min: 1,
              max: 30,
              buttonColor: Colors.teal,
              onChanged: (value) {
                _updateConfig(_config.copyWith(repsPerSet: value));
              },
            ),
            _buildNumberInput(
              label: 'Rest Between Sets (sec)',
              value: _config.restBetweenSets,
              min: 0,
              max: 60,
              buttonColor: Colors.indigo,
              onChanged: (value) {
                _updateConfig(_config.copyWith(restBetweenSets: value));
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
    required Color buttonColor,
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
            onPressed: value > min ? () => onChanged(value - 1) : null,
            style: IconButton.styleFrom(
              backgroundColor: value > min
                  ? buttonColor.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: value > min ? buttonColor : null,
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
            onPressed: value < max ? () => onChanged(value + 1) : null,
            style: IconButton.styleFrom(
              backgroundColor: value < max
                  ? buttonColor.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: value < max ? buttonColor : null,
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
