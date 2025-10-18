import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_cubit.dart';
import 'package:spreadlee/presentation/bloc/business/setting/setting_states.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:spreadlee/presentation/business/settings/widget/gallery_cam_remove_widget.dart';
import 'package:flutter/foundation.dart';

class EditBusinessProfilePhotoScreen extends StatefulWidget {
  const EditBusinessProfilePhotoScreen({super.key});

  @override
  State<EditBusinessProfilePhotoScreen> createState() =>
      _EditBusinessProfilePhotoScreenState();
}

class _EditBusinessProfilePhotoScreenState
    extends State<EditBusinessProfilePhotoScreen> {
  String? _selectedImagePath;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<SettingCubit>().getPhoto();
  }

  Future<void> _showPhotoOptions() async {
    String? currentPhotoUrl;
    if (context.read<SettingCubit>().state is SettingPhotoSuccessState) {
      currentPhotoUrl =
          (context.read<SettingCubit>().state as SettingPhotoSuccessState)
              .photo
              .photoUrl;
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return GalleryCamRemoveWidget(
          currentPhotoUrl: currentPhotoUrl,
          onPhotoSelected: (String path) {
            setState(() {
              _selectedImagePath = path;
            });
          },
          onPhotoRemoved: () async {
            await context.read<SettingCubit>().deletePhoto();
            setState(() {
              _selectedImagePath = null;
            });
          },
        );
      },
    );
  }

  Future<void> _savePhoto() async {
    if (_selectedImagePath != null) {
      final file = await MultipartFile.fromFile(
        _selectedImagePath!,
        filename: _selectedImagePath!.split('/').last,
      );
      await context.read<SettingCubit>().editPhoto(photoUrl: file);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingCubit, SettingState>(
      listener: (context, state) {
        if (state is CreateSettingErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error updating profile photo'),
              backgroundColor: ColorManager.lightError,
            ),
          );
        }
      },
      builder: (context, state) {
        if (kDebugMode) {
          print("Current state: $state");
          if (state is SettingPhotoSuccessState) {
            print("Photo URL: ${state.photo.photoUrl}");
          }
        }
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: ColorManager.gray50,
            appBar: AppBar(
              backgroundColor: ColorManager.secondaryBackground,
              automaticallyImplyLeading: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24.0,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Align(
                alignment: const AlignmentDirectional(-1.0, 0.0),
                child: Text(
                  'Settings'.tr(),
                  textAlign: TextAlign.start,
                  style: getMediumStyle(
                    fontSize: 16.0,
                    color: ColorManager.primaryText,
                  ),
                ),
              ),
              centerTitle: true,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: Align(
                alignment: const AlignmentDirectional(0.0, -1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 28.0, 0.0, 24.0),
                      child: Text(
                        'Profile Photo'.tr(),
                        style: getRegularStyle(
                          color: ColorManager.gray500,
                        ),
                      ),
                    ),
                    Stack(
                      alignment: const AlignmentDirectional(1.0, 1.0),
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            if (state is SettingPhotoSuccessState) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    backgroundColor: Colors.black,
                                    body: Center(
                                      child: Image.network(
                                        state.photo.photoUrl,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Hero(
                            tag: state is SettingPhotoSuccessState
                                ? state.photo.photoUrl
                                : 'default_photo',
                            transitionOnUserGestures: true,
                            child: Container(
                              width: 112.0,
                              height: 112.0,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: _selectedImagePath != null
                                  ? Image.file(
                                      File(_selectedImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : state is SettingPhotoSuccessState
                                      ? Image.network(
                                          state.photo.photoUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                                color:
                                                    ColorManager.blueLight800,
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print("Image error: $error");
                                            return Icon(
                                              Icons.business,
                                              size: 80,
                                              color: ColorManager.gray400,
                                            );
                                          },
                                        )
                                      : Icon(
                                          Icons.business,
                                          size: 80,
                                          color: ColorManager.gray400,
                                        ),
                            ),
                          ),
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: _showPhotoOptions,
                          child: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: const BoxDecoration(
                              color: ColorManager.gray100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: ColorManager.blueLight800,
                              size: 16.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Save Button
                    if (_selectedImagePath != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state is CreateSettingLoadingState
                                ? null
                                : _savePhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.blueLight800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: state is CreateSettingLoadingState
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Save Changes'.tr()),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
