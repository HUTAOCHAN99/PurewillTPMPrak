import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/data/repository/category_repository.dart';
import 'package:purewill/data/repository/target_unit_repository.dart';
import 'package:purewill/data/repository/user_repository.dart';
import 'package:purewill/domain/model/category_model.dart';
import 'package:purewill/domain/model/daily_log_model.dart';
import 'package:purewill/domain/model/habit_model.dart';
import 'package:purewill/domain/model/profile_model.dart';
import 'package:purewill/domain/model/reminder_setting_model.dart';
import 'package:purewill/domain/model/target_unit_model.dart';
import '../../../data/repository/habit_repository.dart';
import '../../../data/repository/daily_log_repository.dart';
import '../../../data/repository/reminder_setting_repository.dart';
import '../../../data/repository/habit_session_repository.dart';

enum HabitStatus { initial, loading, success, failure }

class HabitsState {
  final HabitStatus status;
  final String? errorMessage;
  final List<HabitModel> habits;
  final List<HabitModel> todayHabit;
  final List<DailyLogModel> dailyLogs;
  final List<TargetUnitModel> targetUnits;
  final List<CategoryModel> categories;
  final HabitModel? currentHabitDetail;
  final ReminderSettingModel? currentReminderSetting;
  ProfileModel? currentUser;

  HabitsState({
    this.status = HabitStatus.initial,
    this.errorMessage,
    this.habits = const [],
    this.todayHabit = const [],
    this.dailyLogs = const [],
    this.targetUnits = const [],
    this.categories = const [],
    this.currentUser,
    this.currentHabitDetail,
    this.currentReminderSetting,
  });

  HabitsState copyWith({
    HabitStatus? status,
    String? errorMessage,
    List<HabitModel>? habits,
    List<HabitModel>? todayHabit,
    List<DailyLogModel>? dailyLogs,
    List<TargetUnitModel>? targetUnits,
    List<CategoryModel>? caregories,
    List<ReminderSettingModel>? reminderSettings,
    ProfileModel? currentUser,
    HabitModel? currentHabitDetail,
  }) {
    return HabitsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      habits: habits ?? this.habits,
      todayHabit: todayHabit ?? this.todayHabit,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      targetUnits: targetUnits ?? this.targetUnits,
      categories: caregories ?? categories,
      currentUser: currentUser ?? this.currentUser,
      currentHabitDetail: currentHabitDetail ?? this.currentHabitDetail,
    );
  }
}

class HabitsViewModel extends StateNotifier<HabitsState> {
  final HabitRepository _habitRepository;
  final DailyLogRepository _dailyLogRepository;
  final ReminderSettingRepository _reminderSettingRepository;
  final HabitSessionRepository _habitSessionRepository;
  final TargetUnitRepository _targetUnitRepository;
  final CategoryRepository _categoryRepository;
  final UserRepository _userRepository;
  final String _currentUserId;

  HabitsViewModel(
    this._habitRepository,
    this._dailyLogRepository,
    this._reminderSettingRepository,
    this._habitSessionRepository,
    this._targetUnitRepository,
    this._categoryRepository,
    this._userRepository,
    this._currentUserId,
  ) : super(HabitsState());

  // Method untuk clear/reset state
  void clearState() {
    state = HabitsState(
      status: HabitStatus.initial,
      errorMessage: null,
      habits: const [],
      todayHabit: const [],
      dailyLogs: const [],
      targetUnits: const [],
      categories: const [],
      currentUser: null,
      currentHabitDetail: null,
      currentReminderSetting: null,
    );
  }

  Future<void> getCurrentUser() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);
    try {
      final currentUser = await _userRepository.fetchUserProfile(
        _currentUserId,
      );
      state = state.copyWith(
        status: HabitStatus.success,
        currentUser: currentUser,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load user profile.',
      );
    }
  }

  Future<bool> isHabitStarted({required int habitId}) async {
    try {
      final habit = await _habitSessionRepository.getActiveHabitSession(
        habitId: habitId,
        userId: _currentUserId,
      );
      if (habit == null) {
        return false;
      }
      return true;
    } catch (e) {
      log(
        'IS HABIT STARTED FAILURE: Failed to check if habit $habitId has started.',
        error: e,
        name: 'HABIT_VIEW_MODEL',
      );
      rethrow;
    }
  }

  Future<int> getNofapHabitId() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      return habitId;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DailyLogModel>> getLogNofapHabit() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      final log = await _dailyLogRepository.fetchLogsByHabit(habitId);
      return log;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startNofapHabit() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      await _habitRepository.activeNofapHabit(_currentUserId, habitId);
      await _habitSessionRepository.addHabitSession(
        habitId: habitId,
        userId: _currentUserId,
        startDate: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopNofapHabit() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      final activeSession = await _habitSessionRepository.getActiveHabitSession(
        habitId: habitId,
        userId: _currentUserId,
      );
      await _habitSessionRepository.updateHabitSession(
        sessionId: activeSession!.id,
        endDate: DateTime.now(),
        isActive: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getNofapHabitStreak() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      // final streak = await _habitSessionRepository.fetchNofapHabitLongestStreak(habitId: habitId, userId:
      // _currentUserId);
      final streak = await _habitSessionRepository.fetchNofapHabitLongestStreak(
        habitId: habitId,
        userId: _currentUserId,
      );
      return streak;
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getNofapHabitCurrentStreak() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      // final streak = await _habitSessionRepository.fetchNofapHabitCurrentStreak(habitId: habitId, userId: _currentUserId);
      final streak = await _habitSessionRepository.fetchNofapHabitCurrentStreak(
        habitId: habitId,
        userId: _currentUserId,
      );
      return streak;
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getRelapseCountNofapHabit() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      final relapseCount = await _habitSessionRepository.getRelapseCount(
        habitId: habitId,
        userId: _currentUserId,
      );
      return relapseCount;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DateTime>> getSuccessDaysNofapHabit() async {
    try {
      final habitId = await _habitRepository.getNofapHabitId(_currentUserId);
      final successDays = await _habitSessionRepository.getSuccessDays(
        habitId: habitId,
        userId: _currentUserId,
      );
      return successDays;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadUserHabits() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);

    try {
      final allHabits = await _habitRepository.fetchUserHabits(_currentUserId);
      final habitsWithoutNofap = allHabits
          .where((habit) => habit.name.toLowerCase() != 'nofap')
          .toList();

      state = state.copyWith(
        status: HabitStatus.success,
        habits: habitsWithoutNofap,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load habits.',
      );
    }
  }

  Future<void> loadTodayUserHabits() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);
    try {
      final habits = await _habitRepository.fetchTodayUserHabits(
        _currentUserId,
      );

      final habitsWithoutNofap = habits
          .where((habit) => habit.name.toLowerCase() != 'nofap')
          .toList();

      state = state.copyWith(
        status: HabitStatus.success,
        todayHabit: habitsWithoutNofap,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load today habits.',
      );
    }
  }

  Future<void> loadHabitDetail({required int habitId}) async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);

    try {
      final habitDetail = await _habitRepository.getHabitById(habitId);
      state = state.copyWith(
        status: HabitStatus.success,
        currentHabitDetail: habitDetail,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load habit detail.',
      );
    }
  }

  Future<void> loadUserTargetUnits() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);

    try {
      final targetUnits = await _targetUnitRepository.fetchUserTargetUnits(
        _currentUserId,
      );

      state = state.copyWith(
        status: HabitStatus.success,
        targetUnits: targetUnits,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load target units.',
      );
    }
  }

  Future<void> loadCategories() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);

    try {
      final categories = await _categoryRepository.fetchCategories();

      state = state.copyWith(
        status: HabitStatus.success,
        caregories: categories,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load categorise.',
      );
    }
  }

  Future<void> toggleHabitCompletion(HabitModel habit) async {
    try {
      print("habit id to toggle: ${habit.id}");
      final today = DateTime.now();
      final existingLog = await _dailyLogRepository.getTodayLogForHabit(
        habit.id,
      );

      print(
        "sebelum di toggle, status existing log: ${existingLog?.status.name}",
      );

      if (existingLog != null) {
        final log = await _dailyLogRepository.recordLog(
          habitId: habit.id,
          date: today,
          status: (existingLog.status == LogStatus.success)
              ? LogStatus.failed
              : existingLog.status == LogStatus.failed
              ? LogStatus.neutral
              : LogStatus.success,
          actualValue: habit.targetValue?.toDouble(),
        );

        print("setelah di toggle, status log jadi: ${log.status.name}");
      } else {
        await _dailyLogRepository.recordLog(
          habitId: habit.id,
          date: today,
          status: LogStatus.success,
          actualValue: habit.targetValue?.toDouble(),
        );
      }

      await loadTodayUserHabits();
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to update habit status.' + e.toString(),
      );
    }
  }

  Future<void> completeHabitWithValue({
    required int habitId,
    required double actualValue,
    String? notes,
  }) async {
    try {
      await _dailyLogRepository.recordLog(
        habitId: habitId,
        date: DateTime.now(),
        status: LogStatus.success,
        actualValue: actualValue,
      );

      await _habitRepository.updateHabitStatus(
        habitId: habitId,
        status: 'completed',
      );

      await loadUserHabits();
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to record habit completion.',
      );
    }
  }

  Future<Map<int, LogStatus>> getTodayCompletionStatus() async {
    try {
      final todayLogs = await _dailyLogRepository.fetchLogsByDate(
        DateTime.now(),
      );
      final completionStatus = <int, LogStatus>{};

      for (final log in todayLogs) {
        completionStatus[log.habitId] = log.status;
      }

      return completionStatus;
    } catch (e) {
      return {};
    }
  }

  Future<void> addHabit({
    required String name,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    int? categoryId,
    String? notes,
    int? targetValue,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
  }) async {
    try {
      final newHabit = HabitModel(
        id: 0,
        userId: _currentUserId,
        name: name,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        categoryId: categoryId,
        targetValue: targetValue,
        status: 'neutral',
        notes: notes,
      );

      final habit = await _habitRepository.createHabit(newHabit);
      await _dailyLogRepository.addLogsForNewHabit(habit);
      await _reminderSettingRepository.createReminderSetting(
        ReminderSettingModel(
          id: '',
          habitId: habit.id,
          isEnabled: reminderEnabled ?? false,
          time: reminderTime != null
              ? DateTime(
                  startDate.year,
                  startDate.month,
                  startDate.day,
                  reminderTime.hour,
                  reminderTime.minute,
                )
              : DateTime.now(),
          snoozeDuration: 5,
          repeatDaily: true,
          isSoundEnabled: true,
          isVibrationEnabled: true,
          createdAt: DateTime.now(),
        ),
      );
      await loadTodayUserHabits();
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to add new habit.',
      );
      rethrow;
    }
  }

  Future<void> createTargetUnit({required String nameTargetUnit}) async {
    try {
      await _targetUnitRepository.createTargetUnit(nameTargetUnit);
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to create target unit.',
      );
      rethrow;
    }
  }

  Future<void> deleteHabit({required int habitId}) async {
    try {
      await _reminderSettingRepository.deleteAllReminderSettingsForHabit(
        habitId,
      );
      await _dailyLogRepository.deleteLogsByHabit(habitId);
      await _habitRepository.deleteHabit(habitId);
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to delete habit.',
      );
      rethrow;
    }
  }

  Future<List<DailyLogModel>> fetchLogsForCalendar({
    required int habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final logs = await _dailyLogRepository.fetchLogsByDateRange(
        habitId: habitId,
        startDate: startDate,
        endDate: endDate,
      );

      return logs;
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to delete habit.',
      );
      rethrow;
    }
  }

  Future<int> fetchHabitLogStreak({required int habitId}) async {
    try {
      final streak = await _dailyLogRepository.fetchHabitLogStreak(habitId);
      return streak;
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to fetch habit streak.',
      );
      rethrow;
    }
  }

  Future<List<DailyLogModel>> fetchLogsByHabit({required int habitId}) async {
    try {
      final logs = await _dailyLogRepository.fetchLogsByHabit(habitId);

      return logs;
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to fetch log habit.',
      );
      rethrow;
    }
  }

  Future<void> updateHabits({
    required int habitId,
    String? newName,
    String? newFrequency,
    DateTime? newStartDate,
    DateTime? newEndDate,
    int? newCategoryId,
    String? newNotes,
    int? newTargetValue,
  }) async {
    try {
      final oldHabit = await _habitRepository.getHabitById(habitId);
      if (oldHabit == null) {
        throw Exception('Habit not found');
      }

      final updateData = <String, dynamic>{};
      if (newName != null && newName != oldHabit.name) {
        updateData['name'] = newName;
      }

      if (newFrequency != null && newFrequency != oldHabit.frequency) {
        updateData['frecuency_type'] = newFrequency;
      }

      if (newStartDate != null && newStartDate != oldHabit.startDate) {
        updateData['start_date'] = newStartDate.toIso8601String();
      }

      if (newEndDate != oldHabit.endDate) {
        if (newEndDate != null) {
          updateData['end_date'] = newEndDate.toIso8601String();
        } else {
          updateData['end_date'] = null;
        }
      }

      if (newCategoryId != oldHabit.categoryId) {
        updateData['category_id'] = newCategoryId;
      }

      if (newNotes != oldHabit.notes) {
        updateData['notes'] = newNotes;
      }

      if (newTargetValue != oldHabit.targetValue) {
        updateData['target_value'] = newTargetValue;
      }

      if (updateData.isEmpty) {
        return;
      }

      await _habitRepository.updateHabit(habitId: habitId, updates: updateData);

      if (newStartDate != null && newStartDate != oldHabit.startDate) {
        await _dailyLogRepository.deleteLogsBeforeDate(
          habitId: habitId,
          date: newStartDate,
        );
      }

      if (newEndDate != oldHabit.endDate) {
        if (newEndDate != null) {
          await _dailyLogRepository.deleteLogsAfterDate(
            habitId: habitId,
            date: newEndDate,
          );
        }
      }

      await loadUserHabits();
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to edit habit.',
      );
      rethrow;
    }
  }

  Future<void> saveReminderSetting({
    required int habitId,
    required bool isEnabled,
    required DateTime time,
    required int snoozeDuration,
    required bool repeatDaily,
    required bool isSoundEnabled,
    required bool isVibrationEnabled,
  }) async {
    try {
      final reminderSetting = ReminderSettingModel(
        id: '',
        habitId: habitId,
        isEnabled: isEnabled,
        time: time,
        snoozeDuration: snoozeDuration,
        repeatDaily: repeatDaily,
        isSoundEnabled: isSoundEnabled,
        isVibrationEnabled: isVibrationEnabled,
        createdAt: DateTime.now(), // TAMBAHKAN INI
      );

      final reminderSettingBefore = await _reminderSettingRepository
          .fetchReminderSettingsByHabit(habitId);

      if (reminderSettingBefore.id.isNotEmpty) {
        await _reminderSettingRepository.updateReminderSetting(
          reminderSettingId: reminderSettingBefore.id,
          updates: {
            'is_enabled': isEnabled,
            'time': time.toIso8601String(),
            'snooze_duration': snoozeDuration,
            'repeat_daily': repeatDaily,
            'is_sound_enabled': isSoundEnabled,
            'is_vibration_enabled': isVibrationEnabled,
          },
        );
        await loadCurrentReminderSetting(habitId);
        log(
          'UPDATE REMINDER SETTING SUCCESS: Reminder setting created for habit $habitId.',
          name: 'HABIT_VIEW_MODEL',
        );
        return;
      }

      await _reminderSettingRepository.createReminderSetting(reminderSetting);

      log(
        'CREATE REMINDER SETTING SUCCESS: Reminder setting created for habit $habitId.',
        name: 'HABIT_VIEW_MODEL',
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to create reminder setting.',
      );
      rethrow;
    }
  }

  Future<ReminderSettingModel> loadCurrentReminderSetting(int habitId) async {
    try {
      final reminderSetting = await _reminderSettingRepository
          .fetchReminderSettingsByHabit(habitId);

      return reminderSetting;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReminderSetting(int habitId) async {
    try {
      await _reminderSettingRepository.deleteReminderSetting(habitId);
      await loadCurrentReminderSetting(habitId);
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to delete reminder setting.',
      );
      rethrow;
    }
  }
}
