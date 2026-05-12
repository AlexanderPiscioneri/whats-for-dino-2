import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/pages/catalogue.dart';

class RatingsWidget extends StatelessWidget {
  final dynamic meal;
  final void Function(MealVote vote) onVote;
  final Color? colourOverride;

  const RatingsWidget({
    super.key,
    required this.meal,
    required this.onVote,
    this.colourOverride,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = colourOverride; // null means "use theme"

    final ratioText = _ratio();
    final left = ratioText.split(":")[0];
    final right = ratioText.split(":")[1];

    return Expanded(
      flex: 20,
      child: SizedBox(
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  flex: 50,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
                    icon: Icon(
                      meal.myVote == MealVote.like
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                      color: effectiveColor,
                    ),
                    onPressed: () {
                      onVote(
                        meal.myVote == MealVote.like
                            ? MealVote.none
                            : MealVote.like,
                      );
                    },
                  ),
                ),
                Flexible(
                  flex: 50,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
                    icon: Icon(
                      meal.myVote == MealVote.dislike
                          ? Icons.thumb_down
                          : Icons.thumb_down_alt_outlined,
                      color: effectiveColor,
                    ),
                    onPressed: () {
                      onVote(
                        meal.myVote == MealVote.dislike
                            ? MealVote.none
                            : MealVote.dislike,
                      );
                    },
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: -10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      left,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                  Text(
                    ":",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: effectiveColor,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    child: Text(
                      right,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratio() {
    if (meal.dislikes == 0) return "${meal.likes}:0";
    if (meal.likes == 0) return "0:${meal.dislikes}";

    int gcd(int x, int y) {
      while (y != 0) {
        final t = y;
        y = x % y;
        x = t;
      }
      return x;
    }

    final d = gcd(meal.likes, meal.dislikes);
    return "${meal.likes ~/ d}:${meal.dislikes ~/ d}";
  }
}
