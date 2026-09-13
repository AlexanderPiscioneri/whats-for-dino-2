import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/models/server_message.dart';
import 'package:whats_for_dino_2/services/messages_cache.dart';
import 'package:whats_for_dino_2/widgets/server_message_dialogue.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {

  IconData? _iconFor(String type) {
    return switch (type) {
      'warning' => Icons.warning_amber,
      'error' => Icons.error_outline_sharp,
      'info' => Icons.info_outline,
      _ => null,
    };
  }

  Color _iconColourFor(String type) {
    return switch (type) {
      'warning' => Colors.orange,
      'error' => Colors.red,
      _ => Colors.white70,
    };
  }

  void _openMessage(ServerMessage message) {
    showServerMessageDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final currentColourScheme = Theme.of(context).colorScheme;

    if (MessagesCache.messages.isEmpty) {
      return Scaffold(
        backgroundColor: currentColourScheme.surface,
        body: const Center(
          child: Text(
            'No messages yet.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: currentColourScheme.surface,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: MessagesCache.messages.length,
        separatorBuilder:
            (_, __) => Divider(color: currentColourScheme.primary, height: 1),
        itemBuilder: (context, index) {
          final message = MessagesCache.messages[index];
          final unread = !MessagesCache.readIds.contains(message.id);
          final icon = _iconFor(message.type);

          return ListTile(
            onTap: () => _openMessage(message),
            leading:
                icon != null
                    ? Icon(icon, color: _iconColourFor(message.type))
                    : null,
            title: Text(
              message.title.isEmpty ? 'Notice' : message.title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: unread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle:
                message.text.isNotEmpty
                    ? Text(
                      message.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    )
                    : null,
            trailing:
                unread
                    ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    )
                    : null,
          );
        },
      ),
    );
  }
}
