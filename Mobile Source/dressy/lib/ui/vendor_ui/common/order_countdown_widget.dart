import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/vendor/provider/language/app_localization_provider.dart';

class OrderCountdownWidget extends StatefulWidget {
  const OrderCountdownWidget({
    Key? key,
    required this.deadlineIso,
    this.compact = false,
  }) : super(key: key);

  final String? deadlineIso;
  final bool compact;

  @override
  State<OrderCountdownWidget> createState() => _OrderCountdownWidgetState();
}

class _OrderCountdownWidgetState extends State<OrderCountdownWidget> {
  Timer? _timer;
  DateTime? _deadline;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _parseAndStart();
  }

  @override
  void didUpdateWidget(covariant OrderCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineIso != widget.deadlineIso) {
      _timer?.cancel();
      _parseAndStart();
    }
  }

  void _parseAndStart() {
    final String raw = (widget.deadlineIso ?? '').trim();
    if (raw.isEmpty) {
      _deadline = null;
      return;
    }
    _deadline = DateTime.tryParse(raw)?.toLocal();
    if (_deadline == null) return;
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemaining();
      }
    });
  }

  void _updateRemaining() {
    if (_deadline == null) return;
    final Duration diff = _deadline!.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
    if (diff.isNegative) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _trOr(String key, String fallback) {
    final String v = key.tr;
    return (v.isNotEmpty && v != key) ? v : fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (_deadline == null) {
      return const SizedBox.shrink();
    }

    final bool isExpired = _remaining <= Duration.zero;
    final bool isUrgent = isExpired || _remaining.inHours < 12;

    final int totalHours = _remaining.inHours;
    final int minutes = _remaining.inMinutes.remainder(60);
    final int seconds = _remaining.inSeconds.remainder(60);
    final String formatted =
        '${totalHours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';

    final Color fgColor = isUrgent ? Colors.red.shade700 : Colors.amber.shade900;
    final Color bgColor = isUrgent
        ? Colors.red.withValues(alpha: 0.1)
        : Colors.amber.withValues(alpha: 0.15);
    final Color borderColor = isUrgent
        ? Colors.red.withValues(alpha: 0.35)
        : Colors.amber.shade700.withValues(alpha: 0.35);

    if (widget.compact) {
      return Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.timer_outlined, size: 13, color: fgColor),
            const SizedBox(width: 4),
            Text(
              isExpired
                  ? _trOr('order__deadline_expired', 'Délai expiré')
                  : '${_trOr('order__deadline_remaining', 'Délai expédition')}: $formatted',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.timer_outlined, size: 20, color: fgColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isExpired
                      ? _trOr('order__deadline_expired', 'Délai de 72h expiré')
                      : _trOr('order__deadline_72h_title', 'Délai de traitement (72h)'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
                if (!isExpired)
                  Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: fgColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
