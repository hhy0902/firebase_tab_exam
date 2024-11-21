

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final db = FirebaseFirestore.instance;
  return db.collection("category").orderBy("createdAt", descending: false).snapshots();
});

final currentTabIndexProvider = StateProvider<int>((ref) => 0);








