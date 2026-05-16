// lib/ui/habit-tracker/screen/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/habit-tracker/providers/chat_providers.dart';

class ChatBotScreen extends ConsumerStatefulWidget {
  final String? userName;
  
  const ChatBotScreen({super.key, this.userName});

  @override
  ConsumerState<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends ConsumerState<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasSetUserInfo = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }
  
  @override
  void didUpdateWidget(ChatBotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika userName berubah, update service
    if (widget.userName != oldWidget.userName && widget.userName != null) {
      _updateUserInfo();
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _updateUserInfo() async {
    if (widget.userName == null || widget.userName!.isEmpty) return;
    if (_hasSetUserInfo) return; // Sudah pernah set info
    
    try {
      final chatService = ref.read(chatBotServiceProvider);
      
      // Cek apakah service sudah memiliki nama yang sama
      if (chatService.userName != widget.userName) {
        await chatService.setUserInfo(widget.userName!);
        _hasSetUserInfo = true;
        
        // Update pesan sambutan
        setState(() {
          _messages.clear();
          _messages.add(ChatMessage(
            message: _getWelcomeMessage(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('❌ Error updating user info: $e');
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final chatService = ref.read(chatBotServiceProvider);
      
      print('🔵 ChatBotScreen initialized with userName: ${widget.userName}');
      print('🔵 Service current state - Name: ${chatService.userName}, Gender: ${chatService.userGender}');
      
      // CEK: Apakah service sudah memiliki user info?
      if (widget.userName != null && widget.userName!.isNotEmpty) {
        // Jika nama berbeda, update
        if (chatService.userName != widget.userName) {
          print('🔵 Updating user info from "${chatService.userName}" to "${widget.userName}"');
          await chatService.setUserInfo(widget.userName!);
          _hasSetUserInfo = true;
        } else if (chatService.userName.isNotEmpty) {
          // Jika nama sama, sudah ter-set
          print('🔵 User info already set with same name: ${chatService.userName}');
          _hasSetUserInfo = true;
        } else {
          // Service kosong, set info
          print('🔵 Setting user info for first time: ${widget.userName}');
          await chatService.setUserInfo(widget.userName!);
          _hasSetUserInfo = true;
        }
      } else {
        print('⚠️ No userName provided to ChatBotScreen');
      }
      
      // Tampilkan pesan sambutan dengan nama user
      String welcomeMessage = _getWelcomeMessage();
      
      setState(() {
        _messages.add(ChatMessage(
          message: welcomeMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isInitializing = false;
      });
      
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error initializing chat: $e');
      setState(() {
        _messages.add(ChatMessage(
          message: 'Halo! Aku temen curhat virtual kamu. Cerita aja santai ya 😊',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isInitializing = false;
      });
    }
  }
  
  String _getWelcomeMessage() {
    final chatService = ref.read(chatBotServiceProvider);
    
    print('🔵 Getting welcome message - Service Name: "${chatService.userName}", Gender: "${chatService.userGender}"');
    
    // PRIORITAS: Cek dari service dulu
    String userName = chatService.userName;
    
    // Jika service kosong, cek dari widget
    if (userName.isEmpty && widget.userName != null && widget.userName!.isNotEmpty) {
      userName = widget.userName!;
      print('🔵 Using userName from widget: $userName');
    }
    
    // Jika tetap kosong, pake sambutan biasa
    if (userName.isEmpty) {
      print('⚠️ No userName found, using generic welcome message');
      return 'Halo! Aku temen curhat virtual kamu. Cerita aja santai, aku bakal ingat obrolan kita kok 😊';
    }
    
    final gender = chatService.userGender;
    print('🔵 Building welcome message for: $userName (gender: $gender)');
    
    // Sambutan dengan menyebut nama user
    switch (gender) {
      case 'pria':
        return 'Halo $userName! Senang kenalan ya bro 😊\n\nAku bakal ingat nama kamu kok. Cerita aja santai tentang apapun ya!';
        
      case 'wanita':
        return 'Halo $userName! Senang kenalan ya sis 😊\n\nAku bakal ingat nama kamu kok. Cerita aja santai tentang apapun ya!';
        
      default:
        return 'Halo $userName! Senang kenalan ya 😊\n\nAku bakal ingat nama kamu kok. Cerita aja santai tentang apapun ya!';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        message: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final chatService = ref.read(chatBotServiceProvider);
      final response = await chatService.getResponse(userMessage);
      
      setState(() {
        _messages.add(ChatMessage(
          message: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error sending message: $e');
      setState(() {
        _messages.add(ChatMessage(
          message: 'Maaf, lagi error nih. Coba ketik ulang ya 🙏',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _clearConversation() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Percakapan'),
          content: const Text('Yakin mau menghapus semua percakapan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performClearConversation();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _performClearConversation() {
    final chatService = ref.read(chatBotServiceProvider);
    chatService.clearHistory();
    
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        message: _getWelcomeMessage() + '\n\n(Obrolan sebelumnya sudah direset)',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percakapan sudah direset'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.chat_bubble_outline, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Purewill Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // if (widget.userName != null && widget.userName!.isNotEmpty && !_isInitializing)
                //   Text(
                //     'Halo ${widget.userName} ✨',
                //     style: const TextStyle(fontSize: 12, color: Colors.green),
                //   )
                // else if (!_isInitializing)
                //   const Text(
                //     'Online • Siap membantu',
                //     style: TextStyle(fontSize: 12, color: Colors.green),
                //   )
                // else
                //   const Text(
                //     'Loading...',
                //     style: TextStyle(fontSize: 12, color: Colors.grey),
                //   ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: _clearConversation,
            tooltip: 'Reset percakapan',
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Menyiapkan teman curhat...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sedang mengetik...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Cerita atau tanya apa aja...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.isError;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                      )
                    : null,
                color: isUser 
                    ? null 
                    : (isError ? Colors.red[50] : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isUser ? Colors.white : (isError ? Colors.red[700] : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}