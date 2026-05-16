import 'package:flutter/material.dart';
// <<<<<<< HEAD
// import 'dart:math';

// class MotivationalQuotesWidget extends StatefulWidget {
//   @override
//   _MotivationalQuotesWidgetState createState() =>
//       _MotivationalQuotesWidgetState();
// }

// class _MotivationalQuotesWidgetState extends State<MotivationalQuotesWidget> {
//   final List<Map<String, String>> quotes = [
//     {
//       "quote":
//           "Success is the sum of small efforts repeated day in and day out.",
//       "author": "Robert Collier",
//     },
//     {
//       "quote": "The secret of getting ahead is getting started.",
//       "author": "Mark Twain",
//     },
//     {
//       "quote": "Don't watch the clock; do what it does. Keep going.",
//       "author": "Sam Levenson",
//     },
//     {
//       "quote": "The way to get started is to quit talking and begin doing.",
//       "author": "Walt Disney",
//     },
//     {
//       "quote": "Small daily improvements over time lead to stunning results.",
//       "author": "Robin Sharma",
//     },
//     {
//       "quote":
//           "Motivation is what gets you started. Habit is what keeps you going.",
//       "author": "Jim Ryun",
//     },
//   ];

//   late Map<String, String> currentQuote;
// =======
import 'package:purewill/ui/habit-tracker/widget/habit_detail/motivational_quotes/quote_model.dart';
import 'package:purewill/ui/habit-tracker/widget/habit_detail/motivational_quotes/quote_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';


class MotivationalQuotesWidget extends StatefulWidget {
  const MotivationalQuotesWidget({super.key});

  @override
  State<MotivationalQuotesWidget> createState() => _MotivationalQuotesWidgetState();
}

class _MotivationalQuotesWidgetState extends State<MotivationalQuotesWidget> {
  late QuoteRepository _quoteRepository;
  List<Quote> _quotes = [];
  Quote? _currentQuote;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isLoading = true;
  String? _error;
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c

  @override
  void initState() {
    super.initState();
// <<<<<<< HEAD
//     _getRandomQuote();
//   }

//   void _getRandomQuote() {
//     final random = Random();
//     currentQuote = quotes[random.nextInt(quotes.length)];
// =======
    _initializeRepository();
    _fetchQuotes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeRepository() {
    final supabase = Supabase.instance.client;
    _quoteRepository = QuoteRepository(supabase);
  }

  Future<void> _fetchQuotes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final quotes = await _quoteRepository.fetchQuotes();
      
      if (quotes.isEmpty) {
        // Fallback to default quotes if database is empty
        _quotes = _getDefaultQuotes();
      } else {
        _quotes = quotes;
      }

      // Initialize current quote
      if (_quotes.isNotEmpty) {
        _currentQuote = _quotes[_currentIndex];
        _startTimer();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _quotes = _getDefaultQuotes();
        _currentQuote = _quotes[_currentIndex];
        _startTimer();
      });
    }
  }

  List<Quote> _getDefaultQuotes() {
    return [
      Quote(
        id: '1',
        quote: "Success is the sum of small efforts, repeated day in and day out.",
        author: "Robert Collier",
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '2',
        quote: "The secret of getting ahead is getting started.",
        author: "Mark Twain",
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '3',
        quote: "Don't let yesterday take up too much of today.",
        author: "Will Rogers",
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '4',
        quote: "It's not whether you get knocked down, it's whether you get up.",
        author: "Vince Lombardi",
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '5',
        quote: "The only way to do great work is to love what you do.",
        author: "Steve Jobs",
        createdAt: DateTime.now(),
      ),
    ];
  }

  void _startTimer() {
    // Cancel existing timer
    _timer?.cancel();
    
    // Create new timer that updates every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _nextQuote();
    });
  }

  void _nextQuote() {
    if (_quotes.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % _quotes.length;
      _currentQuote = _quotes[_currentIndex];
    });
  }

  void _refreshQuotes() {
    _fetchQuotes();
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
  }

  @override
  Widget build(BuildContext context) {
// <<<<<<< HEAD
// =======
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null && _currentQuote == null) {
      return _buildErrorWidget();
    }

    return _buildQuoteWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey,
          ),
          SizedBox(width: 16),
          Text(
            'Loading motivational quotes...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load quotes: $_error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _refreshQuotes,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Tap to retry',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteWidget() {
    final quote = _currentQuote!;
    
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
// <<<<<<< HEAD
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFF6366F1).withOpacity(0.8),
//             const Color(0xFF8B5CF6).withOpacity(0.8),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF6366F1).withOpacity(0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.format_quote,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Daily Motivation',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '"${currentQuote["quote"]}"',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontStyle: FontStyle.italic,
//                   height: 1.4,
//                 ),
//                 textAlign: TextAlign.left,
//               ),
//               const SizedBox(height: 8),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Text(
//                   "— ${currentQuote["author"]}",
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
// =======
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated quote indicator
          _buildQuoteIndicator(),
          
          // Quote content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote text with fade animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    '"${quote.quote}"',
                    key: ValueKey(quote.id),
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Author with fade animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '— ${quote.author}',
                      key: ValueKey('${quote.id}_author'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                
                // Refresh button and timer indicator
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ),
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
          ),
        ],
      ),
    );
  }
// <<<<<<< HEAD
// }
// =======

  Widget _buildQuoteIndicator() {
    return Container(
      width: 24,
      height: 60,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated dots
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentIndex == 0 ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentIndex == 1 ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentIndex >= 2 ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

    );
  }
}
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
