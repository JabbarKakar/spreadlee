import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../resources/routes_manager.dart';
import '../provider/chat_provider.dart';
import '../../../bloc/business/chat_bloc/chat_cubit.dart';
import '../../../../services/chat_service.dart';
import '../view/location_picker_screen.dart';
import '../widget/photo_attachment_widget.dart';
import '../../../../widgets/upload_progress_manager.dart';
import '../view/chat_screen.dart';
import 'package:spreadlee/domain/chat_model.dart';
import '../../../widgets/custom_video_picker.dart';
import 'dart:convert';
import '../../../../utils/sound_utils.dart';
import '../../../../services/enhanced_message_status_handler.dart';
import '../../../../services/connection_popup_service.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(bool) onTyping;
  final bool isCustomer;
  final bool isTicketChat;

  const MessageInput(
      {Key? key,
      required this.controller,
      required this.onTyping,
      this.isCustomer = false,
      this.isTicketChat = false})
      : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with WidgetsBindingObserver {
  bool isExpanded = false;
  bool isAudioRecording = false;
  bool isAudioPaused = false;
  bool audioDeleteDisable = false;
  String? audioRecord;
  String? audioURL;
  int? timerStoppedValue;
  int timerMilliseconds = 0;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String timerValue =
      StopWatchTimer.getDisplayTime(0, hours: false, milliSecond: false);
  final AudioRecorder audioRecorder = AudioRecorder();
  final StopWatchTimer timer = StopWatchTimer(mode: StopWatchMode.countUp);
  StreamSubscription? _timerSubscription;
  bool _isTyping = false;
  Timer? _typingTimer;
  String? _selectedPayment;
  List<String> photos = [];
  String? videoPathParam;
  List<Map<String, dynamic>> docs = [];
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  StreamSubscription? _audioPlayerSubscription;
  bool _isSendingAudio = false;

  // Enhanced message status handler
  final EnhancedMessageStatusHandler _statusHandler =
      EnhancedMessageStatusHandler();
  StreamSubscription<MessageStatusUpdate>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('MessageInput initState');
    WidgetsBinding.instance.addObserver(this);

    // Initialize enhanced message status handler
    _initializeStatusHandler();

    // Initialize audio recorder
    try {
      debugPrint('Initializing audio recorder...');
      audioRecorder.dispose(); // Dispose any existing instance
      debugPrint('Audio recorder initialized');
    } catch (e) {
      debugPrint('Error initializing audio recorder: $e');
    }

    // Set up timer subscription
    _setupTimerSubscription();

    // Set up audio player listeners
    _setupAudioPlayerListeners();

    widget.controller.addListener(_onTextChanged);
  }

  /// Initialize the enhanced message status handler
  void _initializeStatusHandler() {
    _statusHandler.initialize();

    // Listen to status updates
    _statusSubscription = _statusHandler.statusUpdateStream.listen((update) {
      _handleStatusUpdate(update);
    });
  }

  /// Handle message status updates from the enhanced handler
  void _handleStatusUpdate(MessageStatusUpdate update) {
    if (kDebugMode) {
      print('MessageInput: Status update received: ${update.type}');
      print('Chat ID: ${update.chatId}, Message ID: ${update.messageId}');
    }

    // You can add UI updates here if needed
    // For example, show a snackbar when messages are read
    if (update.type == MessageStatusType.read && mounted) {}
  }

  void _setupTimerSubscription() {
    _timerSubscription?.cancel();
    _timerSubscription = timer.rawTime.listen((value) {
      if (mounted) {
        setState(() {
          timerMilliseconds = value;
          timerValue = StopWatchTimer.getDisplayTime(value,
              hours: false, milliSecond: false);
        });
      }
    });
  }

  void _cancelTimerSubscription() {
    _timerSubscription?.cancel();
    _timerSubscription = null;
  }

  void _onTextChanged() {
    final isTyping = widget.controller.text.isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      widget.onTyping(isTyping);

      // Notify ChatProvider about typing status
      try {
        final provider = ChatProviderInherited.of(context);
        if (isTyping) {
          provider.startTyping();
        } else {
          provider.stopTyping();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating typing status: $e');
        }
      }

      if (isTyping) {
        // Show keyboard when user starts typing
        _focusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } else {
        // Hide keyboard when text is empty
        _focusNode.unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    }

    // Reset typing timer - reduced delay for customers for faster response
    _typingTimer?.cancel();
    if (isTyping) {
      // Use shorter delay for customers to improve responsiveness
      final delay = widget.isCustomer
          ? const Duration(milliseconds: 500)
          : const Duration(seconds: 1);
      _typingTimer = Timer(delay, () {
        if (mounted) {
          _isTyping = false;
          widget.onTyping(false);
          // Stop typing indicator
          try {
            final provider = ChatProviderInherited.of(context);
            provider.stopTyping();
          } catch (e) {
            if (kDebugMode) {
              print('Error stopping typing status: $e');
            }
          }
        }
      });
    }
  }

  void _setupAudioPlayerListeners() {
    _audioPlayerSubscription?.cancel();
    _audioPlayerSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            // Reset position when completed
            _audioPosition = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });
  }

  void _resetAudioPlayer() {
    _audioPlayer.stop();
    _audioPosition = Duration.zero;
    _audioDuration = Duration.zero;
    _isPlaying = false;
  }

  Future<void> _playAudio() async {
    if (audioRecord == null) return;

    try {
      // Check if the audio file exists
      final file = File(audioRecord!);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      // Stop any currently playing audio first
      await _audioPlayer.stop();

      // Load the audio file
      await _audioPlayer.setFilePath(audioRecord!);

      // Start playing
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error playing audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    debugPrint('MessageInput dispose');
    WidgetsBinding.instance.removeObserver(this);

    // Clean up enhanced message status handler
    _statusSubscription?.cancel();
    _statusHandler.dispose();

    // Clean up any open progress dialogs
    UploadProgressManager.hide();

    // Clean up audio player
    _resetAudioPlayer();
    _audioPlayerSubscription?.cancel();
    _audioPlayer.dispose();

    try {
      debugPrint('Disposing audio recorder...');
      if (isAudioRecording) {
        // Cancel timer subscription first
        _cancelTimerSubscription();

        // Stop timer
        timer.onStopTimer();
        timer.onResetTimer();

        audioRecorder.stop().then((_) {
          audioRecorder.dispose();
          debugPrint('Audio recorder stopped and disposed');
        });
      } else {
        audioRecorder.dispose();
        debugPrint('Audio recorder disposed');
      }
    } catch (e) {
      debugPrint('Error disposing audio recorder: $e');
    }

    // Clean up timer and subscription
    _cancelTimerSubscription();
    timer.dispose();

    widget.controller.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    _focusNode.dispose();

    // Dispose sound utility (fire and forget)
    SoundUtils.dispose().catchError((e) {
      debugPrint('Error disposing SoundUtils: $e');
    });

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isAudioRecording) {
      _stopAudioRecording();
    }
  }

  Future<void> _showPermissionDialog(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        backgroundColor: Colors.transparent,
        alignment: const AlignmentDirectional(0.0, 0.0)
            .resolve(Directionality.of(context)),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(dialogContext),
                    child: const Icon(
                      Icons.close,
                      color: ColorManager.gray100,
                      size: 18.0,
                    ),
                  ),
                ],
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: ColorManager.blueLight800),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: ColorManager.blueLight800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await openAppSettings();
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blueLight800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Settings',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _requestMicrophonePermission() async {
    debugPrint('Requesting microphone permission...');
    try {
      if (Platform.isIOS) {
        // On iOS, we need to request permission first
        final status = await Permission.microphone.request();
        debugPrint('iOS microphone permission status: $status');

        if (status.isGranted) {
          return true;
        }

        if (status.isPermanentlyDenied || status.isDenied) {
          if (mounted) {
            await _showPermissionDialog(
              'To record voice messages, we need access to your microphone. Please enable microphone access in your device settings.',
            );
          }
          return false;
        }

        return false;
      } else {
        // On Android, we can use the recorder's permission check
        final hasPermission = await audioRecorder.hasPermission();
        debugPrint('Android microphone permission status: $hasPermission');

        if (hasPermission) {
          return true;
        }

        // If the recorder's check fails, try the permission handler
        final status = await Permission.microphone.request();
        debugPrint('Android permission handler status: $status');

        if (status.isGranted) {
          return true;
        }

        if (status.isPermanentlyDenied || status.isDenied) {
          if (mounted) {
            await _showPermissionDialog(
              'To record voice messages, we need access to your microphone. Please enable microphone access in your device settings.',
            );
          }
          return false;
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      if (mounted) {
        await _showPermissionDialog(
          'There was an error requesting microphone access. Please try again or check your device settings.',
        );
      }
      return false;
    }
  }

  Future<bool> _requestLocationPermission() async {
    debugPrint('Requesting location permission...');
    try {
      final status = await Permission.location.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.location.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return false;
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  Future<void> _startAudioRecording() async {
    debugPrint('Starting audio recording process...');

    try {
      // Request permission first
      final hasPermission = await _requestMicrophonePermission();
      debugPrint('Permission status: $hasPermission');

      if (!hasPermission) {
        debugPrint('No permission, returning...');
        return;
      }

      // Reset timer state and set up subscription
      timer.onResetTimer();
      _setupTimerSubscription();

      // Get directory
      debugPrint('Getting temporary directory...');
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      debugPrint('Recording file path: $filePath');

      // Start recording with minimal config
      debugPrint('Starting recorder...');
      await audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      debugPrint('Recorder started successfully');

      // Start timer after successful recording start
      timer.onStartTimer();

      // Update UI
      if (mounted) {
        setState(() {
          isAudioRecording = true;
          isExpanded = false;
          isAudioPaused = false;
          audioRecord = null;
          timerStoppedValue = null;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error starting recording')),
        );
      }
    }
  }

  Future<void> _stopAudioRecording() async {
    debugPrint('Stopping audio recording...');

    if (!isAudioRecording) {
      debugPrint('Not recording, returning...');
      return;
    }

    // Store the current timer value before stopping
    final currentTimerValue = timerMilliseconds;

    try {
      // Cancel timer subscription first
      _cancelTimerSubscription();

      // Stop the timer
      timer.onStopTimer();

      debugPrint('Stopping recorder...');
      final path = await audioRecorder.stop();
      debugPrint('Recorder stopped, path: $path');

      if (!mounted) {
        debugPrint('Widget not mounted after stop, returning...');
        return;
      }

      if (path == null) {
        throw Exception('Failed to save audio recording');
      }

      // Validate the recorded file
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Recorded audio file not found');
      }

      final fileSize = await file.length();
      debugPrint('Recorded audio file size: $fileSize bytes');
      debugPrint('Recorded audio file path: $path');
      debugPrint('Recorded audio file extension: ${path.split('.').last}');
      debugPrint('Recorded audio file exists: ${await file.exists()}');

      // Check file size (e.g., 10MB limit)
      const maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
      if (fileSize > maxFileSize) {
        await file.delete(); // Delete the oversized file
        throw Exception('Recording is too large. Maximum size is 10MB');
      }

      // Check if file is empty or too small
      if (fileSize < 1024) {
        // Less than 1KB
        await file.delete(); // Delete the empty/small file
        throw Exception('Recording is too short or empty');
      }

      // Update state with the stored timer value
      if (mounted) {
        setState(() {
          isAudioRecording = false; // Set recording to false after stopping
          isAudioPaused = true;
          timerStoppedValue = currentTimerValue;
          audioRecord = path;
        });
      }

      // Reset timer after state update
      timer.onResetTimer();
      debugPrint('Audio recording saved successfully');
    } catch (e, stackTrace) {
      debugPrint('Error in _stopAudioRecording: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recording'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Reset recording state
      if (mounted) {
        setState(() {
          isAudioRecording = false;
          isAudioPaused = false;
          audioRecord = null;
          timerStoppedValue = null;
        });
      }
    }
  }

  Future<void> _handleSendMessage({
    required String messageText,
    List<String> photoPaths = const [],
    List<Map<String, dynamic>> documents = const [],
    String? videoPathParam,
    String? audioPath,
    double? audioDuration,
    dynamic
        location, // Changed from String? to dynamic to accept both String and Map
    dynamic paymentType, // ✅ Allow both String and Map<String, dynamic>
  }) async {
    debugPrint('=== _handleSendMessage START ===');
    debugPrint('Message text: $messageText');
    debugPrint('Audio path: $audioPath');
    debugPrint('Audio duration: $audioDuration');
    debugPrint('Is audio recording: $isAudioRecording');
    debugPrint('Is audio paused: $isAudioPaused');
    debugPrint('Audio record: $audioRecord');
    debugPrint('Location parameter: $location');
    debugPrint('Location parameter type: ${location.runtimeType}');
    debugPrint('Payment type: $paymentType');
    debugPrint('Payment type type: ${paymentType.runtimeType}');

    // Safety check: prevent customers from sending invoice messages
    if (widget.isCustomer && paymentType != null) {
      debugPrint('Customers cannot send invoice messages');
      return;
    }

    ChatProvider? chatProvider;
    try {
      chatProvider = ChatProviderInherited.of(context);
    } catch (e) {
      if (kDebugMode) {
        print('MessageInput: ChatProviderInherited not available: $e');
      }
      return;
    }
    Map<String, dynamic>? locationMap;

    if (location != null) {
      if (location is String) {
        try {
          locationMap = json.decode(location);
          debugPrint('Parsed location from string: $locationMap');
        } catch (e) {
          debugPrint('Error parsing location string: $e');
        }
      } else if (location is Map<String, dynamic>) {
        locationMap = location;
        debugPrint('Using location map directly: $locationMap');
      } else {
        debugPrint('Unknown location type: ${location.runtimeType}');
      }
    }

    // Set audio sending state if this is an audio message
    if (audioPath != null) {
      setState(() {
        _isSendingAudio = true;
      });

      // Add a safety timer to ensure _isSendingAudio is reset after 10 seconds
      Timer(const Duration(seconds: 10), () {
        if (mounted && _isSendingAudio) {
          debugPrint(
              '=== Safety timer triggered, resetting _isSendingAudio ===');
          setState(() {
            _isSendingAudio = false;
          });
        }
      });
    }

    bool hasAttachments =
        photoPaths.isNotEmpty || videoPathParam != null || documents.isNotEmpty;

    if (hasAttachments) {
      debugPrint('Attachments detected, showing upload progress');
      UploadProgressManager.show(context);
      UploadProgressManager.updateProgress(0.1, 'Preparing attachments...');
    }

    try {
      // ✅ ADD: Ensure socket is ready before sending
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.waitForSocketReady();

      // For files, use cubit to get progress tracking
      final chatCubit = context.read<ChatBusinessCubit>();
      debugPrint('=== Starting chatCubit.sendMessage ===');
      debugPrint('Has attachments: $hasAttachments');
      debugPrint('Audio path: $audioPath');

      // Add a fallback timer to ensure dialog is hidden
      Timer? fallbackTimer;
      if (hasAttachments) {
        fallbackTimer = Timer(const Duration(seconds: 10), () {
          debugPrint('=== Fallback timer triggered, hiding dialog ===');
          UploadProgressManager.hide();
        });
      }

      if (hasAttachments) {
        await chatCubit.sendMessage(
          chatId: chatProvider.chatId,
          messageText: messageText,
          messagePhotos: photoPaths,
          messageVideos: videoPathParam != null ? [videoPathParam] : null,
          messageDocument: documents.isNotEmpty ? documents.first['url'] : null,
          location: locationMap,
          messageInvoice: paymentType,
          messageAudio: audioPath,
          onProgress: (progress, status) {
            debugPrint('=== Progress callback: $progress - $status ===');
            // progress should be a value between 0.0 and 1.0, updated frequently
            UploadProgressManager.updateProgress(progress, status);
          },
        );
      } else {
        // For other types of messages (audio, location, payment, etc.)
        await chatCubit.sendMessage(
          chatId: chatProvider.chatId,
          messageText: messageText,
          location: locationMap,
          messageInvoice: paymentType,
          messageAudio: audioPath,
        );
      }

      debugPrint('=== chatCubit.sendMessage completed successfully ===');

      // Cancel fallback timer since we completed successfully
      fallbackTimer?.cancel();

      // Hide progress dialog on success (only for attachments)
      if (hasAttachments) {
        debugPrint('=== Hiding progress dialog after success ===');
        UploadProgressManager.updateProgress(1.0, 'Upload complete!');
        UploadProgressManager.hide();
      }

      // Play message sent sound
      // await SoundUtils.playMessageSentSound();

      // Clear state after successful send
      setState(() {
        debugPrint('=== Clearing audio state after successful send ===');
        debugPrint('Before clearing - isAudioRecording: $isAudioRecording');
        debugPrint('Before clearing - isAudioPaused: $isAudioPaused');
        debugPrint('Before clearing - audioRecord: $audioRecord');
        debugPrint('Before clearing - audioDeleteDisable: $audioDeleteDisable');

        photos = [];
        this.videoPathParam = null;
        docs = [];
        isAudioRecording = false;
        isAudioPaused = false;
        audioRecord = null;
        audioURL = null;
        timerStoppedValue = null;
        audioDeleteDisable = false;
        _isSendingAudio = false;

        debugPrint('After clearing - isAudioRecording: $isAudioRecording');
        debugPrint('After clearing - isAudioPaused: $isAudioPaused');
        debugPrint('After clearing - audioRecord: $audioRecord');
        debugPrint('After clearing - audioDeleteDisable: $audioDeleteDisable');
      });
      _resetAudioPlayer();

      // Force another setState to ensure UI rebuilds
      if (mounted) {
        setState(() {
          debugPrint('=== Forcing UI rebuild after audio state clearing ===');
        });
      }
    } catch (e) {
      debugPrint('=== ERROR in _handleSendMessage ===');
      debugPrint('Error: $e');
      debugPrint('Error sending message: $e');
      if (mounted) {
        // Check if this is a connection error
        if (e.toString().contains('Socket not connected') ||
            e.toString().contains('Connection lost') ||
            e.toString().contains('reconnect manually')) {
          // Show connection popup instead of error message
          final popupService = ConnectionPopupService();
          // Initialize with current context if not already initialized
          if (!popupService.isShowingPopup) {
            popupService.initialize(context);
          }
          popupService.showSocketConnectionLost();
        } else {
          // Show error in progress dialog for attachments
          if (hasAttachments) {
            UploadProgressManager.showError('Failed to send message: $e');
          }
          // Also show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      // Reset audio sending state on error
      if (mounted) {
        setState(() {
          _isSendingAudio = false;
        });
      }
    } finally {
      debugPrint('=== FINALLY block in _handleSendMessage ===');
      // Always hide the dialog in case of any error or completion
      if (hasAttachments) {
        debugPrint('=== Hiding progress dialog in finally block ===');
        UploadProgressManager.hide();
      }
      // Always reset audio sending state in finally
      if (mounted) {
        setState(() {
          _isSendingAudio = false;
        });
      }
    }
  }

  void _showPaymentDialog() {
    // Safety check: prevent customers from accessing payment dialog
    if (widget.isCustomer) {
      return;
    }

    ChatProvider? chatProvider;
    try {
      chatProvider = ChatProviderInherited.of(context);
    } catch (e) {
      if (kDebugMode) {
        print('MessageInput: ChatProviderInherited not available: $e');
      }
      return;
    }
    var chatData = chatProvider.currentChat;

    // Reset selected payment when dialog opens
    _selectedPayment = null;

    // Defensive fallback for subaccounts: construct minimal chatData if null
    chatData ??= Chats(
      sId: chatProvider.chatId,
      chatUsers: ChatUsers(
        customerId: chatProvider?.userId, // fallback to userId
        // If you have companyId or other info, add here
      ),
      // If you have subaccountId, set it in a custom way
      // You may need to extend ChatUsers to support subaccountId if not present
      // For now, you can pass it in arguments below if needed
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
          backgroundColor: Colors.transparent,
          alignment: const AlignmentDirectional(0.0, 0.0)
              .resolve(Directionality.of(context)),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Choose payment method',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      RadioListTile<String>(
                        title: const Text('Online Payment'),
                        value: 'online',
                        groupValue: _selectedPayment,
                        activeColor: ColorManager.primaryGreen,
                        onChanged: (value) async {
                          setDialogState(() {
                            _selectedPayment = value;
                          });
                          if (kDebugMode) {
                            print('🧾 Starting invoice creation navigation...');
                            print('  - chatData: $chatData');
                            print(
                                '  - chatProvider?.userId: ${chatProvider?.userId}');
                            print(
                                '  - chatProvider.chatId: ${chatProvider?.chatId}');
                          }

                          final invoiceData = await Navigator.pushNamed(
                            context,
                            Routes.invoiceReleaseRoute,
                            arguments: {
                              'customerCompanyRef': chatData
                                      ?.chatCustomerCompanyRef
                                      ?.customerCompaniesId
                                      ?.sId ??
                                  '',
                              'customerRef':
                                  chatData?.chatUsers?.customerId ?? '',
                              'subaccountId': chatData
                                      ?.chatUsers?.subaccountId?.sId ??
                                  chatProvider
                                      ?.userId, // Use correct subaccountId field
                              'name': chatData?.chatCustomerCompanyRef
                                      ?.customerCompaniesId?.companyName ??
                                  '',
                              'chatId': chatData?.sId ?? '',
                              'companyId': {
                                'companyName': chatData
                                        ?.chatUsers?.companyId?.companyName ??
                                    '',
                                'commercialName': chatData?.chatUsers?.companyId
                                        ?.commercialName ??
                                    '',
                                'commercialNumber': chatData?.chatUsers
                                        ?.companyId?.commercialNumber ??
                                    '',
                                'vATNumber':
                                    chatData?.chatUsers?.companyId?.vATNumber ??
                                        '',
                              },
                              'chatCustomerCompanyRef': {
                                'customer_companiesId': {
                                  'companyName': chatData
                                          ?.chatCustomerCompanyRef
                                          ?.customerCompaniesId
                                          ?.companyName ??
                                      '',
                                  'commercialName': chatData
                                          ?.chatCustomerCompanyRef
                                          ?.customerCompaniesId
                                          ?.commercialName ??
                                      '',
                                  'commercialNumber': chatData
                                          ?.chatCustomerCompanyRef
                                          ?.customerCompaniesId
                                          ?.commercialNumber ??
                                      '',
                                  'vATNumber': chatData?.chatCustomerCompanyRef
                                          ?.customerCompaniesId?.vATNumber ??
                                      '',
                                }
                              }
                            },
                          ) as Map<String, dynamic>?;

                          if (kDebugMode) {
                            print('🧾 Invoice creation navigation completed');
                            print('  - invoiceData: $invoiceData');
                            print(
                                '  - invoiceData type: ${invoiceData.runtimeType}');
                            print('  - mounted: $mounted');
                          }

                          if (invoiceData != null && mounted) {
                            Navigator.pop(dialogContext);
                            if (kDebugMode) {
                              print(
                                  '🧾 Invoice data received from InvoiceReleaseWidget:');
                              print('  - invoiceData: $invoiceData');
                              print(
                                  '  - invoiceId: ${invoiceData['invoiceId']}');
                              print('  - _id: ${invoiceData['_id']}');
                              print(
                                  '  - invoice_id: ${invoiceData['invoice_id']}');
                            }
                            await _handleSendMessage(
                              messageText: '[INVOICE]',
                              paymentType:
                                  invoiceData, // ✅ Now passing full invoice data
                            );
                          } else {
                            if (kDebugMode) {
                              print(
                                  '🧾 Invoice data is null or widget not mounted');
                            }
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Bank Transfer'),
                        value: 'bank',
                        groupValue: _selectedPayment,
                        activeColor: ColorManager.primaryGreen,
                        onChanged: (value) async {
                          setDialogState(() {
                            _selectedPayment = value;
                          });
                          final invoiceData = await Navigator.pushNamed(
                            context,
                            Routes.invoiceReleaseBankTransRoute,
                            arguments: {
                              'customerCompanyRef': chatData
                                      ?.chatCustomerCompanyRef
                                      ?.customerCompaniesId
                                      ?.sId ??
                                  '',
                              'customerRef':
                                  chatData?.chatUsers?.customerId ?? '',
                              'subaccountId': chatData
                                      ?.chatUsers?.subaccountId?.sId ??
                                  chatProvider
                                      ?.userId, // Use correct subaccountId field
                              'name': chatData?.chatCustomerCompanyRef
                                      ?.customerCompaniesId?.companyName ??
                                  '',
                              'chatId': chatData?.sId ?? '',
                              'companyId': {
                                'companyName': chatData
                                        ?.chatUsers?.companyId?.companyName ??
                                    '',
                                'commercialName': chatData?.chatUsers?.companyId
                                        ?.commercialName ??
                                    '',
                                'commercialNumber': chatData?.chatUsers
                                        ?.companyId?.commercialNumber ??
                                    '',
                                'vATNumber':
                                    chatData?.chatUsers?.companyId?.vATNumber ??
                                        '',
                              },
                              'chatCustomerCompanyRef': {
                                'customer_companiesId': {
                                  'companyName': chatData
                                          ?.chatCustomerCompanyRef
                                          ?.customerCompaniesId
                                          ?.companyName ??
                                      '',
                                  'commercialName': chatData
                                          ?.chatCustomerCompanyRef
                                          ?.customerCompaniesId
                                          ?.commercialName ??
                                      '',
                                  'commercialNumber': chatData
                                          ?.chatCustomerCompanyRef
                                          ?.customerCompaniesId
                                          ?.commercialNumber ??
                                      '',
                                  'vATNumber': chatData?.chatCustomerCompanyRef
                                          ?.customerCompaniesId?.vATNumber ??
                                      '',
                                }
                              }
                            },
                          ) as Map<String, dynamic>?;

                          if (invoiceData != null && mounted) {
                            Navigator.pop(dialogContext);
                            await _handleSendMessage(
                              messageText: '[INVOICE]',
                              paymentType:
                                  invoiceData, // ✅ Now passing full invoice data
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.blueLight800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          if (!mounted) return;
          await openAppSettings();
          return;
        }
      }
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        await openAppSettings();
        return;
      }

      await showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => PhotoAttachmentWidget(
          onPhotosSelected: (photoPaths) async {
            setState(() {
              photos = photoPaths;
              isExpanded = false;
            });

            await _handleSendMessage(
              messageText: '[IMAGE]',
              photoPaths: photos,
            );
          },
          onClose: () {
            setState(() => isExpanded = false);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          if (!mounted) return;
          await openAppSettings();
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        await openAppSettings();
        return;
      }

      List<SelectedFile>? selectedMedia;
      if (Platform.isIOS) {
        selectedMedia = await CustomVideoPicker.selectMediaWithWeChatPicker(
          context,
          isVideo: true,
          mediaSource: MediaSource.videoGallery,
          multiImage: false,
        );
      } else {
        selectedMedia = await CustomVideoPicker.selectMediaWithWeChatPicker(
          context,
          isVideo: true,
          mediaSource: MediaSource.videoGallery,
          multiImage: false,
        );
      }

      if (selectedMedia == null || selectedMedia.isEmpty) {
        return;
      }

      final selectedFile = selectedMedia.first;

      // Check file size against server limit (65MB)
      if (selectedFile.bytes.length > 65 * 1024 * 1024) {
        if (mounted) {
          await CustomVideoPicker.showServerFileSizeErrorDialog(context);
        }
        return;
      }

      //file size should be less than 50 MB
      if (selectedFile.bytes.length > 50 * 1024 * 1024) {
        await CustomVideoPicker.showFileSizeErrorDialog(context);
        return;
      }

      if (selectedFile.filePath != null) {
        setState(() {
          videoPathParam = selectedFile.filePath;
          isExpanded = false;
        });

        await _handleSendMessage(
          messageText: '[VIDEO]',
          videoPathParam: selectedFile.filePath,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking video')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          if (!mounted) return;
          await openAppSettings();
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        await openAppSettings();
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          docs = [
            {
              'url': file.path!,
              'name': file.name,
              'size': file.size,
              'extension': file.extension,
            }
          ];
          isExpanded = false;
        });

        await _handleSendMessage(
          messageText: '[Document]',
          documents: docs,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking document')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug prints for audio state
    debugPrint('=== Building MessageInput ===');
    debugPrint('isAudioRecording: $isAudioRecording');
    debugPrint('isAudioPaused: $isAudioPaused');
    debugPrint('audioRecord: $audioRecord');
    debugPrint('audioDeleteDisable: $audioDeleteDisable');
    debugPrint('_isSendingAudio: $_isSendingAudio');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (!isAudioRecording &&
                    !(isAudioPaused && audioRecord != null))
                  InkWell(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorManager.blueLight800,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isExpanded ? Icons.close : Icons.add,
                          color: Colors.white,
                          size: 20.0,
                        ),
                        onPressed: null,
                      ),
                    ),
                  ),
                if (!isAudioRecording &&
                    !(isAudioPaused && audioRecord != null))
                  const SizedBox(width: 8),
                if (!isAudioRecording &&
                    !(isAudioPaused && audioRecord != null)) ...[
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) async {
                        if (text.trim().isNotEmpty) {
                          final messageToSend = text.trim();
                          widget.controller.clear(); // Clear immediately

                          // For customers, send immediately without any delay
                          if (widget.isCustomer) {
                            // Clear typing indicator immediately for customers
                            try {
                              final provider =
                                  ChatProviderInherited.of(context);
                              provider.stopTyping();
                            } catch (e) {
                              if (kDebugMode) {
                                print('Error stopping typing status: $e');
                              }
                            }
                          }

                          await _handleSendMessage(
                            messageText: messageToSend,
                          );
                        }
                      },
                      onChanged: (text) {
                        // For customers, enable send button immediately when text is entered
                        if (widget.isCustomer && text.trim().isNotEmpty) {
                          setState(() {
                            _isTyping = true;
                          });
                        }
                      },
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: widget.isCustomer
                            ? 'Type your message...'
                            : 'Type a message...',
                        hintStyle: const TextStyle(color: ColorManager.gray100),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorManager.blueLight800,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: ColorManager.gray100,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: ColorManager.gray100,
                          ),
                        ),
                        filled: true,
                        fillColor: ColorManager.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (!(isAudioPaused && audioRecord != null))
                    const SizedBox(width: 8),
                  if (!(isAudioPaused && audioRecord != null))
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSendingAudio
                            ? ColorManager.gray100
                            : (widget.controller.text.trim().isNotEmpty ||
                                    (isAudioPaused && audioRecord != null)
                                ? ColorManager.blueLight800
                                : ColorManager.gray100),
                      ),
                      child: IconButton(
                        icon: _isSendingAudio
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_outlined,
                                color: Colors.white),
                        onPressed: (_isSendingAudio ||
                                widget.controller.text.trim().isNotEmpty ||
                                (isAudioPaused && audioRecord != null))
                            ? () async {
                                debugPrint('=== Main send button pressed ===');
                                debugPrint('Is audio paused: $isAudioPaused');
                                debugPrint('Audio record: $audioRecord');
                                debugPrint(
                                    'Timer stopped value: $timerStoppedValue');

                                String messageToSend =
                                    widget.controller.text.trim();
                                widget.controller.clear(); // Clear immediately

                                // For customers, clear typing indicator immediately
                                if (widget.isCustomer) {
                                  try {
                                    final provider =
                                        ChatProviderInherited.of(context);
                                    provider.stopTyping();
                                  } catch (e) {
                                    if (kDebugMode) {
                                      print('Error stopping typing status: $e');
                                    }
                                  }
                                }

                                // Handle audio
                                if (isAudioPaused && audioRecord != null) {
                                  messageToSend = '[AUDIO]';
                                  debugPrint(
                                      'Setting message text to [AUDIO] in main send button');
                                }

                                debugPrint(
                                    'About to call _handleSendMessage with:');
                                debugPrint('Message text: $messageToSend');
                                debugPrint('Audio path: $audioRecord');
                                debugPrint(
                                    'Audio duration: ${timerStoppedValue != null ? timerStoppedValue! / 1000 : null}');

                                await _handleSendMessage(
                                  messageText: messageToSend,
                                  audioPath: audioRecord,
                                  audioDuration: timerStoppedValue != null
                                      ? timerStoppedValue! / 1000
                                      : null,
                                );

                                debugPrint(
                                    '=== _handleSendMessage completed in main send button ===');
                              }
                            : null,
                        style: IconButton.styleFrom(
                          disabledForegroundColor:
                              Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ],
            ),
            if (isExpanded && !isAudioRecording)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 1.0,
                  childAspectRatio: 1.3,
                  children: [
                    _AttachmentOption(
                      icon: Icons.image,
                      color: ColorManager.blueLight800,
                      label: 'Photo',
                      onTap: () async {
                        await _pickImage();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.videocam,
                      color: ColorManager.blueLight800,
                      label: 'Video',
                      onTap: () async {
                        await _pickVideo();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.insert_drive_file,
                      color: ColorManager.blueLight800,
                      label: 'Documents',
                      onTap: () async {
                        await _pickDocument();
                      },
                    ),
                    if (!widget.isTicketChat) ...[
                      _AttachmentOption(
                        icon: Icons.mic,
                        color: ColorManager.blueLight800,
                        label: 'Voice Note',
                        onTap: () async {
                          setState(() => isExpanded = false);
                          await _startAudioRecording();
                        },
                      ),
                      _AttachmentOption(
                        icon: Icons.location_on,
                        color: ColorManager.blueLight800,
                        label: 'Location',
                        onTap: () async {
                          setState(() => isExpanded = false);

                          final hasPermission =
                              await _requestLocationPermission();
                          if (!hasPermission) return;

                          if (!mounted) return;

                          try {
                            // Get the providers before navigation
                            final chatProvider =
                                ChatProviderInherited.of(context);

                            // Navigate to location picker screen with provider
                            debugPrint('=== Navigating to location picker ===');
                            final result =
                                await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChangeNotifierProvider<ChatProvider>.value(
                                  value: chatProvider,
                                  child: LocationPickerScreen(
                                    chatId: chatProvider?.chatId ?? '',
                                    userId: chatProvider?.userId ?? '',
                                    userRole: chatProvider?.userRole ?? '',
                                  ),
                                ),
                              ),
                            );

                            debugPrint(
                                '=== Location picker navigation result: $result ===');

                            // Handle the result
                            if (result != null &&
                                result['success'] == true &&
                                mounted) {
                              // Location was sent successfully
                              debugPrint(
                                  '=== Location sent successfully, updating UI ===');

                              // Extract location data and send it through the proper flow
                              final locationData =
                                  result['location'] as Map<String, dynamic>?;
                              if (locationData != null) {
                                debugPrint(
                                    '=== Sending location through cubit: $locationData ===');
                                await _handleSendMessage(
                                  messageText: '[LOCATION]',
                                  location:
                                      locationData, // Pass the map directly
                                );
                              }

                              setState(() {});
                            } else {
                              debugPrint(
                                  '=== Location picker returned false or null ===');
                            }
                          } catch (e) {
                            debugPrint('Error in location picker: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error accessing location'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      if (!widget.isCustomer) ...[
                        _AttachmentOption(
                          icon: Icons.payments,
                          color: ColorManager.blueLight800,
                          label: 'Release Invoice',
                          onTap: () {
                            _showPaymentDialog();
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            if (isAudioRecording || (isAudioPaused && audioRecord != null))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    if (isAudioPaused)
                      Container(
                        width: MediaQuery.of(context).size.width * 0.13,
                        height: MediaQuery.of(context).size.width * 0.13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 24.0,
                          ),
                          onPressed: audioDeleteDisable
                              ? null
                              : () {
                                  _resetAudioPlayer();
                                  setState(() {
                                    isAudioRecording = false;
                                    audioRecord = null;
                                    isAudioPaused = false;
                                    timerStoppedValue = null;
                                    audioURL = null;
                                  });
                                },
                        ),
                      )
                    else
                      Container(
                        width: MediaQuery.of(context).size.width * 0.13,
                        height: MediaQuery.of(context).size.width * 0.13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.pause_outlined,
                            color: Colors.red,
                            size: 24.0,
                          ),
                          onPressed: _stopAudioRecording,
                        ),
                      ),
                    const SizedBox(width: 16.0),
                    if (!isAudioPaused)
                      Expanded(
                        child: Container(
                          height: 45.0,
                          decoration: BoxDecoration(
                            color: ColorManager.gray200,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    'assets/images/Voice.png',
                                    width: 160.0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Text(
                                  timerValue,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (isAudioPaused)
                      Expanded(
                        child: _buildAudioPlayer(),
                      ),
                    const SizedBox(width: 16.0),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.13,
                      height: MediaQuery.of(context).size.width * 0.13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSendingAudio
                            ? ColorManager.gray100
                            : ColorManager.blueLight800,
                      ),
                      child: IconButton(
                        icon: _isSendingAudio
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20.0,
                              ),
                        onPressed: (_isSendingAudio ||
                                widget.controller.text.isNotEmpty ||
                                photos.isNotEmpty ||
                                videoPathParam != null ||
                                docs.isNotEmpty ||
                                (isAudioPaused && audioRecord != null) ||
                                isAudioRecording)
                            ? () async {
                                debugPrint(
                                    '=== Audio recording send button pressed ===');
                                debugPrint('Is audio paused: $isAudioPaused');
                                debugPrint('Audio record: $audioRecord');
                                debugPrint(
                                    'Timer stopped value: $timerStoppedValue');

                                String messageText = widget.controller.text;
                                widget.controller.clear();
                                audioDeleteDisable = true;

                                // Handle different send scenarios
                                String? audioPathToSend;
                                double? audioDurationToSend;

                                if (isAudioRecording) {
                                  // If currently recording, stop recording first and get the audio
                                  debugPrint(
                                      '=== Stopping recording to send audio ===');
                                  await _stopAudioRecording();
                                  audioPathToSend = audioRecord;
                                  audioDurationToSend =
                                      timerStoppedValue != null
                                          ? timerStoppedValue! / 1000
                                          : null;
                                  messageText = '[AUDIO]';
                                } else if (isAudioPaused &&
                                    audioRecord != null) {
                                  // If audio is paused and ready to send
                                  audioPathToSend = audioRecord;
                                  audioDurationToSend =
                                      timerStoppedValue != null
                                          ? timerStoppedValue! / 1000
                                          : null;
                                  messageText = '[AUDIO]';
                                } else if (photos.isNotEmpty) {
                                  messageText = '[IMAGE]';
                                } else if (videoPathParam != null) {
                                  messageText = '[VIDEO]';
                                } else if (docs.isNotEmpty) {
                                  messageText = '[DOCUMENT]';
                                }

                                // Clear audio state immediately to prevent multiple sends
                                setState(() {
                                  // Clear audio state immediately
                                  isAudioRecording = false;
                                  isAudioPaused = false;
                                  audioRecord = null;
                                  audioURL = null;
                                  timerStoppedValue = null;
                                  audioDeleteDisable = false;
                                });

                                debugPrint(
                                    'About to call _handleSendMessage with:');
                                debugPrint('Message text: $messageText');
                                debugPrint('Audio path: $audioPathToSend');
                                debugPrint(
                                    'Audio duration: $audioDurationToSend');

                                try {
                                  await _handleSendMessage(
                                    messageText: messageText,
                                    audioPath: audioPathToSend,
                                    audioDuration: audioDurationToSend,
                                  );

                                  debugPrint(
                                      '=== _handleSendMessage completed in audio recording send button ===');
                                } catch (e) {
                                  debugPrint(
                                      '=== ERROR in audio recording send button ===');
                                  debugPrint('Error: $e');
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    if (audioRecord == null) return const SizedBox.shrink();

    return Container(
      width: 236.0,
      height: 68.0,
      decoration: BoxDecoration(
        color: ColorManager.gray100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: ColorManager.blueLight800,
                ),
                onPressed: _playAudio,
              ),
              Expanded(
                child: Slider(
                  value: _audioDuration.inMilliseconds > 0
                      ? _audioPosition.inMilliseconds.toDouble()
                      : 0.0,
                  min: 0,
                  max: _audioDuration.inMilliseconds > 0
                      ? _audioDuration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    if (_audioDuration.inMilliseconds > 0) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    }
                  },
                  activeColor: ColorManager.blueLight800,
                  inactiveColor: ColorManager.gray400,
                  thumbColor: ColorManager.blueLight800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _formatDuration(_audioPosition),
                  style: const TextStyle(
                    color: ColorManager.primaryText,
                    fontSize: 8.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required Color color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorManager.blueLight800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.cardColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

extension ListDivider on List<Widget> {
  List<Widget> divide(Widget divider) {
    final result = <Widget>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(divider);
      }
    }
    return result;
  }
}
