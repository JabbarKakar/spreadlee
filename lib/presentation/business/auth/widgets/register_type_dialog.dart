import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';

import '../../../resources/routes_manager.dart';

enum RegisterType {
  company,
  influencer,
}

class RegisterTypeDialog extends StatefulWidget {
  const RegisterTypeDialog({super.key});

  @override
  State<RegisterTypeDialog> createState() => _RegisterTypeDialogState();
}

class _RegisterTypeDialogState extends State<RegisterTypeDialog> {
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Register as?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 45,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 18.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedItem,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                hint: const Text('Select Registration Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'As Influencer',
                    child: Text('As Influencer'),
                  ),
                  DropdownMenuItem(
                    value: 'As Company',
                    child: Text('As Company'),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    selectedItem = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              height: 40.0,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedItem == 'As Influencer') {
                    Navigator.pushNamed(
                        context, Routes.registerInfluencerRoute);
                  } else if (selectedItem == 'As Company') {
                    Navigator.pushNamed(context, Routes.registerCompanyRoute);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.blueLight800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
