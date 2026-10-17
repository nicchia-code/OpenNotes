import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages security, PIN code, and locked notes state.
/// Obscures protected notes in list until unlocked.
class SecurityService extends ChangeNotifier {
  static const String _pinKey = 'user_master_pin_hash';
  final Set<String> _unlockedNoteIds = {};
  bool _hasMasterPin = false;

  bool get hasMasterPin => _hasMasterPin;
  bool isNoteUnlocked(String noteId) => _unlockedNoteIds.contains(noteId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hasMasterPin = prefs.containsKey(_pinKey);
    notifyListeners();
  }

  /// Hashes PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  /// Sets or updates the master PIN
  Future<void> setMasterPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    await prefs.setString(_pinKey, hash);
    _hasMasterPin = true;
    notifyListeners();
  }

  /// Verifies if entered PIN matches master PIN
  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(enteredPin);
  }

  /// Unlocks a note for the current session
  void unlockNote(String noteId) {
    _unlockedNoteIds.add(noteId);
    notifyListeners();
  }

  /// Ends the session unlock of a note: once protected, it is hidden again. Listeners are told only when it was unlocked.
  void relockNote(String noteId) {
    if (_unlockedNoteIds.remove(noteId)) notifyListeners();
  }
}
