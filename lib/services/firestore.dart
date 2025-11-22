import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference menus = FirebaseFirestore.instance.collection('menus');

  Future<QuerySnapshot> getMenusOnce() {
    final menusStream = menus.orderBy('startDate', descending: true).get(); // newest menu is the first menu

    return menusStream;
  }
}