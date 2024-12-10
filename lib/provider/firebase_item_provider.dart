

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentCategoryProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final db = FirebaseFirestore.instance;
  return db.collection("category").orderBy("createdAt", descending: false).snapshots();
});

// final currentTabIndexProvider = StateProvider<int>((ref) => 0);

final selectedImageProvider = StateProvider<File?>((ref) => null);


final currentTabIndexProvider = StateNotifierProvider<CurrentTabIndexNotifier, int>((ref) {
  return CurrentTabIndexNotifier();
});

class CurrentTabIndexNotifier extends StateNotifier<int> {
  CurrentTabIndexNotifier() : super(0);

  void updateIndex(int newIndex, int totalTabs) {
    // 인덱스가 유효한 범위 내에 있는지 확인
    state = newIndex < totalTabs ? newIndex : (totalTabs > 0 ? totalTabs - 1 : 0);
  }
}





