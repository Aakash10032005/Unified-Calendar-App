import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:unified_calendar_app/models/event.dart';
import 'package:unified_calendar_app/models/calendar_account.dart';
import 'package:unified_calendar_app/providers/auth_provider.dart';

// CalendarProvider manages all calendar-related data and logic for the frontend.
class CalendarProvider extends ChangeNotifier {
  List<Event> _events = []; // All fetched events for the current user
  List<CalendarAccount> _calendarAccounts = []; // All connected external calendar accounts
  List<String> _selectedSources = ['google', /*'outlook',*/ 'apple', 'custom']; // Active filters for sources
  bool _isLoading = false; // Indicates if data is being fetched/updated
  String? _errorMessage; // Stores any error messages

  List<Event> get events => _events;
  List<CalendarAccount> get calendarAccounts => _calendarAccounts;
  List<String> get selectedSources => _selectedSources;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // List of all possible calendar sources
  final List<String> availableSources = ['google', /*'outlook',*/ 'apple', 'custom'];

  // Sets loading state and notifies listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Sets error message and notifies listeners.
  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Fetches all events and connected calendar accounts from the backend for the current user.
  Future<void> fetchEvents({BuildContext? context}) async { // Ensure 'context' is a named, nullable parameter
    _setLoading(true);
    _setErrorMessage(null);

    try {
      if (context == null) {
        print("Error: Context is null in fetchEvents. Cannot access AuthProvider.");
        return;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId; // Our internal userId

      if (token == null && userId == null) {
        _setErrorMessage('Authentication required to fetch events.');
        _setLoading(false);
        return;
      }

      // Fetch calendar accounts
      final accountsResponse = await http.get(
        Uri.parse('${authProvider.baseUrl}/calendars/accounts/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (accountsResponse.statusCode == 200) {
        final List<dynamic> accountsJson = json.decode(accountsResponse.body);
        _calendarAccounts = accountsJson.map((json) => CalendarAccount.fromJson(json)).toList();
        print('Fetched ${_calendarAccounts.length} calendar accounts.');
      } else {
        throw Exception(json.decode(accountsResponse.body)['message'] ?? 'Failed to fetch calendar accounts.');
      }


      // Fetch events
      final eventsResponse = await http.get(
        Uri.parse('${authProvider.baseUrl}/events/$userId'), // Fetch events for the current user
        headers: {'Authorization': 'Bearer $token'},
      );

      if (eventsResponse.statusCode == 200) {
        final List<dynamic> eventsJson = json.decode(eventsResponse.body);
        _events = eventsJson.map((json) => Event.fromJson(json)).toList();
        print('Fetched ${_events.length} events.');
      } else {
        throw Exception(json.decode(eventsResponse.body)['message'] ?? 'Failed to fetch events.');
      }
    } catch (e) {
      _setErrorMessage('Failed to fetch data: ${e.toString()}');
      print('Error fetching events: $e'); // Debug print
    } finally {
      _setLoading(false);
    }
  }

  // Returns events for a specific day.
  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      final eventDay = DateTime.utc(event.startTime.year, event.startTime.month, event.startTime.day);
      final targetDay = DateTime.utc(day.year, day.month, day.day);
      return eventDay.isAtSameMomentAs(targetDay) && _selectedSources.contains(event.sourceType.toLowerCase());
    }).toList();
  }

  // Toggles the selection status of a calendar source filter.
  void toggleSource(String source) {
    if (_selectedSources.contains(source.toLowerCase())) {
      _selectedSources.remove(source.toLowerCase());
    } else {
      _selectedSources.add(source.toLowerCase());
    }
    notifyListeners(); // Rebuild widgets that depend on selectedSources
  }

  // Adds a new event to the local list and sends it to the backend.
  Future<void> addEvent(Event event, {BuildContext? context}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      if (context == null) {
        throw Exception("Context is null. Cannot access AuthProvider.");
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      if (token == null || userId == null) {
        throw Exception('Authentication required to add events.');
      }

      final response = await http.post(
        Uri.parse('${authProvider.baseUrl}/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          ...event.toJson(),
          'userId': userId, // Ensure userId is passed for association
          // If sourceType is 'custom', externalEventId should be null
          'sourceType': event.sourceType,
          'externalCalendarId': event.sourceType == 'custom' ? null : event.externalEventId,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        final newEvent = Event.fromJson(responseData['event']);
        _events.add(newEvent);
        print('Event added: ${newEvent.title}'); // Debug print
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add event.');
      }
    } catch (e) {
      _setErrorMessage('Failed to add event: ${e.toString()}');
      print('Error adding event: $e'); // Debug print
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Updates an existing event locally and sends updates to the backend.
  Future<void> updateEvent(Event updatedEvent, {BuildContext? context}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      if (context == null) {
        throw Exception("Context is null. Cannot access AuthProvider.");
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Authentication required to update events.');
      }

      final response = await http.patch( // Using PATCH for partial updates
        Uri.parse('${authProvider.baseUrl}/events/${updatedEvent.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedEvent.toJson()), // Send the full updated object
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final index = _events.indexWhere((event) => event.id == updatedEvent.id);
        if (index != -1) {
          _events[index] = Event.fromJson(responseData['event']); // Update with potentially server-modified event
        }
        print('Event updated: ${updatedEvent.title}'); // Debug print
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update event.');
      }
    } catch (e) {
      _setErrorMessage('Failed to update event: ${e.toString()}');
      print('Error updating event: $e'); // Debug print
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Deletes an event locally and from the backend.
  Future<void> deleteEvent(String eventId, {BuildContext? context}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      if (context == null) {
        throw Exception("Context is null. Cannot access AuthProvider.");
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Authentication required to delete events.');
      }

      final response = await http.delete(
        Uri.parse('${authProvider.baseUrl}/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _events.removeWhere((event) => event.id == eventId);
        print('Event deleted: $eventId'); // Debug print
      } else {
        throw Exception(responseData['message'] ?? 'Failed to delete event.');
      }
    } catch (e) {
      _setErrorMessage('Failed to delete event: ${e.toString()}');
      print('Error deleting event: $e'); // Debug print
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Updates the status of an attendee for a specific event (e.g., accept/decline invite).
  Future<void> updateAttendeeStatus(String eventId, String attendeeEmail, String newStatus, {BuildContext? context}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      if (context == null) {
        throw Exception("Context is null. Cannot access AuthProvider.");
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Authentication required to update invite status.');
      }

      final response = await http.patch(
        Uri.parse('${authProvider.baseUrl}/events/$eventId/attendees'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'attendeeEmail': attendeeEmail,
          'status': newStatus,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final updatedEvent = Event.fromJson(responseData['event']);
        final index = _events.indexWhere((event) => event.id == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
        }
        print('Attendee status updated for event: ${updatedEvent.title}'); // Debug print
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update attendee status.');
      }
    } catch (e) {
      _setErrorMessage('Failed to update invite status: ${e.toString()}');
      print('Error updating attendee status: $e'); // Debug print
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Connects an external calendar account (initiates OAuth2 flow on backend).
  Future<String?> connectExternalCalendar(String calendarType, {BuildContext? context}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      if (context == null) {
        throw Exception("Context is null. Cannot access AuthProvider.");
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      if (token == null || userId == null) {
        throw Exception('Authentication required to connect calendars.');
      }

      final response = await http.get(
        Uri.parse('${authProvider.baseUrl}/calendars/connect/$calendarType/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final authUrl = responseData['authUrl'] as String?;
        if (authUrl == null) {
          throw Exception('Authorization URL not received from backend.');
        }
        print('Received auth URL for $calendarType: $authUrl'); // Debug print
        return authUrl; // Return the URL to open in a web browser
      } else {
        throw Exception(responseData['message'] ?? 'Failed to initiate calendar connection.');
      }
    } catch (e) {
      _setErrorMessage('Failed to connect calendar: ${e.toString()}');
      print('Error connecting external calendar: $e'); // Debug print
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Refreshes a specific external calendar account.
  Future<void> refreshCalendarAccount(String accountId, {BuildContext? context}) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      if (context == null) {
        throw Exception("Context is null. Cannot access AuthProvider.");
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Authentication required to refresh calendars.');
      }

      final response = await http.post(
        Uri.parse('${authProvider.baseUrl}/calendars/refresh/$accountId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('Calendar account refreshed: $accountId'); // Debug print
        // Re-fetch all events and accounts to update UI
        await fetchEvents(context: context);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to refresh calendar account.');
      }
    } catch (e) {
      _setErrorMessage('Failed to refresh calendar account: ${e.toString()}');
      print('Error refreshing calendar account: $e'); // Debug print
    } finally {
      _setLoading(false);
    }
  }
}
