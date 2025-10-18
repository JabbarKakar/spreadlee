import 'package:flutter/material.dart';
import '../models/social_media_model.dart';

class SocialMediaDropdown extends StatelessWidget {
  final String mediaImg;
  final String media;
  final String accountName;
  final int index;
  final Function(String) onAccountNameChanged;
  final VoidCallback onRemove;
  final Function(String) onPlatformChanged;

  const SocialMediaDropdown({
    Key? key,
    required this.mediaImg,
    required this.media,
    required this.accountName,
    required this.index,
    required this.onAccountNameChanged,
    required this.onRemove,
    required this.onPlatformChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Platform Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: media,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              selectedItemBuilder: (context) {
                return availableSocialMedia.map((platform) {
                  return Row(
                    children: [
                      Image.network(
                        platform.img,
                        width: 24,
                        height: 24,
                      ),
                    ],
                  );
                }).toList();
              },
              items: availableSocialMedia.map((platform) {
                return DropdownMenuItem<String>(
                  value: platform.name,
                  child: SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        Image.network(
                          platform.img,
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            platform.name,
                            // overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 6, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onPlatformChanged(value);
              },
            ),
          ),
          const SizedBox(width: 65),
          // Username TextField
          Expanded(
            child: TextField(
              onChanged: onAccountNameChanged,
              decoration: InputDecoration(
                hintText: 'Enter Username',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          // Delete Button
          Material(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.delete, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
