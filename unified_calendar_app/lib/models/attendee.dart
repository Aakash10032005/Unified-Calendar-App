// lib/models/attendee.dart

// Represents an attendee for an event
class Attendee {
  final String email;
  String status; // e.g., 'accepted', 'declined', 'pending'
  final bool isOrganizer;

  Attendee({
    required this.email,
    this.status = 'pending',
    this.isOrganizer = false,
  });

  // Factory constructor to create an Attendee from a JSON map
  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      email: json['email'],
      status: json['status'] ?? 'pending',
      isOrganizer: json['isOrganizer'] ?? false,
    );
  }

  // Converts an Attendee object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'status': status,
      'isOrganizer': isOrganizer,
    };
  }
}
