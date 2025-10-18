import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import '../models/social_media_model.dart';
import 'social_media_dropdown.dart';

class SocialMediaAdder extends StatefulWidget {
  final Function(List<SocialMediaModel>) onSocialMediaChanged;

  const SocialMediaAdder({
    Key? key,
    required this.onSocialMediaChanged, required List<Map<String, String>> initialAccounts,
  }) : super(key: key);

  @override
  State<SocialMediaAdder> createState() => _SocialMediaAdderState();
}

class _SocialMediaAdderState extends State<SocialMediaAdder> {
  final List<SocialMediaModel> _addedAccounts = [];

  void _addNewAccount() {
    setState(() {
      _addedAccounts.add(availableSocialMedia[0]); // Default to YouTube
    });
    widget.onSocialMediaChanged(_addedAccounts);
  }

  void _removeAccount(int index) {
    setState(() {
      _addedAccounts.removeAt(index);
    });
    widget.onSocialMediaChanged(_addedAccounts);
  }

  void _updateAccountName(int index, String newName) {
    setState(() {
      _addedAccounts[index] = SocialMediaModel(
        name: _addedAccounts[index].name,
        img: _addedAccounts[index].img,
        accountName: newName,
      );
    });
    widget.onSocialMediaChanged(_addedAccounts);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.gray400,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(_addedAccounts.length, (index) {
            final account = _addedAccounts[index];
            return SocialMediaDropdown(
              key: Key('social_media_$index'),
              mediaImg: account.img,
              media: account.name,
              accountName: account.accountName,
              index: index,
              onAccountNameChanged: (value) => _updateAccountName(index, value),
              onRemove: () => _removeAccount(index),
              onPlatformChanged: (newPlatform) {
                final selected = availableSocialMedia
                    .firstWhere((sm) => sm.name == newPlatform);
                setState(() {
                  _addedAccounts[index] = SocialMediaModel(
                    name: selected.name,
                    img: selected.img,
                    accountName: _addedAccounts[index].accountName,
                  );
                });
                widget.onSocialMediaChanged(_addedAccounts);
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: _addNewAccount,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28.0,
                    height: 28.0,
                    decoration: BoxDecoration(
                      color: ColorManager.blueLight800,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: const Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    'Add New',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
