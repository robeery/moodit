import 'package:flutter/widgets.dart';

// Base accent drives all normal chrome. AI gradients only signal AI edits or
// the active profile.
class MooditColors {
  MooditColors._();

  static const Color baseAccent = Color(0xFFE6E7EC);
  static const Color baseGlow = Color(0x24E6E7EC);
  static const Color baseGlowFaint = Color(0x0FE6E7EC);

  static const Color bgOuter = Color(0xFF232228);
  static const Color bgMid = Color(0xFF141417);
  static const Color bgInner = Color(0xFF0C0C0E);

  static const Color card = Color(0xFF121215);
  static const Color cardAlt = Color(0xFF161619);
  static const Color surfaceSubtle = Color(0x0DFFFFFF);

  static const Color hairline = Color(0x14FFFFFF);
  static const Color hairlineStrong = Color(0x1FFFFFFF);

  static const Color textPrimary = Color(0xFFE9E9EE);
  static const Color textPrimaryAlt = Color(0xFFEDEDF0);
  static const Color textSecondary = Color(0xFF9A9AA4);
  static const Color textMuted = Color(0xFF76767F);
  static const Color textOff = Color(0xFF5C5C62);

  static const Color destructive = Color(0xFFE95050);

  static const RadialGradient pageBackground = RadialGradient(
    center: Alignment(0, -0.35),
    radius: 1.2,
    colors: [bgOuter, bgMid, bgInner],
    stops: [0.0, 0.55, 1.0],
  );
}

class MooditDims {
  MooditDims._();

  static const double screenPadding = 20;
  static const double cardRadius = 22;
  static const double canvasRadius = 16;
  static const double controlRadius = 12;
  static const double pillRadius = 16;

  static const List<BoxShadow> softDrop = [
    BoxShadow(
      color: Color(0xE6000000),
      blurRadius: 60,
      offset: Offset(0, 24),
      spreadRadius: -28,
    ),
  ];
}

// serif: brand/titles, mono: labels/values, body: message/input text.
class MooditType {
  MooditType._();

  static const String serif = 'InstrumentSerif';
  static const String mono = 'GeistMono';
  static const String body = 'HankenGrotesk';

  static const TextStyle wordmark = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    height: 1.0,
    color: MooditColors.textPrimary,
  );

  static const TextStyle displayTitle = TextStyle(
    fontFamily: serif,
    fontSize: 26,
    height: 1.05,
    color: MooditColors.textPrimary,
  );

  static const TextStyle kicker = TextStyle(
    fontFamily: mono,
    fontSize: 9.5,
    letterSpacing: 3.0,
    fontWeight: FontWeight.w500,
    color: MooditColors.textMuted,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: mono,
    fontSize: 10.5,
    letterSpacing: 2.4,
    fontWeight: FontWeight.w500,
    color: MooditColors.textSecondary,
  );

  static const TextStyle monoLabel = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    letterSpacing: 1.6,
    fontWeight: FontWeight.w500,
    color: MooditColors.textPrimary,
  );

  static const TextStyle monoMeta = TextStyle(
    fontFamily: mono,
    fontSize: 9.5,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w400,
    color: MooditColors.textMuted,
  );
}
