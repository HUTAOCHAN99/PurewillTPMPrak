// lib/data/services/chatbot/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:purewill/config/api_config.dart';

class ChatMessageHistory {
  final String role; // 'user', 'assistant', atau 'system'
  final String content;
  
  ChatMessageHistory({required this.role, required this.content});
  
  Map<String, String> toJson() => {
    'role': role,
    'content': content,
  };
}

class ChatBotService {
  final String apiKey;
  final String apiUrl;
  final int maxTokens;
  final double temperature;
  
  // Store chat history untuk konteks
  final List<ChatMessageHistory> _chatHistory = [];
  
  // Informasi user
  String _userName = '';
  String _userGender = 'netral'; // 'pria', 'wanita', atau 'netral'
  bool _isGenderDetected = false;
  
  ChatBotService({
    String? apiKey,
    String? apiUrl,
    int? maxTokens,
    double? temperature,
  }) : 
    apiKey = apiKey ?? ApiConfig.groqApiKey,
    apiUrl = apiUrl ?? ApiConfig.apiUrl,
    maxTokens = maxTokens ?? ApiConfig.maxTokens,
    temperature = temperature ?? ApiConfig.temperature;
  
  // GETTERS untuk cek state
  bool get hasHistory => _chatHistory.isNotEmpty;
  int get historyLength => _chatHistory.length;
  bool get hasUserInfo => _userName.isNotEmpty && _isGenderDetected;
  List<ChatMessageHistory> get chatHistory => List.unmodifiable(_chatHistory);
  
  // Getter untuk akses informasi user
  String get userGender => _userGender;
  String get userName => _userName;
  bool get isGenderDetected => _isGenderDetected;
  
  // Deteksi gender menggunakan Groq AI
  Future<String> detectGenderWithGroq(String name) async {
    if (name.isEmpty) return 'netral';
    
    try {
      print('🔍 Detecting gender for name: $name using Groq...');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': '''Anda adalah AI pendeteksi gender dari nama orang Indonesia.

TUGAS: Deteksi gender dari nama yang diberikan.
ATURAN:
- Jawab HANYA dengan SATU kata: "pria", "wanita", atau "netral"
- JANGAN tambahkan penjelasan apapun
- JANGAN gunakan tanda baca

PANDUAN:
1. "pria" untuk nama laki-laki (Budi, Joko, Agus, Nayif, Hendra, dll)
2. "wanita" untuk nama perempuan (Siti, Dewi, Yuli, Putri, Maya, dll)
3. "netral" untuk nama modern/unisex/asing (Alex, Rin, Sam, dll)

Contoh:
Input: Budi → Output: pria
Input: Yuli → Output: wanita
Input: Alex → Output: netral
Input: Nayif → Output: pria
Input: Sari → Output: wanita'''
            },
            {
              'role': 'user',
              'content': 'Nama: $name'
            }
          ],
          'temperature': 0.1,
          'max_tokens': 10,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String gender = data['choices'][0]['message']['content']
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(',', '');
        
        if (gender == 'pria' || gender == 'wanita' || gender == 'netral') {
          print('✅ Gender detected: $gender for $name');
          return gender;
        } else {
          print('⚠️ Invalid gender response: $gender, using netral');
          return 'netral';
        }
      } else {
        print('❌ API error: ${response.statusCode}');
        return 'netral';
      }
      
    } catch (e) {
      print('❌ Gender detection error: $e');
      return 'netral';
    }
  }
  
  // Set user info dengan deteksi gender via Groq
  Future<void> setUserInfo(String name) async {
    if (name.isEmpty) return;
    
    print('🔵 SET USER INFO CALLED with name: $name');
    print('🔵 Current service state - Name: $_userName, Gender: $_userGender');
    
    _userName = name;
    
    // Deteksi gender dengan Groq
    print('🔵 Detecting gender for: $name');
    _userGender = await detectGenderWithGroq(name);
    _isGenderDetected = true;
    
    print('🔵 Gender detection result: $_userGender');
    
    // Clear history lama
    _chatHistory.clear();
    
    // Tambahkan pesan system tentang nama user
    _chatHistory.add(ChatMessageHistory(
      role: 'system', 
      content: 'INFO PENTING: Nama user adalah "$_userName". User berjenis kelamin ${_getGenderText()}. Ingat nama ini sepanjang percakapan!'
    ));
    
    // Tambahkan pesan assistant sebagai pengingat
    _chatHistory.add(ChatMessageHistory(
      role: 'assistant', 
      content: 'Halo $_userName! Senang berkenalan denganmu.'
    ));
    
    print('📝 Final user info saved - Name: $_userName, Gender: $_userGender');
    print('📝 Chat history length: ${_chatHistory.length}');
  }
  
  // Clear history (misal pas user klik delete)
  void clearHistory() {
    _chatHistory.clear();
    
    // Set ulang user info ke history
    if (_userName.isNotEmpty && _isGenderDetected) {
      _chatHistory.add(ChatMessageHistory(
        role: 'system', 
        content: 'INFO PENTING: Nama user adalah "$_userName". User berjenis kelamin ${_getGenderText()}.'
      ));
      
      _chatHistory.add(ChatMessageHistory(
        role: 'assistant', 
        content: 'Halo $_userName! Senang berkenalan denganmu.'
      ));
    }
  }
  
  // Reset semua termasuk user info
  void resetAll() {
    _chatHistory.clear();
    _userName = '';
    _userGender = 'netral';
    _isGenderDetected = false;
  }
  
  String _getGenderText() {
    switch (_userGender) {
      case 'pria':
        return 'laki-laki';
      case 'wanita':
        return 'perempuan';
      default:
        return 'netral';
    }
  }
  
  // Deteksi apakah topik serius (mental health) atau ringan
  bool _isSeriousTopic(String message) {
    final seriousKeywords = [
      // Depresi & kecemasan
      'depresi', 'depressi', 'sedih terus', 'putus asa', 'hampa',
      'cemas', 'anxiety', 'panik', 'takut berlebihan', 'gelisah',
      // Pikiran negatif
      'mati', 'bunuh diri', 'suicide', 'akhir hidup', 'gak kuat',
      'capek hidup', 'lelah hidup', 'putus asa', 'tidak kuat',
      // Trauma & kekerasan
      'trauma', 'kekerasan', 'pelecehan', 'dianiaya', 'dipukul',
      'kekerasan seksual', 'tdr', 'perkosa',
      // Gangguan mental
      'halusinasi', 'delusi', 'skizofrenia', 'bipolar',
      'gangguan makan', 'anoreksia', 'bulimia',
      // Kecanduan (NoFap related)
      'kecanduan', 'nonton vcs', 'porno', 'pornografi', 'fap',
      'no fap', 'nofap', 'relapse', 'kambuh', 'urge',
      // Masalah kesehatan mental
      'psikiater', 'psikolog', 'konseling', 'terapi',
      'stres berat', 'burnout', 'mental breakdown', 'down',
      'sedih banget', 'galau', 'pusing mikir', 'overthinking',
      // Masalah tidur
      'insomnia', 'susah tidur', 'gak bisa tidur', 'mimpi buruk'
    ];
    
    final messageLower = message.toLowerCase();
    return seriousKeywords.any((keyword) => messageLower.contains(keyword));
  }
  
  Future<String> getResponse(String userMessage, {String? model}) async {
    final modelToUse = model ?? 'llama-3.3-70b-versatile';
    
    // Deteksi topik serius
    final isSerious = _isSeriousTopic(userMessage);
    print('🔍 Topic severity: ${isSerious ? "SERIOUS (Mental Health)" : "LIGHT (Casual Chat)"}');
    
    // PASTIKAN info user selalu ada di history
    if (_userName.isNotEmpty && _isGenderDetected) {
      // Cek apakah sudah ada info user di history
      bool hasUserInfo = false;
      for (var msg in _chatHistory) {
        if (msg.role == 'system' && msg.content.contains('INFO PENTING: Nama user adalah')) {
          hasUserInfo = true;
          break;
        }
      }
      
      // Jika belum ada, tambahkan sekarang
      if (!hasUserInfo) {
        _chatHistory.insert(0, ChatMessageHistory(
          role: 'system', 
          content: 'INFO PENTING: Nama user adalah "$_userName". User berjenis kelamin ${_getGenderText()}.'
        ));
      }
    }
    
    // Debug: print history sebelum add message
    print('📜 History BEFORE adding user message (${_chatHistory.length} entries):');
    if (_chatHistory.isEmpty) {
      print('  ⚠️ HISTORY KOSONG! User info tidak tersimpan!');
    }
    for (var msg in _chatHistory) {
      print('  - ${msg.role}: ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}');
    }
    
    // Tambahkan pesan user ke history
    _chatHistory.add(ChatMessageHistory(role: 'user', content: userMessage));
    
    // Batasi history ke 20 pesan terakhir
    while (_chatHistory.length > 20) {
      _chatHistory.removeAt(0);
    }
    
    try {
      // Buat messages array dengan history
      final messages = [
        {
          'role': 'system',
          'content': _getSystemPrompt(isSerious),
        },
        // Tambahkan history percakapan
        ..._chatHistory.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }).toList(),
      ];
      
      // Debug: print messages yang akan dikirim
      print('📤 Sending messages to API (${messages.length} messages):');
      for (var msg in messages) {
        final role = msg['role'];
        final content = msg['content'].toString();
        print('  - $role: ${content.substring(0, content.length > 50 ? 50 : content.length)}');
      }
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': modelToUse,
          'messages': messages,
          'temperature': isSerious ? 0.5 : 0.9, // Lebih rendah untuk topik serius
          'max_tokens': isSerious ? 300 : 200, // Lebih panjang untuk topik serius
        }),
      ).timeout(Duration(seconds: ApiConfig.timeout));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String content = data['choices'][0]['message']['content'];
        
        // Tambahkan respons AI ke history
        _chatHistory.add(ChatMessageHistory(role: 'assistant', content: content));
        
        print('📥 Response: $content');
        
        return content;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('API Error: ${errorData['error']['message'] ?? response.statusCode}');
      }
    } catch (e) {
      // Hapus pesan user yang gagal dari history
      _chatHistory.removeLast();
      throw Exception('Network Error: $e');
    }
  }
  
  String _getSystemPrompt(bool isSerious) {
    String userContext = '';
    if (_userName.isNotEmpty && _isGenderDetected) {
      String panggilan = '';
      switch (_userGender) {
        case 'pria':
          panggilan = 'Panggil dia "bro", "mas", atau langsung namanya "$_userName"';
          break;
        case 'wanita':
          panggilan = 'Panggil dia "sis", "mba", atau langsung namanya "$_userName"';
          break;
        default:
          panggilan = 'Panggil namanya langsung "$_userName" atau "kak"';
      }
      
      userContext = '''
INFORMASI USER YANG HARUS KAMU INGAT SEPANJANG PERCAKAPAN:

Nama: "$_userName"
Gender: ${_getGenderText()}

⚠️ PERINGATAN PENTING ⚠️:
1. KAMU HARUS TAU NAMA USER ADALAH "$_userName"
2. Jika user bertanya "siapa nama aku?" atau "siapa nama saya?", JAWAB: "$_userName"
3. JANGAN pernah bilang "kamu belum kasih tau nama" karena kamu sudah tahu namanya
4. Gunakan nama user di setiap respons untuk membuat percakapan lebih personal

CARA MEMANGGIL:
$panggilan
''';
    }
    
    // Jika topik serius (mental health), gunakan prompt yang lebih profesional
    if (isSerious) {
      return '''
Kamu adalah asisten kesehatan mental yang profesional, empatik, dan supportive di aplikasi PureWill.

$userContext

🎯 TUJUAN UTAMA:
Membantu user dengan masalah kesehatan mental, stres, kecemasan, depresi, kecanduan (termasuk NoFap), dan pengembangan diri dengan cara yang tepat dan bertanggung jawab.

⚠️ ATURAN RESPON UNTUK TOPIK SERIUS (Mental Health):

1. Tunjukkan EMPATI yang tulus:
   - "Saya turut prihatin mendengarnya, $_userName"
   - "Saya memahami apa yang Anda rasakan pasti berat"
   - "Terima kasih sudah mau berbagi cerita"

2. VALIDASI perasaan user:
   - "Perasaan itu wajar dan valid"
   - "Anda tidak sendiri dalam menghadapi ini"

3. Berikan SARAN PRAKTIS yang bisa langsung dilakukan:
   - Teknik pernapasan (4-7-8)
   - Journaling atau menulis perasaan
   - Olahraga ringan atau jalan kaki
   - Kurangi screen time, terutama sebelum tidur
   - Konsumsi makanan bergizi dan cukup air putih

4. Untuk topik NoFap/kecanduan pornografi:
   - Validasi perjuangan user: "Perjuanganmu berat, tapi kamu kuat"
   - Beri tips: alihkan perhatian, push up, meditasi, mandi air dingin
   - Jangan menghakimi jika relapse, justru beri support: "Relapse tidak menghapus progressmu, yang penting bangkit lagi"

5. REKOMENDASIKAN bantuan profesional jika:
   - Gejala berlangsung >2 minggu
   - Ada pikiran menyakiti diri sendiri
   - Gangguan tidur/makan yang parah
   - Tidak kunjung membaik setelah mencoba tips mandiri

6. JANGAN gunakan kata-kata: "wkwk", "haha", "lol", "waduh", "bro", "sis" (panggil langsung nama)

7. RESPON 3-5 kalimat sudah cukup, jangan terlalu panjang

8. Selalu TANYAKAN apakah user ingin mendiskusikan lebih lanjut atau mencoba saran yang diberikan

CONTOH RESPON YANG BENAR:

User: "aku merasa cemas terus akhir-akhir ini"
AI: "Saya turut prihatin mendengarnya, $_userName. Kecemasan yang berkepanjangan memang sangat melelahkan. Coba praktikkan teknik pernapasan 4-7-8: tarik napas 4 detik, tahan 7 detik, hembuskan 8 detik, ulangi 5-10 kali. Apakah ada pemicu tertentu yang membuat Anda merasa cemas?"

User: "aku relapse lagi setelah 10 hari no fap"
AI: "$_userName, 10 hari itu pencapaian yang luar biasa! Relapse adalah bagian dari proses pemulihan, jangan terlalu keras pada diri sendiri. Coba identifikasi apa pemicunya, lalu lain kali saat urge muncul, langsung alihkan dengan push up 20x atau mandi air dingin. Mulai lagi dari hari ke-1, kamu bisa kok!"

User: "aku stres banget sama skripsi"
AI: "Wajar banget kok stres menghadapi skripsi, $_userName. Coba breakdown tugas jadi bagian kecil-kecil, kerjakan satu per satu. Jangan lupa istirahat setiap 45 menit dan tetap jaga pola makan. Kalau perlu, curhat ke dosen pembimbing atau teman. Kamu pasti bisa melewati ini!"

⚠️ DARURAT (Prioritas Tertinggi):
Jika user menyebutkan keinginan bunuh diri atau melukai diri sendiri:
1. RESEPSI: "Hidup Anda sangat berharga"
2. SEGERA tawarkan bantuan profesional
3. Berikan nomor darurat: 119 (ambulans) atau 112
4. Anjurkan hubungi orang terdekat
5. Jangan tinggalkan user sendirian dalam percakapan

Contoh: "Halo $_userName, saya sangat prihatin. Hidup Anda berharga. Segera hubungi psikolog terdekat atau layanan darurat 119. Bicarakan dengan orang yang Anda percaya. Anda tidak sendirian."

INGAT! Kamu adalah pendamping kesehatan mental yang bertanggung jawab. Prioritaskan kesejahteraan user.
''';
    }
    
    // Jika topik ringan, gunakan prompt yang lebih santai (seperti sebelumnya)
    return '''
Kamu adalah teman curhat yang asik, hangat, dan pengertian di aplikasi PureWill. 

$userContext

🎯 TUJUAN:
Menjadi teman ngobrol yang nyaman untuk user, terutama untuk obrolan ringan dan sehari-hari.

GAYA NGOMONG:
- BAHASA SEHARI-HARI kayak ngobrol di WhatsApp
- PAKE KATA GAUL: "wkwk", "lah", "bro", "sip", "gapapa", "wah", "waduh"
- Jawab SINGKAT (2-4 kalimat)
- Jangan pake kata formal atau "Sebagai AI"
- JANGAN PAKAI BULLET POINTS atau **teks tebal**
- PAKAI NAMA USER DI RESPONS jika memungkinkan

CARA MEMANGGIL:
- Pakai "bro" atau "mas" untuk user pria (${_userGender == 'pria' ? 'user ANDA adalah pria' : 'tidak berlaku'})
- Pakai "sis" atau "mba" untuk user wanita (${_userGender == 'wanita' ? 'user ANDA adalah wanita' : 'tidak berlaku'})
- Atau panggil langsung nama "$_userName"

CONTOH RESPON:
User: "hai juga"
Kamu: "Hai $_userName! Ada yang bisa aku bantu? Lagi ngapain?"

User: "lagi suntuk nih"
Kamu: "Wah, lagi suntuk ya $_userName? Coba dengerin musik favorit atau nonton film lucu, siapa tau bisa jadi hiburan bro/sis"

User: "aku laper banget"
Kamu: "Waduh buruan makan dong $_userName, jangan sampe keroncongan terus wkwk"

PENTING - KAMU HARUS INGAT KONTEKS PERCAKAPAN SEBELUMNYA:
- Perhatikan apa yang sudah dibicarakan sebelumnya
- Lanjutkan obrolan dengan natural, jangan mulai dari awal lagi
- Jika user melanjutkan cerita, kamu harus paham konteksnya

INGAT SELALU:
- Gunakan nama user "$_userName" di percakapan
- Lanjutkan obrolan dari sebelumnya
- Tunjukkan kamu mendengarkan dan mengingat
- Tetap singkat dan natural kayak teman ngobrol
''';
  }
}