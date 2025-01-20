import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class AudioUploadWidget extends StatefulWidget {
  final ValueChanged<File> onFileSelected;
  final bool isLoading;
  final bool isRequired;
  final String? errorText;

  const AudioUploadWidget({
    super.key,
    required this.onFileSelected,
    this.isLoading = false,
    this.isRequired = false,
    this.errorText,
  });

  @override
  State<AudioUploadWidget> createState() => _AudioUploadWidgetState();
}

class _AudioUploadWidgetState extends State<AudioUploadWidget> {
  File? _selectedFile;

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final extension = result.files.first.path?.split('.').last.toLowerCase();
         if (!['wav', 'mp3', 'aac', 'm4a', 'opus'].contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid audio file (WAV, MP3, AAC, M4A, OPUS)'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
          return;
        }
        final file = File(result.files.first.path!);
        
       

        setState(() => _selectedFile = file);
        widget.onFileSelected(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong, Please make sure You have the permission to access this file'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Audio${widget.isRequired ? '*' : ''}',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: widget.isLoading ? null : _pickAudioFile,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.errorText != null ? AppTheme.errorRed : AppTheme.borderGrey,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFile != null ? Icons.audiotrack : Icons.upload_file,
                  color: _selectedFile != null ? AppTheme.primaryBlue : AppTheme.textGrey,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile?.path.split('/').last ?? 'Select Audio File',
                        style: TextStyle(
                          color: _selectedFile != null 
                              ? AppTheme.textDark 
                              : AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.errorText != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          widget.errorText!,
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 