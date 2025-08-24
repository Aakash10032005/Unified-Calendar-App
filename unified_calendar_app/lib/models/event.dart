// lib/models/event.dart
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:unified_calendar_app/models/calendar_account.dart'; // To link events to external calendar accounts
import 'package:unified_calendar_app/models/attendee.dart'; // Import the standalone Attendee model

// Helper for generating unique IDs
final _uuid = const Uuid();

// Represents a calendar event
class Event {
  final String id; // Unique ID for the event (local or external)
  final String? externalEventId; // ID of the event on the external calendar service, null for 'custom' app events
  final String title;
  final String description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  List<Attendee> attendees; // List of attendees for the event (now imported)
  final String sourceType; // e.g., 'google', 'outlook', 'apple', 'custom'
  CalendarAccount? externalCalendarAccount; // Populated from backend, links to the account it belongs to
  final bool isNewlyAccepted; // To highlight events where user just accepted an invite

  Event({
    String? id, // Allow null for new events, will be generated or from backend
    this.externalEventId,
    required this.title,
    this.description = '',
    this.location,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.attendees = const [],
    required this.sourceType, // Must specify source type
    this.externalCalendarAccount,
    this.isNewlyAccepted = false,
  }) : id = id ?? _uuid.v4(); // Generate UUID if no ID is provided

  // Factory constructor to create an Event from a JSON map
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'] ?? _uuid.v4(), // Handle both _id from Mongo and 'id'
      externalEventId: json['externalEventId'],
      title: json['title'],
      description: json['description'] ?? '',
      location: json['location'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isAllDay: json['isAllDay'] ?? false,
      attendees: (json['attendees'] as List<dynamic>?)
          ?.map((aJson) => Attendee.fromJson(aJson))
          .toList() ??
          [],
      sourceType: json['sourceType'],
      // If the populated data is present, use it
      externalCalendarAccount: json['externalCalendarAccountId'] != null && json['externalCalendarAccountId'] is Map<String, dynamic>
          ? CalendarAccount.fromJson(json['externalCalendarAccountId'])
          : null,
      isNewlyAccepted: json['isNewlyAccepted'] ?? false,
    );
  }

  // Converts an Event object to a JSON map for sending to the backend
  Map<String, dynamic> toJson() {
    return {
      // '_id' might be used if updating, but generally we use 'id' or leave it to backend for creation
      'id': id,
      'externalEventId': externalEventId, // Null for custom events
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay,
      'attendees': attendees.map((a) => a.toJson()).toList(),
      'sourceType': sourceType,
      // Only send the ID of the externalCalendarAccount if it exists, not the full object
      'externalCalendarAccountId': externalCalendarAccount?.id,
      'isNewlyAccepted': isNewlyAccepted,
    };
  }
}
