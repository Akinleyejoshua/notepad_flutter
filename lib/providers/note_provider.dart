import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  String _searchQuery = '';
  static const String _storageKey = 'user_notepad_notes';

  NotesProvider() {
    _loadNotesFromDisk(); // 🌟 Auto-hydrate local data cache on startup
  }

  List<Note> get allNotes {
    final sorted = List<Note>.from(_notes);
    sorted.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
    return sorted;
  }

  List<Note> get filteredNotes {
    if (_searchQuery.isEmpty) return allNotes;
    return _notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final contentMatch = note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatch || contentMatch;
    }).toList();
  }

  // Add or update a note
  void addOrUpdateNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    _saveNotesToDisk();
    notifyListeners();
  }

  // Delete a note
  void deleteNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    _saveNotesToDisk();
    notifyListeners();
  }

  // Update note content (rich text)
  void updateNoteContent(String id, String content) {
    final note = _notes.firstWhere((n) => n.id == id);
    note.content = content;
    note.lastEdited = DateTime.now();
    _saveNotesToDisk();
    notifyListeners();
  }

  // Add media to a note
  void addMediaToNote(String id, String mediaPath) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final note = _notes[index];
      final updatedPaths = [...note.mediaPaths, mediaPath];
      _notes[index] = note.copyWith(mediaPaths: updatedPaths, lastEdited: DateTime.now());
      _saveNotesToDisk();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // 💾 Disk Read Operation
  Future<void> _loadNotesFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? serializedData = prefs.getString(_storageKey);
      
      if (serializedData != null) {
        final List<dynamic> decodedList = jsonDecode(serializedData);
        _notes = decodedList.map((item) => Note.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to hydrate storage layer: $e");
    }
  }

  // 💾 Disk Write Operation
  Future<void> _saveNotesToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String serializedData = jsonEncode(_notes.map((n) => n.toMap()).toList());
      await prefs.setString(_storageKey, serializedData);
    } catch (e) {
      debugPrint("Failed to write state changes to disk: $e");
    }
  }

  // State Modifiers with Sync Hooks
  void addNote(Note note) {
    _notes.add(note);
    _saveNotesToDisk();
    notifyListeners();
  }

  void updateNote(String id, String title, String content) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index >= 0) {
      _notes[index] = _notes[index].copyWith(
        title: title,
        content: content,
        lastEdited: DateTime.now(),
      );
      _saveNotesToDisk();
      notifyListeners();
    }
  }
}