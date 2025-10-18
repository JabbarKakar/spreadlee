import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/bloc/customer/reviews_bloc/reviews_cubit.dart';
import 'package:spreadlee/presentation/bloc/customer/reviews_bloc/reviews_state.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/routes_manager.dart';
import 'package:spreadlee/presentation/resources/style_manager.dart';
import 'package:spreadlee/domain/customer_company_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddReviewWidget extends StatefulWidget {
  const AddReviewWidget({
    super.key,
    required this.influencerDoc,
    required this.customerCompany,
  });

  final InvoiceCompanyRef? influencerDoc;
  final CustomerCompanyDataModel? customerCompany;

  @override
  State<AddReviewWidget> createState() => _AddReviewWidgetState();
}

class _AddReviewWidgetState extends State<AddReviewWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  double _ratingBarValue = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  String? _textControllerValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a review';
    }
    if (value.length < 10) {
      return 'Review must be at least 10 characters long';
    }
    return null;
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ratingBarValue == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: ColorManager.lightError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<ReviewsCubit>().addReview(
            description: _textController.text,
            rating: _ratingBarValue.toString(),
            title: widget.customerCompany?.commercialName ?? 'Customer Review',
            companyId: widget.influencerDoc?.id ?? '',
            context: context,
          );

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              content: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rate and Review has been successfully sent',
                      textAlign: TextAlign.center,
                      style: getMediumStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                  context, Routes.customerHomeRoute);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.blueLight800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: getMediumStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error submitting review'),
            backgroundColor: ColorManager.lightError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRatingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _ratingBarValue = index + 1.0;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.star_rounded,
              color: index < _ratingBarValue
                  ? const Color(0xFFFFD700)
                  : Colors.grey[300],
              size: 48.0,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () => Future.value(false),
        child: Scaffold(
          backgroundColor: ColorManager.gray50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: Text(
              'Rate and Review',
              style: getMediumStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            centerTitle: false,
            elevation: 0.0,
          ),
          body: SafeArea(
            top: true,
            child: BlocListener<ReviewsCubit, ReviewsState>(
              listener: (context, state) {
                if (state is ReviewsErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Error submitting review'),
                      backgroundColor: ColorManager.lightError,
                    ),
                  );
                }
              },
              child: ListView(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.vertical,
                children: [
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.85,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0, 0.0, 16.0, 0.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 8.0),
                                  child: Container(
                                    width: 80.0,
                                    height: 80.0,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: widget
                                              .influencerDoc?.photoUrl ??
                                          'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/spread-lee-xf1i5z/assets/gnm1dhgwv47f/profile.png',
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.influencerDoc?.role == 'influencer'
                                      ? widget.influencerDoc?.publicName ??
                                          'User'
                                      : widget.influencerDoc?.commercialName ??
                                          'User',
                                  style: getSemiBoldStyle(
                                    color: Colors.black87,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  widget.influencerDoc?.role == 'influencer'
                                      ? 'Influencer'
                                      : 'Marketing Company',
                                  style: getMediumStyle(
                                    color: Colors.grey[600] ?? Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildRatingBar(),
                            const SizedBox(height: 20),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review:',
                                  style: getMediumStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _textController,
                                  focusNode: _textFieldFocusNode,
                                  autofocus: true,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    hintText: 'Write Here...',
                                    hintStyle: getMediumStyle(
                                      color: Colors.grey[400] ?? Colors.grey,
                                      fontSize: 14,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey[100] ?? Colors.grey,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: ColorManager.blueLight800,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: ColorManager.lightError,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: ColorManager.lightError,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100] ?? Colors.grey,
                                    contentPadding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16.0, 18.0, 16.0, 18.0),
                                  ),
                                  style: getMediumStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                  maxLines: 8,
                                  minLines: 8,
                                  validator: _textControllerValidator,
                                ),
                              ],
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitReview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorManager.blueLight800,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Submit',
                                        style: getMediumStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
