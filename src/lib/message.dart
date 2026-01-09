class Message {
  final String text;
  final String userId;
  final String email;

  Message({
    required this.text,
    required this.userId,
    required this.email,
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      text: data['text'],
      userId: data['userId'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'userId': userId,
      'email': email,
    };
  }
}
