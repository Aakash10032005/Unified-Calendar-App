import 'package:flutter/material.dart';

// Represents an external calendar account connected by the user.
class CalendarAccount {
  final String id; // Our internal ID for the calendar account (MongoDB _id)
  final String userId; // The ID of the user who owns this account
  final String calendarType; // e.g., 'google', 'outlook', 'apple'
  final String? externalCalendarId; // The ID of the calendar on the external service
  final String accountName; // User-friendly name for the calendar
  final String? accountEmail; // Email associated with the external account
  final Color displayColor; // Color for visual distinction in the UI
  final String? lastSyncToken; // Used for incremental sync with external APIs

  CalendarAccount({
    required this.id,
    required this.userId,
    required this.calendarType,
    this.externalCalendarId,
    required this.accountName,
    this.accountEmail,
    required this.displayColor,
    this.lastSyncToken,
  });

  // Factory constructor to create a CalendarAccount from a JSON map
  factory CalendarAccount.fromJson(Map<String, dynamic> json) {
    return CalendarAccount(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      calendarType: json['calendarType'] as String,
      externalCalendarId: json['externalCalendarId'] as String?,
      accountName: json['accountName'] as String,
      accountEmail: json['accountEmail'] as String?,
      // Parse color from hex string stored in JSON to Flutter Color object
      displayColor: Color(int.parse(json['displayColor'].substring(2), radix: 16) + 0xFF000000),
      lastSyncToken: json['lastSyncToken'] as String?,
    );
  }

  // Method to convert a CalendarAccount object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'calendarType': calendarType,
      'externalCalendarId': externalCalendarId,
      'accountName': accountName,
      'accountEmail': accountEmail,
      // Convert Flutter Color object to a hex string for storage
      'displayColor': '#${displayColor.value.toRadixString(16).padLeft(8, '0')}',
      'lastSyncToken': lastSyncToken,
    };
  }
}
