import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference menus = FirebaseFirestore.instance.collection('menus');
  final CollectionReference meals = FirebaseFirestore.instance.collection('meals');

  Future<QuerySnapshot> getMenusOnce() {
    final menusStream = menus.orderBy('startDate', descending: true).get(); // newest menu is the first menu

    return menusStream;
  }

    Future<QuerySnapshot> getMealsOnce() {
    final mealsStream = meals.orderBy('name', descending: false).get(); // ordered alphabetecally from a-z

    return mealsStream;
  }
}