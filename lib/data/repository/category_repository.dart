import 'dart:developer';
import 'package:purewill/domain/model/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRepository {
  final SupabaseClient _supabaseClient;
  static const String _categoryTableName = 'categories';

  CategoryRepository(this._supabaseClient);

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _supabaseClient
          .from(_categoryTableName)
          .select('*')
          .order('name', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      final categories = <CategoryModel>[];
      for (var i = 0; i < response.length; i++) {
        try {
          final category = CategoryModel.fromJson(response[i]);
          categories.add(category);
        } catch (e) {
          rethrow;
        }
      }

      return categories;
    } catch (e, stackTrace) {
      log(
        'FETCH CATEGORIES FAILURE: Failed to fetch categories.',
        error: e,
        stackTrace: stackTrace,
        name: 'CATEGORY_REPO',
      );
      rethrow;
    }
  }
}
