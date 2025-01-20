import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/requirements/req_dto.dart';
import '../../data/enums/req_priority.dart';
import '../../data/enums/requirements_status.dart';
import '../../utils/app_theme.dart';
import '../custom_text_field.dart';

class CreateRequirementsBottomSheet extends StatefulWidget {
  /// The project ID
  final String projectId;
  
  /// Whether the bottom sheet is in loading state
  final bool isLoading;
  
  /// Callback when requirements are submitted
  final ValueChanged<List<ReqDTO>> onSubmit;
  
  /// Callback when a file is uploaded
  final Future<void> Function(String) onFileUpload;
  
  /// Callback when a file is uploaded in web platform
  final void Function(List<int> bytes, String fileName)? onWebFileUpload;

  const CreateRequirementsBottomSheet({
    super.key,
    required this.projectId,
    required this.onSubmit,
    required this.onFileUpload,
    this.onWebFileUpload,
    this.isLoading = false,
  });

  @override
  State<CreateRequirementsBottomSheet> createState() => _CreateRequirementsBottomSheetState();
}

class _CreateRequirementsBottomSheetState extends State<CreateRequirementsBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ReqDTO> _requirements = [];
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for the current requirement being edited
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ReqPriority _priority = ReqPriority.medium;
  RequirementStatus _status = RequirementStatus.newOne;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // Only handle completed tab changes
    if (!_tabController.indexIsChanging) {
      return;
    }

    final newIndex = _tabController.index;
    final oldIndex = _tabController.previousIndex;

    if (_requirements.isNotEmpty) {
      // Prevent tab change
      _tabController.removeListener(_handleTabChange);
      _tabController.index = oldIndex;
      _tabController.addListener(_handleTabChange);
      
      // Show warning dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Requirements'),
          content: const Text(
            'You have unsaved requirements. Do you want to discard them?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _requirements.clear();
                  _tabController.removeListener(_handleTabChange);
                  _tabController.index = newIndex;
                  _tabController.addListener(_handleTabChange);
                });
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ).animate().fadeIn(),

          // Header with actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Requirements',
                    style: AppTheme.headingMedium,
                  ).animate().fadeIn().slideX(begin: -0.2),
                ),
                if (widget.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_requirements.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _submitRequirements,
                    icon: const Icon(Icons.check),
                    label: Text('Add ${_requirements.length}'),
                  ).animate().fadeIn().slideX(begin: 0.2),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Manual'),
              Tab(text: 'File'),
            ],
          ).animate().fadeIn().slideY(begin: -0.2),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildManualEntry(),
                _buildFileUpload(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return Column(
      children: [
        // Form at the top
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Enter requirement title',
                    prefixIcon: Icons.title_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter requirement description',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  SizedBox(height: 24.h),
                  _buildPrioritySelector(),
                  SizedBox(height: 24.h),
                  _buildStatusSelector(),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _addRequirement();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Requirement'),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),

        // Added Requirements List at the bottom
        if (_requirements.isNotEmpty) ...[
          Divider(height: 32.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Added Requirements',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_requirements.length}',
                  style: AppTheme.subtitle.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: _requirements.length,
              itemBuilder: (context, index) {
                final req = _requirements[index];
                return Dismissible(
                  key: ValueKey(req.hashCode),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16.w),
                    color: Colors.red.shade100,
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 24.sp,
                    ),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _requirements.removeAt(index);
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: ListTile(
                      leading: Icon(
                        _getPriorityIcon(req.priority),
                        color: req.priority.color,
                      ),
                      title: Text(req.title),
                      subtitle: req.description != null 
                          ? Text(
                              req.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    ),
                  ),
                ).animate().fadeIn().slideX();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: AppTheme.bodyText,
        ).animate().fadeIn(delay: 300.ms),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          children: ReqPriority.values.map((priority) => InkWell(
            onTap: () => setState(() => _priority = priority),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _priority == priority 
                    ? priority.color.withOpacity(0.1)
                    : AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _priority == priority ? priority.color : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPriorityIcon(priority), 
                       size: 16.sp,
                       color: _priority == priority ? priority.color : AppTheme.textGrey),
                  SizedBox(width: 4.w),
                  Text(priority.label,
                       style: TextStyle(
                         color: _priority == priority ? priority.color : AppTheme.textGrey,
                         fontSize: 14.sp,
                       )),
                ],
              ),
            ),
          )).toList(),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: AppTheme.bodyText,
        ).animate().fadeIn(delay: 500.ms),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardGrey,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: RequirementStatus.values.map((status) {
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _status = status),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 8.w,
                    ),
                    decoration: BoxDecoration(
                      color: _status == status
                          ? status.color.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: _status == status
                            ? status.color
                            : AppTheme.textGrey,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      children: [
        SizedBox(height: 48.h),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: AppTheme.cardGrey,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.cardBorderGrey,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: 48.sp,
                color: AppTheme.textGrey,
              ),
              SizedBox(height: 16.h),
              Text(
                'Upload Requirements File',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Drag and drop or click to select a file',
                style: AppTheme.subtitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.add),
                label: const Text('Select File'),
              ),
            ],
          ),
        ).animate().fadeIn().scale(delay: 200.ms),
        SizedBox(height: 24.h),
        TextButton.icon(
          onPressed: () {
            // TODO: Implement template download
          },
          icon: const Icon(Icons.download),
          label: const Text('Download Template'),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  void _addRequirement() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _requirements.add(ReqDTO(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          priority: _priority,
          status: _status,
        ));
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _priority = ReqPriority.medium;
        _status = RequirementStatus.newOne;
      });
    }
  }

  void _submitRequirements() {
    if (_requirements.isNotEmpty) {
      widget.onSubmit(_requirements);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
        withData: true,
        withReadStream: true,
      );

      if (result != null) {
        if (result.files.single.path != null) {
          await widget.onFileUpload(result.files.single.path!);
        } else if (result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          final fileName = result.files.single.name;
          widget.onWebFileUpload?.call(bytes, fileName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  IconData _getPriorityIcon(ReqPriority priority) {
    switch (priority) {
      case ReqPriority.low:
        return Icons.arrow_downward;
      case ReqPriority.medium:
        return Icons.remove;
      case ReqPriority.high:
        return Icons.arrow_upward;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 