import 'dart:developer';

import 'package:agilemeets/data/enums/days_of_week.dart';
import 'package:agilemeets/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../data/models/create_meeting_form.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import '../../utils/app_theme.dart';
import '../../widgets/meeting/datetime_picker.dart';
import '../../widgets/meeting/timezone_selector.dart';
import '../../widgets/meeting/audio_upload_widget.dart';
import '../../widgets/meeting/member_selector_dialog.dart';
import '../../widgets/meeting/recurring_pattern_form.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../data/enums/meeting_type.dart';
import '../../data/enums/meeting_language.dart';
import '../../data/enums/recurrence_type.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../logic/cubits/project/project_state.dart';
import '../../data/models/project/project_member_dto.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class CreateMeetingScreen extends StatefulWidget {
  final String projectId;

  const CreateMeetingScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  late CreateMeetingForm _form;
  int _currentStep = 0;
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _form = CreateMeetingForm(projectId: widget.projectId);
    
    _titleController.text = _form.title ?? '';
    _goalController.text = _form.goal ?? '';
    _locationController.text = _form.location ?? '';

    // Set default timezone
    _initializeTimezone();
  }

  Future<void> _initializeTimezone() async {
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      log('Current timezone: $currentTimeZone', name: 'CreateMeetingScreen');
      setState(() {
        _form.timeZoneId = currentTimeZone;
      });
    } catch (e) {
      log('Error getting local timezone: $e', name: 'CreateMeetingScreen');
      // Fallback to a default timezone if local can't be determined
      setState(() {
        _form.timeZoneId = 'Asia/Riyadh';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<Step> get _steps => [
    Step(
      title: Text(
        'Basic Info',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Meeting details and type',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppTheme.textGrey,
        ),
      ),
      content: _buildBasicInfoStep(),
      isActive: _currentStep >= 0,
      state: _getStepState(0),
    ),
    Step(
      title: const Text('Schedule'),
      subtitle: Text(
        'Date, time and timezone',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppTheme.textGrey,
        ),
      ),
      content: _buildScheduleStep(),
      isActive: _currentStep >= 1,
      state: _getStepState(1),
    ),
    Step(
      title: const Text('Members'),
      subtitle: Text(
        'Add meeting participants',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppTheme.textGrey,
        ),
      ),
      content: _buildMembersStep(),
      isActive: _currentStep >= 2,
      state: _getStepState(2),
    ),
    Step(
      title: Text(
        'Recurring',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Set recurring pattern',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppTheme.textGrey,
        ),
      ),
      content: _buildRecurrenceStep(),
      isActive: _currentStep >= 3,
      state: _getStepState(3),
    ),
  ];

  StepState _getStepState(int step) {
    if (_currentStep > step) {
      return _validateStep(step) ? StepState.complete : StepState.error;
    }
    return StepState.indexed;
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _form.title?.isNotEmpty == true &&
               (_form.type.isImplemented) &&
               (_form.type != MeetingType.done || _form.audioFile != null);
      case 1:
        return _form.startTime != null &&
               _form.endTime != null &&
               _form.timeZoneId != null &&
               !_form.startTime!.isAfter(_form.endTime!);
      case 2:
        return _form.memberIds.isNotEmpty;
      case 3:
        if (_form.type == MeetingType.done) return true;
        if (!_form.isRecurring) return true;
        return _form.recurringPattern != null &&
               (_form.recurringPattern!.recurrenceType != RecurrenceType.weekly ||
                _form.recurringPattern!.daysOfWeek.value != 0);
      default:
        return true;
    }
  }

  Widget _buildBasicInfoStep() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Title*',
              hint: 'Enter meeting title',
              prefixIcon: Icons.title_outlined,
              onChanged: (value) => setState(() => _form.title = value),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _goalController,
              label: 'Goal',
              hint: 'Enter meeting goal',
              prefixIcon: Icons.flag_outlined,
              maxLines: 3,
              onChanged: (value) => setState(() => _form.goal = value),
            ),
            SizedBox(height: 16.h),
            _buildLanguageSelector(),
            SizedBox(height: 16.h),
            _buildTypeSelector(),
            if (_form.type == MeetingType.done) ...[
              SizedBox(height: 16.h),
              AudioUploadWidget(
                onFileSelected: (file) {
                  setState(() => _form.audioFile = file);
                },
                isRequired: true,
                errorText: _form.type == MeetingType.done && _form.audioFile == null
                    ? 'Audio file is required for past meetings'
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language*',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardGrey,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonFormField<MeetingLanguage>(
            value: _form.language,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.language_outlined, size: 20.w),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            items: MeetingLanguage.values.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(lang.label),
              );
            }).toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _form.language = value);
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Type*',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardGrey,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppTheme.cardBorderGrey),
          ),
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              _buildTypeOption(
                type: MeetingType.inPerson,
                description: 'Schedule an in-person meeting',
              ),
              SizedBox(height: 8.h),
              _buildTypeOption(
                type: MeetingType.online,
                description: 'Host a virtual meeting (Coming Soon)',
                isDisabled: true,
              ),
              SizedBox(height: 8.h),
              _buildTypeOption(
                type: MeetingType.done,
                description: 'Record a past meeting with audio',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required MeetingType type,
    required String description,
    bool isDisabled = false,
  }) {
    final isSelected = _form.type == type;
    
    return InkWell(
      onTap: isDisabled ? null : () => setState(() => _form.type = type),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.grey.withOpacity(0.1)
              : isSelected 
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryBlue
                : AppTheme.cardBorderGrey,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.1)
                    : isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.1)
                        : AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                type.icon,
                color: isDisabled
                    ? Colors.grey
                    : isSelected 
                        ? AppTheme.primaryBlue
                        : AppTheme.textGrey,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? Colors.grey
                          : isSelected 
                              ? AppTheme.primaryBlue
                              : AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDisabled
                          ? Colors.grey
                          : AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled)
              Icon(
                Icons.check_circle,
                color: isSelected 
                    ? AppTheme.primaryBlue
                    : Colors.transparent,
                size: 20.w,
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildScheduleStep() {
    final now = DateTime.now();
    final isStartNow = _form.startTime?.day == now.day && 
                       _form.startTime?.month == now.month && 
                       _form.startTime?.year == now.year &&
                       _form.startTime?.hour == now.hour &&
                       _form.startTime?.minute == now.minute;

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_form.type == MeetingType.done) ...[
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.cardBorderGrey),
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When did this meeting happen?',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: DateTimePicker(
                          label: 'Start Time*',
                          value: _form.startTime,
                          meetingType: _form.type,
                          minDate: null,
                          maxDate: DateTime.now(),
                          onChanged: (value) {
                            setState(() {
                              _form.startTime = value;
                              if (_form.endTime == null || _form.endTime!.isBefore(value)) {
                                _form.endTime = value.add(const Duration(hours: 1));
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: DateTimePicker(
                          label: 'End Time*',
                          value: _form.endTime,
                          minDate: _form.startTime,
                          maxDate: DateTime.now(),
                          onChanged: (value) {
                            setState(() => _form.endTime = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.cardBorderGrey),
              ),
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Meeting will start immediately',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: isStartNow,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (value) async {
                      if (value) {
                        final now = DateTime.now();
                        String timezone;
                        try {
                          timezone = await FlutterTimezone.getLocalTimezone();
                          log('Current timezone: $timezone', name: 'CreateMeetingScreen');
                        } catch (e) {
                          log('Error getting local timezone: $e', name: 'CreateMeetingScreen');
                          timezone = 'Asia/Riyadh';
                        }
                        
                        setState(() {
                          _form.startTime = now;
                          _form.endTime = now.add(const Duration(hours: 1));
                          _form.reminderTime = now;
                          _form.timeZoneId = timezone;
                        });
                      } else {
                        setState(() {
                          _form.startTime = null;
                          _form.endTime = null;
                          _form.reminderTime = null;
                          _form.timeZoneId = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            if (!isStartNow) ...[
              SizedBox(height: 24.h),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardGrey,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.cardBorderGrey),
                ),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: DateTimePicker(
                            label: 'Start Time*',
                            value: _form.startTime,
                            meetingType: _form.type,
                            minDate: _form.type == MeetingType.done 
                                ? null 
                                : DateTime.now(),
                            onChanged: (value) {
                              setState(() {
                                _form.startTime = value;
                                if (_form.endTime == null || _form.endTime!.isBefore(value)) {
                                  _form.endTime = value.add(const Duration(hours: 1));
                                }
                                _form.reminderTime = value.subtract(const Duration(minutes: 15));
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: DateTimePicker(
                            label: 'End Time*',
                            value: _form.endTime,
                            minDate: _form.startTime,
                            minTime: _form.startTime,
                            onChanged: (value) {
                              setState(() => _form.endTime = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],

          SizedBox(height: 24.h),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.cardBorderGrey),
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _form.type == MeetingType.done ? 'Meeting Time Zone' : 'Time Zone',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 16.h),
                TimeZoneSelector(
                  value: _form.timeZoneId ?? 'Asia/Riyadh',
                  onChanged: (value) {
                    setState(() => _form.timeZoneId = value);
                  },
                ),
              ],
            ),
          ),

          if (_form.type == MeetingType.inPerson) ...[
            SizedBox(height: 24.h),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.cardBorderGrey),
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: _locationController,
                    label: 'Location*',
                    hint: 'Enter meeting location',
                    prefixIcon: Icons.location_on_outlined,
                    onChanged: (value) => setState(() => _form.location = value),
                    validator: (value) {
                      if (_form.type == MeetingType.inPerson && 
                          (value?.isEmpty ?? true)) {
                        return 'Location is required for in-person meetings';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersStep() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meeting Members*',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: _showMemberSelector,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (_form.memberIds.isEmpty)
              Center(
                child: Text(
                  'No members selected',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 14.sp,
                  ),
                ),
              )
            else
              BlocBuilder<ProjectCubit, ProjectState>(
                builder: (context, state) {
                  final members = state.projectMembers;
                  
                  if (members == null) {
                    return const Center(child: LoadingIndicator());
                  }
                  
                  return Column(
                    children: _form.memberIds.map((memberId) {
                      final member = members.firstWhere(
                        (m) => m.memberId == memberId,
                        orElse: () => ProjectMemberDTO(
                          userId: '',
                          memberId: memberId,
                          name: 'Unknown Member',
                          email: '',
                          isAdmin: false,
                          meetings: 'None',
                          members: 'None',
                          requirements: 'None',
                          tasks: 'None',
                          settings: 'None',
                        ),
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                          child: Text(
                            member.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(member.name),
                        subtitle: Text(
                          member.email,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              _form.memberIds.remove(memberId);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceStep() {
    if (_form.type == MeetingType.done) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.textGrey,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Recurring meetings are not available for past meetings',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Make this a recurring meeting?',
                  style: TextStyle(
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(
                  height: 0.1.sw,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Switch(
                      value: _form.isRecurring,
                      onChanged: (v) => setState(() => _form.isRecurring = v),
                    ),
                  ),
                ),
              ],
            ),
            if (_form.isRecurring) ...[
              SizedBox(height: 16.h),
              RecurringPatternForm(
                pattern: _form.recurringPattern ?? RecurringMeetingPattern(
                  recurrenceType: RecurrenceType.daily,
                  interval: 1,
                  recurringEndDate: DateTime.now().add(const Duration(days: 7)),
                  daysOfWeek: const DaysOfWeek(0),
                ),
                onChanged: (pattern) {
                  setState(() => _form.recurringPattern = pattern);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showMemberSelector() async {
    final selectedMembers = await showDialog<List<String>>(
      context: context,
      builder: (context) => MemberSelectorDialog(
        selectedMemberIds: _form.memberIds,
        projectId: _form.projectId,
      ),
    );

    if (selectedMembers != null) {
      setState(() => _form.memberIds = selectedMembers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingCubit, MeetingState>(
      listenWhen: (previous, current) => 
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == MeetingStateStatus.created) {
          Navigator.pop(context, true);
        } else if (state.status == MeetingStateStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Failed to create meeting'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
          setState(() => _isSubmitting = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Create Meeting',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            
              if (_currentStep == _steps.length - 1)
                Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: FilledButton(
                  onPressed: _isSubmitting ? null : () {
                    log('Form start time: ${_form.startTime}', name: 'CreateMeetingScreen');
                    if ((_form.startTime?.isAfter(DateTime.now()) ?? true) || 
                        _form.type == MeetingType.done) {
                      log('Submitting meeting', name: 'CreateMeetingScreen');
                      _submit();
                    } else {
                      log('Setting start time to now', name: 'CreateMeetingScreen');
                      var duration = _form.endTime!.difference(_form.startTime!);
                      _form.startTime = DateTime.now();
                      _form.reminderTime = DateTime.now();
                      _form.endTime = DateTime.now().add(duration);
                      log('Submitting meeting', name: 'CreateMeetingScreen');
                      _submit();
                    }
                  },
                  child: _isSubmitting 
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_form.startTime?.isAfter(DateTime.now()) ?? true 
                          ? 'Create' 
                          : 'Start'),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primaryBlue,
              ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_validateStep(_currentStep)) {
                  if (_currentStep < _steps.length - 1) {
                    setState(() => _currentStep++);
                  } else {
                    _submit();
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              onStepTapped: (step) {
                if (step < _currentStep || _validateStep(_currentStep)) {
                  setState(() => _currentStep = step);
                }
              },
              steps: _steps,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentStep > 0)
                        SizedBox(width: 16.w),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : () {
                            if (_currentStep < _steps.length - 1) {
                              details.onStepContinue?.call();
                            } else {
                              log('Form start time: ${_form.startTime}', name: 'CreateMeetingScreen');
                              if ((_form.startTime?.isAfter(DateTime.now()) ?? true) || 
                                  _form.type == MeetingType.done) {
                                log('Submitting meeting', name: 'CreateMeetingScreen');
                                _submit();
                              } else {
                                log('Setting start time to now', name: 'CreateMeetingScreen');
                                var duration = _form.endTime!.difference(_form.startTime!);
                                _form.startTime = DateTime.now();
                                _form.reminderTime = DateTime.now();
                                _form.endTime = DateTime.now().add(duration);
                                log('Submitting meeting', name: 'CreateMeetingScreen');
                                _submit();
                              }
                            }
                          },
                          child: Text(
                            _currentStep < _steps.length - 1 
                                ? 'Next' 
                                : (_form.startTime?.isAfter(DateTime.now()) ?? true 
                                    ? 'Create' 
                                    : 'Start'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      if (_form.isValid) {
        setState(() => _isSubmitting = true);
        
        context.read<MeetingCubit>().createMeeting(
          title: _form.title!,
          goal: _form.goal,
          language: _form.language.value,
          type: _form.type.value,
          startTime: _form.startTime!,
          endTime: _form.endTime!,
          timeZone: _form.timeZoneId!,
          projectId: _form.projectId,
          memberIds: _form.memberIds,
          location: _form.location,
          reminderTime: _form.reminderTime,
          audioFile: _form.audioFile,
          isRecurring: _form.isRecurring,
          recurringPattern: _form.isRecurring ? {
            'recurrenceType': _form.recurringPattern!.recurrenceType.value,
            'interval': _form.recurringPattern!.interval,
            'recurringEndDate': _form.recurringPattern!.recurringEndDate.toIso8601String(),
            'daysOfWeek': _form.recurringPattern!.daysOfWeek.value,
          } : null,
        );
      }
    }
  }
}
