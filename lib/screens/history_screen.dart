import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout.dart';
import '../models/burpee_type.dart';
import '../services/storage_service.dart';
import '../services/workout_service.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutService _workoutService = WorkoutService();
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    List<Workout> workouts;

    debugPrint('=== HistoryScreen: Loading workouts ===');
    debugPrint('User authenticated: ${authProvider.isAuthenticated}');
    debugPrint('User is anonymous: ${authProvider.isAnonymous}');
    debugPrint('User ID: ${authProvider.user?.uid}');
    debugPrint('User email: ${authProvider.user?.email}');

    // If user is authenticated and not anonymous, load from Firestore
    if (authProvider.isAuthenticated && !authProvider.isAnonymous) {
      debugPrint('Attempting to load workouts from Firestore...');
      try {
        workouts = await _workoutService.getWorkouts(authProvider.user!.uid);
        debugPrint('Successfully loaded ${workouts.length} workouts from Firestore');
      } catch (e) {
        // Fall back to local storage if Firestore fails
        debugPrint('Failed to load workouts from Firestore: $e');
        debugPrint('Falling back to local storage...');
        workouts = await StorageService.getWorkouts();
        debugPrint('Loaded ${workouts.length} workouts from local storage');
      }
    } else {
      // For anonymous/guest users, load from local storage
      debugPrint('Loading from local storage (user is anonymous or not authenticated)...');
      workouts = await StorageService.getWorkouts();
      debugPrint('Loaded ${workouts.length} workouts from local storage');
    }

    setState(() {
      _workouts = workouts;
      _isLoading = false;
    });
  }

  Future<void> _deleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Delete from local storage
      await StorageService.deleteWorkout(workout.id);

      // Delete from Firestore if user is authenticated and not anonymous
      if (authProvider.isAuthenticated && !authProvider.isAnonymous) {
        try {
          await _workoutService.deleteWorkout(authProvider.user!.uid, workout.id);
        } catch (e) {
          debugPrint('Failed to delete workout from Firestore: $e');
        }
      }

      await _loadWorkouts();
    }
  }

  void _shareWorkout(Workout workout) {
    SharePlus.instance.share(ShareParams(text: workout.shareText));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? _buildEmptyState()
              : _buildWorkoutList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a workout to see it here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList() {
    return ListView.builder(
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return _buildWorkoutCard(workout);
      },
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final index = _workouts.indexOf(workout);
    final previousWorkout = index < _workouts.length - 1 ? _workouts[index + 1] : null;
    final isIncomplete = !workout.completed;

    final dateStr = '${workout.date.month}/${workout.date.day}/${workout.date.year}';
    final timeStr = '${workout.date.hour}:${workout.date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Design System v2: Desaturate incomplete workouts
      color: isIncomplete
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: Opacity(
        opacity: isIncomplete ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    if (workout.completed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PARTIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              workout.burpeeType.displayName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip(
                  Icons.repeat,
                  '${workout.completedSets}/${workout.numberOfSets} sets',
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.fitness_center,
                  '${workout.totalReps} reps',
                ),
              ],
            ),

            // Performance Metrics (Design System v2)
            if (workout.elapsedSeconds > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildMetricChip(
                    label: 'Reps/min',
                    value: workout.repsPerMinute.toStringAsFixed(1),
                    trend: previousWorkout != null
                        ? _getTrend(workout.repsPerMinute, previousWorkout.repsPerMinute)
                        : null,
                  ),
                  _buildMetricChip(
                    label: 'Density',
                    value: '${workout.workRestDensity.toStringAsFixed(0)}%',
                    trend: previousWorkout != null
                        ? _getTrend(workout.workRestDensity, previousWorkout.workRestDensity)
                        : null,
                  ),
                  _buildMetricChip(
                    label: 'Intensity',
                    value: '${workout.intensityScore}',
                    trend: previousWorkout != null
                        ? _getTrend(workout.intensityScore.toDouble(), previousWorkout.intensityScore.toDouble())
                        : null,
                    isBest: _isBestWorkout(workout, 'intensity'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _shareWorkout(workout),
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                ),
                IconButton(
                  onPressed: () => _deleteWorkout(workout),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// Build performance metric chip with trend arrow (Design System v2)
  Widget _buildMetricChip({
    required String label,
    required String value,
    String? trend,
    bool isBest = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isBest
            ? Colors.amber.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: isBest
            ? Border.all(color: Colors.amber, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBest) ...[
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getTrendColor(trend),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get trend arrow: ↑ (better), ↓ (worse), ↔ (same)
  String? _getTrend(double current, double previous) {
    if (previous == 0) return null;
    final diff = ((current - previous) / previous * 100).abs();

    // Less than 5% change = stable
    if (diff < 5) return '↔';

    return current > previous ? '↑' : '↓';
  }

  /// Get color for trend arrow
  Color _getTrendColor(String trend) {
    return switch (trend) {
      '↑' => Colors.green,
      '↓' => Colors.red,
      '↔' => Colors.grey,
      _ => Colors.grey,
    };
  }

  /// Check if this is the best workout for a given metric
  bool _isBestWorkout(Workout workout, String metric) {
    if (_workouts.isEmpty) return false;

    return switch (metric) {
      'intensity' => _workouts.every((w) => workout.intensityScore >= w.intensityScore),
      'reps' => _workouts.every((w) => workout.totalReps >= w.totalReps),
      'repsPerMin' => _workouts.every((w) => workout.repsPerMinute >= w.repsPerMinute),
      _ => false,
    };
  }
}
