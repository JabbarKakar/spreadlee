import 'package:flutter/material.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:spreadlee/presentation/resources/routes_manager.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  Future<void> _launchPhoneCall(
      BuildContext context, String phoneNumber) async {
    try {
      final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(
        scheme: 'tel',
        path: cleanNumber,
      );

      debugPrint('Attempting to launch phone call: $phoneUri');

      if (await launcher.canLaunchUrl(phoneUri)) {
        await launcher.launchUrl(phoneUri);
        debugPrint('Phone call launched successfully');
      } else {
        throw Exception('Could not launch phone call to $cleanNumber');
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error launching phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@spreadlee.com',
        query: 'subject=Support Request&body=Hello, I need help with...',
      );

      debugPrint('Attempting to launch email: $emailUri');

      if (await launcher.canLaunchUrl(emailUri)) {
        await launcher.launchUrl(emailUri);
        debugPrint('Email launched successfully');
      } else {
        throw Exception('Could not launch email to support@spreadlee.com');
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (!context.mounted) return;
      _showEmailDialog(context);
    }
  }

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to open email app automatically.'),
              const SizedBox(height: 16),
              const Text('Please copy the email address:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  'support@spreadlee.com',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPhoneNumberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 270,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Inside KSA Number:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '011219975',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.phone,
                          color: ColorManager.blueLight800,
                          size: 20,
                        ),
                        onPressed: () => _launchPhoneCall(context, '011219975'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'International Phone Number:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '+96611219975',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.phone,
                          color: ColorManager.blueLight800,
                          size: 20,
                        ),
                        onPressed: () =>
                            _launchPhoneCall(context, '+96611219975'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorManager.blueLight800.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: ColorManager.blueLight800,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: ColorManager.lightGrey,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.customerHomeRoute),
        ),
        title: Text(
          AppStrings.contactUs.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildContactOption(
            title: AppStrings.allTickets.tr(),
            icon: Icons.confirmation_number_outlined,
            onTap: () =>
                Navigator.pushNamed(context, Routes.ticketsRoute),
          ),
          _buildContactOption(
            title: AppStrings.email.tr(),
            icon: Icons.email_outlined,
            onTap: () => _launchEmail(context),
          ),
          _buildContactOption(
            title: AppStrings.phoneNumber.tr(),
            icon: Icons.phone_outlined,
            onTap: () => _showPhoneNumberDialog(context),
          ),
        ],
      ),
    );
  }
}
