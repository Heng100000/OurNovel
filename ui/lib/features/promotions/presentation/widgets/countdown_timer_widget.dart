import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../../l10n/language_service.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime? startDate;
  final DateTime endDate;

  const CountdownTimerWidget({
    super.key,
    this.startDate,
    required this.endDate,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateTimeLeft();
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.startDate != null && now.isBefore(widget.startDate!)) {
      // Not started yet
      setState(() {
        _timeLeft = widget.startDate!.difference(now);
      });
    } else {
      // Started, counting down to end
      setState(() {
        _timeLeft = widget.endDate.difference(now);
      });
    }
    
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);

    if (_timeLeft == Duration.zero) {
      return Text(
        langService.translate('finished'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final isStartingSoon = widget.startDate != null && DateTime.now().isBefore(widget.startDate!);
    final prefix = isStartingSoon ? langService.translate('starts_in_prefix') : "";

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        _buildTimeBox(hours),
        _buildDivider(),
        _buildTimeBox(minutes),
        _buildDivider(),
        _buildTimeBox(seconds),
      ],
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ":",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
