import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'view_file_screen.dart';
import 'replace_file_screen.dart';

import '../../resources/color_manager.dart';

class DetailsPricingContainer extends StatefulWidget {
  const DetailsPricingContainer({super.key});

  @override
  State<DetailsPricingContainer> createState() =>
      _DetailsPricingContainerState();
}

class _DetailsPricingContainerState extends State<DetailsPricingContainer> {
  final String _fileName = 'Pricing Details.pdf'; // Mock data
  final bool _isLoading = false;

  String _getFileNameFromPath(String path) {
    return path.split('/').last;
  }

  Future<void> _viewFile() async {
    final currentState = context.read<SettingCubit>().state;
    if (currentState is SettingSuccessState) {
      if (currentState.settings.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewFileScreen(
              pricingDetails: currentState.settings.first.pricingDetails,
            ),
          ),
        );
      }
    }
  }

  Future<void> _replaceFile() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const ReplaceFileScreen(),
    );

    if (result != null && mounted) {
      // Here you would typically update the pricing details in your backend
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pricing details updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingCubit, SettingState>(
      builder: (context, state) {
        if (state is SettingLoadingState) {
          return Center(
            child: CircularProgressIndicator(
              color: ColorManager.blueLight800,
            ),
          );
        } else if (state is SettingSuccessState) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.description,
                        color: ColorManager.blueLight800,
                        size: 24.0,
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Text(
                          _getFileNameFromPath(
                              state.settings.first.pricingDetails),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _viewFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.blueLight800,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(100, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          disabledBackgroundColor:
                              theme.primaryColor.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'View',
                                style: TextStyle(
                                    fontSize: 12, fontFamily: 'Poppins'),
                              ),
                      ),
                      const SizedBox(width: 12.0),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _replaceFile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorManager.blueLight800,
                          side: BorderSide(color: ColorManager.blueLight800),
                          minimumSize: const Size(100, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          disabledForegroundColor:
                              theme.primaryColor.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ColorManager.blueLight800),
                                ),
                              )
                            : const Text(
                                'Replace',
                                style: TextStyle(
                                    fontSize: 12, fontFamily: 'Poppins'),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        // Default return for other states
        return const SizedBox.shrink();
      },
    );
  }
}
