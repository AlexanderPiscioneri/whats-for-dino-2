import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whats_for_dino_2/pages/catalogue.dart';
import 'package:whats_for_dino_2/services/meals_cache.dart';

class RatingsWidget extends StatelessWidget {
  final LocalMealItem meal;
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

    // final ratioText = _ratio();
    // final left = ratioText.split(":")[0];
    // final right = ratioText.split(":")[1];

    final settingsBox = Hive.box('settingsBox');

    bool hasVotedOnThisMeal = false;
    final index = MealItemsCache.items.indexWhere((m) => m.name == meal.name);
    if (index != -1) hasVotedOnThisMeal = true;

    double bottomButtonOffset = -10;
    double leftRightOffset = 5;

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
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentGeometry.center,
                    children: [
                      Tooltip(
                        message:
                            !kIsWeb ? "Like" : "Get the mobile app to vote!",
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
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
                            if (settingsBox.get(
                              "hapticFeedback",
                              defaultValue: true,
                            ))
                              HapticFeedback.mediumImpact();
                          },
                        ),
                      ),
                      Positioned(
                        right: leftRightOffset,
                        bottom: bottomButtonOffset,
                        child: SizedBox(
                          width: 25,
                          child: Text(
                            meal.likes.toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: effectiveColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 50,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentGeometry.center,
                    children: [
                      Tooltip(
                        message:
                            !kIsWeb ? "Dislike" : "Get the mobile app to vote!",
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),

                        child: IconButton(
                          padding: EdgeInsets.zero,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
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
                            if (settingsBox.get(
                              "hapticFeedback",
                              defaultValue: true,
                            ))
                              HapticFeedback.mediumImpact();
                          },
                        ),
                      ),

                      Positioned(
                        bottom: bottomButtonOffset,
                        left: leftRightOffset,
                        child: SizedBox(
                          width: 20,
                          child: Text(
                            meal.dislikes.toString(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: effectiveColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Positioned(
            //   bottom: -20,
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       SizedBox(
            //         width: 40,
            //         child: Text(
            //           meal.likes != 0 || meal.dislikes != 0 ? "${(meal.likes / (meal.likes + meal.dislikes) * 100).truncate()}%" : "-%",
            //           textAlign: TextAlign.center,
            //           style: TextStyle(
            //             fontSize: 11,
            //             fontWeight: FontWeight.w600,
            //             color: effectiveColor,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // OLD RATIOS
            // Positioned(
            //   bottom: -10,
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       SizedBox(
            //         width: 20,
            //         child: Text(
            //           left,
            //           textAlign: TextAlign.right,
            //           style: TextStyle(
            //             fontSize: 11,
            //             fontWeight: FontWeight.w600,
            //             color: effectiveColor,
            //           ),
            //         ),
            //       ),
            //       Text(
            //         " | ",
            //         style: TextStyle(
            //           fontSize: 11,
            //           fontWeight: FontWeight.w600,
            //           color: effectiveColor,
            //         ),
            //       ),
            //       SizedBox(
            //         width: 20,
            //         child: Text(
            //           right,
            //           textAlign: TextAlign.left,
            //           style: TextStyle(
            //             fontSize: 11,
            //             fontWeight: FontWeight.w600,
            //             color: effectiveColor,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
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
    return "${meal.likes}:${meal.dislikes}";
  }
}
