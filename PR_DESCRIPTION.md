## Summary

- Add Do Not Disturb mode support during workouts (Android only)
- New `DndService` handles enabling/disabling DND with permission management
- Toggle button in home screen app bar to enable/disable the feature
- DND automatically enables when workout starts and restores previous state when workout ends
- Persisted user preference via `StorageService`

## Test plan

- [ ] Verify DND toggle appears on Android devices
- [ ] Verify DND toggle does NOT appear on iOS/web
- [ ] Test permission request flow when enabling DND for the first time
- [ ] Confirm DND activates when starting a workout (with setting enabled)
- [ ] Confirm DND restores to previous state when workout ends
- [ ] Verify preference persists across app restarts
- [ ] Run `make test` to verify all tests pass

🤖 Generated with [Claude Code](https://claude.com/claude-code)
