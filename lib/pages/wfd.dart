import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/main.dart';

class WfdPage extends StatelessWidget {
  const WfdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColour,
      body:PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 10,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Text(
                    'Item $index',
                    style: const TextStyle(color: Colors.black, fontSize: 24),
                  ),
                ),
              ),
            );
          },
        ),
    );
  }
}