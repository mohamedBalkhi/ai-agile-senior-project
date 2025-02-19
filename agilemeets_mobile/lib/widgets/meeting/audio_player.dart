import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/app_theme.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import 'dart:developer' as dev;

class MeetingAudioPlayer extends StatefulWidget {
  final String? meetingId;
  final String? audioUrl;
  final String? filePath;

  const MeetingAudioPlayer({
    super.key,
    this.meetingId,
    this.audioUrl,
  }) : filePath = null;

  const MeetingAudioPlayer.fromFile({
    super.key,
    required this.filePath,
  }) : meetingId = null,
       audioUrl = null;

  @override
  State<MeetingAudioPlayer> createState() => _MeetingAudioPlayerState();
}

class _MeetingAudioPlayerState extends State<MeetingAudioPlayer>
    with AutomaticKeepAliveClientMixin {
  late final AudioPlayer _player;
  final ValueNotifier<double> _playbackSpeed = ValueNotifier<double>(1.0);
  String? _error;
  bool _isDownloading = false;
  String? _audioUrl;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _cachedFilePath;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer(
      audioLoadConfiguration: const AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferDuration: Duration(seconds: 15),
          maxBufferDuration: Duration(minutes: 2),
          bufferForPlaybackDuration: Duration(seconds: 5),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 10),
        ),
        darwinLoadControl: DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(minutes: 1),
        ),
      ),
    );

    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
        if (mounted) {
          setState(() {});
        }
      }
    });

    _initAudioPlayer();
  }

  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.last;
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }

  String _getCacheFileName(String meetingId, String extension) {
    return '$meetingId.$extension';
  }

  Future<String?> _getCachedFilePath(String meetingId, String extension) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final filePath =
          '${cacheDir.path}/audio_cache/${_getCacheFileName(meetingId, extension)}';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      dev.log('Error checking cache: $e', name: 'MeetingAudioPlayer');
      return null;
    }
  }

  Future<String> _cacheFile(String meetingId, String extension) async {
    final cacheDir = await getTemporaryDirectory();
    final cacheFolder = Directory('${cacheDir.path}/audio_cache');
    if (!await cacheFolder.exists()) {
      await cacheFolder.create(recursive: true);
    }
    final filePath =
        '${cacheFolder.path}/${_getCacheFileName(meetingId, extension)}';
    return filePath;
  }

  Future<void> _initAudioPlayer() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      dev.log('Initializing audio player', name: 'MeetingAudioPlayer');

      if (widget.filePath != null) {
        dev.log('Loading audio from file: ${widget.filePath}');
        await _player.setFilePath(widget.filePath!);
      } else if (widget.audioUrl != null) {
        dev.log('Loading audio from URL: ${widget.audioUrl}');
        await _player.setUrl(widget.audioUrl!);
        _audioUrl = widget.audioUrl;
      } else if (widget.meetingId != null) {
        final audioUrl = await context.read<MeetingCubit>().getMeetingAudioUrl(widget.meetingId!);
        if (!mounted) return;

        final extension = _getFileExtension(audioUrl);
        dev.log('File extension: $extension', name: 'MeetingAudioPlayer');

        // Check if we have a cached version
        final cachedPath = await _getCachedFilePath(widget.meetingId!, extension);
        if (cachedPath != null) {
          dev.log('Using cached audio file: $cachedPath', name: 'MeetingAudioPlayer');
          _cachedFilePath = cachedPath;
          await _player.setFilePath(cachedPath);
        } else {
          dev.log('Setting audio source: $audioUrl', name: 'MeetingAudioPlayer');

          // Prepare cache file path
          final cacheFilePath = await _cacheFile(widget.meetingId!, extension);
          
          _cachedFilePath = cacheFilePath;

          await _player.setUrl(audioUrl);
        }
        _audioUrl = audioUrl;
      } else {
        dev.log('No audio source provided');
        return;
      }

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      dev.log('Audio source set successfully', name: 'MeetingAudioPlayer');
    } catch (e, stackTrace) {
      dev.log('Error initializing audio player: $e\n$stackTrace',
          name: 'MeetingAudioPlayer');
      if (mounted) {
        setState(() {
          _error = 'Failed to load audio. Please try downloading instead.';
          _isInitialized = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAudio() async {
    if (_isDownloading || widget.meetingId == null) return;

    try {
      setState(() {
        _isDownloading = true;
        _error = null;
      });

      final extension = _getFileExtension(_audioUrl!);
      final cachedPath = await _getCachedFilePath(widget.meetingId!, extension);

      String? filePath;
      if (cachedPath != null && File(cachedPath).existsSync()) {
        filePath = await context.read<MeetingCubit>().downloadMeetingAudio(
              widget.meetingId!,
              cachedFile: cachedPath,
            );
      } else {
        filePath = await context.read<MeetingCubit>().downloadMeetingAudio(
          widget.meetingId!,
        );
      }

      if (!mounted) return;

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 5),
            content: Text('Audio saved successfully'),
          ),
        );
      } else {
        throw Exception('Failed to download audio');
      }
    } catch (e) {
      dev.log('Error downloading audio: $e', name: 'MeetingAudioPlayer');
      if (mounted) {
        setState(() => _error = 'Failed to download audio');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download audio. Please try again.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                _buildErrorWidget()
              else if (_isLoading || !_isInitialized)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 40.w,
                          height: 40.h,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 8.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardGrey,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                height: 8.h,
                                width: 150.w,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardGrey,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.meetingId != null) ...[
                          SizedBox(width: 16.w),
                          Icon(
                            Icons.download,
                            color: AppTheme.textGrey,
                            size: 24.w,
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              else ...[
                _buildProgressBar(),
                SizedBox(height: 8.h),
                _buildPlayerControls(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Icon(Icons.error_outline, color: AppTheme.errorRed, size: 24.w),
        SizedBox(height: 8.h),
        Text(
          _error ?? 'An error occurred',
          style: TextStyle(
            color: AppTheme.errorRed,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: _initAudioPlayer,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildPlayerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPlayPauseButton(),
        PopupMenuButton<double>(
          icon: const Icon(Icons.speed),
          onOpened: _isInitialized ? null : () {},
          onSelected: (speed) {
            _player.setSpeed(speed);
            _playbackSpeed.value = speed;
          },
          itemBuilder: (context) => [
            _buildSpeedMenuItem(0.5),
            _buildSpeedMenuItem(0.75),
            _buildSpeedMenuItem(1.0),
            _buildSpeedMenuItem(1.25),
            _buildSpeedMenuItem(1.5),
            _buildSpeedMenuItem(2.0),
          ],
        ),
        if (widget.meetingId != null)
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  )
                : Icon(
                    Icons.download,
                    color: _isInitialized ? AppTheme.primaryBlue : AppTheme.textGrey,
                  ),
            onPressed: _isInitialized && !_isDownloading ? _downloadAudio : null,
          ),
      ],
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double speed) {
    return PopupMenuItem(
      value: speed,
      child: ValueListenableBuilder<double>(
        valueListenable: _playbackSpeed,
        builder: (context, currentSpeed, child) {
          return Row(
            children: [
              if ((currentSpeed - speed).abs() < 0.01)
                const Icon(Icons.check, size: 16)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text('${speed}x'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero;
            if (position > duration) {
              position = duration;
            }
            return ProgressBar(
              progress: position,
              buffered: _player.bufferedPosition,
              total: duration,
              onSeek: (duration) {
                _player.seek(duration);
              },
              baseBarColor: AppTheme.cardGrey,
              progressBarColor: AppTheme.primaryBlue,
              bufferedBarColor: AppTheme.cardGrey.withOpacity(0.5),
              thumbColor: AppTheme.primaryBlue,
              barHeight: 3.0,
              thumbRadius: 5.0,
              timeLabelTextStyle: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 12.sp,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayPauseButton() {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 24.w,
            height: 24.w,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return IconButton(
            icon: const Icon(Icons.play_arrow),
            iconSize: 24.w,
            onPressed: _player.play,
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.pause),
            iconSize: 24.w,
            onPressed: _player.pause,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
