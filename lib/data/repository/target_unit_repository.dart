import 'dart:developer';
import 'package:purewill/domain/model/target_unit_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TargetUnitRepository {
  final SupabaseClient _supabaseClient;
  static const String _targetUnitTable = 'target_units';

  TargetUnitRepository(this._supabaseClient);

  Future<List<TargetUnitModel>> fetchUserTargetUnits(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_targetUnitTable)
          .select('*')
          .eq('user_id', userId)
          .order('name', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      final targetUnits = <TargetUnitModel>[];
      for (var i = 0; i < response.length; i++) {
        try {
          final targetUnit = TargetUnitModel.fromJson(response[i]);
          targetUnits.add(targetUnit);
        } catch (e) {
          rethrow;
        }
      }

      return targetUnits;
    } catch (e, stackTrace) {
      log(
        'FETCH TARGET UNIT FAILURE: Failed to fetch target units.',
        error: e,
        stackTrace: stackTrace,
        name: 'TARGET_UNIT_REPO',
      );
      rethrow;
    }
  }

  Future<TargetUnitModel> createTargetUnit(String newTargetUnit) async {
    try {
      final response = await _supabaseClient
          .from(_targetUnitTable)
          .insert(newTargetUnit)
          .select()
          .single();

      return TargetUnitModel.fromJson(response);
    } catch (e, stackTrace) {
      log(
        'CREATE TARGET UNIT FAILURE: Failed to create target unit.',
        error: e,
        stackTrace: stackTrace,
        name: 'TARGET_UNIT_REPO',
      );
      rethrow;
    }
  }
}
