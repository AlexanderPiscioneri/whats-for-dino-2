import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/models/server_message.dart';
import 'package:whats_for_dino_2/services/utils.dart';

Future<void> showServerMessageDialog(
  BuildContext context,
  ServerMessage message,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.title.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    message.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(
                          message.imageUrl!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        actions: [
          Row(
            children: [
              Expanded(
                child: _DialogButton(
                  label: message.buttonText,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              if (message.link != null && message.link!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: _DialogButton(
                    label: message.linkButtonText ?? 'Open Link',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      openLink(message.link!);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DialogButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
