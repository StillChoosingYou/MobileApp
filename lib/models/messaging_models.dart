import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';

/// Types of messages in the chat system.
enum MessageType {
  text('Text'),
  image('Image'),
  file('File'),
  system('System');

  const MessageType(this.label);
  final String label;
}

/// Represents a chat conversation (1:1 or group).
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    this.groupName,
    this.groupAvatarUrl,
    this.lastMessage,
    required this.updatedAt,
    required this.unreadCounts,
    this.isArchived = false,
  });

  final String id;
  final List<String> participantIds;
  final String? groupName;
  final String? groupAvatarUrl;
  final Message? lastMessage;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts; // userId -> unread count
  final bool isArchived;

  /// Whether this is a group chat.
  bool get isGroup => groupName != null;

  /// Get display name for a specific user (excludes their own name in 1:1).
  String getDisplayName(String currentUserId, List<AppUser> allUsers) {
    if (isGroup) return groupName ?? 'Group Chat';

    // 1:1 chat - find the other participant
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return 'Unknown';

    final otherUser = allUsers.firstWhere(
      (u) => u.id == otherId,
      orElse: () => AppUser(
        id: otherId,
        loginId: otherId,
        role: UserRole.student,
        name: 'Unknown User',
        email: '',
      ),
    );
    return otherUser.name;
  }

  /// Get avatar URL for display.
  String? getAvatarUrl(String currentUserId, List<AppUser> allUsers) {
    if (isGroup) return groupAvatarUrl;

    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return null;

    final otherUser = allUsers.firstWhere(
      (u) => u.id == otherId,
      orElse: () => AppUser(
        id: otherId,
        loginId: otherId,
        role: UserRole.student,
        name: 'Unknown User',
        email: '',
      ),
    );
    return otherUser.photoUrl;
  }

  /// Get unread count for a user.
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    String? groupName,
    String? groupAvatarUrl,
    Message? lastMessage,
    DateTime? updatedAt,
    Map<String, int>? unreadCounts,
    bool? isArchived,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          participantIds == other.participantIds &&
          groupName == other.groupName &&
          groupAvatarUrl == other.groupAvatarUrl &&
          lastMessage == other.lastMessage &&
          updatedAt == other.updatedAt &&
          unreadCounts == other.unreadCounts &&
          isArchived == other.isArchived;

  @override
  int get hashCode => Object.hash(
        id,
        participantIds,
        groupName,
        groupAvatarUrl,
        lastMessage,
        updatedAt,
        unreadCounts,
        isArchived,
      );

  @override
  String toString() => 'Conversation(id: $id, groupName: $groupName, '
      'participants: ${participantIds.length}, unread: $unreadCounts)';
}

/// A single message within a conversation.
@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.type,
    required this.content,
    this.metadata,
    required this.sentAt,
    this.isRead = false,
    this.readBy = const [],
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final MessageType type;
  final String content;
  final Map<String, String>? metadata; // fileUrl, replyToId, etc.
  final DateTime sentAt;
  final bool isRead;
  final List<String> readBy; // userIds who have read this

  /// Whether this message was sent by the current user.
  bool isSentBy(String userId) => senderId == userId;

  /// Get display content based on type.
  String getDisplayContent() {
    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 ${metadata?['fileName'] ?? 'File'}';
      case MessageType.system:
        return content;
    }
  }

  /// Check if message has been read by a specific user.
  bool isReadBy(String userId) => readBy.contains(userId);

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    MessageType? type,
    String? content,
    Map<String, String>? metadata,
    DateTime? sentAt,
    bool? isRead,
    List<String>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          senderAvatarUrl == other.senderAvatarUrl &&
          type == other.type &&
          content == other.content &&
          metadata == other.metadata &&
          sentAt == other.sentAt &&
          isRead == other.isRead &&
          readBy == other.readBy;

  @override
  int get hashCode => Object.hash(
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatarUrl,
        type,
        content,
        metadata,
        sentAt,
        isRead,
        readBy,
      );

  @override
  String toString() => 'Message(id: $id, sender: $senderName, type: $type, '
      'content: ${content.length > 30 ? '${content.substring(0, 30)}...' : content})';
}