import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/burpee_type.dart';
import '../models/workout_template.dart';
import '../services/storage_service.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final WorkoutTemplate? existingTemplate;

  const WorkoutBuilderScreen({super.key, this.existingTemplate});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form values
  late String _name;
  late BurpeeType _burpeeType;
  late int _initialCountdown;
  late int _numberOfSets;
  late int _secondsPerSet;
  late int _repsPerSet;
  late int _restBetweenSets;

  @override
  void initState() {
    super.initState();
    // Initialize with existing template or defaults
    if (widget.existingTemplate != null) {
      _name = widget.existingTemplate!.name;
      _burpeeType = widget.existingTemplate!.burpeeType;
      _initialCountdown = widget.existingTemplate!.initialCountdown;
      _numberOfSets = widget.existingTemplate!.numberOfSets;
      _secondsPerSet = widget.existingTemplate!.secondsPerSet;
      _repsPerSet = widget.existingTemplate!.repsPerSet;
      _restBetweenSets = widget.existingTemplate!.restBetweenSets;
    } else {
      _name = '';
      _burpeeType = BurpeeType.militarySixCount;
      _initialCountdown = 10;
      _numberOfSets = 10;
      _secondsPerSet = 20;
      _repsPerSet = 5;
      _restBetweenSets = 4;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveTemplate() async {
    final template = WorkoutTemplate(
      id: widget.existingTemplate?.id,
      name: _name,
      burpeeType: _burpeeType,
      repsPerSet: _repsPerSet,
      secondsPerSet: _secondsPerSet,
      numberOfSets: _numberOfSets,
      restBetweenSets: _restBetweenSets,
      initialCountdown: _initialCountdown,
      createdAt: widget.existingTemplate?.createdAt,
    );

    await StorageService.saveWorkoutTemplate(template);

    if (mounted) {
      Navigator.pop(context, template);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTemplate == null
            ? 'Create Workout'
            : 'Edit Workout'),
        actions: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: const Text('BACK'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildNamePage(),
                _buildBurpeeTypePage(),
                _buildInitialCountdownPage(),
                _buildNumberOfSetsPage(),
                _buildSecondsPerSetPage(),
                _buildRepsPerSetPage(),
                _buildRestBetweenSetsPage(),
                _buildReviewPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(8, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentPage + 1} of 8',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return _PageWrapper(
      title: 'Name Your Workout',
      description: 'Give this workout configuration a memorable name',
      child: Column(
        children: [
          TextField(
            autofocus: true,
            controller: TextEditingController(text: _name)
              ..selection = TextSelection.collapsed(offset: _name.length),
            decoration: const InputDecoration(
              labelText: 'Workout Name',
              hintText: 'e.g., Morning Quick Burn',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _name = value;
              });
            },
            onSubmitted: (_) {
              if (_name.trim().isNotEmpty) {
                _nextPage();
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _name.trim().isEmpty ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('NEXT'),
          ),
        ],
      ),
    );
  }

  Widget _buildBurpeeTypePage() {
    return _PageWrapper(
      title: 'Choose Burpee Type',
      description: 'Select the burpee style for this workout',
      child: Column(
        children: [
          ...BurpeeType.values.map((type) {
            return Card(
              color: _burpeeType == type
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _burpeeType = type;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<BurpeeType>(
                            value: type,
                            groupValue: _burpeeType,
                            onChanged: (value) {
                              setState(() {
                                _burpeeType = value!;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              type.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Text(
                          type.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('NEXT'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCountdownPage() {
    return _buildNumberInputPage(
      title: 'Initial Countdown',
      description: 'How many seconds before the workout starts?',
      value: _initialCountdown,
      unit: 'seconds',
      min: 3,
      max: 30,
      buttonColor: Colors.blue,
      onChanged: (value) {
        setState(() {
          _initialCountdown = value;
        });
      },
    );
  }

  Widget _buildNumberOfSetsPage() {
    return _buildNumberInputPage(
      title: 'Number of Sets',
      description: 'How many sets will you complete?',
      value: _numberOfSets,
      unit: 'sets',
      min: 1,
      max: 20,
      buttonColor: Colors.purple,
      onChanged: (value) {
        setState(() {
          _numberOfSets = value;
        });
      },
    );
  }

  Widget _buildSecondsPerSetPage() {
    return _buildNumberInputPage(
      title: 'Seconds per Set',
      description: 'How long is each work interval?',
      value: _secondsPerSet,
      unit: 'seconds',
      min: 1,
      max: 60,
      buttonColor: Colors.orange,
      onChanged: (value) {
        setState(() {
          _secondsPerSet = value;
        });
      },
    );
  }

  Widget _buildRepsPerSetPage() {
    return _buildNumberInputPage(
      title: 'Reps per Set',
      description: 'How many burpees per set?',
      value: _repsPerSet,
      unit: 'reps',
      min: 1,
      max: 30,
      buttonColor: Colors.teal,
      onChanged: (value) {
        setState(() {
          _repsPerSet = value;
        });
      },
    );
  }

  Widget _buildRestBetweenSetsPage() {
    return _buildNumberInputPage(
      title: 'Rest Between Sets',
      description: 'How long to rest between sets?',
      value: _restBetweenSets,
      unit: 'seconds',
      min: 0,
      max: 60,
      buttonColor: Colors.indigo,
      onChanged: (value) {
        setState(() {
          _restBetweenSets = value;
        });
      },
    );
  }

  Widget _buildNumberInputPage({
    required String title,
    required String description,
    required int value,
    required String unit,
    required int min,
    required int max,
    required Color buttonColor,
    required ValueChanged<int> onChanged,
  }) {
    return _PageWrapper(
      title: title,
      description: description,
      child: Column(
        children: [
          Card(
            color: buttonColor.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: buttonColor,
                        ),
                  ),
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: buttonColor.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                icon: const Icon(Icons.remove),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: value > min
                      ? buttonColor.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: value > min ? buttonColor : null,
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 100,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: TextEditingController(text: '$value')
                    ..selection =
                        TextSelection.collapsed(offset: '$value'.length),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: buttonColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: buttonColor, width: 2),
                    ),
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null) {
                      onChanged(parsed.clamp(min, max));
                    }
                  },
                ),
              ),
              const SizedBox(width: 24),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: value < max ? () => onChanged(value + 1) : null,
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: value < max
                      ? buttonColor.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: value < max ? buttonColor : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Range: $min - $max $unit',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('NEXT'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    final totalWorkoutSeconds =
        (_secondsPerSet * _numberOfSets) + (_restBetweenSets * (_numberOfSets - 1));
    final duration = Duration(seconds: totalWorkoutSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final formattedDuration = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return _PageWrapper(
      title: 'Review Your Workout',
      description: 'Check everything looks good before saving',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem('Name', _name),
                  const Divider(),
                  _buildReviewItem('Burpee Type', _burpeeType.displayName),
                  const Divider(),
                  _buildReviewItem('Initial Countdown', '$_initialCountdown sec'),
                  const Divider(),
                  _buildReviewItem('Number of Sets', '$_numberOfSets'),
                  const Divider(),
                  _buildReviewItem('Seconds per Set', '$_secondsPerSet sec'),
                  const Divider(),
                  _buildReviewItem('Reps per Set', '$_repsPerSet'),
                  const Divider(),
                  _buildReviewItem('Rest Between Sets', '$_restBetweenSets sec'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
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
                    formattedDuration,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_numberOfSets sets × $_repsPerSet reps = ${_numberOfSets * _repsPerSet} total reps',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveTemplate,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('SAVE WORKOUT'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _PageWrapper extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _PageWrapper({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}
