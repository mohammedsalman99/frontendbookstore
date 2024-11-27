import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContinueBooksProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _continueBooks = [];

  List<Map<String, dynamic>> get continueBooks => _continueBooks;

  ContinueBooksProvider() {
    _loadBooksFromStorage();
  }

  void addBook(Map<String, dynamic> book) {
    _continueBooks.removeWhere((b) => b['id'] == book['id']);
    _continueBooks.insert(0, book);
    _saveBooksToStorage(); 
    notifyListeners();
  }

  void removeBook(String bookId) {
    _continueBooks.removeWhere((book) => book['id'] == bookId);
    _saveBooksToStorage(); 
    notifyListeners();
  }

  Future<void> _loadBooksFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBooks = prefs.getString('continue_books');
    if (savedBooks != null) {
      _continueBooks = List<Map<String, dynamic>>.from(json.decode(savedBooks));
      print("Loaded books: $_continueBooks"); 
      notifyListeners();
    }
  }

  Future<void> _saveBooksToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    print("Saving books: ${json.encode(_continueBooks)}");
    await prefs.setString('continue_books', json.encode(_continueBooks));
  }

  Future<void> clearSavedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('continue_books');
    _continueBooks.clear();
    notifyListeners();
  }
}
