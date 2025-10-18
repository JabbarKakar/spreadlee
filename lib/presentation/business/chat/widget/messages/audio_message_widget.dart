import 'package:flutter/material.dart';
import 'package:spreadlee/domain/chat_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class AudioMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isFromUser;
  final DateTime? lastReadMessageDate;
  final Function(String)? onAudioTap;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onMessageVisible;

  const AudioMessageWidget({
    Key? key,
    required this.message,
    required this.isFromUser,
    this.lastReadMessageDate,
    this.onAudioTap,
    required this.chatId,
    required this.currentUserId,
    this.onMessageVisible,
  }) : super(key: key);

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (widget.message.messageAudio != null) {
      try {
        debugPrint(
            'Initializing audio player with: ${widget.message.messageAudio}');

        // Check if it's a local file path or remote URL
        if (widget.message.messageAudio!.startsWith('http')) {
          // Remote URL
          await _audioPlayer.setUrl(widget.message.messageAudio!);
          debugPrint('Set remote audio URL successfully');
        } else {
          // Local file path
          final file = File(widget.message.messageAudio!);
          if (!await file.exists()) {
            throw Exception(
                'Audio file does not exist: ${widget.message.messageAudio}');
          }
          debugPrint('Audio file exists, size: ${await file.length()} bytes');
          await _audioPlayer.setFilePath(widget.message.messageAudio!);
          debugPrint('Set local audio file path successfully');
        }

        _duration = _audioPlayer.duration ?? Duration.zero;
        debugPrint('Audio duration: $_duration');

        _audioPlayer.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
            debugPrint(
                'Audio player state: ${state.processingState} - playing: ${state.playing}');
            if (state.processingState == ProcessingState.completed) {
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          }
        });

        _audioPlayer.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _position = position;
            });
          }
        });
      } catch (e) {
        debugPrint('Error loading audio: $e');
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Error loading audio: $e'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      }
    } else {
      debugPrint('No audio URL provided in message');
    }
  }

  Future<void> _togglePlayPause() async {
    if (widget.message.messageAudio == null) {
      debugPrint('No audio URL available for playback');
      return;
    }

    debugPrint('Toggling play/pause. Current state: $_isPlaying');
    debugPrint('Audio URL: ${widget.message.messageAudio}');
    debugPrint('Current position: $_position, Duration: $_duration');

    if (_isPlaying) {
      debugPrint('Pausing audio playback');
      await _audioPlayer.pause();
    } else {
      // If the audio has reached the end, seek to the beginning before playing
      if (_position >= _duration && _duration > Duration.zero) {
        debugPrint('Audio reached end, seeking to beginning');
        await _audioPlayer.seek(Duration.zero);
        // Update the position state immediately to reflect the seek
        if (mounted) {
          setState(() {
            _position = Duration.zero;
          });
        }
      }

      if (widget.onAudioTap != null) {
        debugPrint('Calling onAudioTap callback');
        widget.onAudioTap!(widget.message.messageAudio!);
      }

      debugPrint('Starting audio playback');
      try {
        await _audioPlayer.play();
        debugPrint('Audio playback started successfully');
      } catch (e) {
        debugPrint('Error starting audio playback: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine sender role - prioritize messageCreatorRole over messageCreator.role
    // This handles cases where messageCreator object might be incorrect but messageCreatorRole is correct
    final senderRole = widget.message.messageCreatorRole?.toLowerCase() ??
        (widget.message.messageCreator?.role.toLowerCase() ?? '');
    Color bubbleColor;
    if (senderRole == 'customer') {
      bubbleColor = ColorManager.blueLight800;
    } else if (senderRole == 'company' || senderRole == 'influencer') {
      bubbleColor = ColorManager.gray500;
    } else if (senderRole == 'subaccount') {
      bubbleColor = ColorManager.primaryGreen;
    } else {
      bubbleColor = ColorManager.primaryGreen;
    }
    // Get status values from message
    final isSeen = widget.message.isSeen ?? false;
    final isReceived = widget.message.isReceived ?? false;
    final isRead = widget.message.isRead ?? false;
    final isDelivered = widget.message.isDelivered ?? false;

    // Determine message status based on proper progression: sent → delivered → read
    String? messageStatus;
    if (widget.isFromUser && widget.message.isFailed != true) {
      if (isRead || isSeen) {
        messageStatus = 'read'; // Blue double check - message has been read
      } else if (isReceived && isDelivered) {
        messageStatus =
            'delivered'; // Gray double check - message delivered but not read
      } else {
        messageStatus =
            'sent'; // Gray single check - message sent but not delivered
      }
    }
    return Column(
      crossAxisAlignment:
          widget.isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: const BoxConstraints(
            maxWidth: 270,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderRole.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    senderRole == 'customer'
                        ? 'Customer'
                        : (senderRole == 'company' ||
                                senderRole == 'influencer')
                            ? 'Manager'
                            : senderRole == 'subaccount'
                                ? 'Employee'
                                : 'Employee',
                    style: getRegularStyle(
                      fontSize: 11,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            min: 0,
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) async {
                              final position = Duration(seconds: value.toInt());
                              await _audioPlayer.seek(position);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.isFromUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Text(
                _formatMessageTime(widget.message.messageDate),
                style: getRegularStyle(
                  fontSize: 12,
                  color: widget.message.isFailed == true
                      ? ColorManager.error
                      : widget.isFromUser
                          ? ColorManager.black.withOpacity(0.7)
                          : ColorManager.black,
                ),
              ),
              if (widget.isFromUser && messageStatus != 'pending')
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    messageStatus == 'read' ||
                            messageStatus == 'delivered' ||
                            widget.message.isDelivered == true ||
                            widget.message.isRead == true
                        ? Icons.done_all // Double check for delivered/read
                        : Icons.check, // Single check for sent
                    size: 16,
                    color: messageStatus == 'read' ||
                            widget.message.isSeen == true ||
                            widget.message.isRead == true
                        ? ColorManager.black
                            .withOpacity(0.7)
                        : ColorManager.black
                            .withOpacity(0.7), // Gray for sent/delivered
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'moments ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24 &&
        now.day == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
