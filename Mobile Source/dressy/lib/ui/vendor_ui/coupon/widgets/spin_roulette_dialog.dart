import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../../../../config/ps_config.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';

class SpinRouletteDialog extends StatefulWidget {
  const SpinRouletteDialog({
    Key? key,
    required this.userId,
    required this.headerToken,
  }) : super(key: key);

  final String userId;
  final String headerToken;

  @override
  State<SpinRouletteDialog> createState() => _SpinRouletteDialogState();
}

class _SpinRouletteDialogState extends State<SpinRouletteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _spinAnimation;
  double _currentAngle = 0.0;
  int _lastTickSegment = -1;
  bool _isSpinning = false;
  int? _rewardPercent;
  String? _couponCode;
  String? _errorMsg;

  // 6 visual slices: 5%, 20%, 10%, 50%, 5%, 10% (awarded prize is always 5% or 10%)
  static const List<int> _segments = <int>[5, 20, 10, 50, 5, 10];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning || _couponCode != null) {
      return;
    }

    setState(() {
      _isSpinning = true;
      _errorMsg = null;
    });

    try {
      final Uri uri =
          Uri.parse('${PsConfig.ps_app_url}coupons/roulette-spin');
      final http.Response res = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
              'header-token': widget.headerToken,
            },
            body: json.encode(<String, dynamic>{
              'login_user_id': widget.userId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = json.decode(res.body);
      if (res.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] == true) {
        final int reward =
            int.tryParse(decoded['reward_percent']?.toString() ?? '5') ?? 5;
        final Map<String, dynamic>? coupon =
            decoded['coupon'] as Map<String, dynamic>?;
        final String code = (coupon?['code'] ?? '').toString();

        // Pick a segment index matching the server-assigned reward (5 or 10)
        final int targetIdx = reward == 10 ? 2 : 0;
        const double segAngle = (2 * math.pi) / 6;
        // Pointer is at top (-pi/2); align center of targetIdx under top pointer
        final double targetCenterAngle = -(targetIdx * segAngle) - (segAngle / 2);
        const double fullTurns = 8 * 2 * math.pi;
        final double endAngle = fullTurns + targetCenterAngle;
        _lastTickSegment = (_currentAngle / segAngle).floor();

        _spinAnimation = Tween<double>(
          begin: _currentAngle,
          end: endAngle,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
        )..addListener(() {
            if (mounted) {
              final double val = _spinAnimation!.value;
              final int segNow = (val / segAngle).floor();
              if (segNow != _lastTickSegment) {
                _lastTickSegment = segNow;
                HapticFeedback.selectionClick();
              }
              setState(() {
                _currentAngle = val;
              });
            }
          });

        _controller.reset();
        await _controller.forward();
        HapticFeedback.heavyImpact();

        if (mounted) {
          setState(() {
            _isSpinning = false;
            _rewardPercent = reward;
            _couponCode = code;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isSpinning = false;
            _errorMsg = (decoded is Map<String, dynamic>
                    ? decoded['message']?.toString()
                    : null) ??
                'roulette__unavailable'.tr;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _errorMsg = 'roulette__unavailable'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF1F1635), Color(0xFF3A1D3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD166).withValues(alpha: 0.65),
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    'roulette__title'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: _isSpinning ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'roulette__subtitle'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: 244,
                    height: 244,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFFFE082), Color(0xFFFFB703), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFFFB703).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _currentAngle,
                      child: CustomPaint(
                        painter: _RouletteWheelPainter(segments: _segments),
                      ),
                    ),
                  ),
                ),
                // Top Pointer
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD166),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Color(0xFF1F1635),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_errorMsg != null) ...<Widget>[
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              const SizedBox(height: 10),
            ],
            if (_couponCode != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD166)),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '${'roulette__won_prefix'.tr} $_rewardPercent% !',
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _couponCode!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _couponCode!));
                            Fluttertoast.showToast(
                              msg: 'coupon__copied'.tr,
                              toastLength: Toast.LENGTH_SHORT,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD166),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.copy, size: 15),
                          label: Text('coupon__copy'.tr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'roulette__valid_24h'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSpinning ? null : _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7768),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSpinning ? 'roulette__spinning'.tr : 'roulette__spin_btn'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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

class _RouletteWheelPainter extends CustomPainter {
  _RouletteWheelPainter({required this.segments});

  final List<int> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2;
    final double sweep = (2 * math.pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final double startAngle = -math.pi / 2 + i * sweep;
      final Paint slicePaint = Paint()
        ..color = i.isEven ? const Color(0xFFE63946) : const Color(0xFFFFB703)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        slicePaint,
      );

      final Paint borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        borderPaint,
      );

      final double textAngle = startAngle + sweep / 2;
      final Offset textPos = Offset(
        center.dx + radius * 0.62 * math.cos(textAngle),
        center.dy + radius * 0.62 * math.sin(textAngle),
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '-${segments[i]}%',
          style: TextStyle(
            color: i.isEven ? Colors.white : const Color(0xFF1F1635),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: i.isEven
                ? <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, textPos - Offset(tp.width / 2, tp.height / 2));
    }

    // Outer rim indicator dots
    for (int j = 0; j < 12; j++) {
      final double dotAngle = (2 * math.pi / 12) * j;
      final Offset dotPos = Offset(
        center.dx + (radius - 6) * math.cos(dotAngle),
        center.dy + (radius - 6) * math.sin(dotAngle),
      );
      canvas.drawCircle(
        dotPos,
        2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }

    canvas.drawCircle(
      center,
      22,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      16,
      Paint()..color = const Color(0xFFFFB703),
    );
    canvas.drawCircle(
      center,
      8,
      Paint()..color = const Color(0xFF1F1635),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
