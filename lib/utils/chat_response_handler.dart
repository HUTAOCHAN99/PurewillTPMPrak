class ChatResponseHandler {
  // Deteksi basa-basi otomatis
  static bool isSmallTalk(String message) {
    final smallTalkPatterns = [
      // Sapaan
      r'^(halo|hai|hey|hi|hello)$',
      r'^halo+$',
      r'^hai+$',
      
      // Basa-basi umum
      r'^(maaf|permisi|punten)$',
      r'^(gini|begini|ini)$',
      r'^(coba|eh|heh|oh)$',
      r'^(iya|ya|oke|ok)$',
      r'^(kak|bang|mbak|mas|pak|bu)$',
      r'^(assalamualaikum|salam)$',
      
      // Pertanyaan basa-basi
      r'^apa kabar?*$',
      r'^kabar baik?*$',
      r'^lagi apa?*$',
      r'^lagi ngapain?*$',
      
      // Kata tunggal yang ambigu
      r'^test$',
      r'^tes$',
      r'^coba$',
      r'^tolong$',
    ];
    
    final cleanedMessage = message.toLowerCase().trim();
    
    for (var pattern in smallTalkPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(cleanedMessage)) {
        return true;
      }
    }
    
    // Deteksi jika pesan terlalu pendek (kurang dari 5 karakter)
    if (cleanedMessage.length < 5 && !cleanedMessage.contains(' ')) {
      return true;
    }
    
    return false;
  }
  
  // Generate response untuk basa-basi
  static String generateSmallTalkResponse(String message) {
    final cleaned = message.toLowerCase().trim();
    
    // Sapaan
    if (RegExp(r'^(halo|hai|hey|hi|hello)').hasMatch(cleaned)) {
      return "Halo juga! Ada yang bisa aku bantu? 😊";
    }
    
    // Maaf/permisi
    if (RegExp(r'^(maaf|permisi|punten)').hasMatch(cleaned)) {
      return "Iya gapapa. Mau cerita atau tanya apa? Aku siap dengerin kok.";
    }
    
    // Gini/begini
    if (RegExp(r'^(gini|begini|ini)').hasMatch(cleaned)) {
      return "Iya silakan, aku dengerin baik-baik. Ada masalah apa?";
    }
    
    // Panggilan (kak/mbak/bang/mas)
    if (RegExp(r'^(kak|mbak|bang|mas|pak|bu)$').hasMatch(cleaned)) {
      return "Iya sayang, ada yang bisa aku bantu? Cerita aja 😊";
    }
    
    // Apa kabar
    if (RegExp(r'^apa kabar').hasMatch(cleaned)) {
      return "Baik-baik aja kok! Kamu sendiri gimana kabarnya? Semoga selalu sehat ya 😊";
    }
    
    // Test
    if (RegExp(r'^(test|tes|coba)$').hasMatch(cleaned)) {
      return "Aku online dan siap membantu kok! Ada yang mau kamu ceritain atau tanyakan?";
    }
    
    // Default untuk basa-basi lainnya
    return "Iya, aku dengerin. Silakan cerita atau tanya apa pun tentang kesehatan mental ya 😊";
  }
  
  // Cek apakah pesan mengandung masalah (bukan basa-basi)
  static bool hasRealProblem(String message) {
    final problemKeywords = [
      'stres', 'cemas', 'sedih', 'marah', 'kecewa', 'kesal',
      'takut', 'khawatir', 'depresi', 'sendiri', 'kesepian',
      'masalah', 'kerjaan', 'tugas', 'sekolah', 'kuliah',
      'pacarku', 'suamiku', 'istriku', 'orang tua', 'temen',
      'ga bisa', 'susah', 'berat', 'pusing', 'capek',
      'hubungan', 'percaya diri', 'minder', 'overthinking',
      'tidur', 'makan', 'malas', 'semangat', 'motivasi',
    ];
    
    final cleaned = message.toLowerCase();
    for (var keyword in problemKeywords) {
      if (cleaned.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}