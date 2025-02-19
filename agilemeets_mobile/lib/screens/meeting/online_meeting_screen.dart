import 'dart:developer';
import 'dart:io';
import 'package:collection/collection.dart' show IterableExtension; // for firstWhereOrNull
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:livekit_client/livekit_client.dart';

import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared/loading_indicator.dart';
// Add this class to mirror Android's Activity result codes

class OnlineMeetingScreen extends StatefulWidget {
  final String meetingId;

  const OnlineMeetingScreen({super.key, required this.meetingId});

  @override
  State<OnlineMeetingScreen> createState() => _OnlineMeetingScreenState();
}

class _OnlineMeetingScreenState extends State<OnlineMeetingScreen> {
  // Room & listener
  Room? _room;
  EventsListener<RoomEvent>? _listener;



  // 
   bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  // Pre-join toggles
  bool _wantAudio = true;
  bool _wantVideo = true;

  // If true, we show the pre-join screen. Once user clicks "Join Meeting", we proceed to connect
  bool _showPreJoin = true;

  // Local preview track (for the pre-join UI) so user can see themselves
  LocalVideoTrack? _previewTrack;

  // Flags for current in-meeting toggles
  bool _isAudioEnabled = true;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;

  // Keep a list of all participants (local + remote)
  List<Participant> _participants = [];

  // Add these new state variables
Participant? _selectedParticipant;
bool _isScreenSharing = false;


  @override
  void initState() {
    super.initState();
    // Initialize preview track since video is on by default
    _setupPreviewTrack();
  }

  // ----------------- PRE-JOIN LOGIC -----------------

  /// Optionally set up a local camera preview track if user wants video in pre-join screen.
  Future<void> _setupPreviewTrack() async {
    // If user doesn't want video, skip
    if (!_wantVideo) {
      _disposePreviewTrack();
      return;
    }
    // Already have a preview track? Just return
    if (_previewTrack != null) return;

    try {
      const cameraOptions = CameraCaptureOptions(maxFrameRate: 30.0);
      final track = await LocalVideoTrack.createCameraTrack(cameraOptions);
      setState(() {
        _previewTrack = track;
      });
    } catch (e) {
      log('Error creating preview track: $e');
      _disposePreviewTrack();
    }
  }

  void _disposePreviewTrack() {
    _previewTrack?.stop();
    _previewTrack?.dispose();
    _previewTrack = null;
  }

  /// Called when user clicks "Join Meeting" from the pre-join screen.
  Future<void> _onJoinMeetingPressed() async {
    setState(() {
      _showPreJoin = false;
      // We carry over the user's pre-join toggles
      _isAudioEnabled = _wantAudio;
      _isVideoEnabled = _wantVideo;
    });
    // Now start the actual meeting flow
    try {
      // This triggers the MeetingCubit => calls the server => eventually `_connectToRoom`
      await context.read<MeetingCubit>().joinMeeting(widget.meetingId);
    } catch (e) {
      log('Error starting meeting: $e');
      _showErrorSnackBar('Failed to join meeting. Please try again.');
      if (mounted) {
        // If something fails, revert and show pre-join again
        setState(() => _showPreJoin = true);
      }
    }
  }

  // ----------------- MEETING LOGIC -----------------

  Future<void> _connectToRoom(String token, String serverUrl) async {
    try {
      // High quality video encoding with adaptive bitrate
      final videoPublishOptions = VideoPublishOptions(
        videoEncoding: const VideoEncoding(
          maxBitrate: 2500 * 1024, // 2.5Mbps for high quality
          maxFramerate: 60,         // Higher framerate for smoother video

        ),
        videoCodec: Platform.isIOS ? 'h264' : 'vp8',  // Use H.264 for iOS, VP8 for others for best hardware acceleration
        simulcast: true,           // Enable simulcast for bandwidth adaptation
        // screenShareEncoding: VideoEncoding( // Separate encoding for screen share
        //   maxBitrate: 4000 * 1024, // 4Mbps for crisp screen sharing
        //   maxFramerate: 30,

        // ),
      );

      const cameraCaptureOptions = CameraCaptureOptions(
        maxFrameRate: 60.0,        // Higher framerate camera capture
        params: VideoParametersPresets.h1080_169, // Full HD capture
      );

      const audioCaptureOptions = AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
        typingNoiseDetection: true,
        voiceIsolation: true,
        // Stereo audio
      );

      final roomOptions = RoomOptions(
  adaptiveStream: true,
  dynacast: true,
  defaultVideoPublishOptions: videoPublishOptions,
  defaultAudioCaptureOptions: audioCaptureOptions,
  defaultAudioOutputOptions: const AudioOutputOptions(
    speakerOn: true,
  ),
  stopLocalTrackOnUnpublish: true, // Ensure this is set to true
);

      final room = Room(
        roomOptions: roomOptions,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );
      _room = room;
      _listener = room.createListener();
      _setUpRoomListeners(room);

      // Enable wake lock to keep screen on during meeting
      try {
        // Keep immersive mode while enabling wake lock
        if (Platform.isAndroid) {
          await const MethodChannel('screen_capture_service')
              .invokeMethod('keepScreenOn', true);
          // Restore immersive mode
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
          );
        }
      } catch (e) {
        log('Error enabling wake lock: $e', name: 'OnlineMeetingScreen');
      }

     // Update Android audio configuration in _connectToRoom
await webrtc.Helper.setAndroidAudioConfiguration(
  webrtc.AndroidAudioConfiguration(
    manageAudioFocus: true,
    androidAudioMode: webrtc.AndroidAudioMode.inCommunication, // Changed from callScreening
    androidAudioFocusMode: webrtc.AndroidAudioFocusMode.gainTransient, // Transient focus
    androidAudioStreamType: webrtc.AndroidAudioStreamType.voiceCall,
    androidAudioAttributesUsageType: 
      webrtc.AndroidAudioAttributesUsageType.voiceCommunication,
    forceHandleAudioRouting: true,
  )
);
      // Connect to the LiveKit server
      await room.connect(
        serverUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
        roomOptions: roomOptions,
      );

      // Force speaker on (for iOS/Android)
      await room.setSpeakerOn(true);

      // Now enable camera & mic with the user's chosen initial states
      final localParticipant = room.localParticipant;
if (localParticipant != null) {
  if (_isVideoEnabled) {
    await localParticipant.setCameraEnabled(
      true,
      cameraCaptureOptions: cameraCaptureOptions,
    );
  }
  // Check if audio is already enabled to avoid redundant calls
  if (_isAudioEnabled && !localParticipant.isMicrophoneEnabled()) {
    await localParticipant.setMicrophoneEnabled(true);
  }
      }

      // We can now safely dispose the pre-join preview track
      _disposePreviewTrack();

      _refreshParticipants();
      setState(() {});
    } catch (e) {
      log('Error connecting to room: $e', name: 'OnlineMeetingScreen');
      if (mounted) {
        _showErrorSnackBar('Error connecting to room: $e');
      }
    }
  }

  void _setUpRoomListeners(Room room) {
   
  // Add these new listeners
  _listener?.on<ParticipantMetadataUpdatedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<ParticipantNameUpdatedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<ParticipantConnectionQualityUpdatedEvent>((event) {
    _refreshParticipants();
  });
  _listener?.on<RoomReconnectingEvent>((event) {
    log('Room is reconnecting...', name: 'OnlineMeetingScreen');
    setState(() => _isReconnecting = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Connection unstable, attempting to reconnect...'),
      backgroundColor: Colors.orangeAccent,
      duration: Duration(seconds: 2),
    ));
  });

  _listener?.on<RoomReconnectedEvent>((event) async {
  log('Room reconnected!', name: 'OnlineMeetingScreen');
  setState(() {
    _isReconnecting = false;
    _reconnectAttempts = 0;
  });
  final localParticipant = _room?.localParticipant;
  if (localParticipant != null && _isAudioEnabled) {
    // Only enable if not already enabled
    if (!localParticipant.isMicrophoneEnabled()) {
      await localParticipant.setMicrophoneEnabled(true);
    }
  }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Connection restored!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));
    _refreshParticipants();
  });

  _listener?.on<RoomAttemptReconnectEvent>((event) {
    log('Reconnect attempt ${event.attempt} of ${event.maxAttemptsRetry}',
        name: 'OnlineMeetingScreen');
    setState(() => _reconnectAttempts = event.attempt);
  });
    _listener?.on<ParticipantConnectedEvent>((event) {
      log('Participant connected: ${event.participant.identity}');
      _refreshParticipants();
    });

    _listener?.on<ParticipantDisconnectedEvent>((event) {
      log('Participant disconnected: ${event.participant.identity}');
      _refreshParticipants();
    });

    _listener?.on<TrackPublishedEvent>((event) {
      log('Track published by: ${event.participant.identity}');
      log('Track published: ${event.publication.track?.sid}');
      log('Track published: ${event.publication.track?.source}');
      log('Track published: ${event.publication.track?.kind}');
      log('Track published: ${event.publication.track?.mediaType}');

      _refreshParticipants();
    });
    _listener?.on<TrackUnpublishedEvent>((event) {
      log('Track unpublished by: ${event.participant.identity}');
      _refreshParticipants();
    });
    _listener?.on<TrackSubscribedEvent>((event) {
      log('Track subscribed: ${event.participant.identity}, track: ${event.publication.sid}');
      _refreshParticipants();
    });
    _listener?.on<TrackUnsubscribedEvent>((event) {
      log('Track unsubscribed: ${event.participant.identity}, track: ${event.publication.sid}');
      _refreshParticipants();
    });

    // Mute/unmute
    _listener?.on<TrackMutedEvent>((event) {
      log('Track muted: ${event.participant.identity}');
      _refreshParticipants();
    });
    _listener?.on<TrackUnmutedEvent>((event) {
      log('Track unmuted: ${event.participant.identity}');
      log('Track unmuted: ${event.publication.track?.mediaType}');
      log('Track unmuted: ${event.publication.track?.kind}');
      log('Track unmuted: ${event.publication.track?.source}');
      log('Track unmuted: ${event.publication.track?.sid}');
      _refreshParticipants();
    });

    _listener?.on<LocalTrackPublishedEvent>((event) {
  _refreshParticipants();
});

_listener?.on<LocalTrackUnpublishedEvent>((event) {
  _refreshParticipants();
});

// Add these additional listeners
  _listener?.on<ActiveSpeakersChangedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<TrackSubscriptionPermissionChangedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<ParticipantPermissionsUpdatedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<TrackStreamStateUpdatedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<SpeakingChangedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<DataReceivedEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<TranscriptionEvent>((event) {
    _refreshParticipants();
  });

  _listener?.on<TrackSubscriptionExceptionEvent>((event) {
    _refreshParticipants();
  });

    // Disconnected
    _listener?.on<RoomDisconnectedEvent>((event) async {
      log('Room disconnected: ${event.reason}', name: 'OnlineMeetingScreen');
      if (mounted) {
        // Show a snackbar with the disconnection reason
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Meeting ended: ${_getDisconnectReasonMessage(event.reason)}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait for snackbar to be visible before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Ensure we're still mounted before navigating
        if (mounted) {
          // Pop until we reach the meetings screen
          Navigator.of(context).popUntil((route) => 
            route.settings.name?.contains('meetings') == true || 
            route.isFirst
          );
        }
      }
    });
  }
// Remove throttling from refresh
void _refreshParticipants() {
  final room = _room;
  if (room == null) return;
  
  final newParticipants = [
    room.localParticipant,
    ...room.remoteParticipants.values,
  ].whereType<Participant>().toList();

  // Force new list creation for proper state updates
  //  if (!const DeepCollectionEquality().equals(_participants, newParticipants)) {
    setState(() {
      _participants = List.from(newParticipants);
    });
  // }
}
  // ----------------- MEETING CONTROLS -----------------

 Future<void> _toggleAudio() async {
  final localParticipant = _room?.localParticipant;
  if (localParticipant == null) return;

  try {
    setState(() => _isAudioEnabled = !_isAudioEnabled);
    if (_isAudioEnabled) {
      // Ensure any existing track is unpublished first
      await localParticipant.setMicrophoneEnabled(false);
    }
    await localParticipant.setMicrophoneEnabled(_isAudioEnabled);
  } catch (error) {
    log('Error toggling audio: $error');
    setState(() => _isAudioEnabled = !_isAudioEnabled);
    _showErrorSnackBar('Failed to toggle audio');
  }
}

  Future<void> _toggleVideo() async {
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return;

    try {
      setState(() => _isVideoEnabled = !_isVideoEnabled);
      await localParticipant.setCameraEnabled(_isVideoEnabled);
    } catch (error) {
      log('Error toggling video: $error', name: 'OnlineMeetingScreen');
      setState(() => _isVideoEnabled = !_isVideoEnabled);
      _showErrorSnackBar('Failed to toggle video');
    }
  }

  Future<void> _switchCamera() async {
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return;

    try {
      final cameraPub = localParticipant.videoTrackPublications.firstWhereOrNull(
        (pub) => pub.track?.source == TrackSource.camera,
      );
      final track = cameraPub?.track;
      if (track == null) {
        log('No camera track found to switch.', name: 'OnlineMeetingScreen');
        return;
      }
      setState(() => _isFrontCamera = !_isFrontCamera);
      await track.setCameraPosition(
        _isFrontCamera ? CameraPosition.front : CameraPosition.back,
      );
    } catch (error) {
      log('Error switching camera: $error', name: 'OnlineMeetingScreen');
      _showErrorSnackBar('Failed to switch camera');
    }
  }

 Future<void> _leaveRoom() async {
  try {
    // Reset audio configuration before disconnecting
    await webrtc.Helper.setAndroidAudioConfiguration(
      webrtc.AndroidAudioConfiguration.media
    );
    
    await _room?.disconnect();
    
    // Additional audio cleanup
    await webrtc.Helper.setSpeakerphoneOn(false);
    // await webrtc.Helper.selectAudioOutput(webrtc.AndroidAudioStreamType.);

    if (Platform.isAndroid) {
      await const MethodChannel('screen_capture_service')
          .invokeMethod('keepScreenOn', false);
    }
  } finally {
    if (mounted) Navigator.pop(context);
  }
}

  // ----------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeetingCubit, MeetingState>(
      listener: (context, state) {
        if (state.status == MeetingStateStatus.joinedMeeting &&
            state.joinMeetingResponse != null) {
          // The user has "joined" from the server perspective. Let's connect the Room now.
          _connectToRoom(
            state.joinMeetingResponse!.token,
            state.joinMeetingResponse!.serverUrl,
          );
        }
      },
      builder: (context, state) {
        // 1) If still in pre-join mode, show the pre-join UI
        if (_showPreJoin) {
          return _buildPreJoinScreen();
        }

        // 2) If the user has pressed "Join Meeting" => we proceed with your existing logic
        if (state.status == MeetingStateStatus.joiningMeeting) {
          // Show a loading UI while in the process of joining
          return const Scaffold(
            body: Center(child: LoadingIndicator()),
          );
        }

        // Show a loading UI until we've created & connected the Room
        if (_room == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoadingIndicator(),
                  SizedBox(height: 8.h),
                  Text(
                    'Connecting...',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ],
              ),
            ),
          );
        }

        // Once _room is non-null, display the main meeting UI
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.selectedMeeting?.title ?? 'Online Meeting',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textDark,
          ),
          body: Stack(
            children: [
              Positioned.fill(child: _buildParticipantsGrid()),
                          if (_isReconnecting) _buildReconnectingBanner(),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomControls(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReconnectingBanner() {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
    color: Colors.orange,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        SizedBox(width: 12.w),
        Text(
          'Reconnecting... (Attempt $_reconnectAttempts)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  /// --------------------
  /// Pre-Join Screen UI
  /// --------------------
  Widget _buildPreJoinScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Meeting'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Example local camera preview (if user has toggled camera on)
              Expanded(
                child: Center(
                  child: _previewTrack != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: VideoTrackRenderer(
          _previewTrack!, // as a VideoTrack
          fit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
        ),
      ): Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          width: 200.w,
                          height: 200.w,
                          child: const Icon(
                            Icons.videocam_off,
                            color: Colors.black54,
                            size: 48,
                          ),
                        ),
                ),
              ),

              // Toggles for mic and camera
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Audio toggle
                  IconButton(
                    icon: Icon(
                      _wantAudio ? Icons.mic : Icons.mic_off,
                      color: _wantAudio ? AppTheme.primaryBlue : AppTheme.errorRed,
                    ),
                    iconSize: 36.r,
                    onPressed: () {
                      setState(() => _wantAudio = !_wantAudio);
                    },
                  ),
                  SizedBox(width: 24.w),
                  // Video toggle
                  IconButton(
                    icon: Icon(
                      _wantVideo ? Icons.videocam : Icons.videocam_off,
                      color: _wantVideo ? AppTheme.primaryBlue : AppTheme.errorRed,
                    ),
                    iconSize: 36.r,
                    onPressed: () async {
                      setState(() => _wantVideo = !_wantVideo);
                      // If user just enabled video, start preview
                      if (_wantVideo) {
                        await _setupPreviewTrack();
                      } else {
                        // If user disabled, clean up
                        _disposePreviewTrack();
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Join meeting button
              ElevatedButton.icon(
                onPressed: _onJoinMeetingPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: const Icon(Icons.video_call, color: Colors.white),
                label: Text(
                  'Join Meeting',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildParticipantsGrid() {
    // Get local participant first
    final localParticipant = _participants.firstWhereOrNull((p) => p is LocalParticipant);
    final orderedParticipants = [
      if (localParticipant != null) localParticipant,
      ..._participants.where((p) => p != localParticipant),
    ];

    final mainParticipant = _selectedParticipant ?? orderedParticipants.firstOrNull;
    final otherParticipants = orderedParticipants.where((p) => p != mainParticipant).toList();

    return Stack(
      children: [
        Column(
          children: [
            // Main view (40% height)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: _buildMainParticipantView(mainParticipant),
              ),
            ),
            // Grid view with minimum 2 columns
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 100.h, // Space for controls
                  left: 8.w,
                  right: 8.w,
                ),
                child: GridView.builder(
                  physics: const ClampingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(),
                    mainAxisSpacing: 8.w,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 4/3,
                  ),
                  itemCount: otherParticipants.length,
                  itemBuilder: (_, index) {
                    final participant = otherParticipants[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedParticipant = participant),
                      child: _buildParticipantView(
                        participant,
                        isLocal: participant == localParticipant,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  int _calculateCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? 3 : 2; // Always at least 2 columns
  }

  Widget _buildMainParticipantView(Participant? participant) {
    bool isLocal = participant is LocalParticipant;
    return participant != null
        ? _buildParticipantView(participant, isMain: true, isLocal: isLocal)
        : Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Select a participant',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
  }

  Widget _buildParticipantView(Participant participant, {bool isMain = false, bool isLocal = false}) {
    // Prioritize screen share track
    final screenSharePub = participant.videoTrackPublications.firstWhereOrNull(
      (pub) => pub.source == TrackSource.screenShareVideo,
    );
    
    final videoPub = screenSharePub ?? participant.videoTrackPublications.firstWhereOrNull(
      (pub) => pub.track is VideoTrack,
    );

    final hasScreenShare = screenSharePub != null;
    final videoTrack = videoPub?.track as VideoTrack?;
    final hasVideo = videoTrack != null && !(videoPub?.muted ?? true);

    // Determine if audio is muted
    bool isAudioMuted;
    if (participant is LocalParticipant) {
      isAudioMuted = !_isAudioEnabled;
    } else {
      final audioPub = participant.audioTrackPublications.firstWhereOrNull(
        (pub) => pub.track is AudioTrack,
      );
      isAudioMuted = (audioPub == null) || audioPub.muted;
    }

    // Display name
    final displayName = isLocal
        ? 'You'
        : (participant.name.isNotEmpty ? participant.name : 'Participant');

    final isInRoom = _participants.contains(participant);
    
    return Visibility(
      visible: isInRoom,
      child: KeyedSubtree(
        key: ValueKey('${participant.sid}_${videoTrack?.sid}'), // Track changes
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isLocal ? AppTheme.primaryBlue : Colors.transparent,
              width: 2.w,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                // Video renderer
                if (hasVideo)
                  VideoTrackRenderer(
                    videoTrack,
                    fit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  )
                else
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white60,
                        size: 48.w,
                      ),
                    ),
                  ),

                // Screen share indicator
                if (hasScreenShare)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.screen_share, size: 16.w),
                    ),
                  ),

                // Local participant badge
                if (isLocal)
                  Positioned(
                    top: 8.w,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Participant name
                if (!isLocal)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),

                // Mic off indicator
                if (isAudioMuted)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.mic_off,
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).padding.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/unmute audio
          IconButton(
            onPressed: _toggleAudio,
            icon: Icon(
              _isAudioEnabled ? Icons.mic : Icons.mic_off,
              color: _isAudioEnabled ? AppTheme.primaryBlue : AppTheme.errorRed,
            ),
          ),
          // Mute/unmute video
          IconButton(
            onPressed: _toggleVideo,
            icon: Icon(
              _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              color:
                  _isVideoEnabled ? AppTheme.primaryBlue : AppTheme.errorRed,
            ),
          ),
          // Add to bottom controls
IconButton(
  onPressed: _toggleScreenShare,
  icon: Icon(
    _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
    color: _isScreenSharing ? AppTheme.errorRed : AppTheme.primaryBlue,
  ),
),
          // Switch camera
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(
              Icons.flip_camera_ios,
              color: AppTheme.primaryBlue,
            ),
          ),
          // End call
          IconButton(
            onPressed: _leaveRoom,
            icon: const Icon(
              Icons.call_end,
              color: AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }
  
Future<void> _toggleScreenShare() async {
  try {
    if (_isScreenSharing) {
      await _disableScreenShare();
    } else {
      await _enableScreenShare();
    }
  } catch (e) {
    log('Screen share error: $e');
    _showErrorSnackBar('Screen share failed: ${e.toString()}');
  }
}

Future<void> _enableScreenShare() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Desktop platforms
    final source = await showDialog<webrtc.DesktopCapturerSource>(
      context: context,
      builder: (_) => ScreenSelectDialog(),
    );
    
    if (source == null) {
      log('Screen share cancelled');
      return;
    }

    var track = await LocalVideoTrack.createScreenShareTrack(
      ScreenShareCaptureOptions(
        sourceId: source.id,
        maxFrameRate: 30.0,
        captureScreenAudio: true,
        params: VideoParametersPresets.screenShareH1080FPS30
      ),
    );
    await _room?.localParticipant?.publishVideoTrack(track);
    setState(() => _isScreenSharing = true);
    return;
  }

  if (Platform.isAndroid) {
      // Add explicit audio permission check
      // await Permission.audio.request();
      
      // Check both capture and audio permissions
      final hasCapture = await webrtc.Helper.requestCapturePermission();
      // final hasAudio = await Permission.audio.isGranted;
      
      if (!hasCapture) {
        _showErrorSnackBar('Permissions required for screen sharing');
        return;
      }

      // Wait for background service initialization
      bool isEnabled = await _requestBackgroundPermission();
      if (!isEnabled) {
        _showErrorSnackBar('Failed to enable background service');
        return;
      }
      
      // Add delay for system to register permissions
      await Future.delayed(const Duration(milliseconds: 1500));
    }

  if (Platform.isIOS) {
    var track = await LocalVideoTrack.createScreenShareTrack(
      const ScreenShareCaptureOptions(
        useiOSBroadcastExtension: true,
        maxFrameRate: 30.0,
        captureScreenAudio: true,
        params: VideoParametersPresets.screenShareH1080FPS30
      ),
    );
    await _room?.localParticipant?.publishVideoTrack(track);
    setState(() => _isScreenSharing = true);
    Future.delayed(const Duration(seconds: 1), _refreshParticipants);

    return;
  }

  await _room?.localParticipant?.setScreenShareEnabled(true, captureScreenAudio: true,
   screenShareCaptureOptions: const ScreenShareCaptureOptions(
    maxFrameRate: 30.0,
    captureScreenAudio: true,
    params: VideoParametersPresets.screenShareH1080FPS30
   ));
  setState(() => _isScreenSharing = true);
}

Future<bool> _requestBackgroundPermission([bool isRetry = false]) async {
  try {
    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!isRetry) {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'Screen Sharing',
        notificationText: 'AgileMeets is sharing the screen.',
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
      );
      hasPermissions = await FlutterBackground.initialize(
        androidConfig: androidConfig,
      );
    }
    if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
      bool isEnabled = await FlutterBackground.enableBackgroundExecution();
      return isEnabled;
    }
    return false;
  } catch (e) {
    if (!isRetry) {
      return await Future<bool>.delayed(
        const Duration(seconds: 1),
        () => _requestBackgroundPermission(true),
      );
    }
    log('Background permission error: $e');
    _showErrorSnackBar('Failed to get background permissions');
    return false;
  }
}

Future<void> _disableScreenShare() async {
  try {
    await _room?.localParticipant?.setScreenShareEnabled(false);
    
    // Extra audio track cleanup
    _room?.localParticipant?.audioTrackPublications.forEach((track) {
      track.track?.stop();
      track.dispose();
    });

    if (Platform.isAndroid) {
      await FlutterBackground.disableBackgroundExecution();
      // Reset audio mode after screen sharing
      await webrtc.Helper.setAndroidAudioConfiguration(
        webrtc.AndroidAudioConfiguration.media
      );
    }
  } catch (error) {
    log('Error disabling screen share: $error');
  } finally {
    setState(() => _isScreenSharing = false);
  }
}

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

@override
void dispose() {
  _disposePreviewTrack();
  _listener?.dispose();
  // Clean up all participants
  for (var p in _participants) {
    for (var track in p.videoTrackPublications) {
      track.dispose();
    }
    for (var track in p.audioTrackPublications) {
      track.dispose();
    }
  }
  _room?.disconnect();
  super.dispose();
}

  String _getDisconnectReasonMessage(DisconnectReason? reason) {
    switch (reason) {
      case DisconnectReason.clientInitiated:
        return 'You left the meeting';
      case DisconnectReason.duplicateIdentity:
        return 'Another device joined with your account';
      case DisconnectReason.unknown:
        return 'Meeting ended by host';
      case DisconnectReason.participantRemoved:
        return 'You were removed from the meeting';
      case DisconnectReason.roomDeleted:
        return 'Meeting was ended';
      case DisconnectReason.stateMismatch:
        return 'Connection error occurred';
      case null:
        return 'Meeting ended';
      default:
        return 'Meeting ended';
    }
  }
}

