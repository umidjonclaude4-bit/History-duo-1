import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/errors.dart';
import '../models/book.dart';

class BookService {
  BookService._();
  static final BookService instance = BookService._();

  static const _builtInFiles = [
    'assets/books/uzbekistan.json',
    'assets/books/world.json',
    'assets/books/tarix6.json',
    'assets/books/uztarix7.json',
    'assets/books/jahon7.json',
  ];
  static const maxCustomBooks = 20;
  static const maxTopicsPerBook = 40;
  static const maxTotalChars = 300000;

  List<Book>? _builtIn;

  Future<List<Book>> builtInBooks() async {
    if (_builtIn != null) return _builtIn!;
    final list = <Book>[];
    for (final f in _builtInFiles) {
      final raw = await rootBundle.loadString(f);
      final m = json.decode(raw) as Map<String, dynamic>;
      list.add(Book.fromMap(m, id: m['id'] as String, isCustom: false));
    }
    _builtIn = list;
    return list;
  }

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('books');
  }

  Stream<List<Book>> customBooks() {
    return _col.orderBy('createdAt').snapshots().map((snap) => snap.docs
        .map((d) => Book.fromMap(d.data(), id: d.id, isCustom: true))
        .toList());
  }

  Stream<Book?> bookStream(String id) {
    return _col.doc(id).snapshots().map((d) {
      final data = d.data();
      if (data == null) return null;
      return Book.fromMap(data, id: d.id, isCustom: true);
    });
  }

  Future<void> addBook(String title, String description) async {
    final existing = await _col.limit(maxCustomBooks + 1).get();
    if (existing.size >= maxCustomBooks) {
      throw const UserFacingException(
          "Shaxsiy kitoblar soni chegarasiga yetdingiz (20 ta)");
    }
    await _col.add({
      'title': title,
      'description': description,
      'topics': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTopic(Book book, Topic topic) async {
    if (book.topics.length >= maxTopicsPerBook) {
      throw const UserFacingException(
          "Bir kitobga ko'pi bilan 40 ta mavzu qo'shish mumkin");
    }
    var total = 0;
    for (final t in book.topics) {
      for (final s in t.sections) {
        total += s.text.length;
      }
    }
    for (final s in topic.sections) {
      total += s.text.length;
    }
    if (total > maxTotalChars) {
      throw const UserFacingException("Kitob hajmi juda katta bo'lib ketdi");
    }
    final topics = [...book.topics, topic].map((t) => t.toMap()).toList();
    await _col.doc(book.id).update({'topics': topics});
  }

  Future<void> deleteTopic(Book book, String topicId) async {
    final topics = book.topics
        .where((t) => t.id != topicId)
        .map((t) => t.toMap())
        .toList();
    await _col.doc(book.id).update({'topics': topics});
  }

  Future<void> deleteBook(String id) => _col.doc(id).delete();
}
