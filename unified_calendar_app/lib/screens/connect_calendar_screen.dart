import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unified_calendar_app/providers/calendar_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening URLs in browser

class ConnectCalendarScreen extends StatelessWidget {
  const ConnectCalendarScreen({super.key});

  // Function to launch URL in an external browser
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback for older Flutter versions or if externalApplication fails
      if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
        throw Exception('Could not launch $url');
      }
    }
  }

  // Helper to build a button for connecting a calendar service
  Widget _buildConnectButton(BuildContext context, CalendarProvider calendarProvider, String calendarType, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(
          'Connect ${calendarType.capitalizeFirstLetter()} Calendar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailing: calendarProvider.isLoading
            ? const CircularProgressIndicator()
            : Icon(Icons.arrow_forward_ios, color: Theme.of(context).iconTheme.color),
        onTap: () async {
          if (calendarProvider.isLoading) return; // Prevent multiple taps

          try {
            // Initiate the OAuth2 flow with the backend
            final authUrl = await calendarProvider.connectExternalCalendar(calendarType, context: context);
            if (authUrl != null) {
              await _launchUrl(authUrl); // Open the URL in the browser for user authentication
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please complete authentication in your browser for ${calendarType.capitalizeFirstLetter()}.'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  duration: const Duration(seconds: 5),
                ),
              );
              // After successful connection via browser, refresh the calendar accounts and events
              // This is crucial to update the UI after coming back from the browser.
              await calendarProvider.fetchEvents(context: context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(calendarProvider.errorMessage ?? 'Failed to get authentication URL.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect External Calendars'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Integrate your calendars from different services to see all your events in one unified view.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildConnectButton(context, calendarProvider, 'google', FontAwesomeIcons.google, Colors.red),
            // Commented out Outlook Calendar button
            // _buildConnectButton(context, calendarProvider, 'outlook', FontAwesomeIcons.microsoft, Colors.blue),
            // Apple Calendar integration is more complex, as detailed in the backend section.
            // For a hackathon, you might omit direct integration or provide a disclaimer.
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(FontAwesomeIcons.apple, color: Colors.grey, size: 40),
                title: Text(
                  'Apple Calendar (Read-only / Manual Sync)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  'Direct API integration for Apple Calendar is complex for third-party web services. For this app, consider manual export/import or a more limited read-only sync via CalDAV if supported by your setup.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Icon(Icons.info_outline, color: Theme.of(context).iconTheme.color),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Apple Calendar integration for full read/write is challenging with web-based OAuth. Focusing on Google/Outlook for direct sync for now.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      duration: const Duration(seconds: 6),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Once connected, your events will start syncing automatically. You can manage connected accounts and refresh events from the main calendar view.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
