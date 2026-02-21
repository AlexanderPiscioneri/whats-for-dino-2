import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/services/utils.dart';


class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme currentColourScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'The breakfast of champions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w400,
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.primary),
            ElevatedButton(
              onPressed: () => openLink("https://example.com"),
              style: ButtonStyle(
                backgroundColor: WidgetStateColor.resolveWith(
                  (_) => currentColourScheme.primary,
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                minimumSize: WidgetStateProperty.all(Size(170, 60)),
                elevation: WidgetStateProperty.resolveWith<double>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return 0; // pressed (flat)
                  }
                  return 8; // normal
                }),
              ),
              child: Text(
                'Dino Feedback Form',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.primary),
            Text(
              'Found something wrong with the app?\nHave an idea for another feature?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            ElevatedButton(
              onPressed:
                  () => openLink("https://forms.gle/mc7dDUUe1d5iCwes9"),
              style: ButtonStyle(
                backgroundColor: WidgetStateColor.resolveWith(
                  (_) => currentColourScheme.primary,
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                minimumSize: WidgetStateProperty.all(Size(170, 60)),
                elevation: WidgetStateProperty.resolveWith<double>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return 0; // pressed (flat)
                  }
                  return 8; // normal
                }),
              ),
              child: Text(
                'Anonymous App Feedback Form',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary,
              indent: 20,
              endIndent: 20,
            ),
            Text(
              'Want to get in touch?\nAre you ambitious?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            ElevatedButton(
              onPressed:
                  () => openLink("https://linktr.ee/alexanderpiscioneri"),
              style: ButtonStyle(
                backgroundColor: WidgetStateColor.resolveWith(
                  (_) => currentColourScheme.primary,
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                minimumSize: WidgetStateProperty.all(Size(170, 60)),
                elevation: WidgetStateProperty.resolveWith<double>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return 0; // pressed (flat)
                  }
                  return 8; // normal
                }),
              ),
              child: Text(
                'Reach Out To Me Directly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
