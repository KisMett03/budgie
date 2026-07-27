import 'package:flutter/foundation.dart';
import '../../entities/financial_goal.dart';
import '../../repositories/goals_repository.dart';

/// Use case for getting active financial goals
class GetGoalsUseCase {
  final GoalsRepository _goalsRepository;

  GetGoalsUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to get active goals
  Future<List<FinancialGoal>> execute() async {
    try {
      debugPrint('🎯 GetGoalsUseCase: Getting active goals');
      return await _goalsRepository.getActiveGoals();
    } catch (_) {
      debugPrint('GetGoalsUseCase: Error getting active goals');
      return [];
    }
  }
}

/// Use case for getting goal history
class GetGoalHistoryUseCase {
  final GoalsRepository _goalsRepository;

  GetGoalHistoryUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to get goal history
  Future<List<GoalHistory>> execute() async {
    try {
      debugPrint('🎯 GetGoalHistoryUseCase: Getting goal history');
      return await _goalsRepository.getGoalHistory();
    } catch (_) {
      debugPrint('GetGoalHistoryUseCase: Error getting goal history');
      return [];
    }
  }
}

/// Use case for getting a specific goal by ID
class GetGoalByIdUseCase {
  final GoalsRepository _goalsRepository;

  GetGoalByIdUseCase({
    required GoalsRepository goalsRepository,
  }) : _goalsRepository = goalsRepository;

  /// Execute the use case to get a goal by ID
  Future<FinancialGoal?> execute(String id) async {
    try {
      debugPrint('GetGoalByIdUseCase: Getting goal');
      return await _goalsRepository.getGoalById(id);
    } catch (_) {
      debugPrint('GetGoalByIdUseCase: Error getting goal');
      return null;
    }
  }
}
