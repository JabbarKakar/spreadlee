import 'package:flutter/material.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import '../../../resources/color_manager.dart';
import 'package:intl/intl.dart';

class WalletCard extends StatefulWidget {
  final InvoiceModel invoice;
  final int pageIndex;
  final Function(bool) onCheckboxChanged;
  final VoidCallback onTap;
  final DateTime? claimDate;

  const WalletCard({
    super.key,
    required this.invoice,
    required this.pageIndex,
    required this.onCheckboxChanged,
    required this.onTap,
    this.claimDate,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  late StopWatchTimer _timer;
  String _timerValue = '00:00:00';
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _timer = StopWatchTimer();
    _initializeTimer();
  }

  void _initializeTimer() {
    if (widget.invoice.claimCreationDate == null) return;

    final now = DateTime.now();
    final claimTime = widget.invoice.claimCreationDate!;
    final endTime = claimTime.add(const Duration(hours: 48));
    final difference = endTime.difference(now);
    final milliseconds = difference.inMilliseconds;

    if (milliseconds < 1) {
      _timerValue = '00:00:00';
    } else {
      // Reset timer before setting new time
      _timer.dispose();
      _timer = StopWatchTimer();

      // Set the timer to count down
      _timer.setPresetTime(mSec: milliseconds);
      _timer.onStartTimer();

      // Listen to timer updates
      _timer.rawTime.listen((value) {
        if (mounted) {
          setState(() {
            if (value <= 0) {
              _timerValue = '00:00:00';
            } else {
              _timerValue =
                  StopWatchTimer.getDisplayTime(value, milliSecond: false);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: ColorManager.customYellowF1D261,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'Invoice ID: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: ColorManager.black, fontFamily: 'Poppins'),
                    ),
                    Text(
                      widget.invoice.invoice_id?.toString() ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: ColorManager.black,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins'),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.pageIndex == 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked = !_isChecked;
                          });
                          widget.onCheckboxChanged(_isChecked);
                        },
                        child: Container(
                          width: 20.0,
                          height: 20.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: _isChecked
                                  ? ColorManager.blueLight800
                                  : ColorManager.gray300,
                              width: 1.0,
                            ),
                          ),
                          child: _isChecked
                              ? Icon(
                                  Icons.check,
                                  size: 14.0,
                                  color: ColorManager.blueLight800,
                                )
                              : null,
                        ),
                      ),
                    if (widget.pageIndex == 1)
                      Text(
                        _timerValue == '00:00:00' ? 'Timed out' : _timerValue,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: _timerValue == '00:00:00'
                                ? ColorManager.alertError500
                                : ColorManager.blueLight800,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Release Date: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.black, fontFamily: 'Poppins'),
                        ),
                        Text(
                          widget.invoice.createdAt != null
                              ? DateFormat('yyyy-MM-dd').format(
                                  DateTime.parse(widget.invoice.createdAt!))
                              : '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.black,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Amount: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.black, fontFamily: 'Poppins'),
                        ),
                        Text(
                          'SAR ${widget.invoice.invoice_total_with_app_fee.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.black,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.blueLight800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(77.0, 30.0),
                    padding: EdgeInsets.zero,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
