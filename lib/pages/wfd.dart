import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/main.dart';
import 'package:whats_for_dino_2/services/firestore.dart';

class WfdPage extends StatefulWidget {
  const WfdPage({super.key});

  @override
  State<WfdPage> createState() => _WfdPageState();
}

class _WfdPageState extends State<WfdPage> {
  final FirestoreService firestoreService = FirestoreService();

  List<DocumentSnapshot> menuList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      QuerySnapshot snapshot = await firestoreService.getMenusOnce();
      setState(() {
        menuList = snapshot.docs;
        isLoading = false;
      });
      print("Menu loaded: $menuList");
    } catch (e) {
      print("Error loading menu: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: secondaryColour,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (menuList.isEmpty) {
      return Scaffold(
        backgroundColor: secondaryColour,
        body: const Center(child: Text("No data")),
      );
    }

    return Scaffold(
      backgroundColor: secondaryColour,
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: menuList.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> data =
              menuList[index].data() as Map<String, dynamic>;
          String menuName = data['name'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              color: Colors.white,
              child: Center(
                child: Text(
                  menuName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}