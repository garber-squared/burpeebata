import 'dart:io';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Do Not Disturb mode during workouts.
/// Only functional on Android; other platforms return no-op behavior.
class DndService {
  static final DndService _instance = DndService._internal();
  factory DndService() => _instance;
  DndService._internal();

  final DoNotDisturbPlugin _dnd = DoNotDisturbPlugin();

  bool _wasEnabled = false;
  bool _didEnableDnd = false;

  /// Check if DND feature is supported on this platform
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Check if the app has permission to modify DND settings
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await _dnd.isNotificationPolicyAccessGranted();
    } catch (e) {
      debugPrint('DndService: Error checking permission: $e');
      return false;
    }
  }

  /// Request permission to modify DND settings.
  /// Opens system settings where user can grant permission.
  Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await _dnd.openNotificationPolicyAccessSettings();
    } catch (e) {
      debugPrint('DndService: Error requesting permission: $e');
    }
  }

  /// Get current DND status
  Future<bool> isDndEnabled() async {
    if (!isSupported) return false;
    try {
      final status = await _dnd.getDNDStatus();
      return status != InterruptionFilter.all;
    } catch (e) {
      debugPrint('DndService: Error getting DND status: $e');
      return false;
    }
  }

  /// Enable DND mode, saving the previous state for later restoration.
  /// Returns true if DND was successfully enabled.
  Future<bool> enableDnd() async {
    if (!isSupported) return false;

    final hasAccess = await hasPermission();
    if (!hasAccess) {
      debugPrint('DndService: No permission to enable DND');
      return false;
    }

    try {
      // Save current state before changing
      _wasEnabled = await isDndEnabled();

      if (!_wasEnabled) {
        // Only enable if not already enabled
        // priority mode allows alarms and priority notifications
        await _dnd.setInterruptionFilter(InterruptionFilter.priority);
        _didEnableDnd = true;
        debugPrint('DndService: DND enabled');
      } else {
        _didEnableDnd = false;
        debugPrint('DndService: DND already enabled, not changing');
      }
      return true;
    } catch (e) {
      debugPrint('DndService: Error enabling DND: $e');
      return false;
    }
  }

  /// Restore DND to its previous state (before enableDnd was called).
  /// Only disables DND if we were the ones who enabled it.
  Future<void> restoreDnd() async {
    if (!isSupported) return;

    if (!_didEnableDnd) {
      debugPrint('DndService: We did not enable DND, not restoring');
      return;
    }

    final hasAccess = await hasPermission();
    if (!hasAccess) {
      debugPrint('DndService: No permission to restore DND');
      return;
    }

    try {
      // all = allow all notifications (DND off)
      await _dnd.setInterruptionFilter(InterruptionFilter.all);
      _didEnableDnd = false;
      debugPrint('DndService: DND restored (disabled)');
    } catch (e) {
      debugPrint('DndService: Error restoring DND: $e');
    }
  }
}
