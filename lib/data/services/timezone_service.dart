// lib/services/timezone_service.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimezoneService {
  static final TimezoneService _instance = TimezoneService._internal();
  factory TimezoneService() => _instance;
  TimezoneService._internal();

  tz.Location? _location;
  String _currentTimezone = 'Asia/Jakarta';
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      tz.initializeTimeZones();
      _currentTimezone = await _getLocalTimezone();
      _location = tz.getLocation(_currentTimezone);
      _isInitialized = true;
      debugPrint('✅ Timezone initialized: $_currentTimezone');
    } catch (e) {
      debugPrint('❌ Error initializing timezone: $e');
      // Fallback ke WIB
      _location = tz.getLocation('Asia/Jakarta');
      _isInitialized = true;
    }
  }

  Future<String> _getLocalTimezone() async {
    try {
      // Method 1: Dari offset UTC
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      
      // Method 2: Dari timeZoneName
      final timeZoneName = DateTime.now().timeZoneName;
      debugPrint('Device timeZoneName: $timeZoneName, offset: $hours');
      
      // Mapping berdasarkan offset UTC
      return _getTimezoneByOffset(hours, timeZoneName);
      
    } catch (e) {
      debugPrint('Error getting local timezone: $e');
      return _getFallbackTimezone();
    }
  }

  String _getTimezoneByOffset(int offsetHours, String timeZoneName) {
    // Mapping berdasarkan offset UTC
    switch (offsetHours) {
      case 7:
        return 'Asia/Jakarta';      // WIB (Indonesia Western)
      case 8:
        return 'Asia/Makassar';     // WITA (Indonesia Central)
      case 9:
        return 'Asia/Jayapura';     // WIT (Indonesia Eastern)
      case -5:
        return 'America/New_York';   // EST
      case -6:
        return 'America/Chicago';    // CST
      case -7:
        return 'America/Denver';     // MST
      case -8:
        return 'America/Los_Angeles'; // PST
      case 0:
        return 'Europe/London';      // GMT
      case 1:
        return 'Europe/Paris';       // CET
      case 2:
        return 'Europe/Berlin';      // EET
      case 3:
        return 'Europe/Moscow';      // MSK
      case 5:
        return 'Asia/Karachi';       // PKT
      case 5.5:
        return 'Asia/Kolkata';       // IST
      case 6:
        return 'Asia/Dhaka';         // BST
      case 7:
        return 'Asia/Jakarta';       // WIB
      case 8:
        return 'Asia/Singapore';     // SGT
      case 9:
        return 'Asia/Tokyo';         // JST
      case 10:
        return 'Australia/Sydney';   // AEST
      case 11:
        return 'Pacific/Guadalcanal'; // SBT
      case 12:
        return 'Pacific/Auckland';   // NZST
      default:
        return _getTimezoneByName(timeZoneName);
    }
  }

  String _getTimezoneByName(String timeZoneName) {
    final mapping = {
      'WIB': 'Asia/Jakarta',
      'WITA': 'Asia/Makassar',
      'WIT': 'Asia/Jayapura',
      'ICT': 'Asia/Bangkok',
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'GMT': 'Europe/London',
      'BST': 'Europe/London',
      'CET': 'Europe/Paris',
      'CEST': 'Europe/Paris',
      'EET': 'Europe/Helsinki',
      'EEST': 'Europe/Helsinki',
      'JST': 'Asia/Tokyo',
      'KST': 'Asia/Seoul',
      'CST': 'Asia/Shanghai',
      'MSK': 'Europe/Moscow',
      'IST': 'Asia/Kolkata',
      'PKT': 'Asia/Karachi',
      'SGT': 'Asia/Singapore',
      'AEST': 'Australia/Sydney',
      'AEDT': 'Australia/Sydney',
      'NZST': 'Pacific/Auckland',
      'NZDT': 'Pacific/Auckland',
    };
    
    return mapping[timeZoneName] ?? 'Asia/Jakarta';
  }

  String _getFallbackTimezone() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale?.countryCode?.toUpperCase();
    
    switch (countryCode) {
      case 'ID': return 'Asia/Jakarta';
      case 'US': return 'America/New_York';
      case 'GB': return 'Europe/London';
      case 'JP': return 'Asia/Tokyo';
      case 'KR': return 'Asia/Seoul';
      case 'MY': return 'Asia/Kuala_Lumpur';
      case 'SG': return 'Asia/Singapore';
      case 'AU': return 'Australia/Sydney';
      case 'DE': return 'Europe/Berlin';
      case 'FR': return 'Europe/Paris';
      case 'IT': return 'Europe/Rome';
      case 'ES': return 'Europe/Madrid';
      case 'NL': return 'Europe/Amsterdam';
      case 'BE': return 'Europe/Brussels';
      case 'CH': return 'Europe/Zurich';
      case 'AT': return 'Europe/Vienna';
      case 'SE': return 'Europe/Stockholm';
      case 'NO': return 'Europe/Oslo';
      case 'DK': return 'Europe/Copenhagen';
      case 'FI': return 'Europe/Helsinki';
      case 'PL': return 'Europe/Warsaw';
      case 'RU': return 'Europe/Moscow';
      case 'TR': return 'Europe/Istanbul';
      case 'IN': return 'Asia/Kolkata';
      case 'PK': return 'Asia/Karachi';
      case 'BD': return 'Asia/Dhaka';
      case 'TH': return 'Asia/Bangkok';
      case 'VN': return 'Asia/Ho_Chi_Minh';
      case 'PH': return 'Asia/Manila';
      case 'TW': return 'Asia/Taipei';
      case 'HK': return 'Asia/Hong_Kong';
      case 'CN': return 'Asia/Shanghai';
      case 'BR': return 'America/Sao_Paulo';
      case 'MX': return 'America/Mexico_City';
      case 'CA': return 'America/Toronto';
      case 'ZA': return 'Africa/Johannesburg';
      case 'EG': return 'Africa/Cairo';
      case 'NG': return 'Africa/Lagos';
      case 'KE': return 'Africa/Nairobi';
      default: return 'Asia/Jakarta';
    }
  }

  tz.Location get location {
    if (!_isInitialized) {
      throw Exception('TimezoneService not initialized. Call initialize() first.');
    }
    return _location ?? tz.getLocation('Asia/Jakarta');
  }

  String get timezoneName => _currentTimezone;
  
  DateTime get now {
    if (!_isInitialized) return DateTime.now();
    return tz.TZDateTime.now(location);
  }
  
  DateTime toLocalDateTime(DateTime utcTime) {
    if (!_isInitialized) return utcTime.toLocal();
    return tz.TZDateTime.from(utcTime, location);
  }
  
  DateTime toUtc(DateTime localTime) {
    // Konversi local time ke UTC
    // Kurangi dengan offset timezone
    final offset = tz.TZDateTime.now(location).timeZoneOffset;
    return localTime.subtract(offset);
  }
  
  String formatTime(DateTime time, {bool withDate = true}) {
    final local = toLocalDateTime(time);
    if (withDate) {
      return '${local.day}/${local.month}/${local.year} ${_formatTimeOfDay(local)}';
    }
    return _formatTimeOfDay(local);
  }
  
  String _formatTimeOfDay(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
  
  String getTimezoneOffset() {
    if (!_isInitialized) return 'UTC+07:00';
    final now = tz.TZDateTime.now(location);
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.abs() % 60;
    final sign = hours >= 0 ? '+' : '-';
    
    String offsetString = 'UTC$sign${hours.abs().toString().padLeft(2, '0')}';
    if (minutes > 0) {
      offsetString += ':${minutes.toString().padLeft(2, '0')}';
    }
    return offsetString;
  }
  
  bool isTimePassedForToday(TimeOfDay time) {
    final now = this.now;
    final todayTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return todayTime.isBefore(now);
  }
  
  DateTime getNextScheduledTime(TimeOfDay time) {
    final now = this.now;
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
  
  // Helper untuk mendapatkan waktu saat ini dalam format string lokal
  String getCurrentTimeString() {
    return formatTime(now);
  }
  
  // Helper untuk mendapatkan tanggal saat ini dalam format string lokal
  String getCurrentDateString() {
    final now = this.now;
    return '${now.day}/${now.month}/${now.year}';
  }
  
  // Helper untuk mendapatkan hari dalam seminggu
  String getCurrentDayName() {
    final now = this.now;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1];
  }
  
  // Helper untuk mendapatkan informasi lengkap waktu lokal
  Map<String, dynamic> getCurrentTimeInfo() {
    final now = this.now;
    return {
      'timezone': timezoneName,
      'offset': getTimezoneOffset(),
      'datetime': now,
      'date': getCurrentDateString(),
      'time': getCurrentTimeString(),
      'day': getCurrentDayName(),
      'timestamp': now.millisecondsSinceEpoch,
    };
  }
  
  // Format TimeOfDay ke string
  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Parse string ke TimeOfDay
  TimeOfDay parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    return TimeOfDay.now();
  }
}