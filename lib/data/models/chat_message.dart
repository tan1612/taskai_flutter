enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });
}
