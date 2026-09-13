import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:app_badge_control_flutter/app_badge_control_flutter.dart';
import 'package:whats_for_dino_2/models/server_message.dart';

// Fires whenever the unread count changes. The Messages nav icon listens
// to this directly (no Provider plumbing needed), and it also drives the
// OS-level app icon badge.
final ValueNotifier<int> unreadMessagesNotifier = ValueNotifier<int>(0);

class MessagesCache {
  // Most-recent-first. Order is persisted, not recomputed from timestamps.
  static List<ServerMessage> messages = [];
  static Set<String> readIds = {};
}

Future<void> initializeMessagesCache() async {
  final metaDataBox = Hive.box('metaDataBox');

  final storedMessages = metaDataBox.get('cachedMessages', defaultValue: []);
  MessagesCache.messages =
      (storedMessages as List)
          .map((e) => ServerMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  final storedReadIds = metaDataBox.get('readMessageIds', defaultValue: []);
  MessagesCache.readIds = Set<String>.from(storedReadIds as List);

  _refreshUnreadCount();
}

// Merge freshly-fetched messages into the persistent cache. Existing
// messages are updated in place (keeping their position); genuinely new
// ones are inserted at the top. Nothing already cached is ever removed,
// even if it later disappears from the server doc, so this behaves like a
// message history rather than a mirror of "currently active" messages.
Future<void> mergeServerMessages(List<ServerMessage> incoming) async {
  final metaDataBox = Hive.box('metaDataBox');

  for (final message in incoming) {
    final index = MessagesCache.messages.indexWhere((m) => m.id == message.id);

    if (index == -1) {
      MessagesCache.messages.insert(0, message);
    } else {
      MessagesCache.messages[index] = message;
    }
  }

  await metaDataBox.put(
    'cachedMessages',
    MessagesCache.messages.map((m) => m.toJson()).toList(),
  );

  _refreshUnreadCount();
}

Future<void> markAllMessagesRead() async {
  final metaDataBox = Hive.box('metaDataBox');

  MessagesCache.readIds.addAll(MessagesCache.messages.map((m) => m.id));
  await metaDataBox.put('readMessageIds', MessagesCache.readIds.toList());

  _refreshUnreadCount();
}

void _refreshUnreadCount() {
  final count =
      MessagesCache.messages
          .where((m) => !MessagesCache.readIds.contains(m.id))
          .length;

  unreadMessagesNotifier.value = count;
}

// Call once at startup (after Hive is ready) to sync the OS app-icon badge
// whenever the unread count changes.
void wireAppIconBadge() {
  if (kIsWeb) return;

  unreadMessagesNotifier.addListener(() {
    final count = unreadMessagesNotifier.value;
    if (count > 0) {
      AppBadgeControlFlutter.updateBadgeCount(count);
    } else {
      AppBadgeControlFlutter.removeBadge();
    }
  });
}
