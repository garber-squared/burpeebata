import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/burpee_type.dart';
import '../models/workout_config.dart';
import '../models/workout_template.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/dnd_service.dart';
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
  bool _powerUserMode = false;
  bool _dndDuringWorkout = false;
  bool _isLoading = true;

  final DndService _dndService = DndService();

  WorkoutConfig get _config => _configs[_selectedType]!;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Load user preferences and last-used configuration (Power User feature)
  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    // Load power user mode preference
    final powerUserMode = await StorageService.isPowerUserMode();

    // Load DND during workout preference
    final dndDuringWorkout = await StorageService.isDndDuringWorkout();

    // Load last-used configuration
    final lastConfig = await StorageService.getLastUsedConfig();

    setState(() {
      _powerUserMode = powerUserMode;
      _dndDuringWorkout = dndDuringWorkout;
      if (lastConfig != null) {
        _selectedType = lastConfig.burpeeType;
        _configs[lastConfig.burpeeType] = lastConfig;
      }
      _isLoading = false;
    });
  }

  /// Save current configuration as last-used (Power User feature)
  Future<void> _saveAsLastUsed() async {
    await StorageService.saveLastUsedConfig(_config);
  }

  /// Toggle power user mode
  Future<void> _togglePowerUserMode() async {
    final newValue = !_powerUserMode;
    await StorageService.setPowerUserMode(newValue);
    setState(() => _powerUserMode = newValue);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newValue
              ? 'Power User Mode enabled - Last workout auto-loads'
              : 'Power User Mode disabled',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Toggle Do Not Disturb during workout (Android only)
  Future<void> _toggleDndDuringWorkout() async {
    // Check if DND is supported on this platform
    if (!_dndService.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Do Not Disturb is only available on Android'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If enabling, check for permission first
    if (!_dndDuringWorkout) {
      final hasPermission = await _dndService.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'To enable Do Not Disturb during workouts, '
              'the app needs permission to modify notification settings.\n\n'
              'Would you like to open settings to grant this permission?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          await _dndService.requestPermission();
        }
        return;
      }
    }

    final newValue = !_dndDuringWorkout;
    await StorageService.setDndDuringWorkout(newValue);
    setState(() => _dndDuringWorkout = newValue);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newValue
              ? 'Do Not Disturb will be enabled during workouts'
              : 'Do Not Disturb during workouts disabled',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              'v1.3.0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ),
        title: const Text('BurpeeBata'),
        centerTitle: true,
        actions: [
          // Do Not Disturb toggle (Android only)
          if (_dndService.isSupported)
            IconButton(
              icon: Icon(
                _dndDuringWorkout ? Icons.do_not_disturb_on : Icons.do_not_disturb_off,
                color: _dndDuringWorkout ? Colors.red : null,
              ),
              tooltip: _dndDuringWorkout ? 'DND During Workout (ON)' : 'DND During Workout (OFF)',
              onPressed: _toggleDndDuringWorkout,
            ),
          // Power User Mode toggle
          IconButton(
            icon: Icon(
              _powerUserMode ? Icons.flash_on : Icons.flash_off,
              color: _powerUserMode ? Colors.amber : null,
            ),
            tooltip: _powerUserMode ? 'Power User Mode (ON)' : 'Power User Mode (OFF)',
            onPressed: _togglePowerUserMode,
          ),
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
            // Hide templates section in power user mode (streamlined workflow)
            if (!_powerUserMode) ...[
              _buildWorkoutTemplateSection(),
              const SizedBox(height: 24),
            ],
            if (_loadedTemplate != null) _buildLoadedTemplateInfo(),
            if (_loadedTemplate != null) const SizedBox(height: 24),
            _buildBurpeeTypeSelector(),
            const SizedBox(height: 24),
            _buildStartButton(),
            const SizedBox(height: 24),
            _buildWorkoutSummary(),
            const SizedBox(height: 24),
            _buildConfigCard(),
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
          // Value display with long-press for direct input (Power User feature)
          GestureDetector(
            onLongPress: () => _showNumericInputDialog(
              context: context,
              label: label,
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
            child: SizedBox(
              width: 60,
              child: TextFormField(
                key: ValueKey('$label-$value'),
                initialValue: '$value',
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
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

  /// Show numeric input dialog (triggered by long-press - Power User feature)
  Future<void> _showNumericInputDialog({
    required BuildContext context,
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) async {
    final controller = TextEditingController(text: '$value');
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: '$min-$max',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text);
                if (parsed != null) {
                  Navigator.pop(context, parsed.clamp(min, max));
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
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
      onPressed: () async {
        // Save current config as last-used (Power User feature)
        await _saveAsLastUsed();

        if (!mounted) return;
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
