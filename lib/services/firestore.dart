import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:whats_for_dino_2/models/server_message.dart';

class FirestoreService {
  final CollectionReference menus = FirebaseFirestore.instance.collection(
    'menus',
  );
  final CollectionReference meals = FirebaseFirestore.instance.collection(
    'meals',
  );

  Future<QuerySnapshot> getMenusOnce() {
    return menus.orderBy('startDate', descending: true).get();
  }

  Future<QuerySnapshot> getMealsOnce() {
    return meals.orderBy('name', descending: false).get();
  }

  // Just 1 read to check if anything changed
  Future<DateTime?> getLastUpdated() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('metadata')
              .doc('version')
              .get();
      final ts = doc.data()?['lastUpdated'] as Timestamp?;
      return ts?.toDate();
    } catch (e) {
      return null;
    }
  }

  Future<List<ServerMessage>> getServerMessages(String currentVersion) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('metadata')
              .doc('messages')
              .get();

      if (!doc.exists) return [];

      final rawMessages = doc.data()?['messages'] as List<dynamic>? ?? [];
      final now = DateTime.now();

      return rawMessages
          .map((m) => ServerMessage.fromJson(m as Map<String, dynamic>))
          .where((message) => message.isActive(now, currentVersion))
          .toList();
    } catch (e) {
      debugPrint("Error fetching server messages: $e");
      return [];
    }
  }
}
