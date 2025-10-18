import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/widgets/photo_attachment_widget.dart';

class MessageInput extends StatefulWidget {
  final Function(String message, {List<String>? photoPaths}) onSendMessage;

  const MessageInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  bool _isExpanded = false;
  List<String> _selectedPhotos = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => PhotoAttachmentWidget(
        onPhotosSelected: (photoPaths) {
          setState(() {
            _selectedPhotos = photoPaths;
            _isExpanded = false;
          });
          widget.onSendMessage('[IMAGE]', photoPaths: photoPaths);
        },
        onClose: () {
          setState(() => _isExpanded = false);
        },
      ),
    );
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty || _selectedPhotos.isNotEmpty) {
      widget.onSendMessage(
        message,
        photoPaths: _selectedPhotos.isNotEmpty ? _selectedPhotos : null,
      );
      _messageController.clear();
      setState(() {
        _selectedPhotos = [];
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AttachmentOption(
                        icon: Icons.image,
                        color: ColorManager.blueLight800,
                        label: 'Photo',
                        onTap: _showPhotoOptions,
                      ),
                      _AttachmentOption(
                        icon: Icons.videocam,
                        color: ColorManager.blueLight800,
                        label: 'Video',
                        onTap: () {
                          // Implement video attachment
                        },
                      ),
                      _AttachmentOption(
                        icon: Icons.insert_drive_file,
                        color: ColorManager.blueLight800,
                        label: 'Document',
                        onTap: () {
                          // Implement document attachment
                        },
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    icon: Icon(
                      _isExpanded ? Icons.close : Icons.add_circle_outline,
                      color: ColorManager.blueLight800,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: ColorManager.gray100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 5,
                      minLines: 1,
                    ),
                  ),
                  IconButton(
                    onPressed: _handleSendMessage,
                    icon: Icon(
                      Icons.send,
                      color: ColorManager.blueLight800,
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
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: ColorManager.gray500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
