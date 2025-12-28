import 'package:flutter/material.dart';
import '../models/workout_config.dart';

class PostWorkoutQuestionnaireScreen extends StatefulWidget {
  final WorkoutConfig config;
  final int elapsedSeconds;

  const PostWorkoutQuestionnaireScreen({
    super.key,
    required this.config,
    required this.elapsedSeconds,
  });

  @override
  State<PostWorkoutQuestionnaireScreen> createState() =>
      _PostWorkoutQuestionnaireScreenState();
}

class _PostWorkoutQuestionnaireScreenState
    extends State<PostWorkoutQuestionnaireScreen> {
  bool? _didCompleteAllSets;
  bool? _didCompleteInTime;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout Complete!'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 20),
                const Text(
                  'Great job!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildQuestion1Card(),
                const SizedBox(height: 20),
                if (_didCompleteAllSets == true) ...[
                  _buildQuestion2Card(),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildQuestion1Card() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Did you complete all the sets?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    label: 'YES',
                    isSelected: _didCompleteAllSets == true,
                    onTap: () {
                      setState(() {
                        _didCompleteAllSets = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    label: 'NO',
                    isSelected: _didCompleteAllSets == false,
                    onTap: () {
                      setState(() {
                        _didCompleteAllSets = false;
                        _didCompleteInTime = false; // Reset Q2 if Q1 is No
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion2Card() {
    final elapsedMinutes = (widget.elapsedSeconds / 60).floor();
    final elapsedSecondsRemainder = widget.elapsedSeconds % 60;
    final timeDisplay =
        '$elapsedMinutes:${elapsedSecondsRemainder.toString().padLeft(2, '0')}';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Did you complete the workout in less than 5 minutes?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your time: $timeDisplay',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    label: 'YES',
                    isSelected: _didCompleteInTime == true,
                    onTap: () {
                      setState(() {
                        _didCompleteInTime = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    label: 'NO',
                    isSelected: _didCompleteInTime == false,
                    onTap: () {
                      setState(() {
                        _didCompleteInTime = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: isSelected ? 4 : 1,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _didCompleteAllSets != null && !_isSubmitting;

    return ElevatedButton(
      onPressed: isEnabled ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        disabledBackgroundColor: Colors.grey[400],
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'SUBMIT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
    });

    // Return the results to the previous screen
    if (mounted) {
      Navigator.pop(context, {
        'isCompleted': _didCompleteAllSets ?? false,
        'isCompletedInTime': _didCompleteInTime ?? false,
      });
    }
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text(
          'Your workout will be saved with default values if you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      // Return default values
      Navigator.pop(context, {
        'isCompleted': false,
        'isCompletedInTime': false,
      });
      return false; // Prevent default pop
    }

    return false; // Don't pop by default
  }
}
