import 'dart:ui';

// ── Design canvas ────────────────────────────────────────────────────────────
const double kDesignWidth = 390.0;
const double kDesignHeight = 844.0;

// ── Baby face layout (world coordinates) ─────────────────────────────────────
const double kFaceCenterX = 195.0;
const double kFaceCenterY = 370.0;
const double kFaceRadius = 122.0;

// BabyFaceComponent size (anchor: center)
const double kBabyFaceWidth = 284.0;
const double kBabyFaceHeight = 300.0;

// ── Mouth rect in BabyFaceComponent LOCAL space ───────────────────────────────
// Face local center = (kBabyFaceWidth/2, kBabyFaceHeight/2) = (142, 150)
// Mouth sits 30px below face center, horizontally centered
const double kMouthLocalX = 77.0; // 142 - 65
const double kMouthLocalY = 182.0; // 150 + 32
const double kMouthWidth = 130.0;
const double kMouthHeight = 58.0;

// ── Teeth ─────────────────────────────────────────────────────────────────────
const double kToothWidth = 16.0;
const double kToothHeight = 21.0;
const double kToothGap = 3.0;

// ── Colors ────────────────────────────────────────────────────────────────────
const Color kBackgroundTop = Color(0xFF87CEEB);
const Color kBackgroundBottom = Color(0xFF98E4FF);
const Color kSkinColor = Color(0xFFFFC896);
const Color kSkinShadow = Color(0xFFE8A870);
const Color kSkinHighlight = Color(0xFFFFDDB8);
const Color kMouthColor = Color(0xFF3A0000);
const Color kGumColor = Color(0xFFFF6B8A);
const Color kGumDark = Color(0xFFDD4070);
const Color kToothColor = Color(0xFFF8F8F0);
const Color kToothCountedColor = Color(0xFFFFD700);
const Color kToothPressedColor = Color(0xFFDDDDD0);
const Color kTongueColor = Color(0xFFE87090);
const Color kTongueDark = Color(0xFFCC5570);
const Color kEyeWhite = Color(0xFFFFFFFF);
const Color kPupilColor = Color(0xFF2D1B00);
const Color kIrisColor = Color(0xFF6B4226);
const Color kCheekColor = Color(0x55FF9BB4);
const Color kHeartFull = Color(0xFFFF3333);
const Color kHeartEmpty = Color(0x44FF3333);
const Color kScoreColor = Color(0xFFFFFFFF);
const Color kLevelColor = Color(0xFFFFE066);
const Color kHudBg = Color(0x88000000);
const Color kBiteFlashColor = Color(0x88FF0000);

// ── Overlay names ─────────────────────────────────────────────────────────────
const String kPauseOverlay = 'pause';
const String kResultOverlay = 'result';
const String kGameOverOverlay = 'gameOver';
