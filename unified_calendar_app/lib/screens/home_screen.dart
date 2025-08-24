import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:unified_calendar_app/providers/auth_provider.dart';
import 'package:unified_calendar_app/models/event.dart';
import 'package:unified_calendar_app/providers/calendar_provider.dart';
import 'package:unified_calendar_app/screens/event_detail_screen.dart';
import 'package:unified_calendar_app/screens/event_form_screen.dart';
import 'package:unified_calendar_app/screens/connect_calendar_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // Day, week, month view toggle
  DateTime _focusedDay = DateTime.now(); // The day currently focused in the calendar
  DateTime? _selectedDay; // The specific day selected by the user

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Fetch events when the home screen initializes, after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(context, listen: false).fetchEvents(context: context);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);

    // Group events by day for TableCalendar's eventLoader
    Map<DateTime, List<Event>> eventsByDay = {};
    for (var event in calendarProvider.events) {
      // Normalize date to UTC for consistent grouping (ignore time part)
      final day = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
      if (eventsByDay[day] == null) {
        eventsByDay[day] = [];
      }
      eventsByDay[day]!.add(event);
    }

    // Filter events for the selected day based on active sources
    final List<Event> selectedDayEvents = calendarProvider.getEventsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Calendar'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
              // No need to navigate, Consumer in main.dart handles it
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar Sources',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  // Display truncated User ID or 'Guest'
                  Text(
                    authProvider.userId != null
                        ? 'User ID: ${authProvider.userId!.substring(0, 8)}...'
                        : 'Guest',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Filter options for calendar sources
            ...calendarProvider.availableSources.map((source) {
              final isSelected = calendarProvider.selectedSources.contains(source);
              return CheckboxListTile(
                title: Text(source.toUpperCase()),
                value: isSelected,
                onChanged: (bool? value) {
                  calendarProvider.toggleSource(source);
                },
                secondary: Icon(_getCalendarSourceIcon(source)),
                activeColor: _getCalendarSourceColor(source),
              );
            }).toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Connect New Calendar'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).pushNamed('/connect-calendars');
              },
            ),
            // Refresh button for connected accounts (optional, can be per-account)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh All Calendars'),
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing events...')),
                );
                await calendarProvider.fetchEvents(context: context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(calendarProvider.errorMessage ?? 'Calendars refreshed!'),
                    backgroundColor: calendarProvider.errorMessage != null ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // TableCalendar widget for day, week, month views
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            // Event loader to display markers on days with events
            eventLoader: (day) {
              final normalizedDay = DateTime.utc(day.year, day.month, day.day);
              return eventsByDay[normalizedDay]
                  ?.where((event) => calendarProvider.selectedSources.contains(event.sourceType.toLowerCase()))
                  .toList() ??
                  [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            // Customizing the calendar's appearance
            calendarStyle: CalendarStyle(
              // Current day decoration
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              // Selected day decoration
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              // Decoration for event markers on days with events
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
              markersMaxCount: 3, // Max number of markers shown per day
              // Text styles for various day types
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              weekendTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
              outsideTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[700]),
              disabledTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[800]),
              holidayTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.redAccent),
              withinRangeTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              rangeStartTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              rangeEndTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              rowDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
              cellMargin: const EdgeInsets.all(6.0),
              cellAlignment: Alignment.center,
              tablePadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            ),
            // Customizing the calendar's header
            headerStyle: HeaderStyle(
              formatButtonShowsNext: false, // Hide "Next" button in format toggle
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
              formatButtonDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
              titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white70),
              weekendStyle: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 8.0),
          // Event List for the selected day
          Expanded(
            child: calendarProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : calendarProvider.errorMessage != null
                ? Center(child: Text(calendarProvider.errorMessage!, style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.error)))
                : selectedDayEvents.isEmpty
                ? Center(
              child: Text(
                'No events for ${DateFormat('EEEE, MMM d').format(_selectedDay!)}.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final event = selectedDayEvents[index];
                // Event card for the list view
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      _getCalendarSourceIcon(event.sourceType),
                      color: _getCalendarSourceColor(event.sourceType),
                      size: 28,
                    ),
                    title: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${event.isAllDay ? 'All day' : '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'} ${event.location != null && event.location!.isNotEmpty ? ' | ${event.location}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: event.isNewlyAccepted
                        ? const Icon(Icons.star, color: Colors.amber, size: 24) // Highlight newly accepted invites
                        : null,
                    onTap: () {
                      // Navigate to event detail screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button for creating new events
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventFormScreen(
                selectedDate: _selectedDay ?? _focusedDay, // Pre-fill date with selected/focused day
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
