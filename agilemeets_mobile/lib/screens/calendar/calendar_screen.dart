import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:io'; // For Platform check
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'dart:convert';

import '../../logic/cubits/calendar/calendar_cubit.dart';

class CalendarScreen extends StatefulWidget {
  final String? projectId;

  const CalendarScreen({
    super.key,
    this.projectId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalendarFeed();
  }

  Future<void> _loadCalendarFeed() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final timeZoneId = await FlutterTimezone.getLocalTimezone();
      final feedUrl = await context.read<CalendarCubit>().getCalendarFeedUrl(
        projectId: widget.projectId,
      );
      final encodedTimeZone = Uri.encodeComponent(timeZoneId);
      final feedUrlWithTimeZone = '$feedUrl/$encodedTimeZone';
      print('Feed URL with time zone: $feedUrlWithTimeZone');
      
      final response = await http.get(Uri.parse(feedUrlWithTimeZone));
      if (response.statusCode == 200) {
        final icalData = response.body;
        print('iCal Data: $icalData'); // Debug print
        
        // Preprocess the iCal data to handle IN-PROGRESS status
        final processedIcalData = icalData.replaceAll(
          RegExp(r'STATUS:IN-PROGRESS(\r\n|\r|\n)'),
          'STATUS:CONFIRMED\r\n'
        );
        
        final iCalendar = ICalendar.fromString(processedIcalData);
        print('Parsed Calendar: ${iCalendar.data}'); // Debug print
        
        final events = <DateTime, List<Map<String, dynamic>>>{};
        
        for (final event in iCalendar.data) {
          print('Processing event: $event'); // Debug print
          
          if (event['type'] != 'VEVENT') continue;
          
          // Restore the original status if it was IN-PROGRESS
          if (event['status'] == 'CONFIRMED' && 
              icalData.contains('STATUS:IN-PROGRESS')) {
            event['status'] = 'IN-PROGRESS';
          }
          
          final startDate = event['dtstart'];
          print('Start date: $startDate'); // Debug print
          
          if (startDate != null) {
            DateTime? dateTime;
            
            if (startDate is IcsDateTime) {
              dateTime = startDate.toDateTime();
            } else if (startDate is Map) {
              final dt = startDate['dt'];
              if (dt is String) {
                dateTime = _parseDateTime(dt, startDate['tzid'] as String?);
              }
            } else if (startDate is String) {
              dateTime = _parseDateTime(startDate, null);
            }
            
            print('Parsed dateTime: $dateTime'); // Debug print
            
            if (dateTime != null) {
              final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
              events[day] = [...(events[day] ?? []), event];
              print('Added event for day: $day'); // Debug print
            }
          }
        }

        if (mounted) {
          setState(() {
            _events = events;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load calendar feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading calendar: $e'); // Debug print
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load calendar. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  DateTime? _parseDateTime(String dt, String? tzid) {
    try {
      // Handle UTC format
      if (dt.endsWith('Z')) {
        return DateTime.parse(dt.substring(0, dt.length - 1)).toLocal();
      }
      
      // Handle basic format without time
      if (dt.length == 8) {
        return DateTime.parse('${dt.substring(0, 4)}-${dt.substring(4, 6)}-${dt.substring(6, 8)}');
      }
      
      // Handle full format with time
      if (dt.length >= 15) {
        return DateTime.parse(
          '${dt.substring(0, 4)}-${dt.substring(4, 6)}-${dt.substring(6, 8)}T${dt.substring(9, 11)}:${dt.substring(11, 13)}:${dt.substring(13, 15)}'
        ).toLocal();
      }
      
      return null;
    } catch (e) {
      print('Error parsing date: $e'); // Debug print
      return null;
    }
  }
  Future<void> _handleCalendarExport() async {
    try {
      final feedUrl = await context.read<CalendarCubit>().getCalendarFeedUrl(
        projectId: widget.projectId,
      );
      final timeZoneId =await  FlutterTimezone.getLocalTimezone();
      final encodedTimeZone = Uri.encodeComponent(timeZoneId);
      final feedUrlWithTimeZone = '$feedUrl/$encodedTimeZone';

      // Download the iCal file
      final response = await http.get(Uri.parse(feedUrlWithTimeZone));
      if (response.statusCode != 200) {
        throw Exception('Failed to download calendar file');
      }

      // Get temporary directory to save the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/calendar.ics';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      // Open calendar file based on platform
      if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        final authority = "${packageInfo.packageName}.fileprovider";
        final contentUri = Uri.parse(
          'content://$authority/shared_cache/calendar.ics'
        );

        final intent = AndroidIntent(
          action: 'action_view',
          data: contentUri.toString(),
          type: 'text/calendar',
          flags: [
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_GRANT_READ_URI_PERMISSION,
          ],
        );
        await intent.launch();
      } else {
        // iOS handling
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception('Failed to open calendar file: ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error exporting calendar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export calendar. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _decodeText(String text) {
    try {
      // First try UTF-8 decoding
      return utf8.decode(text.runes.toList());
    } catch (e) {
      try {
        // If UTF-8 fails, try decoding the escaped unicode
        return text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
          return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
        });
      } catch (e) {
        // If all decoding fails, return original text
        return text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _loadCalendarFeed,
            tooltip: 'Refresh Calendar',
          ),
          IconButton(
            icon: Icon(
              Platform.isAndroid ? Icons.calendar_month : Icons.ios_share,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _handleCalendarExport,
            tooltip: 'Export Calendar',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _loadCalendarFeed,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCalendarFeed,
              child: ListView(
                children: [
                  TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                  ),
                  const Divider(),
                  if (_selectedDay == null)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Text(
                          'Select a day to view meetings',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      _getEventsForDay(_selectedDay!).length,
                      (index) {
                        final event = _getEventsForDay(_selectedDay!)[index];
                        
                        // Extract meeting type from description
                        String? meetingType;
                        if (event['description'] != null) {
                          final description = _decodeText(event['description'].toString());
                          final typeMatch = RegExp(r'Type: (\w+)').firstMatch(description);
                          if (typeMatch != null) {
                            meetingType = typeMatch.group(1);
                          }
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          child: ListTile(
                            leading: Icon(
                              _getMeetingTypeIcon(meetingType),
                              color: _getMeetingTypeColor(meetingType, context),
                            ),
                            title: Text(_decodeText(event['summary']?.toString() ?? '')),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatTime(event['dtstart'])} - ${_formatTime(event['dtend'])}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(event['status']),
                                      size: 16.sp,
                                      color: _getStatusColor(event['status'], context),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _formatStatus(event['status']),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _getStatusColor(event['status'], context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (event['description'] != null) ..._formatDescription(
                                  _decodeText(event['description'].toString()),
                                  context,
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16.sp,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: Theme.of(context).textTheme.bodySmall,
                                          children: [
                                            TextSpan(
                                              text: 'Organizer: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            TextSpan(
                                              text: _getOrganizer(event['organizer']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              final meetingId = event['uid']?.toString();
                              if (meetingId != null) {
                                Navigator.pushNamed(
                                  context,
                                  '/meetings/details/',
                                  arguments: meetingId,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return '';
    
    DateTime? parsedDateTime;
    
    if (dateTime is IcsDateTime) {
      parsedDateTime = dateTime.toDateTime();
    } else if (dateTime is Map) {
      final dt = dateTime['dt'];
      if (dt is String) {
        parsedDateTime = _parseDateTime(dt, dateTime['tzid'] as String?);
      }
    } else if (dateTime is String) {
      parsedDateTime = _parseDateTime(dateTime, null);
    }
    
    if (parsedDateTime == null) return '';
    
    return DateFormat('HH:mm').format(parsedDateTime);
  }

  IconData _getMeetingTypeIcon(String? type) {
    print('Meeting type: $type');
    switch (type?.toLowerCase()) {
      case 'online':
        return Icons.video_camera_front;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }

  Color _getMeetingTypeColor(String? type, BuildContext context) {
    switch (type?.toLowerCase()) {
      case 'online':
        return Theme.of(context).colorScheme.primary;
      case 'done':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getOrganizer(dynamic organizer) {
    if (organizer == null) return 'No organizer';
    
    if (organizer is Map) {
      String displayText = '';
      
      if (organizer.containsKey('name')) {
        displayText = organizer['name'].toString();
      }
      
      if (organizer.containsKey('mail')) {
        final email = organizer['mail'].toString().replaceFirst('mailto:', '');
        if (displayText.isNotEmpty) {
          displayText += ' • ';
        }
        displayText += email;
      }
      
      return displayText.isNotEmpty ? displayText : 'Unknown organizer';
    }
    
    return 'Unknown organizer';
  }

  List<Widget> _formatDescription(String description, BuildContext context) {
    final lines = description.split('\\n');
    final widgets = <Widget>[];
    
    Map<String, String> details = {};
    
    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          details[key] = value;
        }
      }
    }
    
    // Format the details in a more organized way
    if (details.containsKey('Goal')) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Row(
            children: [
              Icon(
                Icons.flag,
                size: 16.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  details['Goal']!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final infoWidgets = <Widget>[];
    
    if (details.containsKey('Type')) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              details['Type']?.toLowerCase() == 'online' 
                ? Icons.video_camera_front 
                : details['Type']?.toLowerCase() == 'done'
                  ? Icons.check_circle
                  : Icons.event,
              size: 16.sp,
              color: details['Type']?.toLowerCase() == 'done'
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 4.w),
            Text(
              details['Type']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: details['Type']?.toLowerCase() == 'done'
                  ? Colors.green
                  : null,
              ),
            ),
          ],
        ),
      );
    }
    
    if (details.containsKey('Language')) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 16.sp, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 4.w),
            Text(
              details['Language']!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    
    if (details.containsKey('Members')) {
      infoWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group, size: 16.sp, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                details['Members']!,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    
    if (infoWidgets.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            children: infoWidgets,
          ),
        ),
      );
    }
    
    return widgets;
  }

  IconData _getStatusIcon(dynamic status) {
    if (status == null) return Icons.help_outline;
    
    final statusStr = status.toString().toLowerCase();
    if (statusStr == 'in-progress') return Icons.play_circle;
    if (statusStr.contains('completed')) return Icons.check_circle;
    if (statusStr.contains('confirmed')) return Icons.event_available;
    if (statusStr.contains('cancelled')) return Icons.event_busy;
    return Icons.schedule; // For TENTATIVE
  }

  Color _getStatusColor(dynamic status, BuildContext context) {
    if (status == null) return Theme.of(context).colorScheme.primary;
    
    final statusStr = status.toString().toLowerCase();
    if (statusStr == 'in-progress') return Colors.orange;
    if (statusStr.contains('completed')) return Colors.green;
    if (statusStr.contains('confirmed')) return Theme.of(context).colorScheme.primary;
    if (statusStr.contains('cancelled')) return Theme.of(context).colorScheme.error;
    return Colors.grey; // For TENTATIVE
  }

  String _formatStatus(dynamic status) {
    if (status == null) return 'Unknown';
    
    final statusStr = status.toString().toLowerCase();
    
    // Clean up the status string by removing IcsStatus prefix if present
    String cleanStatus = statusStr.replaceAll('icsstatus.', '');
    
    switch (cleanStatus) {
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'tentative':
        return 'Tentative';
      default:
        // Convert any other status to Title Case
        return cleanStatus.split(RegExp(r'[_\-\s]+')).map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }
} 