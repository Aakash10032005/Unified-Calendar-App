// lib/screens/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unified_calendar_app/models/event.dart';
import 'package:unified_calendar_app/models/attendee.dart'; // Explicitly import Attendee from its dedicated file
import 'package:unified_calendar_app/providers/calendar_provider.dart';
import 'package:unified_calendar_app/providers/auth_provider.dart';
import 'package:unified_calendar_app/screens/event_form_screen.dart';
import 'package:intl/intl.dart'; // For date and time formatting
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  // Helper function to determine the icon for a given calendar source type
  IconData _getCalendarSourceIcon(String sourceType) {
    switch (sourceType.toLowerCase()) {
      case 'google':
        return FontAwesomeIcons.google;
      case 'outlook':
        return FontAwesomeIcons.microsoft; // Using Microsoft icon for Outlook
      case 'apple':
        return FontAwesomeIcons.apple;
      case 'custom':
        return Icons.event;
      default:
        return Icons.calendar_today;
    }
  }

  // Helper function to determine the color for a given calendar source type
  Color _getCalendarSourceColor(String sourceType) {
    switch (sourceType.toLowerCase()) {
      case 'google':
        return Colors.blueAccent;
    // case 'outlook': // Commented out Outlook color
    //   return Colors.orangeAccent;
      case 'apple':
        return Colors.grey;
      case 'custom':
        return Colors.deepPurpleAccent;
      default:
        return Colors.white70;
    }
  }

  // Builds a row for event details (icon + label + value)
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handles accepting or declining an event invitation
  Future<void> _handleInviteResponse(BuildContext context, String newStatus) async {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Assuming the authenticated user's email is the 'userId' from authProvider
    // In a real app, you'd typically have `authProvider.userEmail`
    final currentUserIdentifier = authProvider.userId;

    if (currentUserIdentifier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot respond: User not authenticated.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    try {
      await calendarProvider.updateAttendeeStatus(event.id, currentUserIdentifier, newStatus, context: context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation $newStatus for "${event.title}"'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      // After responding, pop the detail screen and let the home screen refresh
      Navigator.of(context).pop();
      // Explicitly trigger fetch events on the CalendarProvider so HomeScreen updates
      await calendarProvider.fetchEvents(context: context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String? currentUserEmail = authProvider.userEmail; // This should be the actual user email from AuthProvider

    // Determine current user's attendance status if they are an attendee
    Attendee? currentUserAttendee;
    if (currentUserEmail != null) {
      currentUserAttendee = event.attendees.firstWhere(
            (attendee) => attendee.email == currentUserEmail,
        orElse: () => Attendee(email: currentUserEmail, status: 'not_found'), // Default if not found
      );
    }

    final bool isUserAttendee = currentUserAttendee?.status != 'not_found';
    final bool isPending = currentUserAttendee?.status == 'pending';
    final bool isAccepted = currentUserAttendee?.status == 'accepted';
    final bool isDeclined = currentUserAttendee?.status == 'declined';

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        centerTitle: true,
        actions: [
          // Edit button for the event
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Event',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventFormScreen(event: event, selectedDate: event.startTime),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title and source type
            Row(
              children: [
                Icon(_getCalendarSourceIcon(event.sourceType), color: _getCalendarSourceColor(event.sourceType), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Event description
            if (event.description.isNotEmpty)
              _buildDetailRow(context, Icons.notes, 'Description', event.description),

            // Event time and date
            _buildDetailRow(
              context,
              Icons.calendar_month,
              'When',
              event.isAllDay
                  ? 'All Day - ${DateFormat('EEEE, MMM d, yyyy').format(event.startTime)}'
                  : '${DateFormat('EEEE, MMM d, yyyy – HH:mm').format(event.startTime)} to ${DateFormat('HH:mm').format(event.endTime)}',
            ),

            // Event location
            if (event.location != null && event.location!.isNotEmpty)
              _buildDetailRow(context, Icons.location_on, 'Where', event.location!),

            // Attendees list
            if (event.attendees.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Attendees', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Column(
                children: event.attendees.map((attendee) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCalendarSourceColor(attendee.status), // Color based on status
                      child: Text(attendee.email[0].toUpperCase()),
                    ),
                    title: Text(attendee.email, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(
                      'Status: ${attendee.status.replaceAll('_', ' ')}' + (attendee.isOrganizer ? ' (Organizer)' : ''),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: attendee.status == 'accepted' ? Colors.greenAccent :
                        attendee.status == 'declined' ? Colors.redAccent :
                        Colors.white70,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Invite Management Buttons (only if user is an attendee and status is pending)
            if (isUserAttendee && isPending) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text('Respond to Invite', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleInviteResponse(context, 'accepted'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Green for accept
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleInviteResponse(context, 'declined'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Red for decline
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
            // Show current status if not pending
            if (isUserAttendee && !isPending) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  isAccepted ? 'You have Accepted this invite.' : 'You have Declined this invite.',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: isAccepted ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
