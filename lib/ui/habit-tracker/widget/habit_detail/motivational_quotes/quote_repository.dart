// lib\ui\habit-tracker\widget\habit_detail\repositories\quote_repository.dart
import 'package:purewill/ui/habit-tracker/widget/habit_detail/motivational_quotes/quote_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteRepository {
  final SupabaseClient _supabase;

  QuoteRepository(this._supabase);

  // Fetch quotes from Supabase
  Future<List<Quote>> fetchQuotes({int limit = 50}) async {
    final response = await _supabase
        .from('motivational_quotes')
        .select('*')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Quote.fromJson(json))
        .toList();
  }

  // Fetch random single quote
  Future<Quote> fetchRandomQuote() async {
    final response = await _supabase
        .rpc('get_random_quote')
        .select('*')
        .limit(1)
        .single();

    return Quote.fromJson(response);
  }

  // Add new quote (for admin)
  Future<void> addQuote(String quote, String author) async {
    await _supabase.from('motivational_quotes').insert({
      'quote': quote,
      'author': author,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}