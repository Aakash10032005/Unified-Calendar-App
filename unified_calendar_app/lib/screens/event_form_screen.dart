import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unified_calendar_app/models/event.dart';
import 'package:unified_calendar_app/models/attendee.dart';
import 'package:unified_calendar_app/providers/calendar_provider.dart';
import 'package:unified_calendar_app/providers/auth_provider.dart';
import 'package:intl/intl.dart'; // For date and time formatting

class EventFormScreen extends StatefulWidget {
  final Event? event; // Optional: If provided, this is an edit screen
  final DateTime selectedDate; // Initial date for new events

  const EventFormScreen({super.key, this.event, required this.selectedDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _attendeeEmailController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _isAllDay;
  late List<Attendee> _attendees;
  String? _selectedSourceType; // To select which calendar to save to (e.g., 'custom')

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _attendeeEmailController = TextEditingController();

    _startDate = widget.event?.startTime ?? widget.selectedDate;
    _startTime = widget.event != null
        ? TimeOfDay.fromDateTime(widget.event!.startTime)
        : TimeOfDay.now();
    _endDate = widget.event?.endTime ?? widget.selectedDate;
    _endTime = widget.event != null
        ? TimeOfDay.fromDateTime(widget.event!.endTime)
        : TimeOfDay.fromDateTime(widget.selectedDate.add(const Duration(hours: 1)));
    _isAllDay = widget.event?.isAllDay ?? false;
    _attendees = List.from(widget.event?.attendees ?? []);
    _selectedSourceType = widget.event?.sourceType ?? 'custom'; // Default to 'custom' for new events
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _attendeeEmailController.dispose();
    super.dispose();
  }

  // Function to pick a date using Flutter's date picker
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.white, // Body text color
              surface: Theme.of(context).colorScheme.surface, // Background for the picker
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Function to pick a time using Flutter's time picker
  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.white, // Body text color
              surface: Theme.of(context).colorScheme.surface, // Background for the picker
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // Function to add an attendee to the list
  void _addAttendee() {
    final email = _attendeeEmailController.text.trim();
    if (email.isNotEmpty && ! _attendees.any((a) => a.email == email)) {
      setState(() {
        _attendees.add(Attendee(email: email, status: 'pending', isOrganizer: false));
        _attendeeEmailController.clear();
      });
    } else if (email.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendee "$email" already added or invalid email.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  // Function to remove an attendee from the list
  void _removeAttendee(Attendee attendee) {
    setState(() {
      _attendees.remove(attendee);
    });
  }

  // Function to submit the event form (create or update)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // Combine date and time
    final fullStartTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final fullEndTime = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

    if (fullEndTime.isBefore(fullStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End time cannot be before start time.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    final newEvent = Event(
      id: widget.event?.id ?? '', // For new events, backend will generate ID
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text.isEmpty ? null : _locationController.text,
      startTime: fullStartTime,
      endTime: fullEndTime,
      isAllDay: _isAllDay,
      attendees: _attendees,
      sourceType: _selectedSourceType!, // Should be 'custom' for new events
      externalEventId: widget.event?.externalEventId, // Keep existing external ID if editing
    );

    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);

    try {
      if (widget.event == null) {
        // Create new event
        await calendarProvider.addEvent(newEvent, context: context);
      } else {
        // Update existing event
        await calendarProvider.updateEvent(newEvent, context: context);
      }
      Navigator.of(context).pop(); // Go back to home screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.event == null ? 'Event created successfully!' : 'Event updated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      // Refresh events on home screen to show changes
      calendarProvider.fetchEvents(context: context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context); // To get user's email for attendee status

    // Find the current user's email in the attendees list if editing an event
    final currentUserEmail = authProvider.userId; // This would typically be user.email
    final isOrganizer = _attendees.any((a) => a.email == currentUserEmail && a.isOrganizer); // Simplified

    final title = widget.event == null ? 'Create Event' : 'Edit Event';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          // Delete button only if editing an existing event
          if (widget.event != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Event',
              onPressed: () => _confirmDelete(context, calendarProvider),
            ),
        ],
      ),
      body: calendarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.event_note),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _isAllDay ? null : () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Time',
                          prefixIcon: const Icon(Icons.access_time),
                          fillColor: _isAllDay ? Colors.grey[700] : Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        child: Text(_isAllDay ? 'All Day' : _startTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _isAllDay ? null : () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Time',
                          prefixIcon: const Icon(Icons.access_time),
                          fillColor: _isAllDay ? Colors.grey[700] : Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        child: Text(_isAllDay ? 'All Day' : _endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('All Day Event', style: Theme.of(context).textTheme.bodyLarge),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) {
                      setState(() {
                        _isAllDay = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Attendees', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              // Input for adding new attendees
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _attendeeEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Attendee Email',
                        prefixIcon: Icon(Icons.person_add),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addAttendee,
                    child: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
              // List of current attendees
              if (_attendees.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150), // Limit height for scroll
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _attendees.length,
                    itemBuilder: (context, index) {
                      final attendee = _attendees[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(attendee.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () => _removeAttendee(attendee),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              // Source type selection (for custom events, only 'custom' is typically editable)
              Text('Save to Calendar', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Calendar Source',
                  prefixIcon: Icon(Icons.cloud),
                ),
                value: _selectedSourceType,
                items: calendarProvider.availableSources.map((String source) {
                  return DropdownMenuItem<String>(
                    value: source,
                    child: Text(source.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSourceType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a calendar source.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50), // Wide button
                  ),
                  child: Text(widget.event == null ? 'Create Event' : 'Update Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Confirmation dialog for deleting an event
  Future<void> _confirmDelete(BuildContext context, CalendarProvider calendarProvider) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Event'),
          content: Text('Are you sure you want to delete "${widget.event!.title}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await calendarProvider.deleteEvent(widget.event!.id, context: context);
        Navigator.of(context).pop(); // Go back from form screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${widget.event!.title}" deleted.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        calendarProvider.fetchEvents(context: context); // Refresh events on home screen
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }
}
