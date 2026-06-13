import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whats_for_dino_2/services/utils.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme currentColourScheme = Theme.of(context).colorScheme;
    final settingsBox = Hive.box('settingsBox');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'All feedback is always welcome.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.primary),
            ElevatedButton(
              onPressed: () {
                if (settingsBox.get("hapticFeedback", defaultValue: true))
                  HapticFeedback.mediumImpact();
                openLink(
                  "https://forms.office.com/Pages/ResponsePage.aspx?id=pM_2PxXn20i44Qhnufn7o91DYUQ6lW9MsGLk8aV9AgNUNlFXTDUwUEgwVzJQNUVYRjdMQVdJNkxSMS4u&origin=QRCode",
                );
              },
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.primary),
            Text(
              'Something wrong with the app?\nHave an idea for another feature?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (settingsBox.get("hapticFeedback", defaultValue: true))
                  HapticFeedback.mediumImpact();
                openLink("https://forms.gle/mc7dDUUe1d5iCwes9");
              },
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
                textAlign: TextAlign.center,
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
              'Something else?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (settingsBox.get("hapticFeedback", defaultValue: true))
                  HapticFeedback.mediumImpact();
                openLink("https://linktr.ee/alexanderpiscioneri");
              },
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
                textAlign: TextAlign.center,
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
