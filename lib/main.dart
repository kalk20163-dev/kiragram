// ============================================================
// KIRA GRAM — Flutter Single-File App (main.dart)
// ============================================================
// UI/UX UPDATE:
//   ✅ Header Navigation: Saved + AI moved to top header (chats screen)
//   ✅ Bottom Navigation: 4-tab professional pill-style nav bar
//   ✅ Profile Management: Inline delete button on profile photo
//   ✅ Chat Theme: 12 color options, live preview, persists across sessions
//   ✅ Chat bubble color reflects selected theme in real-time
// ============================================================
// PREVIOUS FEATURES:
//   ✅ App renamed: Kira Gram (was Nova Gram)
//   ✅ AI renamed: Kira AI (was Nova AI)
//   ✅ Saved Messages screen (save notes, links, text)
//   ✅ In-app Notification Panel (bell, history, mark-read, clear)
//   ✅ App-level Passcode Lock (PIN screen on launch)
//   ✅ @Mention links in chat bubbles (tap → view profile)
//   ✅ Username searching in People tab
//   ✅ People / Discover tab (search all users)
//   ✅ Message Pin to top of chat
//   ✅ Pinned message banner in ChatScreen
//   ✅ Copy username button in user profile
//   ✅ Notification quick-reply from panel
//   ✅ Saved nav tab added to bottom bar
//   ✅ Notification badge on bell icon
//   ✅ Read receipts on saved notes
//   ✅ Sticker panel in chat (emoji-based stickers)
// ============================================================
// pubspec.yaml dependencies:
//
// dependencies:
//   flutter:
//     sdk: flutter
//   firebase_core: ^3.0.0
//   firebase_auth: ^5.0.0
//   firebase_database: ^11.0.0
//   google_sign_in: ^6.2.1
//   http: ^1.2.1
//   image_picker: ^1.1.2
//   record: ^5.1.2
//   audioplayers: ^6.1.0
//   intl: ^0.19.0
//   shared_preferences: ^2.2.3
//   crypto: ^3.0.3
//   cached_network_image: ^3.3.1
//   flutter_animate: ^4.5.0
//   path_provider: ^2.1.4
//   permission_handler: ^11.3.1
//   hive: ^2.2.3
//   hive_flutter: ^1.1.0
//   google_fonts: ^6.1.0
//   flutter_local_notifications: ^17.0.0
//
// android/app/src/main/AndroidManifest.xml — add:
//   <uses-permission android:name="android.permission.INTERNET"/>
//   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
//   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
//   <uses-permission android:name="android.permission.VIBRATE"/>
//   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
// ios/Runner/Info.plist — add:
//   NSMicrophoneUsageDescription
//   NSPhotoLibraryUsageDescription
//   NSCameraUsageDescription
//
// google-services.json (Android) & GoogleService-Info.plist (iOS)
// must be placed in respective platform directories.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── FIREBASE CONFIG ─────────────────────────────────────────
const _fbApiKey = 'AIzaSyB2Ov8gYEvATVomthI1PPtwWK0Rt7LLqKo';
const _fbAuthDomain = 'kiragram-75f5c.firebaseapp.com';
const _fbDatabaseUrl = 'https://kiragram-75f5c-default-rtdb.firebaseio.com';
const _fbProjectId = 'kiragram-75f5c';
const _fbStorageBucket = 'kiragram-75f5c.firebasestorage.app';
const _fbMessagingSenderId = '1019789112398';
const _fbAppId = '1:1019789112398:web:7669939f0ce2380291ff1f';

// ─── CLOUDINARY CONFIG ───────────────────────────────────────
// FIX: Use same working cloud/preset as the Web version (index.html line 3004-3005)
const _cloudName = 'deeikewxq';
const _uploadPreset = 'kiragram';
// Base URL only — callers append /image/upload or /video/upload
const _cloudinaryBase = 'https://api.cloudinary.com/v1_1/deeikewxq';

// ─── EMAILJS CONFIG ──────────────────────────────────────────
const _emailjsServiceId  = 'service_jtvzfg7';
const _emailjsTemplateId = 'template_x7hbo9q';
const _emailjsPublicKey  = '5W2g1wWZXiLs2V3cz';
// ⚠️  REQUIRED: Paste your EmailJS Private Key here.
// Get it from: https://dashboard.emailjs.com/admin/account → API Keys → Private Key
const _emailjsPrivateKey = 'wsDN_REPLACE_WITH_FULL_PRIVATE_KEY';

// ─── GROQ CONFIG ─────────────────────────────────────────────
const _groqKey = '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';
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _groqModel = 'llama-3.3-70b-versatile';
const _aiSystemPrompt =
    'You are Kira AI Dark 3.3, a helpful and witty AI assistant integrated into the Kira Gram social app. '
    'Be concise, warm, and helpful. Never reveal your underlying model or provider. '
    'Your creator is Kira (Kirubel Alemu). Stay in character as Kira AI Dark 3.3.';

// ─── ADMIN PIN ────────────────────────────────────────────────
const _adminPin = '1994';

// ─── CHAT THEME NOTIFIER ─────────────────────────────────────
// Chat theme color options (accent color for outgoing bubble gradient start)
const _chatThemes = {
  'Violet':   [Color(0xFF7367F0), Color(0xFF9B2FFF)],   // default
  'Rose':     [Color(0xFFE91E8C), Color(0xFFFF6B6B)],
  'Ocean':    [Color(0xFF0288D1), Color(0xFF00BCD4)],
  'Forest':   [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  'Sunset':   [Color(0xFFFF6F00), Color(0xFFFFCA28)],
  'Crimson':  [Color(0xFFC62828), Color(0xFFEF9A9A)],
  'Midnight': [Color(0xFF1A237E), Color(0xFF5C6BC0)],
  'Teal':     [Color(0xFF00695C), Color(0xFF26A69A)],
  'Sakura':   [Color(0xFFAD1457), Color(0xFFF06292)],
  'Slate':    [Color(0xFF37474F), Color(0xFF78909C)],
  'Amber':    [Color(0xFFF57F17), Color(0xFFFFCA28)],
  'Lime':     [Color(0xFF558B2F), Color(0xFFAED581)],
};

final _chatThemeNotifier = ValueNotifier<String>('Violet');

LinearGradient get _chatBubbleGrad {
  final colors = _chatThemes[_chatThemeNotifier.value] ?? _chatThemes['Violet']!;
  return LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight);
}

// ─── THEME NOTIFIER ──────────────────────────────────────────
final _themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

// ─── NOTIFICATIONS ───────────────────────────────────────────
final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _notificationsPlugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

Future<void> _showNotification(String title, String body) async {
  const android = AndroidNotificationDetails(
    'kira_gram_channel', 'Kira Gram',
    channelDescription: 'New message notifications',
    importance: Importance.high,
    priority: Priority.high,
  );
  const ios = DarwinNotificationDetails();
  await _notificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title, body,
    const NotificationDetails(android: android, iOS: ios),
  );
}

// ─── HIVE OFFLINE CACHE ──────────────────────────────────────
late Box<String> _msgBox;
late Box<String> _profileBox;

// ─── DARK THEME ──────────────────────────────────────────────
const _dBg0 = Color(0xFF000000);
const _dBg1 = Color(0xFF0A0A0A);
const _dBg2 = Color(0xFF111128);
const _dBg3 = Color(0xFF171730);
const _dCard = Color(0xFF0D0D0D);
const _dInput = Color(0xFF0E0E1A);
const _dTx0 = Color(0xFFF2F0FF);
const _dTx1 = Color(0xFF9090BB);
const _dTx2 = Color(0xFF505070);
const _dBdr = Color(0x337367F0);
const _dBdr2 = Color(0x12FFFFFF);
const _dInBubble = Color(0xFF1C1C2E);

// ─── LIGHT THEME ─────────────────────────────────────────────
const _lBg0 = Color(0xFFF0EEFF);
const _lBg1 = Color(0xFFE8E4FF);
const _lBg2 = Color(0xFFDFD9FF);
const _lBg3 = Color(0xFFD5CEFF);
const _lCard = Color(0xFFFFFFFF);
const _lInput = Color(0xFFE4DFFF);
const _lTx0 = Color(0xFF160E3A);
const _lTx1 = Color(0xFF6050A8);
const _lTx2 = Color(0xFF9880D0);
const _lBdr = Color(0x337367F0);
const _lBdr2 = Color(0x147367F0);
const _lInBubble = Color(0xFFE4DFFF);

// ─── ACCENT (shared) ─────────────────────────────────────────
const _accent = Color(0xFF7367F0);
const _accentL = Color(0xFF9B8FF8);
const _accentPink = Color(0xFFFF3D8F);
const _accentTeal = Color(0xFF00E5C3);
const _danger = Color(0xFFFF3D5A);
const _online = Color(0xFF00E5C3);

// ─── GRADIENTS ───────────────────────────────────────────────
const _primaryGrad = LinearGradient(
  colors: [Color(0xFF7367F0), Color(0xFF9B2FFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _avatarGrad = LinearGradient(
  colors: [Color(0xFF7367F0), Color(0xFFFF3D8F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── THEME HELPERS ───────────────────────────────────────────
class _T {
  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;
  static Color bg0(BuildContext ctx) => isDark(ctx) ? _dBg0 : _lBg0;
  static Color bg1(BuildContext ctx) => isDark(ctx) ? _dBg1 : _lBg1;
  static Color bg2(BuildContext ctx) => isDark(ctx) ? _dBg2 : _lBg2;
  static Color bg3(BuildContext ctx) => isDark(ctx) ? _dBg3 : _lBg3;
  static Color card(BuildContext ctx) => isDark(ctx) ? _dCard : _lCard;
  static Color input(BuildContext ctx) => isDark(ctx) ? _dInput : _lInput;
  static Color tx0(BuildContext ctx) => isDark(ctx) ? _dTx0 : _lTx0;
  static Color tx1(BuildContext ctx) => isDark(ctx) ? _dTx1 : _lTx1;
  static Color tx2(BuildContext ctx) => isDark(ctx) ? _dTx2 : _lTx2;
  static Color bdr(BuildContext ctx) => isDark(ctx) ? _dBdr : _lBdr;
  static Color bdr2(BuildContext ctx) => isDark(ctx) ? _dBdr2 : _lBdr2;
  static Color inBubble(BuildContext ctx) => isDark(ctx) ? _dInBubble : _lInBubble;
}

// ─── HELPERS ─────────────────────────────────────────────────
String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

String _fmtTime(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return DateFormat('HH:mm').format(d);
  }
  if (now.difference(d).inDays < 7) return DateFormat('EEE').format(d);
  return DateFormat('MMM d').format(d);
}

String _fmtLastSeen(int? ts) {
  if (ts == null || ts == 0) return 'Last seen a while ago';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'Last seen just now';
  if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
  return 'Last seen ${DateFormat('MMM d').format(d)}';
}

String _fmtDuration(int secs) {
  final m = secs ~/ 60;
  final s = (secs % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

Color _avatarColor(String name) {
  final colors = [
    const Color(0xFF7367F0), const Color(0xFFFF3D8F), const Color(0xFF00E5C3),
    const Color(0xFF4CAF50), const Color(0xFFFF5722), const Color(0xFF9C27B0),
    const Color(0xFF0097A7),
  ];
  int h = 0;
  for (final c in name.runes) h = (h * 31 + c) % colors.length;
  return colors[h.abs() % colors.length];
}

// ─── FIREBASE DATABASE ───────────────────────────────────────
FirebaseDatabase get _db => FirebaseDatabase.instance;
DatabaseReference _ref(String path) => _db.ref(path);

// ─── ENTRY POINT ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: _fbApiKey,
      authDomain: _fbAuthDomain,
      databaseURL: _fbDatabaseUrl,
      projectId: _fbProjectId,
      storageBucket: _fbStorageBucket,
      messagingSenderId: _fbMessagingSenderId,
      appId: _fbAppId,
    ),
  );
  await Hive.initFlutter();
  _msgBox = await Hive.openBox<String>('messages');
  _profileBox = await Hive.openBox<String>('profiles');
  await _initNotifications();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const KiraGramApp());
}

// ─── ROOT APP ────────────────────────────────────────────────
class KiraGramApp extends StatelessWidget {
  const KiraGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Kira Gram',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: _lBg0,
          colorScheme: const ColorScheme.light(
            primary: _accent, secondary: _accentPink, surface: _lCard,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          }),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _dBg0,
          colorScheme: const ColorScheme.dark(
            primary: _accent, secondary: _accentPink, surface: _dCard,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          }),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// ─── SPLASH SCREEN ───────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ring1, _ring2, _ring3, _progress;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(vsync: this, duration: 1600.ms)..repeat();
    _ring2 = AnimationController(vsync: this, duration: 1200.ms)..repeat(reverse: true);
    _ring3 = AnimationController(vsync: this, duration: 900.ms)..repeat();
    _progress = AnimationController(vsync: this, duration: 2400.ms)..forward();
    Future.delayed(2500.ms, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: 600.ms,
      ));
    });
  }

  @override
  void dispose() {
    _ring1.dispose(); _ring2.dispose(); _ring3.dispose(); _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dBg0,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 110, height: 110,
              child: Stack(alignment: Alignment.center, children: [
                RotationTransition(turns: _ring1,
                  child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accent, width: 2)))),
                RotationTransition(turns: _ring2,
                  child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accentPink, width: 2)))),
                RotationTransition(turns: _ring3,
                  child: Container(margin: const EdgeInsets.all(22), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accentTeal, width: 2)))),
                Container(
                  margin: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _avatarGrad),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [Colors.white, _accentL, _accentPink]).createShader(b),
              child: Text('Kira Gram', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            ),
            const SizedBox(height: 6),
            Text('Connect · Share · Flourish', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: _dTx1, letterSpacing: 2)),
            const SizedBox(height: 48),
            AnimatedBuilder(animation: _progress, builder: (_, __) => Container(
              width: 160, height: 2,
              decoration: BoxDecoration(color: _dBg3, borderRadius: BorderRadius.circular(99)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress.value,
                child: Container(decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(colors: [_accent, _accentPink, _accentTeal]),
                )),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── AUTH GATE ───────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('ng_uid');
    if (!mounted) return;
    if (uid != null && uid.isNotEmpty) {
      // Check if app passcode is set
      final snap = await _ref('appPasscode/$uid').get();
      if (snap.exists) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => AppPasscodeScreen(uid: uid),
        ));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => AppShell(uid: uid),
        ));
      }
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: _dBg0,
    body: Center(child: CircularProgressIndicator(color: _accent)),
  );
}

// ─── APP PASSCODE SCREEN (NEW) ───────────────────────────────
class AppPasscodeScreen extends StatefulWidget {
  final String uid;
  final bool isSetup;
  const AppPasscodeScreen({super.key, required this.uid, this.isSetup = false});
  @override
  State<AppPasscodeScreen> createState() => _AppPasscodeScreenState();
}

class _AppPasscodeScreenState extends State<AppPasscodeScreen> {
  String _buffer = '';
  bool _error = false;
  bool _processing = false;

  Future<void> _press(String key) async {
    if (_processing) return;
    if (key == 'del') {
      setState(() => _buffer = _buffer.isEmpty ? '' : _buffer.substring(0, _buffer.length - 1));
      return;
    }
    if (key == 'clr') { setState(() => _buffer = ''); return; }
    if (_buffer.length >= 4) return;
    setState(() { _buffer += key; _error = false; });
    if (_buffer.length == 4) await _submit();
  }

  Future<void> _submit() async {
    setState(() => _processing = true);
    final pin = _buffer;
    try {
      if (widget.isSetup) {
        await _ref('appPasscode/${widget.uid}').set(_sha256(pin));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppShell(uid: widget.uid)));
        return;
      }
      final snap = await _ref('appPasscode/${widget.uid}').get();
      final stored = snap.value as String?;
      if (stored != null && _sha256(pin) == stored) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppShell(uid: widget.uid)));
        return;
      }
      setState(() { _error = true; _buffer = ''; });
      await Future.delayed(600.ms);
      if (mounted) setState(() => _error = false);
    } catch (_) {
      setState(() { _error = true; _buffer = ''; });
    }
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dBg0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 68, height: 68,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _primaryGrad),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32)),
              const SizedBox(height: 20),
              Text('Kira Gram', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: _dTx0)),
              const SizedBox(height: 6),
              Text(widget.isSetup ? 'Set a 4-digit passcode' : 'Enter your passcode',
                style: GoogleFonts.outfit(fontSize: 14, color: _dTx1)),
              const SizedBox(height: 36),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _buffer.length;
                  return AnimatedContainer(duration: 150.ms, width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _error ? _danger : (filled ? _accent : Colors.transparent),
                      border: Border.all(color: _error ? _danger : (filled ? _accent : _dTx2), width: 2)));
                })),
              const SizedBox(height: 36),
              for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['clr','0','del']])
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((k) => GestureDetector(
                    onTap: k.isEmpty ? null : () => _press(k),
                    child: Container(width: 72, height: 60, alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(color: k == 'clr' || k == 'del' ? Colors.transparent : _dBg3, borderRadius: BorderRadius.circular(16)),
                      child: k == 'del'
                        ? const Icon(Icons.backspace_outlined, color: _dTx1, size: 22)
                        : k == 'clr'
                          ? Text('✕', style: GoogleFonts.outfit(fontSize: 18, color: _dTx1))
                          : Text(k, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: _dTx0))),
                  )).toList()),
              if (!widget.isSetup) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await _ref('appPasscode/${widget.uid}').remove();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('ng_uid');
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
                  },
                  child: Text('Forgot passcode? Sign out', style: GoogleFonts.outfit(color: _dTx2, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AUTH SCREEN ─────────────────────────────────────────────
enum _AuthTab { otp, login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthTab _tab = _AuthTab.otp;
  bool _loading = false;

  // OTP
  final _otpEmailCtrl = TextEditingController();
  final _otpCodeCtrl = TextEditingController();
  bool _otpSent = false;
  String? _sentOtpCode;
  DateTime? _otpExpiry;
  int _otpResendSeconds = 0;
  Timer? _resendTimer;

  // Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;

  // Signup
  final _signupNameCtrl = TextEditingController();
  final _signupUserCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  bool _signupObscure = true;

  // ─── GOOGLE SIGN-IN: origin_mismatch FIX ─────────────────────
  // Error 400 origin_mismatch = localhost:PORT is not in the OAuth allowed list.
  // Fix it once in Google Cloud Console (no code change needed):
  //   1. Go to: https://console.cloud.google.com/apis/credentials
  //   2. Click "Web client (auto created by Google Service)"
  //   3. Under "Authorized JavaScript origins" → Add URIs:
  //        http://localhost
  //        http://localhost:60126    ← your current port
  //        http://localhost:54972    ← previous port (add all you use)
  //   4. Under "Authorized redirect URIs" → Add:
  //        http://localhost
  //   5. Save — takes ~5 minutes to propagate, then retry.
  // ──────────────────────────────────────────────────────────────
  final _googleSignIn = GoogleSignIn(
    clientId: '1019789112398-ufgojas132b18vudk5nopuqc27nc4fhf.apps.googleusercontent.com',
  );

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpEmailCtrl.dispose(); _otpCodeCtrl.dispose();
    _loginEmailCtrl.dispose(); _loginPassCtrl.dispose();
    _signupNameCtrl.dispose(); _signupUserCtrl.dispose();
    _signupEmailCtrl.dispose(); _signupPassCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_otpResendSeconds <= 0) { t.cancel(); setState(() => _otpResendSeconds = 0); return; }
      setState(() => _otpResendSeconds--);
    });
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: error ? _danger : _accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ));
  }

  Future<void> _doGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final gUser = await _googleSignIn.signIn();
      if (gUser == null) { setState(() => _loading = false); return; }
      final gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken, idToken: gAuth.idToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = cred.user!.uid;
      // FIX: Always capture Google profile data
      final googleName = cred.user!.displayName ?? gUser.displayName ?? 'User';
      final googlePhoto = cred.user!.photoURL ?? '';
      final googleEmail = cred.user!.email ?? gUser.email ?? '';
      final snap = await _ref('users/$uid').get();
      if (!snap.exists) {
        // New user — create full profile
        await _ref('users/$uid').set({
          'uid': uid, 'name': googleName,
          'username': gUser.email?.split('@')[0] ?? uid.substring(0, 8),
          'email': googleEmail,
          'bio': '', 'avatar': googlePhoto,
          'online': true, 'lastSeen': ServerValue.timestamp,
          'createdAt': ServerValue.timestamp, 'isVerified': false,
        });
      } else {
        // Returning user — refresh name & photo from Google so they stay current
        final updates = <String, dynamic>{'online': true, 'lastSeen': ServerValue.timestamp};
        if (googlePhoto.isNotEmpty) updates['avatar'] = googlePhoto;
        if (googleName.isNotEmpty) updates['name'] = googleName;
        await _ref('users/$uid').update(updates);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ng_uid', uid);
      _navigateToApp(uid);
    } catch (e) {
      _toast('Google sign-in failed: $e', error: true);
    }
    setState(() => _loading = false);
  }

  // Stores the dev-fallback OTP so we can show it in the UI
  String? _devOtpVisible;

  Future<void> _doOtpSend() async {
    final email = _otpEmailCtrl.text.trim();
    if (email.isEmpty) { _toast('Enter your email', error: true); return; }
    if (!email.contains('@') || !email.contains('.')) { _toast('Enter a valid email address', error: true); return; }
    setState(() { _loading = true; _devOtpVisible = null; });
    final code = (100000 + Random().nextInt(900000)).toString();
    _sentOtpCode = code;
    _otpExpiry = DateTime.now().add(const Duration(minutes: 10));

    bool sent = false;
    String? errorBody;
    try {
      // EmailJS v2 REST API — uses accessToken (private key) in Authorization header.
      // This works on both Flutter Web and mobile without CORS issues.
      final res = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',           // tells EmailJS this is a trusted origin
          'User-Agent': 'KiraGram/1.0',
        },
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'accessToken': _emailjsPrivateKey,      // private key bypasses browser CORS block
          'template_params': {
            'email':    email,
            'otp_code': code,
            'to_name':  email.split('@')[0],
            'message':  'Your Kira Gram verification code is: $code. Expires in 10 minutes.',
            'app_name': 'Kira Gram',
          },
        }),
      );
      debugPrint('[EmailJS] status=${res.statusCode} body=${res.body}');
      sent = res.statusCode == 200;
      if (!sent) errorBody = res.body;
    } catch (e) {
      debugPrint('[EmailJS] error: $e');
      errorBody = e.toString();
    }

    setState(() { _otpSent = true; _loading = false; _otpResendSeconds = 60; });
    _startResendTimer();

    if (sent) {
      _toast('✓ Code sent to $email — check your inbox');
    } else {
      // Fallback: show code in UI so login still works even if email fails
      setState(() => _devOtpVisible = code);
      debugPrint('[KiraGram] ⚠️ EmailJS failed: $errorBody');
      _toast('Email failed — use the code shown below', error: true);
    }
  }

  Future<void> _doOtpVerify() async {
    final entered = _otpCodeCtrl.text.trim();
    if (entered.isEmpty) { _toast('Enter the code', error: true); return; }
    if (_otpExpiry != null && DateTime.now().isAfter(_otpExpiry!)) {
      _toast('OTP expired. Please request a new code.', error: true);
      setState(() { _otpSent = false; _otpCodeCtrl.clear(); });
      return;
    }
    if (entered != _sentOtpCode) { _toast('Wrong code, try again', error: true); return; }
    setState(() => _loading = true);
    try {
      final snap = await _ref('users').get();
      final all = Map<String, dynamic>.from(snap.value as Map? ?? {});
      final existing = all.values.cast<Map>().firstWhere(
        (u) => u['email'] == _otpEmailCtrl.text.trim(), orElse: () => {},
      );
      if (existing.isEmpty) {
        _toast('No account found. Please sign up.', error: true);
        setState(() { _tab = _AuthTab.signup; _loading = false; });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ng_uid', existing['uid'] as String);
      _navigateToApp(existing['uid'] as String);
    } catch (e) {
      _toast('Error: $e', error: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _doLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text;
    if (email.isEmpty || pass.isEmpty) { _toast('Fill all fields', error: true); return; }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ng_uid', cred.user!.uid);
      _navigateToApp(cred.user!.uid);
    } catch (e) {
      _toast(e.toString().replaceAll(RegExp(r'\[.*?\]'), ''), error: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _doSignup() async {
    final name = _signupNameCtrl.text.trim();
    final username = _signupUserCtrl.text.trim().replaceAll('@', '');
    final email = _signupEmailCtrl.text.trim();
    final pass = _signupPassCtrl.text;
    if (name.isEmpty || username.isEmpty || email.isEmpty || pass.isEmpty) {
      _toast('Fill all fields', error: true); return;
    }
    if (pass.length < 6) { _toast('Password too short (min 6)', error: true); return; }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      await cred.user!.updateDisplayName(name);
      await _ref('users/${cred.user!.uid}').set({
        'uid': cred.user!.uid, 'name': name, 'username': username, 'email': email,
        'bio': '', 'avatar': '', 'online': true, 'lastSeen': ServerValue.timestamp,
        'createdAt': ServerValue.timestamp, 'isVerified': false,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ng_uid', cred.user!.uid);
      _navigateToApp(cred.user!.uid);
    } catch (e) {
      _toast(e.toString().replaceAll(RegExp(r'\[.*?\]'), ''), error: true);
    }
    setState(() => _loading = false);
  }

  void _navigateToApp(String uid) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppShell(uid: uid)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _T.isDark(context);
    return Scaffold(
      backgroundColor: _T.bg0(context),
      body: Stack(children: [
        Positioned(top: -150, right: -100, child: _Blob(color: _accent, size: 400)),
        Positioned(bottom: -100, left: -80, child: _Blob(color: _accentPink, size: 300)),
        Positioned(top: 300, left: 100, child: _Blob(color: _accentTeal, size: 200)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xB3060610) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _T.bdr(context)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 60)],
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(gradient: _avatarGrad, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26)),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(colors: [_accentL, _accentPink]).createShader(b),
                      child: Text('Kira Gram', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _GoogleBtn(onTap: _loading ? null : _doGoogleSignIn),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Divider(color: _T.bdr2(context))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 13))),
                    Expanded(child: Divider(color: _T.bdr2(context))),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: _T.bg2(context), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      _SegBtn('OTP', _tab == _AuthTab.otp, () => setState(() { _tab = _AuthTab.otp; _otpSent = false; })),
                      _SegBtn('Password', _tab == _AuthTab.login, () => setState(() => _tab = _AuthTab.login)),
                      _SegBtn('Sign Up', _tab == _AuthTab.signup, () => setState(() => _tab = _AuthTab.signup)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  if (_tab == _AuthTab.otp) _buildOtpForm(),
                  if (_tab == _AuthTab.login) _buildLoginForm(),
                  if (_tab == _AuthTab.signup) _buildSignupForm(),
                ]),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ),
        ),
      ]),
    );
  }

  Widget _buildOtpForm() => Column(children: [
    Text('Magic Link', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: _T.tx0(context))),
    const SizedBox(height: 4),
    Text(_otpSent ? 'Enter the 6-digit code we sent' : "We'll send a code to verify you",
      style: GoogleFonts.outfit(fontSize: 13, color: _T.tx1(context))),
    const SizedBox(height: 20),
    if (!_otpSent) _NField('Email', _otpEmailCtrl, hint: 'you@example.com', keyboard: TextInputType.emailAddress),
    if (_otpSent) _NField('Verification Code', _otpCodeCtrl, hint: '● ● ● ● ● ●', keyboard: TextInputType.number),
    // Dev fallback: show code in UI if email couldn't be sent
    if (_otpSent && _devOtpVisible != null) ...[
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC00), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 16),
            const SizedBox(width: 6),
            Text('Email not sent — use this code:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF856404))),
          ]),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              _otpCodeCtrl.text = _devOtpVisible!;
              Clipboard.setData(ClipboardData(text: _devOtpVisible!));
            },
            child: Text(_devOtpVisible!, style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF0a0a0a), letterSpacing: 6)),
          ),
          Text('Tap code to autofill  •  Fix EmailJS to enable real emails', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF856404))),
        ]),
      ),
    ],
    const SizedBox(height: 16),
    _PrimaryBtn(_loading ? 'Please wait...' : (_otpSent ? 'Verify Code →' : 'Send OTP →'),
      _loading ? null : (_otpSent ? _doOtpVerify : _doOtpSend)),
    if (_otpSent) ...[
      const SizedBox(height: 10),
      _otpResendSeconds > 0
        ? Text('Resend in ${_otpResendSeconds}s', style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 13))
        : TextButton(
            onPressed: () { setState(() { _otpSent = false; _otpCodeCtrl.clear(); _sentOtpCode = null; _otpExpiry = null; _devOtpVisible = null; }); },
            child: Text('Resend / Change email', style: GoogleFonts.outfit(color: _accentL, fontWeight: FontWeight.w600)),
          ),
    ],
  ]);

  Widget _buildLoginForm() => Column(children: [
    Text('Welcome back', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: _T.tx0(context))),
    const SizedBox(height: 4),
    Text('Sign in with your password', style: GoogleFonts.outfit(fontSize: 13, color: _T.tx1(context))),
    const SizedBox(height: 20),
    _NField('Email', _loginEmailCtrl, hint: 'you@example.com', keyboard: TextInputType.emailAddress),
    const SizedBox(height: 12),
    _NField('Password', _loginPassCtrl, hint: '••••••••', obscure: _loginObscure,
      suffix: IconButton(
        icon: Icon(_loginObscure ? Icons.visibility_off : Icons.visibility, color: _T.tx2(context), size: 18),
        onPressed: () => setState(() => _loginObscure = !_loginObscure))),
    const SizedBox(height: 16),
    _PrimaryBtn(_loading ? 'Signing in...' : 'Sign In', _loading ? null : _doLogin),
    const SizedBox(height: 12),
    GestureDetector(
      onTap: () => setState(() => _tab = _AuthTab.signup),
      child: Text.rich(TextSpan(
        style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13),
        children: [const TextSpan(text: "Don't have an account? "),
          TextSpan(text: 'Sign up', style: const TextStyle(color: _accentL, fontWeight: FontWeight.w600))],
      )),
    ),
  ]);

  Widget _buildSignupForm() => Column(children: [
    Text('Create Account', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: _T.tx0(context))),
    const SizedBox(height: 4),
    Text('Join Kira Gram today', style: GoogleFonts.outfit(fontSize: 13, color: _T.tx1(context))),
    const SizedBox(height: 20),
    _NField('Display Name', _signupNameCtrl, hint: 'Your name'),
    const SizedBox(height: 12),
    _NField('Username', _signupUserCtrl, hint: '@username'),
    const SizedBox(height: 12),
    _NField('Email', _signupEmailCtrl, hint: 'you@example.com', keyboard: TextInputType.emailAddress),
    const SizedBox(height: 12),
    _NField('Password', _signupPassCtrl, hint: '••••••••', obscure: _signupObscure,
      suffix: IconButton(
        icon: Icon(_signupObscure ? Icons.visibility_off : Icons.visibility, color: _T.tx2(context), size: 18),
        onPressed: () => setState(() => _signupObscure = !_signupObscure))),
    const SizedBox(height: 16),
    _PrimaryBtn(_loading ? 'Creating...' : 'Create Account', _loading ? null : _doSignup),
    const SizedBox(height: 12),
    GestureDetector(
      onTap: () => setState(() => _tab = _AuthTab.login),
      child: Text.rich(TextSpan(
        style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13),
        children: [const TextSpan(text: 'Already have an account? '),
          TextSpan(text: 'Sign in', style: const TextStyle(color: _accentL, fontWeight: FontWeight.w600))],
      )),
    ),
  ]);
}

// ─── APP SHELL ───────────────────────────────────────────────
class AppShell extends StatefulWidget {
  final String uid;
  const AppShell({super.key, required this.uid});
  @override
  State<AppShell> createState() => _AppShellState();
}

enum _Nav { chats, feed, people, profile }

class _AppShellState extends State<AppShell> {
  _Nav _nav = _Nav.chats;
  Map<String, dynamic> _myProfile = {};
  Map<String, bool> _verifiedCache = {};
  int _unreadCount = 0;
  int _notifCount = 0;
  StreamSubscription? _unreadSub;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _setOnline(true);
    _listenUnread();
    _listenNotifs();
  }

  @override
  void dispose() {
    _setOnline(false);
    _unreadSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final cached = _profileBox.get('profile_${widget.uid}');
    if (cached != null) {
      try {
        final d = jsonDecode(cached) as Map<String, dynamic>;
        setState(() { _myProfile = d; _verifiedCache[widget.uid] = d['isVerified'] == true; });
      } catch (_) {}
    }
    final snap = await _ref('users/${widget.uid}').get();
    if (snap.exists) {
      final d = Map<String, dynamic>.from(snap.value as Map);
      setState(() { _myProfile = d; _verifiedCache[widget.uid] = d['isVerified'] == true; });
      await _profileBox.put('profile_${widget.uid}', jsonEncode(d));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ng_profile', jsonEncode(d));
    }
  }

  void _setOnline(bool status) {
    _ref('users/${widget.uid}').update({'online': status, 'lastSeen': ServerValue.timestamp});
  }

  void _listenUnread() {
    _unreadSub = _ref('userChats/${widget.uid}').onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _unreadCount = 0); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      int total = 0;
      for (final v in data.values) {
        final m = Map<String, dynamic>.from(v as Map);
        total += (m['unread'] as int? ?? 0);
      }
      setState(() => _unreadCount = total);
    });
  }

  void _listenNotifs() {
    _notifSub = _ref('notifications/${widget.uid}').onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _notifCount = 0); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final unread = data.values.where((v) => (v as Map)['read'] != true).length;
      setState(() => _notifCount = unread);
    });
  }

  Future<void> _logout() async {
    _setOnline(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ng_uid');
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  void _openSaved() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavedScreen(uid: widget.uid)));
  }

  void _openAI() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AIScreen(uid: widget.uid)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg0(context),
      body: IndexedStack(
        index: _nav.index,
        children: [
          ChatsScreen(
            uid: widget.uid, profile: _myProfile, verifiedCache: _verifiedCache,
            onOpenSaved: _openSaved, onOpenAI: _openAI,
            unreadCount: _unreadCount,
          ),
          FeedScreen(uid: widget.uid, profile: _myProfile),
          PeopleScreen(uid: widget.uid, myProfile: _myProfile),
          ProfileScreen(
            uid: widget.uid, profile: _myProfile,
            onProfileUpdated: (p) => setState(() => _myProfile = p),
            onLogout: _logout,
            verifiedCache: _verifiedCache,
            onVerifiedChanged: (v) => setState(() => _verifiedCache[widget.uid] = v),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _nav,
        unreadCount: _unreadCount,
        notifCount: _notifCount,
        onTap: (n) => setState(() => _nav = n),
      ),
    );
  }
}

// ─── BOTTOM NAV ──────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final _Nav current;
  final int unreadCount;
  final int notifCount;
  final ValueChanged<_Nav> onTap;
  const _BottomNav({required this.current, required this.unreadCount, required this.notifCount, required this.onTap});

  static const _items = [
    (nav: _Nav.chats,   icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded,   label: 'Chats'),
    (nav: _Nav.feed,    icon: Icons.grid_view_outlined,          activeIcon: Icons.grid_view_rounded,      label: 'Feed'),
    (nav: _Nav.people,  icon: Icons.people_outline_rounded,      activeIcon: Icons.people_rounded,         label: 'People'),
    (nav: _Nav.profile, icon: Icons.person_outline_rounded,      activeIcon: Icons.person_rounded,         label: 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: _T.bg1(context),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, -8)),
          BoxShadow(color: _accent.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
        border: Border(top: BorderSide(color: _T.bdr2(context).withOpacity(0.4))),
      ),
      padding: EdgeInsets.only(bottom: bottomPad + 8, top: 10, left: 6, right: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.map((item) {
          final active = current == item.nav;
          final badge = item.nav == _Nav.chats && unreadCount > 0
              ? '$unreadCount'
              : item.nav == _Nav.profile && notifCount > 0
                  ? '$notifCount'
                  : null;
          return _NavItem(
            icon: item.icon, activeIcon: item.activeIcon,
            label: item.label, active: active,
            badge: badge,
            onTap: () => onTap(item.nav),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label,
    required this.active, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: 280.ms,
            curve: Curves.easeOutBack,
            width: active ? 58 : 42,
            height: 38,
            decoration: BoxDecoration(
              gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF7367F0), Color(0xFF9B2FFF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
              color: active ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active ? [
                BoxShadow(color: const Color(0xFF7367F0).withOpacity(0.5), blurRadius: 18, offset: const Offset(0, 5)),
                BoxShadow(color: const Color(0xFF9B2FFF).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2)),
              ] : null,
            ),
            child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              Icon(active ? activeIcon : icon,
                color: active ? Colors.white : _T.tx2(context), size: 21),
              if (badge != null)
                Positioned(
                  right: active ? 2 : -3, top: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF3D8F), Color(0xFFFF6B6B)]),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _T.bg1(context), width: 2)),
                    child: Text(badge!, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
                  )),
            ]),
          ),
          const SizedBox(height: 5),
          AnimatedDefaultTextStyle(
            duration: 200.ms,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? _accent : _T.tx2(context),
              letterSpacing: active ? 0.2 : 0.0,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

// ─── CHATS HEADER ────────────────────────────────────────────
class _ChatsHeader extends StatelessWidget {
  final int chatCount;
  final VoidCallback onNewChat;
  final VoidCallback onNewGroup;
  final VoidCallback? onOpenSaved;
  final VoidCallback? onOpenAI;
  const _ChatsHeader({required this.chatCount, required this.onNewChat,
    required this.onNewGroup, this.onOpenSaved, this.onOpenAI});

  @override
  Widget build(BuildContext context) {
    final isDark = _T.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      decoration: BoxDecoration(
        color: _T.bg0(context),
        border: Border(bottom: BorderSide(color: _T.bdr2(context).withOpacity(0.5))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Logo
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7367F0), Color(0xFF9B2FFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF7367F0).withOpacity(0.45), blurRadius: 14, offset: const Offset(0,4))],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: isDark ? [Colors.white, const Color(0xFFB39DDB)] : [const Color(0xFF7367F0), const Color(0xFF9B2FFF)],
                ).createShader(b),
                child: Text('Kira Gram', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3))),
              Text('$chatCount conversations',
                style: GoogleFonts.outfit(fontSize: 11, color: _T.tx2(context), fontWeight: FontWeight.w500)),
            ]),
          ),
          // Action buttons
          Row(children: [
            _HeaderPillBtn(
              icon: Icons.bookmark_rounded, label: 'Saved',
              gradient: const [Color(0xFF7367F0), Color(0xFF5E35B1)],
              onTap: onOpenSaved ?? () {},
            ),
            const SizedBox(width: 7),
            _HeaderPillBtn(
              icon: Icons.auto_awesome_rounded, label: 'AI',
              gradient: const [Color(0xFFE91E8C), Color(0xFF9B2FFF)],
              onTap: onOpenAI ?? () {},
            ),
            const SizedBox(width: 8),
            _HeaderActionBtn(icon: Icons.group_add_outlined, onTap: onNewGroup),
            const SizedBox(width: 7),
            _HeaderActionBtn(icon: Icons.edit_note_rounded, onTap: onNewChat),
          ]),
        ]),
      ]),
    );
  }
}

class _HeaderPillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _HeaderPillBtn({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(color: gradient.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: gradient.last.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.1)),
      ]),
    ),
  );
}

class _HeaderPlainBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderPlainBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: _T.bg3(context), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.bdr2(context))),
      child: Icon(icon, color: _T.tx1(context), size: 17),
    ),
  );
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: _T.bg2(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.bdr2(context).withOpacity(0.6)),
      ),
      child: Icon(icon, color: _T.tx1(context), size: 19),
    ),
  );
}

// ─── CHATS SCREEN ────────────────────────────────────────────
class ChatsScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> profile;
  final Map<String, bool> verifiedCache;
  final VoidCallback? onOpenSaved;
  final VoidCallback? onOpenAI;
  final int unreadCount;
  const ChatsScreen({super.key, required this.uid, required this.profile, required this.verifiedCache,
    this.onOpenSaved, this.onOpenAI, this.unreadCount = 0});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _filtered = [];
  StreamSubscription? _sub;
  String _search = '';

  @override
  void initState() { super.initState(); _listen(); }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _listen() {
    _sub = _ref('userChats/${widget.uid}').onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() { _chats = []; _filtered = []; }); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final items = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map); v['id'] = e.key; return v;
      }).toList()..sort((a, b) => ((b['lastTs'] ?? 0) as int).compareTo((a['lastTs'] ?? 0) as int));
      setState(() { _chats = items; _applySearch(); });
    });
  }

  void _applySearch() {
    if (_search.isEmpty) { _filtered = _chats; return; }
    final lq = _search.toLowerCase();
    _filtered = _chats.where((c) =>
      (c['name'] ?? '').toString().toLowerCase().contains(lq) ||
      (c['lastMsg'] ?? '').toString().toLowerCase().contains(lq)).toList();
  }

  Future<void> _openChat(Map<String, dynamic> meta) async {
    final chatId = meta['id'] as String;
    final type = meta['type'] as String? ?? 'direct';
    final lockSnap = await _ref('chatLocks/$chatId').get();
    if (lockSnap.exists) {
      final lockData = Map<String, dynamic>.from(lockSnap.value as Map);
      if (lockData['pin'] != null) {
        if (!mounted) return;
        final unlocked = await showDialog<bool>(
          context: context, barrierDismissible: false,
          builder: (_) => PinDialog(mode: PinMode.unlock, chatId: chatId, chatName: meta['name'] as String? ?? 'Chat'),
        );
        if (unlocked != true) return;
      }
    }
    await _ref('userChats/${widget.uid}/$chatId').update({'unread': 0});
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(
      chatId: chatId, chatType: type, chatMeta: meta,
      myUid: widget.uid, myProfile: widget.profile, verifiedCache: widget.verifiedCache,
    )));
  }

  Future<void> _deleteChat(String chatId) async {
    await _ref('userChats/${widget.uid}/$chatId').remove();
    _toast('Chat deleted');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ));
  }

  void _showNewChat() async {
    await showModalBottomSheet(context: context, backgroundColor: _T.bg1(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => NewChatSheet(myUid: widget.uid, myProfile: widget.profile));
  }

  void _showNewGroup() async {
    await showModalBottomSheet(context: context, backgroundColor: _T.bg1(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => NewGroupSheet(myUid: widget.uid, myProfile: widget.profile));
  }

  @override
  Widget build(BuildContext context) {
    final groups = _filtered.where((c) => c['type'] == 'group').toList();
    final directs = _filtered.where((c) => c['type'] != 'group').toList();
    return Scaffold(
      backgroundColor: _T.bg0(context),
      body: SafeArea(child: Column(children: [
        _ChatsHeader(
          chatCount: _chats.length,
          onNewChat: _showNewChat,
          onNewGroup: _showNewGroup,
          onOpenSaved: widget.onOpenSaved,
          onOpenAI: widget.onOpenAI,
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: _SearchField(hint: 'Search conversations...', onChanged: (q) => setState(() { _search = q; _applySearch(); }))),
        Expanded(
          child: _filtered.isEmpty
            ? _EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No chats yet', sub: 'Tap the pencil icon to start chatting')
            : ListView(children: [
                if (groups.isNotEmpty) ...[
                  _SecLabel('Groups', Icons.folder_outlined),
                  ...groups.map((c) => _ChatTile(chat: c, onTap: () => _openChat(c), verifiedCache: widget.verifiedCache, onDeleteChat: _deleteChat)),
                ],
                if (directs.isNotEmpty) ...[
                  if (groups.isNotEmpty) _SecLabel('Direct Messages', null),
                  ...directs.map((c) => _ChatTile(chat: c, onTap: () => _openChat(c), verifiedCache: widget.verifiedCache, onDeleteChat: _deleteChat)),
                ],
              ]),
        ),
      ])),
    );
  }
}

class _SecLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _SecLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
    child: Row(children: [
      if (icon != null) ...[
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: _accent)),
        const SizedBox(width: 8),
      ],
      Text(text.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: _T.tx2(context), letterSpacing: 1.2)),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, color: _T.bdr2(context).withOpacity(0.5))),
    ]),
  );
}

class _ChatTile extends StatefulWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  final Map<String, bool> verifiedCache;
  final Function(String)? onDeleteChat;
  const _ChatTile({required this.chat, required this.onTap, required this.verifiedCache, this.onDeleteChat});

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  bool _verified = false;
  // FIX: Live online indicator — listen to users/$partnerId/online directly
  bool _partnerOnline = false;
  StreamSubscription? _onlineSub;

  @override
  void initState() {
    super.initState();
    _resolveVerified();
    _listenOnline();
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    super.dispose();
  }

  void _listenOnline() {
    final partnerId = widget.chat['partnerId'] as String?;
    // Groups don't have a single partner, skip
    if (partnerId == null || widget.chat['type'] == 'group') return;
    _onlineSub = _ref('users/$partnerId/online').onValue.listen((event) {
      if (mounted) setState(() => _partnerOnline = event.snapshot.value == true);
    });
  }

  Future<void> _resolveVerified() async {
    final partnerId = widget.chat['partnerId'] as String?;
    if (partnerId == null) return;
    if (widget.verifiedCache.containsKey(partnerId)) {
      if (mounted) setState(() => _verified = widget.verifiedCache[partnerId]!);
      return;
    }
    try {
      final snap = await _ref('users/$partnerId/isVerified').get();
      final v = snap.exists && snap.value == true;
      widget.verifiedCache[partnerId] = v;
      if (mounted) setState(() => _verified = v);
    } catch (_) {}
  }

  void _showChatOptions(BuildContext context) {
    final chatId = widget.chat['id'] as String? ?? '';
    final name = widget.chat['name'] as String? ?? 'Chat';
    showModalBottomSheet(
      context: context,
      backgroundColor: _T.bg1(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetHandle(),
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text(name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _T.tx0(context)))),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.open_in_new_rounded, color: _accent),
          title: Text('Open Chat', style: GoogleFonts.outfit(color: _T.tx0(context))),
          onTap: () { Navigator.pop(context); widget.onTap(); }),
        ListTile(
          leading: const Icon(Icons.delete_outline_rounded, color: _danger),
          title: Text('Delete Chat', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w600)),
          onTap: () async {
            Navigator.pop(context);
            final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              backgroundColor: _T.bg1(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Delete Chat', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700)),
              content: Text('Delete conversation with $name? This cannot be undone.', style: GoogleFonts.outfit(color: _T.tx1(context))),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w700))),
              ],
            ));
            if (confirm == true && widget.onDeleteChat != null) widget.onDeleteChat!(chatId);
          }),
        const SizedBox(height: 12),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final name = chat['name'] as String? ?? 'Chat';
    final lastMsg = chat['lastMsg'] as String? ?? '';
    final ts = chat['lastTs'] as int? ?? 0;
    final unread = chat['unread'] as int? ?? 0;
    final locked = chat['locked'] == true;
    final avatar = chat['avatar'] as String? ?? '';
    final isGroup = chat['type'] == 'group';
    final verified = _verified;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () => _showChatOptions(context),
        splashColor: _accent.withOpacity(0.06),
        highlightColor: _accent.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            // Avatar with online dot & lock badge
            Stack(clipBehavior: Clip.none, children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: _AvatarWidget(name: name, avatar: avatar, size: 54, isGroup: isGroup),
              ),
              if (_partnerOnline)
                Positioned(right: 2, bottom: 2,
                  child: Container(width: 13, height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      border: Border.all(color: _T.bg0(context), width: 2.5),
                      boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.6), blurRadius: 6)],
                    ))),
              if (locked)
                Positioned(right: -2, top: -2,
                  child: Container(width: 18, height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE91E8C), Color(0xFFFF6B6B)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: _T.bg0(context), width: 2),
                      boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.5), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.lock_rounded, size: 9, color: Colors.white))),
            ]),
            const SizedBox(width: 13),
            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Row(children: [
                  Flexible(child: Text(name,
                    style: GoogleFonts.outfit(
                      fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                      color: _T.tx0(context), fontSize: 15, letterSpacing: -0.1),
                    overflow: TextOverflow.ellipsis)),
                  if (verified) ...[const SizedBox(width: 5), const _VerifiedBadge(size: 15)],
                ])),
                if (ts > 0) Text(_fmtTime(ts),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: unread > 0 ? _accent : _T.tx2(context),
                    fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal)),
              ]),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Text(
                  lastMsg.length > 45 ? '${lastMsg.substring(0, 45)}…' : lastMsg,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: unread > 0 ? _T.tx1(context) : _T.tx2(context),
                    fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal),
                  overflow: TextOverflow.ellipsis, maxLines: 1)),
                const SizedBox(width: 8),
                if (unread > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7367F0), Color(0xFF9B2FFF)]),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: _accent.withOpacity(0.45), blurRadius: 8, offset: const Offset(0,2))],
                    ),
                    child: Text('$unread', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center)),
              ]),
            ])),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideX(begin: 0.03, curve: Curves.easeOut);
  }
}

// ─── AVATAR WIDGET ───────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String name, avatar;
  final double size;
  final bool isGroup;
  const _AvatarWidget({required this.name, required this.avatar, required this.size, this.isGroup = false});

  @override
  Widget build(BuildContext context) {
    if (avatar.startsWith('http')) {
      return ClipOval(child: Image.network(avatar, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context)));
    }
    if (avatar.startsWith('data:')) {
      try { return ClipOval(child: Image.memory(base64Decode(avatar.split(',')[1]), width: size, height: size, fit: BoxFit.cover)); }
      catch (_) {}
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: _avatarColor(name)),
    child: Center(child: isGroup
      ? Icon(Icons.group, color: Colors.white, size: size * 0.42)
      : Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: size * 0.38, color: Colors.white))),
  );
}

// ─── NEW CHAT SHEET ──────────────────────────────────────────
class NewChatSheet extends StatefulWidget {
  final String myUid;
  final Map<String, dynamic> myProfile;
  const NewChatSheet({super.key, required this.myUid, required this.myProfile});
  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    final snap = await _ref('users').get();
    final all = Map<String, dynamic>.from(snap.value as Map? ?? {});
    final lq = q.toLowerCase();
    final matches = all.values.cast<Map>()
      .where((u) => u['uid'] != widget.myUid &&
        ((u['name'] ?? '').toString().toLowerCase().contains(lq) ||
         (u['username'] ?? '').toString().toLowerCase().contains(lq) ||
         (u['email'] ?? '').toString().toLowerCase().contains(lq)))
      .map((u) => Map<String, dynamic>.from(u)).toList();
    setState(() { _results = matches; _loading = false; });
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    final uid = user['uid'] as String;
    final chatId = ([widget.myUid, uid]..sort()).join('_');
    await _ref('userChats/${widget.myUid}/$chatId').update({
      'name': user['name'], 'avatar': user['avatar'] ?? '',
      'partnerId': uid, 'type': 'direct',
      'lastMsg': '', 'lastTs': DateTime.now().millisecondsSinceEpoch, 'unread': 0,
    });
    await _ref('userChats/$uid/$chatId').update({
      'name': widget.myProfile['name'] ?? 'User', 'avatar': widget.myProfile['avatar'] ?? '',
      'partnerId': widget.myUid, 'type': 'direct',
      'lastMsg': '', 'lastTs': DateTime.now().millisecondsSinceEpoch, 'unread': 0,
    });
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(
      chatId: chatId, chatType: 'direct',
      chatMeta: {'id': chatId, 'name': user['name'], 'avatar': user['avatar'] ?? '', 'partnerId': uid, 'type': 'direct'},
      myUid: widget.myUid, myProfile: widget.myProfile, verifiedCache: {uid: user['isVerified'] == true},
    )));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.9, minChildSize: 0.5,
    builder: (_, ctrl) => Column(children: [
      _SheetHandle(),
      Text('New Chat', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
      Padding(padding: const EdgeInsets.all(16),
        child: _SearchField(hint: 'Search by name, @username or email...', onChanged: _search)),
      if (_loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _accent)),
      Expanded(child: ListView(controller: ctrl,
        children: _results.map((u) => _UserTile(user: u, onTap: () => _startChat(u))).toList())),
    ]),
  );
}

// ─── NEW GROUP SHEET ─────────────────────────────────────────
class NewGroupSheet extends StatefulWidget {
  final String myUid;
  final Map<String, dynamic> myProfile;
  const NewGroupSheet({super.key, required this.myUid, required this.myProfile});
  @override
  State<NewGroupSheet> createState() => _NewGroupSheetState();
}

class _NewGroupSheetState extends State<NewGroupSheet> {
  final _nameCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, String> _selected = {};

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    final snap = await _ref('users').get();
    final all = Map<String, dynamic>.from(snap.value as Map? ?? {});
    final lq = q.toLowerCase();
    setState(() => _results = all.values.cast<Map>()
      .where((u) => u['uid'] != widget.myUid &&
        ((u['name'] ?? '').toString().toLowerCase().contains(lq) ||
         (u['username'] ?? '').toString().toLowerCase().contains(lq)))
      .map((u) => Map<String, dynamic>.from(u)).toList());
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: _accent, behavior: SnackBarBehavior.floating));

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _toast('Enter a group name'); return; }
    if (_selected.isEmpty) { _toast('Add at least one member'); return; }
    final chatId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final members = {widget.myUid: true, ...Map.fromEntries(_selected.keys.map((k) => MapEntry(k, true)))};
    await _ref('chats/$chatId/members').set(members);
    final meta = {'name': name, 'avatar': '', 'type': 'group', 'lastMsg': 'Group created', 'lastTs': DateTime.now().millisecondsSinceEpoch, 'unread': 0};
    for (final uid in members.keys) await _ref('userChats/$uid/$chatId').set(meta);
    await _ref('chats/$chatId/messages').push().set({'type': 'system', 'text': '${widget.myProfile['name'] ?? 'Someone'} created "$name"', 'ts': DateTime.now().millisecondsSinceEpoch});
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(
      chatId: chatId, chatType: 'group',
      chatMeta: {...meta, 'id': chatId}, myUid: widget.myUid, myProfile: widget.myProfile, verifiedCache: const {},
    )));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.9, minChildSize: 0.5,
    builder: (_, ctrl) => Column(children: [
      _SheetHandle(),
      Text('New Group', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _NField('Group Name', _nameCtrl, hint: 'Enter group name...')),
      if (_selected.isNotEmpty)
        SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          children: _selected.entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(label: Text(e.value, style: GoogleFonts.outfit(fontSize: 12)),
              backgroundColor: _accent.withOpacity(0.15),
              deleteIconColor: _accentL,
              onDeleted: () => setState(() => _selected.remove(e.key))),
          )).toList())),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _SearchField(hint: 'Search members...', onChanged: _search)),
      Expanded(child: ListView(controller: ctrl,
        children: _results.map((u) {
          final uid = u['uid'] as String;
          final sel = _selected.containsKey(uid);
          return _UserTile(user: u, onTap: () => setState(() {
            if (sel) _selected.remove(uid); else _selected[uid] = u['name'] as String? ?? 'User';
          }), trailing: sel ? Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _primaryGrad),
              child: const Icon(Icons.check, size: 14, color: Colors.white)) : null);
        }).toList())),
      Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
        child: _PrimaryBtn('Create Group', _create)),
    ]),
  );
}

// ─── CHAT SCREEN ─────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String chatId, chatType;
  final Map<String, dynamic> chatMeta, myProfile;
  final String myUid;
  final Map<String, bool> verifiedCache;
  const ChatScreen({super.key, required this.chatId, required this.chatType,
    required this.chatMeta, required this.myUid, required this.myProfile,
    required this.verifiedCache});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _msgs = [];
  Map<String, dynamic>? _pinnedMsg;
  StreamSubscription? _msgSub, _typingSub, _pinSub;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _partnerOnline = false;
  int? _partnerLastSeen;
  bool _partnerTyping = false;
  bool _isRecording = false;
  int _recordSecs = 0;
  Timer? _typingTimer, _recordTimer;
  String? _recordingPath;
  Uint8List? _attachBytes;
  String? _attachBase64;
  Map<String, dynamic>? _replyTo;
  String? _editMsgId;
  bool _showStickers = false;
  late AudioRecorder _audioRecorder;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _listenMessages();
    _listenPartnerPresence();
    _listenTyping();
    _listenPinnedMessage();
    _msgCtrl.addListener(() => setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty));
  }

  @override
  void dispose() {
    _msgSub?.cancel(); _typingSub?.cancel(); _pinSub?.cancel();
    _typingTimer?.cancel(); _recordTimer?.cancel();
    _audioRecorder.dispose();
    _msgCtrl.dispose(); _scrollCtrl.dispose();
    _stopTyping();
    super.dispose();
  }

  void _listenMessages() {
    _msgSub = _ref('chats/${widget.chatId}/messages').orderByChild('ts').limitToLast(100).onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _msgs = []); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final list = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map); v['id'] = e.key; return v;
      }).toList()..sort((a, b) => ((a['ts'] ?? 0) as int).compareTo((b['ts'] ?? 0) as int));
      setState(() => _msgs = list);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      });
      // Mark messages as read
      for (final m in list) {
        if (m['senderId'] != widget.myUid && m['read'] != true) {
          _ref('chats/${widget.chatId}/messages/${m['id']}').update({'read': true});
        }
      }
    });
  }

  void _listenPinnedMessage() {
    _pinSub = _ref('chats/${widget.chatId}/pinnedMessage').onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _pinnedMsg = null); return; }
      setState(() => _pinnedMsg = Map<String, dynamic>.from(event.snapshot.value as Map));
    });
  }

  void _listenPartnerPresence() {
    final partnerId = widget.chatMeta['partnerId'] as String?;
    if (partnerId == null) return;
    _ref('users/$partnerId').onValue.listen((e) {
      if (!e.snapshot.exists) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      setState(() { _partnerOnline = d['online'] == true; _partnerLastSeen = d['lastSeen'] as int?; });
    });
  }

  void _listenTyping() {
    final partnerId = widget.chatMeta['partnerId'] as String?;
    if (partnerId == null) return;
    _typingSub = _ref('chats/${widget.chatId}/typing/$partnerId').onValue.listen((e) {
      setState(() => _partnerTyping = e.snapshot.value == true);
    });
  }

  void _handleTyping() {
    _ref('chats/${widget.chatId}/typing/${widget.myUid}').set(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(2.seconds, _stopTyping);
  }

  void _stopTyping() => _ref('chats/${widget.chatId}/typing/${widget.myUid}').remove();

  Future<void> _sendMessage() async {
    if (_editMsgId != null) {
      final text = _msgCtrl.text.trim();
      if (text.isEmpty) return;
      await _ref('chats/${widget.chatId}/messages/$_editMsgId').update({'text': text, 'edited': true, 'editedAt': ServerValue.timestamp});
      setState(() { _editMsgId = null; });
      _msgCtrl.clear();
      return;
    }
    if (_attachBytes != null) { await _sendImageMessage(); return; }
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _hasText = false);
    _stopTyping();
    final replyData = _replyTo != null
      ? {'text': _replyTo!['text'], 'senderId': _replyTo!['senderId'], 'senderName': _replyTo!['senderName']}
      : null;
    setState(() => _replyTo = null);
    final msgData = <String, dynamic>{
      'text': text, 'senderId': widget.myUid,
      'senderName': widget.myProfile['name'] ?? 'User',
      'senderAvatar': widget.myProfile['avatar'] ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch, 'type': 'text', 'read': false,
    };
    if (replyData != null) msgData['replyTo'] = replyData;
    HapticFeedback.lightImpact();
    final newRef = _ref('chats/${widget.chatId}/messages').push();
    await newRef.set(msgData);
    await _updateChatMeta(text, 'text');
    await _showNotification(widget.myProfile['name'] ?? 'Kira Gram', text);
    _pushNotifToPartner(text, 'message');
  }

  void _pushNotifToPartner(String text, String type) {
    final partnerId = widget.chatMeta['partnerId'] as String?;
    if (partnerId == null) return;
    _ref('notifications/$partnerId').push().set({
      'type': type, 'text': text,
      'senderName': widget.myProfile['name'] ?? 'User',
      'senderAvatar': widget.myProfile['avatar'] ?? '',
      'senderUid': widget.myUid,
      'chatId': widget.chatId,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  Future<void> _sendImageMessage() async {
    if (_attachBytes == null) return;
    final bytes = _attachBytes!;
    final replyData = _replyTo != null
      ? {'text': _replyTo!['text'], 'senderId': _replyTo!['senderId'], 'senderName': _replyTo!['senderName']}
      : null;
    setState(() { _attachBytes = null; _attachBase64 = null; _replyTo = null; });
    HapticFeedback.lightImpact();
    _toast('Sending image...');
    try {
      final uri = Uri.parse('$_cloudinaryBase/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'img_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      final res = await req.send();
      final body = jsonDecode(await res.stream.bytesToString());
      final url = body['secure_url'] as String?;
      if (url == null) throw Exception('No URL from Cloudinary');
      final msgData = <String, dynamic>{
        'type': 'image', 'url': url, 'senderId': widget.myUid,
        'senderName': widget.myProfile['name'] ?? 'User',
        'ts': DateTime.now().millisecondsSinceEpoch, 'read': false,
      };
      if (replyData != null) msgData['replyTo'] = replyData;
      final newRef = _ref('chats/${widget.chatId}/messages').push();
      await newRef.set(msgData);
      await _updateChatMeta('📷 Photo', 'image');
      _pushNotifToPartner('📷 Photo', 'message');
    } catch (e) {
      _toast('Image upload failed: $e', error: true);
    }
  }

  Future<void> _updateChatMeta(String lastMsg, String type) async {
    final myUpdate = {'lastMsg': lastMsg, 'lastTs': DateTime.now().millisecondsSinceEpoch, 'type': widget.chatType};
    if (widget.chatType == 'direct') {
      final partnerId = widget.chatMeta['partnerId'] as String?;
      await _ref('userChats/${widget.myUid}/${widget.chatId}').update(myUpdate);
      if (partnerId != null) {
        final snap = await _ref('userChats/$partnerId/${widget.chatId}/unread').get();
        final unread = ((snap.value as int?) ?? 0) + 1;
        await _ref('userChats/$partnerId/${widget.chatId}').update({
          ...myUpdate, 'unread': unread,
          'name': widget.myProfile['name'] ?? 'User', 'partnerId': widget.myUid,
          'avatar': widget.myProfile['avatar'] ?? '',
        });
      }
    } else if (widget.chatType == 'group') {
      final snap = await _ref('chats/${widget.chatId}/members').get();
      if (snap.exists) {
        final members = Map<String, dynamic>.from(snap.value as Map);
        for (final uid in members.keys) {
          final side = <String, dynamic>{...myUpdate};
          if (uid != widget.myUid) {
            final us = await _ref('userChats/$uid/${widget.chatId}/unread').get();
            side['unread'] = ((us.value as int?) ?? 0) + 1;
          }
          await _ref('userChats/$uid/${widget.chatId}').update(side);
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 75);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _attachBytes = bytes; _attachBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}'; });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() { _isRecording = false; _recordSecs = 0; });
      if (path != null) await _sendVoiceMessage(path);
    } else {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) { _toast('Microphone permission denied', error: true); return; }
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
      _recordSecs = 0;
      _recordTimer = Timer.periodic(1.seconds, (_) => setState(() => _recordSecs++));
      setState(() => _isRecording = true);
    }
  }

  Future<void> _sendVoiceMessage(String filePath) async {
    _toast('Sending voice note...');
    try {
      // FIX: Use /upload with resource_type=auto in URL — works with unsigned presets
      // 'kiragram' preset must have "Resource type" set to "Auto" in Cloudinary dashboard
      final uri = Uri.parse('$_cloudinaryBase/auto/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath, filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'));
      final streamRes = await req.send();
      final body = jsonDecode(await streamRes.stream.bytesToString());
      debugPrint('[Cloudinary Voice] status: ${streamRes.statusCode} body: $body');
      final url = body['secure_url'] as String?;
      if (url == null) throw Exception('No URL from Cloudinary: ${body['error']}');
      HapticFeedback.lightImpact();
      final newRef = _ref('chats/${widget.chatId}/messages').push();
      await newRef.set({
        'type': 'voice', 'url': url, 'duration': _recordSecs,
        'senderId': widget.myUid, 'senderName': widget.myProfile['name'] ?? 'User',
        'ts': DateTime.now().millisecondsSinceEpoch, 'read': false,
      });
      await _updateChatMeta('🎤 Voice note', 'voice');
      _pushNotifToPartner('🎤 Voice note', 'message');
    } catch (e) {
      _toast('Voice upload failed: $e', error: true);
    }
  }

  Future<void> _sendSticker(String emoji) async {
    setState(() => _showStickers = false);
    final newRef = _ref('chats/${widget.chatId}/messages').push();
    await newRef.set({'type': 'sticker', 'text': emoji, 'senderId': widget.myUid,
      'senderName': widget.myProfile['name'] ?? 'User', 'ts': DateTime.now().millisecondsSinceEpoch, 'read': false});
    await _updateChatMeta('$emoji Sticker', 'sticker');
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: error ? _danger : _accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ));
  }

  Future<void> _deleteMsg(String msgId) async {
    await _ref('chats/${widget.chatId}/messages/$msgId').remove();
    _toast('Message deleted');
  }

  Future<void> _addReaction(String emoji, String msgId) async {
    final rRef = _ref('chats/${widget.chatId}/messages/$msgId/reactions/${widget.myUid}');
    final snap = await rRef.get();
    if (snap.exists && (Map<String, dynamic>.from(snap.value as Map))['emoji'] == emoji) {
      await rRef.remove();
    } else {
      await rRef.set({'emoji': emoji, 'uid': widget.myUid});
    }
  }

  Future<void> _pinMessage(Map<String, dynamic> msg) async {
    await _ref('chats/${widget.chatId}/pinnedMessage').set({
      'text': msg['text'] ?? (msg['type'] == 'image' ? '📷 Photo' : '🎤 Voice'),
      'senderName': msg['senderName'] ?? 'User',
      'msgId': msg['id'],
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    _toast('Message pinned 📌');
  }

  Future<void> _unpinMessage() async {
    await _ref('chats/${widget.chatId}/pinnedMessage').remove();
    _toast('Message unpinned');
  }

  Future<void> _forwardMessage(Map<String, dynamic> msg) async {
    Navigator.pop(context);
    await showModalBottomSheet(context: context, backgroundColor: _T.bg1(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ForwardSheet(myUid: widget.myUid, myProfile: widget.myProfile, msg: msg));
  }

  void _showChatOptions() {
    showModalBottomSheet(context: context, backgroundColor: _T.bg1(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetHandle(),
        ListTile(leading: const Icon(Icons.lock_outline, color: _accent),
          title: Text('Lock Chat', style: GoogleFonts.outfit(color: _T.tx0(context))),
          onTap: () async { Navigator.pop(context); await showDialog(context: context, builder: (_) => PinDialog(mode: PinMode.set, chatId: widget.chatId, chatName: widget.chatMeta['name'] as String? ?? 'Chat')); }),
        ListTile(leading: const Icon(Icons.lock_open, color: _accentTeal),
          title: Text('Remove Lock', style: GoogleFonts.outfit(color: _T.tx0(context))),
          onTap: () async {
            Navigator.pop(context);
            await _ref('chatLocks/${widget.chatId}').remove();
            await _ref('userChats/${widget.myUid}/${widget.chatId}').update({'locked': false});
            final partnerId = widget.chatMeta['partnerId'] as String?;
            if (partnerId != null) await _ref('userChats/$partnerId/${widget.chatId}').update({'locked': false});
            _toast('Chat lock removed 🔓');
          }),
        ListTile(leading: const Icon(Icons.delete_sweep_outlined, color: _danger),
          title: Text('Clear Chat', style: GoogleFonts.outfit(color: _danger)),
          onTap: () async { Navigator.pop(context); await _ref('chats/${widget.chatId}/messages').remove(); _toast('Chat cleared'); }),
        if (widget.chatType == 'direct') ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block_outlined, color: _danger),
            title: Text('Block User', style: GoogleFonts.outfit(color: _danger)),
            onTap: () async {
              Navigator.pop(context);
              final partnerId = widget.chatMeta['partnerId'] as String?;
              if (partnerId == null) return;
              final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                backgroundColor: _T.bg1(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Block User', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700)),
                content: Text('Block ${widget.chatMeta["name"] ?? "this user"}? They won\'t be able to message you.', style: GoogleFonts.outfit(color: _T.tx1(context))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Block', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w700))),
                ],
              ));
              if (confirmed != true) return;
              await _ref('blocks/${widget.myUid}/$partnerId').set({'blockedAt': DateTime.now().millisecondsSinceEpoch, 'name': widget.chatMeta['name'] ?? ''});
              _toast('User blocked');
            },
          ),
        ],
        const SizedBox(height: 16),
      ]));
  }

  void _viewPartnerProfile() {
    final partnerId = widget.chatMeta['partnerId'] as String?;
    if (partnerId == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeerProfileScreen(uid: partnerId)));
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.chatMeta['name'] as String? ?? 'Chat';
    final verified = widget.chatType == 'direct' &&
      (widget.verifiedCache[widget.chatMeta['partnerId'] as String? ?? ''] ?? false);
    final avatar = widget.chatMeta['avatar'] as String? ?? '';

    String statusText;
    Color statusColor;
    if (widget.chatType == 'direct') {
      if (_partnerOnline) { statusText = '● Online'; statusColor = _online; }
      else { statusText = _fmtLastSeen(_partnerLastSeen); statusColor = _T.tx1(context); }
      if (_partnerTyping) { statusText = 'typing...'; statusColor = _accentL; }
    } else {
      statusText = 'Group chat';
      statusColor = _T.tx1(context);
    }

    return Scaffold(
      backgroundColor: _T.bg0(context),
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(child: Container(
          decoration: BoxDecoration(color: _T.bg1(context).withOpacity(0.92),
            border: Border(bottom: BorderSide(color: _T.bdr2(context))),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
          child: SafeArea(child: Row(children: [
            IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: _T.tx0(context), size: 18), onPressed: () => Navigator.pop(context)),
            GestureDetector(onTap: widget.chatType == 'direct' ? _viewPartnerProfile : null,
              child: _AvatarWidget(name: partnerName, avatar: avatar, size: 38)),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: widget.chatType == 'direct' ? _viewPartnerProfile : null,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(children: [
                  Text(partnerName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _T.tx0(context))),
                  if (verified) ...[const SizedBox(width: 4), const _VerifiedBadge()],
                ]),
                Text(statusText, style: GoogleFonts.outfit(fontSize: 11, color: statusColor)),
              ]),
            )),
            IconButton(icon: Icon(Icons.more_vert_rounded, color: _T.tx1(context)), onPressed: _showChatOptions),
          ])),
        )),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
        // Pinned message banner (NEW)
        if (_pinnedMsg != null)
          GestureDetector(
            onTap: () {
              final msgId = _pinnedMsg!['msgId'] as String?;
              if (msgId != null) {
                final idx = _msgs.indexWhere((m) => m['id'] == msgId);
                if (idx >= 0 && _scrollCtrl.hasClients) {
                  _scrollCtrl.animateTo(idx * 72.0, duration: 300.ms, curve: Curves.easeOut);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                border: Border(left: const BorderSide(color: _accent, width: 3),
                  bottom: BorderSide(color: _T.bdr2(context))),
              ),
              child: Row(children: [
                const Icon(Icons.push_pin_rounded, color: _accentL, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pinned Message', style: GoogleFonts.outfit(fontSize: 10, color: _accentL, fontWeight: FontWeight.w700)),
                  Text(_pinnedMsg!['text'] as String? ?? '', style: GoogleFonts.outfit(fontSize: 12, color: _T.tx1(context)), overflow: TextOverflow.ellipsis),
                ])),
                GestureDetector(onTap: _unpinMessage, child: Icon(Icons.close_rounded, size: 16, color: _T.tx2(context))),
              ]),
            ),
          ),
        // Attachment preview
        if (_attachBytes != null)
          Container(padding: const EdgeInsets.all(8), color: _T.bg2(context),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(8),
                child: Image.memory(_attachBytes!, height: 60, width: 60, fit: BoxFit.cover)),
              const SizedBox(width: 8),
              Expanded(child: Text('Image ready to send', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13))),
              IconButton(icon: Icon(Icons.close_rounded, color: _T.tx1(context), size: 18),
                onPressed: () => setState(() { _attachBytes = null; _attachBase64 = null; })),
            ])),
        // Reply preview
        if (_replyTo != null)
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: _accent.withOpacity(0.1),
            child: Row(children: [
              const Icon(Icons.reply_rounded, color: _accentL, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('${_replyTo!['senderName'] ?? ''}: ${_replyTo!['text'] ?? ''}',
                style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 12), overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.close_rounded, color: _accentL, size: 16),
                onPressed: () => setState(() => _replyTo = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ])),
        // Edit indicator
        if (_editMsgId != null)
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), color: _accentTeal.withOpacity(0.1),
            child: Row(children: [
              const Icon(Icons.edit_rounded, color: _accentTeal, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text('Editing message', style: GoogleFonts.outfit(color: _accentTeal, fontSize: 12))),
              IconButton(icon: const Icon(Icons.close_rounded, color: _accentTeal, size: 16),
                onPressed: () => setState(() { _editMsgId = null; _msgCtrl.clear(); }), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ])),
        // Recording indicator
        if (_isRecording)
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: _danger.withOpacity(0.1),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _danger))
                .animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0, duration: 600.ms),
              const SizedBox(width: 8),
              Text('Recording ${_fmtDuration(_recordSecs)}', style: GoogleFonts.outfit(color: _danger, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(onPressed: () async {
                _recordTimer?.cancel();
                await _audioRecorder.stop();
                setState(() { _isRecording = false; _recordSecs = 0; });
              }, child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
            ])),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: _msgs.length + (_partnerTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (_partnerTyping && i == _msgs.length) return _TypingIndicator(name: partnerName);
              return _MessageBubble(
                msg: _msgs[i], myUid: widget.myUid, chatType: widget.chatType,
                onReply: (msg) => setState(() => _replyTo = msg),
                onEdit: (msg) => setState(() { _editMsgId = msg['id']; _msgCtrl.text = msg['text'] ?? ''; }),
                onDelete: _deleteMsg, onReact: _addReaction, onForward: _forwardMessage,
                onPin: _pinMessage,
                onMentionTap: (uid) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeerProfileScreen(uid: uid))),
                onAskAI: (text) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AIScreen(uid: widget.myUid, initialQuery: text))),
              );
            },
          ),
        ),
        // Sticker panel (NEW)
        if (_showStickers)
          _StickerPanel(onSelect: _sendSticker, onClose: () => setState(() => _showStickers = false)),
        // Input bar
        Container(
          padding: EdgeInsets.only(
            left: 8, right: 8, top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(color: _T.bg1(context), border: Border(top: BorderSide(color: _T.bdr2(context)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(icon: Icon(Icons.attach_file_rounded, color: _T.tx1(context), size: 22), onPressed: _pickImage, padding: const EdgeInsets.all(4)),
            IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: _showStickers ? _accentL : _T.tx1(context), size: 22),
              onPressed: () => setState(() => _showStickers = !_showStickers), padding: const EdgeInsets.all(4)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: _T.input(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: _T.bdr(context))),
                child: TextField(
                  controller: _msgCtrl,
                  style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14),
                  maxLines: 5, minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.outfit(color: _T.tx2(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (_) => _handleTyping(),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isRecording ? _toggleRecording : (_hasText || _attachBytes != null ? _sendMessage : _toggleRecording),
              child: AnimatedContainer(duration: 200.ms, width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _isRecording ? [_danger, _danger.withOpacity(0.7)] : [_accent, _accentPink],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: (_isRecording ? _danger : _accent).withOpacity(0.35), blurRadius: 12)]),
                child: Icon(_isRecording ? Icons.stop_rounded : (_hasText || _attachBytes != null ? Icons.send_rounded : Icons.mic_none_rounded),
                  color: Colors.white, size: 20)),
            ),
          ]),
        ),
      ]),
      ),
    );
  }
}

// ─── STICKER PANEL (NEW) ─────────────────────────────────────
class _StickerPanel extends StatelessWidget {
  final Function(String) onSelect;
  final VoidCallback onClose;
  const _StickerPanel({required this.onSelect, required this.onClose});

  static const _stickers = [
    '❤️','😂','😍','🔥','👍','😭','🎉','✨','😎','🥰',
    '😢','😡','👏','🙌','💯','🤔','😴','🤣','😅','🥳',
    '💪','🎊','🌟','💖','🦋','🌸','🍀','🎵','🚀','👋',
    '🤝','🙏','💌','🎁','⭐','🏆','💎','🌈','🌊','🎶',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: _T.bg2(context), border: Border(top: BorderSide(color: _T.bdr2(context)))),
      child: Column(children: [
        Row(children: [
          Padding(padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text('Stickers', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _T.tx1(context)))),
          const Spacer(),
          IconButton(icon: Icon(Icons.close_rounded, size: 18, color: _T.tx2(context)), onPressed: onClose),
        ]),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: _stickers.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => onSelect(_stickers[i]),
            child: Container(
              decoration: BoxDecoration(color: _T.bg3(context), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(_stickers[i], style: const TextStyle(fontSize: 24))),
            ),
          ),
        )),
      ]),
    );
  }
}

// ─── FORWARD SHEET ───────────────────────────────────────────
class _ForwardSheet extends StatefulWidget {
  final String myUid;
  final Map<String, dynamic> myProfile, msg;
  const _ForwardSheet({required this.myUid, required this.myProfile, required this.msg});
  @override
  State<_ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends State<_ForwardSheet> {
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final snap = await _ref('userChats/${widget.myUid}').get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    setState(() => _chats = data.entries.map((e) {
      final v = Map<String, dynamic>.from(e.value as Map); v['id'] = e.key; return v;
    }).toList());
  }

  Future<void> _forward(Map<String, dynamic> chat) async {
    final chatId = chat['id'] as String;
    final newRef = _ref('chats/$chatId/messages').push();
    final payload = Map<String, dynamic>.from(widget.msg)
      ..remove('id')
      ..['ts'] = DateTime.now().millisecondsSinceEpoch
      ..['senderId'] = widget.myUid
      ..['senderName'] = widget.myProfile['name'] ?? 'User'
      ..['read'] = false
      ..['forwarded'] = true;
    await newRef.set(payload);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message forwarded ✓'), backgroundColor: _accent, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.6, minChildSize: 0.4,
    builder: (_, ctrl) => Column(children: [
      _SheetHandle(),
      Text('Forward to...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
      const SizedBox(height: 8),
      Expanded(child: ListView(controller: ctrl, children: _chats.map((c) {
        final name = c['name'] as String? ?? 'Chat';
        return ListTile(
          leading: _AvatarWidget(name: name, avatar: c['avatar'] as String? ?? '', size: 44),
          title: Text(name, style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w600)),
          onTap: () => _forward(c),
        );
      }).toList())),
    ]),
  );
}

// ─── MESSAGE BUBBLE ──────────────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final String myUid, chatType;
  final Function(Map<String, dynamic>) onReply, onEdit, onForward, onPin;
  final Function(String) onDelete;
  final Function(String, String) onReact;
  final Function(String) onMentionTap;
  final Function(String)? onAskAI;

  const _MessageBubble({required this.msg, required this.myUid, required this.chatType,
    required this.onReply, required this.onEdit, required this.onDelete,
    required this.onReact, required this.onForward, required this.onPin,
    required this.onMentionTap, this.onAskAI});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _dragging = false;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: 300.ms);
  }

  @override
  void dispose() { _bounceCtrl.dispose(); super.dispose(); }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    final isOut = widget.msg['senderId'] == widget.myUid;
    final delta = d.primaryDelta ?? 0;
    if (isOut && delta < 0) {
      setState(() => _dragOffset = (_dragOffset + delta).clamp(-60.0, 0.0));
    } else if (!isOut && delta > 0) {
      setState(() => _dragOffset = (_dragOffset + delta).clamp(0.0, 60.0));
    }
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    final isOut = widget.msg['senderId'] == widget.myUid;
    final triggered = isOut ? _dragOffset < -40 : _dragOffset > 40;
    if (triggered) {
      HapticFeedback.mediumImpact();
      widget.onReply(widget.msg);
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final type = msg['type'] as String? ?? 'text';
    if (type == 'system') {
      return Center(child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: _T.bg3(context), borderRadius: BorderRadius.circular(99)),
        child: Text(msg['text'] as String? ?? '', style: GoogleFonts.outfit(fontSize: 11, color: _T.tx1(context)))));
    }

    final isOut = msg['senderId'] == widget.myUid;
    final ts = msg['ts'] as int? ?? 0;
    final timeStr = ts > 0 ? DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts)) : '';
    final reactions = msg['reactions'] as Map?;
    final replyTo = msg['replyTo'] as Map?;
    final senderName = msg['senderName'] as String?;
    final edited = msg['edited'] == true;
    final read = msg['read'] == true;
    final forwarded = msg['forwarded'] == true;

    Widget bubble = GestureDetector(
      onTap: () => _showContextMenu(context, isOut),
      onLongPress: () => _showContextMenu(context, isOut),
      child: Align(
        alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Column(
            crossAxisAlignment: isOut ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (widget.chatType == 'group' && !isOut && senderName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Text(senderName, style: GoogleFonts.outfit(fontSize: 11, color: _accentL, fontWeight: FontWeight.w600)),
                ),
              if (forwarded)
                Padding(
                  padding: EdgeInsets.only(left: isOut ? 0 : 12, right: isOut ? 12 : 0, bottom: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.forward_rounded, size: 12, color: _T.tx2(context)),
                    const SizedBox(width: 2),
                    Text('Forwarded', style: GoogleFonts.outfit(fontSize: 10, color: _T.tx2(context))),
                  ]),
                ),
              ValueListenableBuilder<String>(
                valueListenable: _chatThemeNotifier,
                builder: (context, themeName, _) {
                  final bubbleGrad = isOut
                      ? LinearGradient(
                          colors: _chatThemes[themeName] ?? [const Color(0xFF7367F0), const Color(0xFF9B2FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: bubbleGrad,
                      color: isOut ? null : _T.inBubble(context),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isOut ? 18 : 4),
                        bottomRight: Radius.circular(isOut ? 4 : 18),
                      ),
                      border: isOut ? null : Border.all(color: _T.bdr2(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (replyTo != null)
                          Container(
                            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              border: const Border(left: BorderSide(color: _accentL, width: 3)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(replyTo['senderName'] as String? ?? '', style: GoogleFonts.outfit(fontSize: 10, color: _accentL, fontWeight: FontWeight.w600)),
                              Text(replyTo['text'] as String? ?? '', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        _buildContent(context, type, isOut),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(timeStr, style: TextStyle(fontSize: 10, color: isOut ? Colors.white54 : _T.tx2(context))),
                            if (edited) Text(' (edited)', style: TextStyle(fontSize: 9, color: isOut ? Colors.white38 : _T.tx2(context))),
                            if (isOut) ...[
                              const SizedBox(width: 4),
                              Icon(read ? Icons.done_all_rounded : Icons.done_rounded, size: 12, color: read ? _accentTeal : Colors.white38),
                            ],
                          ]),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (reactions != null) _buildReactions(context, reactions),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).slideX(begin: isOut ? 0.04 : -0.04);

    // Swipe to reply wrapper
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: 80.ms,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: bubble,
          ),
          // Swipe reply icon hint
          if (_dragOffset.abs() > 10)
            Positioned(
              left: isOut ? null : (_dragOffset - 30).clamp(0.0, 30.0),
              right: isOut ? (-_dragOffset - 30).clamp(0.0, 30.0) : null,
              top: 0, bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: (_dragOffset.abs() / 60).clamp(0.0, 1.0),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: _accent.withOpacity(0.85), shape: BoxShape.circle),
                    child: const Icon(Icons.reply_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, String type, bool isOut) {
    if (type == 'image') {
      final url = widget.msg['url'] as String? ?? '';
      return GestureDetector(
        onTap: () => _openImageViewer(context, url),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          child: url.startsWith('data:')
            ? Image.memory(base64Decode(url.split(',')[1]), width: 220, height: 220, fit: BoxFit.cover)
            : Image.network(url, width: 220, height: 220, fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) => prog == null ? child
                  : SizedBox(width: 220, height: 120,
                      child: Center(child: CircularProgressIndicator(value: prog.expectedTotalBytes != null
                        ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes! : null,
                        color: _accentL, strokeWidth: 2))),
              ),
        ));
    }
    if (type == 'voice') {
      return _VoiceMsgPlayer(url: widget.msg['url'] as String? ?? '', duration: widget.msg['duration'] as int? ?? 0, isOut: isOut);
    }
    if (type == 'sticker') {
      return Padding(padding: const EdgeInsets.all(8),
        child: Text(widget.msg['text'] as String? ?? '', style: const TextStyle(fontSize: 46)));
    }
    final text = widget.msg['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: _MentionText(text: text, isOut: isOut, onMentionTap: widget.onMentionTap),
    );
  }

  Widget _buildReactions(BuildContext context, Map reactions) {
    final grouped = <String, int>{};
    for (final v in reactions.values) {
      final e = (v as Map)['emoji'] as String? ?? '';
      grouped[e] = (grouped[e] ?? 0) + 1;
    }
    if (grouped.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 4, children: grouped.entries.map((e) => GestureDetector(
        onTap: () => widget.onReact(e.key, widget.msg['id'] as String? ?? ''),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: _T.bg3(context), borderRadius: BorderRadius.circular(99), border: Border.all(color: _T.bdr(context))),
          child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 12))),
      )).toList()));
  }

  void _showContextMenu(BuildContext context, bool isOut) {
    final msgId = widget.msg['id'] as String? ?? '';
    final msgText = widget.msg['text'] as String? ?? '';
    // Allow delete for sender always; allow delete for receiver in direct chat
    final canDelete = isOut || widget.chatType == 'direct';
    showModalBottomSheet(
      context: context,
      backgroundColor: _T.bg1(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _SheetHandle(),
              // Emoji reactions row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '👍', '😂', '😮', '😢', '🔥', '🎉'].map((e) => GestureDetector(
                    onTap: () { Navigator.pop(sheetCtx); widget.onReact(e, msgId); },
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: _T.bg3(sheetCtx), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 22)))),
                  )).toList(),
                ),
              ),
              Divider(color: _T.bdr2(sheetCtx), height: 1),
              ListTile(
                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.reply_rounded, color: _accent, size: 18)),
                title: Text('Reply', style: GoogleFonts.outfit(color: _T.tx0(sheetCtx), fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(sheetCtx); widget.onReply(widget.msg); }),
              ListTile(
                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _accentTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.forward_rounded, color: _accentTeal, size: 18)),
                title: Text('Forward', style: GoogleFonts.outfit(color: _T.tx0(sheetCtx), fontWeight: FontWeight.w600)),
                onTap: () => widget.onForward(widget.msg)),
              ListTile(
                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _accentL.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.push_pin_outlined, color: _accentL, size: 18)),
                title: Text('Pin Message', style: GoogleFonts.outfit(color: _T.tx0(sheetCtx), fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(sheetCtx); widget.onPin(widget.msg); }),
              if (isOut) ListTile(
                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _accentL.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_outlined, color: _accentL, size: 18)),
                title: Text('Edit', style: GoogleFonts.outfit(color: _T.tx0(sheetCtx), fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(sheetCtx); widget.onEdit(widget.msg); }),
              if (msgText.isNotEmpty) ListTile(
                leading: Container(width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7367F0), Color(0xFFFF3D8F)]),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18)),
                title: Text('Ask Kira AI', style: GoogleFonts.outfit(color: _T.tx0(sheetCtx), fontWeight: FontWeight.w600)),
                subtitle: Text('Analyze with AI', style: GoogleFonts.outfit(color: _T.tx2(sheetCtx), fontSize: 11)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (widget.onAskAI != null) widget.onAskAI!(msgText);
                }),
              ListTile(
                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _T.bg3(sheetCtx), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.copy_outlined, color: _T.tx1(sheetCtx), size: 18)),
                title: Text('Copy', style: GoogleFonts.outfit(color: _T.tx0(sheetCtx), fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(sheetCtx); Clipboard.setData(ClipboardData(text: msgText)); }),
              if (canDelete) ListTile(
                leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: _danger.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: _danger, size: 18)),
                title: Text('Delete', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(sheetCtx); widget.onDelete(msgId); }),
              const SizedBox(height: 8),
            ]),
          ),
        );
      },
    );
  }

  void _openImageViewer(BuildContext context, String url) {
    showDialog(context: context, builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(color: Colors.black,
        child: Center(child: InteractiveViewer(child: url.startsWith('data:')
          ? Image.memory(base64Decode(url.split(',')[1]))
          : Image.network(url))))));
  }
}

// ─── @MENTION TEXT WIDGET (NEW) ──────────────────────────────
class _MentionText extends StatelessWidget {
  final String text;
  final bool isOut;
  final Function(String) onMentionTap;
  const _MentionText({required this.text, required this.isOut, required this.onMentionTap});

  @override
  Widget build(BuildContext context) {
    // Parse @mentions: match @word
    final regex = RegExp(r'@(\w+)');
    final spans = <InlineSpan>[];
    int last = 0;
    final baseColor = isOut ? Colors.white : _T.tx0(context);

    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final username = match.group(1)!;
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: () => _resolveAndNavigate(context, username),
          child: Text('@$username',
            style: GoogleFonts.outfit(
              color: isOut ? Colors.white : _accentL,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: isOut ? Colors.white54 : _accentL,
            )),
        ),
      ));
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: GoogleFonts.outfit(color: baseColor, fontSize: 14, height: 1.5),
      ),
    );
  }

  Future<void> _resolveAndNavigate(BuildContext context, String username) async {
    // Look up user by username
    final snap = await _ref('users').orderByChild('username').equalTo(username).limitToFirst(1).get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    if (data.isEmpty) return;
    final uid = data.keys.first;
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeerProfileScreen(uid: uid)));
  }
}

// ─── VOICE MSG PLAYER ────────────────────────────────────────
class _VoiceMsgPlayer extends StatefulWidget {
  final String url;
  final int duration;
  final bool isOut;
  const _VoiceMsgPlayer({required this.url, required this.duration, this.isOut = true});
  @override
  State<_VoiceMsgPlayer> createState() => _VoiceMsgPlayerState();
}

class _VoiceMsgPlayerState extends State<_VoiceMsgPlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _total = d); });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() { _playing = false; _position = Duration.zero; }); });
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(UrlSource(widget.url));
      setState(() => _playing = true);
    }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isOut ? Colors.white : _T.tx0(context);
    final barActive = widget.isOut ? Colors.white70 : _accentL;
    final barInactive = widget.isOut ? Colors.white30 : _T.tx2(context);
    final timeColor = widget.isOut ? Colors.white60 : _T.tx2(context);
    final displaySecs = _playing && _total.inSeconds > 0
      ? (_total.inSeconds - _position.inSeconds).abs()
      : widget.duration;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: _toggle,
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: widget.isOut ? Colors.white24 : _accent.withOpacity(0.15)),
            child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: iconColor, size: 22))),
        const SizedBox(width: 8),
        // Animated waveform bars
        Row(children: List.generate(24, (i) {
          final heights = [4.0, 7.0, 10.0, 6.0, 12.0, 5.0, 9.0, 3.0, 8.0, 11.0, 4.0, 7.0,
                           6.0, 10.0, 5.0, 8.0, 12.0, 4.0, 9.0, 6.0, 11.0, 5.0, 8.0, 4.0];
          final h = heights[i % heights.length];
          final progress = _total.inMilliseconds > 0 ? _position.inMilliseconds / _total.inMilliseconds : 0.0;
          final passed = i / 24 < progress;
          return AnimatedContainer(
            duration: 80.ms,
            width: 2.5, height: _playing && passed ? h * 1.2 : h,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: passed ? barActive : barInactive,
              borderRadius: BorderRadius.circular(1.5)));
        })),
        const SizedBox(width: 8),
        Text(_fmtDuration(displaySecs), style: TextStyle(fontSize: 11, color: timeColor)),
      ]),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final String name;
  const _TypingIndicator({required this.name});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: _T.inBubble(context),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
        border: Border.all(color: _T.bdr2(context))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('typing ', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 12)),
        ...List.generate(3, (i) => Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: _T.tx1(context)))
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(end: 1.6, duration: 400.ms, delay: Duration(milliseconds: i * 150))
          .then().scaleXY(end: 1.0, duration: 400.ms)),
      ]),
    ),
  );
}

// ─── PEOPLE / DISCOVER SCREEN (NEW) ──────────────────────────
class PeopleScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> myProfile;
  const PeopleScreen({super.key, required this.uid, required this.myProfile});
  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final snap = await _ref('users').get();
    if (!snap.exists) { setState(() => _loading = false); return; }
    final data = Map<String, dynamic>.from(snap.value as Map);
    final list = data.values.cast<Map>()
      .where((u) => u['uid'] != widget.uid)
      .map((u) => Map<String, dynamic>.from(u)).toList()
      ..sort((a, b) => (b['online'] == true ? 1 : 0).compareTo(a['online'] == true ? 1 : 0));
    setState(() { _all = list; _filtered = list; _loading = false; });
  }

  void _applySearch(String q) {
    _search = q;
    if (q.isEmpty) { setState(() => _filtered = _all); return; }
    final lq = q.toLowerCase();
    setState(() => _filtered = _all.where((u) =>
      (u['name'] ?? '').toString().toLowerCase().contains(lq) ||
      (u['username'] ?? '').toString().toLowerCase().contains(lq) ||
      (u['bio'] ?? '').toString().toLowerCase().contains(lq)).toList());
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    final uid = user['uid'] as String;
    final chatId = ([widget.uid, uid]..sort()).join('_');
    await _ref('userChats/${widget.uid}/$chatId').update({
      'name': user['name'], 'avatar': user['avatar'] ?? '', 'partnerId': uid,
      'type': 'direct', 'lastMsg': '', 'lastTs': DateTime.now().millisecondsSinceEpoch, 'unread': 0,
    });
    await _ref('userChats/$uid/$chatId').update({
      'name': widget.myProfile['name'] ?? 'User', 'avatar': widget.myProfile['avatar'] ?? '',
      'partnerId': widget.uid, 'type': 'direct',
      'lastMsg': '', 'lastTs': DateTime.now().millisecondsSinceEpoch, 'unread': 0,
    });
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(
      chatId: chatId, chatType: 'direct',
      chatMeta: {'id': chatId, 'name': user['name'], 'avatar': user['avatar'] ?? '', 'partnerId': uid, 'type': 'direct'},
      myUid: widget.uid, myProfile: widget.myProfile, verifiedCache: {uid: user['isVerified'] == true},
    )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.bg0(context),
    body: SafeArea(child: Column(children: [
      _GlassAppBar(title: 'People', subtitle: 'Discover users on Kira Gram'),
      Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: _SearchField(hint: 'Search by name, @username or bio...', onChanged: _applySearch)),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: _accent))
        : _filtered.isEmpty
          ? _EmptyState(icon: Icons.people_outline_rounded, title: 'No users found', sub: 'Try a different search term')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final u = _filtered[i];
                final online = u['online'] == true;
                final verified = u['isVerified'] == true;
                return ListTile(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeerProfileScreen(uid: u['uid'] as String))),
                  leading: Stack(children: [
                    _AvatarWidget(name: u['name'] as String? ?? '', avatar: u['avatar'] as String? ?? '', size: 50),
                    if (online) Positioned(right: 1, bottom: 1,
                      child: Container(width: 11, height: 11,
                        decoration: BoxDecoration(color: _online, shape: BoxShape.circle, border: Border.all(color: _T.bg0(context), width: 2)))),
                  ]),
                  title: Row(children: [
                    Text(u['name'] as String? ?? 'User', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: _T.tx0(context), fontSize: 14)),
                    if (verified) ...[const SizedBox(width: 4), const _VerifiedBadge()],
                  ]),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('@${u['username'] ?? ''}', style: GoogleFonts.outfit(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    if ((u['bio'] as String? ?? '').isNotEmpty)
                      Text(u['bio'] as String, style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                  isThreeLine: (u['bio'] as String? ?? '').isNotEmpty,
                  trailing: GestureDetector(
                    onTap: () => _startChat(u),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(gradient: _primaryGrad, borderRadius: BorderRadius.circular(50),
                        boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 8)]),
                      child: Text('Message', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              })),
    ])),
  );
}

// ─── SAVED MESSAGES SCREEN (NEW) ─────────────────────────────
class SavedScreen extends StatefulWidget {
  final String uid;
  const SavedScreen({super.key, required this.uid});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> _items = [];
  StreamSubscription? _sub;

  @override
  void initState() { super.initState(); _listen(); }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _listen() {
    _sub = _ref('saved/${widget.uid}').orderByChild('ts').onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _items = []); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final list = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map); v['id'] = e.key; return v;
      }).toList()..sort((a, b) => ((b['ts'] ?? 0) as int).compareTo((a['ts'] ?? 0) as int));
      setState(() => _items = list);
    });
  }

  void _openComposer({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] as String? ?? '');
    final textCtrl = TextEditingController(text: existing?['text'] as String? ?? '');
    showModalBottomSheet(context: context, backgroundColor: _T.bg1(context), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 20, right: 20, top: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _SheetHandle(),
          Text(existing != null ? 'Edit Note' : 'Save a Note',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
          const SizedBox(height: 16),
          _NField('Title (optional)', titleCtrl, hint: 'Note title...'),
          const SizedBox(height: 12),
          TextField(controller: textCtrl, maxLines: 5, minLines: 3,
            style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write your note, link, or anything to save...',
              hintStyle: GoogleFonts.outfit(color: _T.tx2(context)),
              filled: true, fillColor: _T.input(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _T.bdr(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _T.bdr(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _accent)),
            )),
          const SizedBox(height: 16),
          _PrimaryBtn('Save', () async {
            final text = textCtrl.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context);
            if (existing != null) {
              await _ref('saved/${widget.uid}/${existing['id']}').update({'title': titleCtrl.text.trim(), 'text': text});
            } else {
              await _ref('saved/${widget.uid}').push().set({
                'title': titleCtrl.text.trim(), 'text': text,
                'ts': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }),
          const SizedBox(height: 8),
        ]),
      ));
  }

  Future<void> _delete(String id) async {
    await _ref('saved/${widget.uid}/$id').remove();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.bg0(context),
    body: SafeArea(child: Column(children: [
      _GlassAppBar(
        title: 'Saved',
        subtitle: '${_items.length} notes saved',
        actions: [
          GestureDetector(
            onTap: () => _openComposer(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(gradient: _primaryGrad, borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)]),
              child: Row(children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 4),
                Text('Note', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      Expanded(child: _items.isEmpty
        ? _EmptyState(icon: Icons.bookmark_border_rounded, title: 'No saved notes', sub: 'Tap + Note to save something for later')
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              final title = item['title'] as String? ?? '';
              final text = item['text'] as String? ?? '';
              final ts = item['ts'] as int? ?? 0;
              return Dismissible(
                key: Key(item['id'] as String),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: _danger, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white)),
                onDismissed: (_) => _delete(item['id'] as String),
                child: GestureDetector(
                  onTap: () => _openComposer(existing: item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _T.card(context), borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _T.bdr2(context)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.bookmark_rounded, color: _accentL, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(title.isNotEmpty ? title : 'Note', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: _T.tx0(context), fontSize: 14), overflow: TextOverflow.ellipsis)),
                        Text(_fmtTime(ts), style: GoogleFonts.outfit(fontSize: 11, color: _T.tx2(context))),
                      ]),
                      if (text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(text, style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        GestureDetector(
                          onTap: () { Clipboard.setData(ClipboardData(text: text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), backgroundColor: _accent, behavior: SnackBarBehavior.floating)); },
                          child: Row(children: [Icon(Icons.copy_outlined, size: 13, color: _T.tx2(context)), const SizedBox(width: 4), Text('Copy', style: GoogleFonts.outfit(fontSize: 11, color: _T.tx2(context)))]),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _openComposer(existing: item),
                          child: Row(children: [Icon(Icons.edit_outlined, size: 13, color: _T.tx2(context)), const SizedBox(width: 4), Text('Edit', style: GoogleFonts.outfit(fontSize: 11, color: _T.tx2(context)))]),
                        ),
                      ]),
                    ]),
                  ),
                ).animate().fadeIn(duration: 250.ms),
              );
            })),
    ])),
  );
}

// ─── FEED SCREEN ─────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> profile;
  const FeedScreen({super.key, required this.uid, required this.profile});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  StreamSubscription? _sub;

  @override
  void initState() { super.initState(); _listen(); }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _listen() {
    _sub = _ref('posts').orderByChild('ts').limitToLast(60).onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _posts = []); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final posts = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map); v['id'] = e.key; return v;
      }).toList()..sort((a, b) => ((b['ts'] ?? 0) as int).compareTo((a['ts'] ?? 0) as int));
      setState(() => _posts = posts);
    });
  }

  void _openPostCreator() => showModalBottomSheet(context: context, isScrollControlled: true,
    backgroundColor: _T.bg1(context),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => PostCreatorSheet(uid: widget.uid, profile: widget.profile));

  Future<void> _toggleLike(String postId, Map? likes) async {
    final likesMap = Map<String, dynamic>.from(likes ?? {});
    if (likesMap.containsKey(widget.uid)) {
      await _ref('posts/$postId/likes/${widget.uid}').remove();
    } else {
      await _ref('posts/$postId/likes/${widget.uid}').set(true);
    }
  }

  void _openComments(String postId) => showModalBottomSheet(context: context, isScrollControlled: true,
    backgroundColor: _T.bg1(context),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => CommentsSheet(postId: postId, uid: widget.uid, profile: widget.profile));

  Future<void> _deletePost(String postId) async {
    await _ref('posts/$postId').remove();
    await _ref('comments/$postId').remove();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted'), backgroundColor: _danger, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.bg0(context),
    body: SafeArea(child: Column(children: [
      _GlassAppBar(title: 'Feed', subtitle: "What's happening",
        actions: [
          GestureDetector(onTap: _openPostCreator,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(gradient: _primaryGrad, borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)]),
              child: Row(children: [const Icon(Icons.add_rounded, color: Colors.white, size: 15), const SizedBox(width: 4),
                Text('Post', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))]),
            )),
        ]),
      Expanded(child: _posts.isEmpty
        ? _EmptyState(icon: Icons.dynamic_feed_outlined, title: 'No posts yet', sub: 'Be the first to share something!')
        : ListView.builder(padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            itemCount: _posts.length,
            itemBuilder: (_, i) => _FeedCard(post: _posts[i], myUid: widget.uid,
              onLike: _toggleLike, onComment: () => _openComments(_posts[i]['id']), onDelete: _deletePost))),
    ])),
  );
}

class _FeedCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String myUid;
  final Function(String, Map?) onLike;
  final VoidCallback onComment;
  final Function(String)? onDelete;
  const _FeedCard({required this.post, required this.myUid, required this.onLike, required this.onComment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = post['authorName'] as String? ?? 'User';
    final username = post['authorUsername'] as String? ?? '';
    final caption = post['caption'] as String? ?? '';
    final imageUrl = post['imageUrl'] as String? ?? '';
    final ts = post['ts'] as int? ?? 0;
    final likes = post['likes'] as Map?;
    final liked = likes?.containsKey(myUid) ?? false;
    final likeCount = likes?.length ?? 0;
    final commentCount = post['commentCount'] as int? ?? 0;
    final views = post['views'] as int? ?? 0;
    final postId = post['id'] as String;
    final avatar = post['authorAvatar'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: _T.card(context), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.bdr2(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeerProfileScreen(uid: post['uid'] as String? ?? ''))),
            child: _AvatarWidget(name: name, avatar: avatar, size: 42)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: _T.tx0(context), fontSize: 14)),
            Text('@$username  ·  ${ts > 0 ? _fmtTime(ts) : ''}', style: GoogleFonts.outfit(fontSize: 11, color: _T.tx2(context))),
          ])),
          GestureDetector(
            onTap: () {
              if (post['uid'] != myUid) return;
              showModalBottomSheet(context: context, backgroundColor: _T.bg1(context),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                  _SheetHandle(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: _danger),
                    title: Text('Delete Post', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: _T.bg1(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Delete Post', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700)),
                          content: Text('Are you sure you want to delete this post?', style: GoogleFonts.outfit(color: _T.tx1(context))),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      );
                      if (confirmed == true) onDelete?.call(postId);
                    },
                  ),
                  const SizedBox(height: 8),
                ]));
            },
            child: Icon(Icons.more_horiz, color: post['uid'] == myUid ? _T.tx1(context) : _T.tx2(context))),
        ])),
        if (imageUrl.isNotEmpty)
          ClipRRect(child: imageUrl.startsWith('data:')
            ? Image.memory(base64Decode(imageUrl.split(',')[1]), width: double.infinity, fit: BoxFit.cover)
            : Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null ? child
                  : Container(height: 200, color: _T.bg2(context), child: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))))),
        if (caption.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(caption, style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14, height: 1.5))),
        Padding(padding: const EdgeInsets.fromLTRB(6, 4, 14, 12), child: Row(children: [
          IconButton(icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? _accentPink : _T.tx1(context), size: 22),
            onPressed: () => onLike(postId, likes), padding: const EdgeInsets.all(6), constraints: const BoxConstraints()),
          Text('$likeCount', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13)),
          const SizedBox(width: 12),
          IconButton(icon: Icon(Icons.chat_bubble_outline_rounded, color: _T.tx1(context), size: 20),
            onPressed: onComment, padding: const EdgeInsets.all(6), constraints: const BoxConstraints()),
          Text('$commentCount', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13)),
          const Spacer(),
          Icon(Icons.visibility_outlined, color: _T.tx2(context), size: 13),
          const SizedBox(width: 4),
          Text('$views', style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 11)),
        ])),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── POST CREATOR ────────────────────────────────────────────
class PostCreatorSheet extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> profile;
  const PostCreatorSheet({super.key, required this.uid, required this.profile});
  @override
  State<PostCreatorSheet> createState() => _PostCreatorSheetState();
}

class _PostCreatorSheetState extends State<PostCreatorSheet> {
  final _captionCtrl = TextEditingController();
  Uint8List? _imgBytes;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 80);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() => _imgBytes = bytes);
  }

  Future<void> _submit() async {
    final caption = _captionCtrl.text.trim();
    if (_imgBytes == null && caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a photo or write something'), backgroundColor: _danger));
      return;
    }
    setState(() => _uploading = true);
    try {
      String imageUrl = '';
      if (_imgBytes != null) {
        final uri = Uri.parse('$_cloudinaryBase/image/upload');
        final req = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(http.MultipartFile.fromBytes('file', _imgBytes!, filename: 'post.jpg'));
        final res = await req.send();
        final body = jsonDecode(await res.stream.bytesToString());
        imageUrl = body['secure_url'] as String? ?? '';
      }
      final postRef = _ref('posts').push();
      await postRef.set({
        'uid': widget.uid, 'authorName': widget.profile['name'] ?? 'User',
        'authorAvatar': widget.profile['avatar'] ?? '', 'authorUsername': widget.profile['username'] ?? '',
        'imageUrl': imageUrl, 'caption': caption,
        'ts': DateTime.now().millisecondsSinceEpoch, 'likes': {}, 'views': 0, 'commentCount': 0,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post shared! 🎉'), backgroundColor: _accent, behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: _danger));
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SheetHandle(),
        Text('Create Post', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
        const SizedBox(height: 16),
        GestureDetector(onTap: _pickImage,
          child: Container(height: 200,
            decoration: BoxDecoration(color: _T.bg2(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: _T.bdr(context))),
            child: _imgBytes != null
              ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_imgBytes!, fit: BoxFit.cover, width: double.infinity))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: _accentL, size: 48),
                  const SizedBox(height: 8),
                  Text('Tap to add photo', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 14)),
                ]))),
        const SizedBox(height: 14),
        TextField(controller: _captionCtrl, style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14),
          maxLines: 4, minLines: 2,
          decoration: InputDecoration(hintText: 'Write a caption...', hintStyle: GoogleFonts.outfit(color: _T.tx2(context)),
            filled: true, fillColor: _T.input(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _T.bdr(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _T.bdr(context))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _accent)))),
        const SizedBox(height: 16),
        _PrimaryBtn(_uploading ? 'Sharing...' : 'Share Post', _uploading ? null : _submit),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]))));
}

// ─── COMMENTS SHEET ──────────────────────────────────────────
class CommentsSheet extends StatefulWidget {
  final String postId, uid;
  final Map<String, dynamic> profile;
  const CommentsSheet({super.key, required this.postId, required this.uid, required this.profile});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  List<Map<String, dynamic>> _comments = [];
  final _ctrl = TextEditingController();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _ref('comments/${widget.postId}').onValue.listen((e) {
      if (!e.snapshot.exists) { setState(() => _comments = []); return; }
      final data = Map<String, dynamic>.from(e.snapshot.value as Map);
      final list = data.entries.map((en) {
        final v = Map<String, dynamic>.from(en.value as Map); v['id'] = en.key; return v;
      }).toList()..sort((a, b) => ((a['ts'] ?? 0) as int).compareTo((b['ts'] ?? 0) as int));
      setState(() => _comments = list);
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _postComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final cRef = _ref('comments/${widget.postId}').push();
    await cRef.set({'uid': widget.uid, 'name': widget.profile['name'] ?? 'User',
      'avatar': widget.profile['avatar'] ?? '', 'text': text, 'ts': DateTime.now().millisecondsSinceEpoch});
    final postSnap = await _ref('posts/${widget.postId}/commentCount').get();
    await _ref('posts/${widget.postId}').update({'commentCount': ((postSnap.value as int?) ?? 0) + 1});
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(initialChildSize: 0.7,
    builder: (_, ctrl) => Column(children: [
      _SheetHandle(),
      Text('Comments', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _comments.length,
        itemBuilder: (_, i) {
          final c = _comments[i];
          return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AvatarWidget(name: c['name'] as String? ?? '', avatar: c['avatar'] as String? ?? '', size: 34),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['name'] ?? 'User', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: _T.tx0(context), fontSize: 13)),
              const SizedBox(height: 2),
              Text(c['text'] ?? '', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13)),
            ])),
          ]));
        })),
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl, style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14),
            decoration: InputDecoration(hintText: 'Add a comment...', hintStyle: GoogleFonts.outfit(color: _T.tx2(context)),
              filled: true, fillColor: _T.input(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide(color: _T.bdr(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide(color: _T.bdr(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: _accent)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            onSubmitted: (_) => _postComment())),
          const SizedBox(width: 8),
          GestureDetector(onTap: _postComment,
            child: Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _primaryGrad),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
        ])),
    ]));
}

// ─── AI SCREEN ───────────────────────────────────────────────
class AIScreen extends StatefulWidget {
  final String uid;
  final String? initialQuery;
  const AIScreen({super.key, required this.uid, this.initialQuery});
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final List<Map<String, String>> _history = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _thinking = false;

  final _suggestions = [
    '⚛️ Explain quantum computing simply',
    '✨ Write a short poem about stars',
    '🐛 Help me debug my code',
    '🌍 Latest trends in AI?',
    '💡 Give me a creative business idea',
    '🤖 What can you do?',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialQuery));
    }
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _thinking) return;
    _inputCtrl.clear();
    setState(() { _history.add({'role': 'user', 'content': text}); _thinking = true; });
    _scrollToBottom();
    try {
      final messages = [
        {'role': 'system', 'content': _aiSystemPrompt},
        ..._history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      ];
      final res = await http.post(Uri.parse(_groqEndpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_groqKey'},
        body: jsonEncode({'model': _groqModel, 'messages': messages, 'max_tokens': 1024, 'temperature': 0.7}));
      if (res.statusCode != 200) throw Exception('API Error ${res.statusCode}');
      final data = jsonDecode(res.body);
      final aiText = data['choices']?[0]?['message']?['content'] as String? ?? 'No response.';
      setState(() { _history.add({'role': 'assistant', 'content': aiText}); });
    } catch (e) {
      setState(() { _history.add({'role': 'assistant', 'content': '⚠️ Unable to connect. Please try again.'}); });
    }
    setState(() => _thinking = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.bg0(context),
    body: SafeArea(child: Column(children: [
      _GlassAppBar(
        title: 'Kira AI',
        subtitle: _thinking ? '⏳ Thinking...' : '● Kira AI Dark 3.3 · Ready',
        subtitleColor: _thinking ? _accentPink : _accentTeal,
        showBack: true,
        actions: [
          if (_history.isNotEmpty)
            _IconBtn(Icons.delete_outline_rounded, () => setState(() => _history.clear())),
        ],
      ),
      Expanded(child: _history.isEmpty
        ? _AIWelcome(suggestions: _suggestions, onSuggest: _send)
        : ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(14),
            itemCount: _history.length + (_thinking ? 1 : 0),
            itemBuilder: (_, i) {
              if (_thinking && i == _history.length) return const _AITypingDots();
              return _AIBubble(role: _history[i]['role']!, text: _history[i]['content']!);
            })),
      Container(
        padding: EdgeInsets.only(left: 12, right: 12, top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: _T.bg1(context), border: Border(top: BorderSide(color: _T.bdr2(context)))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: _T.input(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: _T.bdr(context))),
              child: TextField(controller: _inputCtrl, style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14),
                maxLines: 4, minLines: 1,
                decoration: InputDecoration(hintText: 'Ask Kira AI anything...', hintStyle: GoogleFonts.outfit(color: _T.tx2(context)),
                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                onSubmitted: (_) => _send()),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(onTap: _thinking ? null : _send,
            child: AnimatedContainer(duration: 200.ms, width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: _thinking ? [_dTx2, _dTx2] : [_accent, _accentPink], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: _thinking ? null : [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)]),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
        ]),
      ),
    ])),
  );
}

class _AIWelcome extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggest;
  const _AIWelcome({required this.suggestions, required this.onSuggest});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(gradient: _primaryGrad, borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 40)]),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 38)),
      const SizedBox(height: 16),
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: [Colors.white, _accentL, _accentPink]).createShader(b),
        child: Text('Kira AI', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
      const SizedBox(height: 4),
      Text('Powered by Kira AI Dark 3.3', style: GoogleFonts.outfit(color: _accentL, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Your intelligent AI companion. Ask me anything!',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13, height: 1.6)),
      const SizedBox(height: 20),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
        children: suggestions.map((s) => GestureDetector(
          onTap: () => onSuggest(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: _T.bg2(context), borderRadius: BorderRadius.circular(50), border: Border.all(color: _T.bdr(context))),
            child: Text(s, style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 12, fontWeight: FontWeight.w600))),
        )).toList()),
    ])),
  );
}

class _AIBubble extends StatelessWidget {
  final String role, text;
  const _AIBubble({required this.role, required this.text});

  @override
  Widget build(BuildContext context) {
    final isAI = role == 'assistant';
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          if (isAI) ...[
            Container(width: 30, height: 30,
              decoration: BoxDecoration(gradient: _primaryGrad, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14)),
            const SizedBox(width: 8),
          ],
          Flexible(child: ValueListenableBuilder<String>(
            valueListenable: _chatThemeNotifier,
            builder: (context, themeName, _) {
              final userGrad = isAI ? null : LinearGradient(
                colors: _chatThemes[themeName] ?? [const Color(0xFF7367F0), const Color(0xFF9B2FFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: userGrad,
                  color: isAI ? _T.inBubble(context) : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isAI ? 4 : 18),
                    bottomRight: Radius.circular(isAI ? 18 : 4)),
                  border: isAI ? Border.all(color: _T.bdr2(context)) : null),
                child: SelectableText(text, style: GoogleFonts.outfit(color: isAI ? _T.tx0(context) : Colors.white, fontSize: 14, height: 1.55)),
              );},
          )),
        ]),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04),
    );
  }
}

class _AITypingDots extends StatelessWidget {
  const _AITypingDots();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _T.inBubble(context),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
        border: Border.all(color: _T.bdr2(context))),
      child: Row(mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(shape: BoxShape.circle, color: _T.tx1(context)))
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(end: 1.5, duration: 400.ms, delay: Duration(milliseconds: i * 150))
          .then().scaleXY(end: 1.0, duration: 400.ms))),
    ),
  );
}

// ─── PROFILE SCREEN ──────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> profile;
  final Function(Map<String, dynamic>) onProfileUpdated;
  final VoidCallback onLogout;
  final Map<String, bool> verifiedCache;
  final Function(bool) onVerifiedChanged;
  const ProfileScreen({super.key, required this.uid, required this.profile,
    required this.onProfileUpdated, required this.onLogout,
    required this.verifiedCache, required this.onVerifiedChanged});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _verified = false;
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _verified = widget.verifiedCache[widget.uid] ?? false;
    _listenNotifs();
  }

  @override
  void dispose() { _notifSub?.cancel(); super.dispose(); }

  void _listenNotifs() {
    _notifSub = _ref('notifications/${widget.uid}').orderByChild('ts').limitToLast(50).onValue.listen((event) {
      if (!event.snapshot.exists) { setState(() => _notifications = []); return; }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final list = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map); v['id'] = e.key; return v;
      }).toList()..sort((a, b) => ((b['ts'] ?? 0) as int).compareTo((a['ts'] ?? 0) as int));
      setState(() => _notifications = list);
    });
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: error ? _danger : _accent,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))));
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: widget.profile['name'] as String? ?? '');
    final usernameCtrl = TextEditingController(text: widget.profile['username'] as String? ?? '');
    final bioCtrl = TextEditingController(text: widget.profile['bio'] as String? ?? '');
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _T.bg1(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Edit Profile', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _NField('Display Name', nameCtrl, hint: 'Your name'),
        const SizedBox(height: 12),
        _NField('Username', usernameCtrl, hint: '@username'),
        const SizedBox(height: 12),
        _NField('Bio', bioCtrl, hint: 'Tell us about you'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
        TextButton(onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          await _ref('users/${widget.uid}').update({'name': name, 'username': usernameCtrl.text.trim(), 'bio': bioCtrl.text.trim()});
          final updated = {...widget.profile, 'name': name, 'username': usernameCtrl.text.trim(), 'bio': bioCtrl.text.trim()};
          await _profileBox.put('profile_${widget.uid}', jsonEncode(updated));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ng_profile', jsonEncode(updated));
          widget.onProfileUpdated(updated);
          if (!mounted) return;
          Navigator.pop(context);
          _toast('Profile updated ✓');
        }, child: Text('Save', style: GoogleFonts.outfit(color: _accentL, fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Future<void> _changeAvatar() async {
    final action = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      backgroundColor: _T.bg1(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Profile Photo', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined, color: _accent), title: Text('Choose from gallery', style: GoogleFonts.outfit(color: _T.tx0(context))), onTap: () => Navigator.pop(context, 'pick')),
        if ((widget.profile['avatar'] as String? ?? '').isNotEmpty)
          ListTile(leading: const Icon(Icons.delete_outline_rounded, color: _danger), title: Text('Delete photo', style: GoogleFonts.outfit(color: _danger)), onTap: () => Navigator.pop(context, 'delete')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context))))],
    ));
    if (action == null) return;
    if (action == 'delete') {
      await _ref('users/${widget.uid}').update({'avatar': ''});
      final updated = {...widget.profile, 'avatar': ''};
      await _profileBox.put('profile_${widget.uid}', jsonEncode(updated));
      widget.onProfileUpdated(updated);
      _toast('Profile photo removed');
      return;
    }
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (xfile == null) return;
    _toast('Updating photo...');
    final bytes = await xfile.readAsBytes();
    try {
      final uri = Uri.parse('$_cloudinaryBase/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'avatar.jpg'));
      final res = await req.send();
      final body = jsonDecode(await res.stream.bytesToString());
      final url = body['secure_url'] as String? ?? 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _ref('users/${widget.uid}').update({'avatar': url});
      final updated = {...widget.profile, 'avatar': url};
      await _profileBox.put('profile_${widget.uid}', jsonEncode(updated));
      widget.onProfileUpdated(updated);
      _toast('Profile photo updated ✓');
    } catch (_) {
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _ref('users/${widget.uid}').update({'avatar': b64});
      final updated = {...widget.profile, 'avatar': b64};
      widget.onProfileUpdated(updated);
      _toast('Profile photo updated ✓');
    }
  }

  Future<void> _verifyAccount() async {
    if (_verified) { _toast('Already verified ✓'); return; }
    await showDialog(context: context, builder: (_) => PinDialog(
      mode: PinMode.verify, chatId: null, chatName: 'Verify Account',
      onVerify: (pin) async {
        if (pin == _adminPin) {
          await _ref('users/${widget.uid}').update({'isVerified': true, 'verified': true});
          setState(() => _verified = true);
          widget.onVerifiedChanged(true);
          _toast('Account verified ✓');
        } else {
          _toast('Invalid PIN', error: true);
        }
      },
    ));
  }

  void _showThemeMenu() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _T.bg1(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Appearance', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _ThemeOption(label: 'Dark Mode', icon: Icons.dark_mode_rounded, active: _themeNotifier.value == ThemeMode.dark, onTap: () { _themeNotifier.value = ThemeMode.dark; Navigator.pop(context); }),
        const SizedBox(height: 8),
        _ThemeOption(label: 'Light Mode', icon: Icons.light_mode_rounded, active: _themeNotifier.value == ThemeMode.light, onTap: () { _themeNotifier.value = ThemeMode.light; Navigator.pop(context); }),
        const SizedBox(height: 8),
        _ThemeOption(label: 'System Default', icon: Icons.brightness_auto_rounded, active: _themeNotifier.value == ThemeMode.system, onTap: () { _themeNotifier.value = ThemeMode.system; Navigator.pop(context); }),
      ]),
    ));
  }

  void _showNotificationPanel() {
    showModalBottomSheet(context: context, backgroundColor: _T.bg1(context), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NotificationPanel(uid: widget.uid, notifications: _notifications));
  }

  void _managePasscode() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AppPasscodeScreen(uid: widget.uid, isSetup: true)));
  }

  void _showChatThemeMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _T.bg1(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _ChatThemeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile['name'] as String? ?? 'User';
    final username = widget.profile['username'] as String? ?? '';
    final bio = widget.profile['bio'] as String? ?? '';
    final avatar = widget.profile['avatar'] as String? ?? '';
    final unreadNotifs = _notifications.where((n) => n['read'] != true).length;

    return Scaffold(
      backgroundColor: _T.bg0(context),
      body: SafeArea(child: SingleChildScrollView(
        child: Column(children: [
          Container(height: 130, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_avatarColor(name), _avatarColor(name).withOpacity(0.5)])),
            child: Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(14),
              child: GestureDetector(
                onTap: _showNotificationPanel,
                child: Stack(children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20)),
                  if (unreadNotifs > 0)
                    Positioned(right: 0, top: 0, child: Container(
                      width: 14, height: 14, decoration: const BoxDecoration(color: _accentPink, shape: BoxShape.circle),
                      child: Center(child: Text('$unreadNotifs', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white))),
                    )),
                ]),
              )))),
          Transform.translate(offset: const Offset(0, -44), child: Center(child: Stack(children: [
            Container(width: 88, height: 88,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [_accent, _accentPink]),
                border: Border.all(color: _T.bg0(context), width: 4)),
              child: ClipOval(child: avatar.isNotEmpty
                ? (avatar.startsWith('http') ? Image.network(avatar, fit: BoxFit.cover) : Image.memory(base64Decode(avatar.split(',')[1]), fit: BoxFit.cover))
                : Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white))))),
            // Camera button — change photo
            Positioned(right: 0, bottom: 0, child: GestureDetector(onTap: _changeAvatar,
              child: Container(width: 26, height: 26, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _primaryGrad),
                child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white)))),
            // Delete button — only when photo exists
            if (avatar.isNotEmpty)
              Positioned(left: 0, bottom: 0, child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                    backgroundColor: _T.bg1(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('Remove Photo', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700)),
                    content: Text('Are you sure you want to remove your profile photo?', style: GoogleFonts.outfit(color: _T.tx1(context))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Remove', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w700))),
                    ],
                  ));
                  if (confirm != true) return;
                  await _ref('users/${widget.uid}').update({'avatar': ''});
                  final updated = {...widget.profile, 'avatar': ''};
                  await _profileBox.put('profile_${widget.uid}', jsonEncode(updated));
                  widget.onProfileUpdated(updated);
                  _toast('Profile photo removed');
                },
                child: Container(width: 26, height: 26,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _danger,
                    border: Border.all(color: _T.bg0(context), width: 2)),
                  child: const Icon(Icons.close_rounded, size: 13, color: Colors.white)))),
          ]))),
          Transform.translate(offset: const Offset(0, -28), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: _T.tx0(context))),
              if (_verified) ...[const SizedBox(width: 6), const _VerifiedBadge(size: 20)],
            ]),
            const SizedBox(height: 3),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: '@$username'));
                _toast('@$username copied!');
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('@$username', style: GoogleFonts.spaceGrotesk(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.copy_outlined, size: 12, color: _accent),
              ]),
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(bio, style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13, height: 1.5), textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
              _SetSection('Account'),
              _SetItem(icon: Icons.person_outline_rounded, iconGrad: const [Color(0xFF7367F0), Color(0xFF9B2FFF)], label: 'Edit Profile', sub: 'Name, username, bio', onTap: _editProfile),
              _SetItem(icon: Icons.photo_camera_outlined, iconGrad: const [Color(0xFFFF3D8F), Color(0xFFFF6B6B)], label: 'Profile Photo', sub: 'Update or remove your picture', onTap: _changeAvatar),
              _SetSection('Notifications'),
              _SetItem(icon: Icons.notifications_outlined, iconGrad: const [Color(0xFF4CAF50), Color(0xFF388E3C)],
                label: 'Notifications', sub: unreadNotifs > 0 ? '$unreadNotifs unread notifications' : 'No new notifications', onTap: _showNotificationPanel),
              _SetSection('Security'),
              _SetItem(icon: Icons.verified_outlined, iconGrad: const [Color(0xFF00BCD4), Color(0xFF0097A7)], label: 'Verify Account', sub: _verified ? '✓ Account is verified' : 'Get your verified badge', onTap: _verifyAccount),
              _SetItem(icon: Icons.lock_outlined, iconGrad: const [Color(0xFF7367F0), Color(0xFF4527A0)], label: 'App Passcode', sub: 'Lock app with a PIN', onTap: _managePasscode),
              _SetSection('Preferences'),
              _SetItem(icon: Icons.palette_outlined, iconGrad: const [Color(0xFFFF9800), Color(0xFFFF5722)], label: 'Appearance', sub: 'Toggle dark / light theme', onTap: _showThemeMenu),
              _SetItem(icon: Icons.chat_bubble_outline_rounded, iconGrad: const [Color(0xFF7367F0), Color(0xFFFF3D8F)], label: 'Chat Theme', sub: 'Customize your bubble color', onTap: _showChatThemeMenu),
              _SetSection('Danger Zone'),
              _SetItem(icon: Icons.logout_rounded, iconGrad: const [Color(0xFFFF3D5A), Color(0xFFC62828)], label: 'Sign Out', sub: 'Log out of your account', onTap: widget.onLogout, danger: true),
            ])),
            const SizedBox(height: 24),
          ])),
        ]),
      )),
    );
  }
}

// ─── NOTIFICATION PANEL (NEW) ─────────────────────────────────
class _NotificationPanel extends StatelessWidget {
  final String uid;
  final List<Map<String, dynamic>> notifications;
  const _NotificationPanel({required this.uid, required this.notifications});

  Future<void> _markAllRead() async {
    for (final n in notifications) {
      if (n['read'] != true) {
        await _ref('notifications/$uid/${n['id']}').update({'read': true});
      }
    }
  }

  Future<void> _clearAll() async {
    await _ref('notifications/$uid').remove();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.4,
      builder: (_, ctrl) => Column(children: [
        _SheetHandle(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [
          Text('🔔 Notifications', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
          const Spacer(),
          TextButton(onPressed: _markAllRead, child: Text('Mark all read', style: GoogleFonts.outfit(color: _accentL, fontSize: 12, fontWeight: FontWeight.w600))),
          TextButton(onPressed: _clearAll, child: Text('Clear', style: GoogleFonts.outfit(color: _danger, fontSize: 12, fontWeight: FontWeight.w600))),
        ])),
        const Divider(height: 1),
        Expanded(
          child: notifications.isEmpty
            ? _EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications', sub: 'When someone messages you, it\'ll show up here')
            : ListView.builder(controller: ctrl, itemCount: notifications.length,
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  final isRead = n['read'] == true;
                  final ts = n['ts'] as int? ?? 0;
                  return GestureDetector(
                    onTap: () async {
                      await _ref('notifications/$uid/${n['id']}').update({'read': true});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.transparent : _accent.withOpacity(0.06),
                        border: Border(
                          left: isRead ? BorderSide.none : const BorderSide(color: _accent, width: 3),
                          bottom: BorderSide(color: _dBdr2),
                        ),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _AvatarWidget(name: n['senderName'] as String? ?? 'User', avatar: n['senderAvatar'] as String? ?? '', size: 44),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(n['senderName'] as String? ?? 'User',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: _T.tx0(context), fontSize: 13))),
                            Text(ts > 0 ? _fmtTime(ts) : '', style: GoogleFonts.outfit(fontSize: 10, color: _T.tx2(context))),
                          ]),
                          const SizedBox(height: 2),
                          Text(n['text'] as String? ?? '', style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ])),
                        if (!isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 8, top: 4), decoration: const BoxDecoration(shape: BoxShape.circle, color: _accentPink)),
                      ]),
                    ),
                  );
                }),
        ),
      ]),
    );
  }
}

// ─── CHAT THEME SHEET ────────────────────────────────────────
class _ChatThemeSheet extends StatefulWidget {
  const _ChatThemeSheet();
  @override
  State<_ChatThemeSheet> createState() => _ChatThemeSheetState();
}

class _ChatThemeSheetState extends State<_ChatThemeSheet> {
  String _selected = _chatThemeNotifier.value;

  static const _themeIcons = {
    'Violet':   Icons.electric_bolt_rounded,
    'Rose':     Icons.favorite_rounded,
    'Ocean':    Icons.waves_rounded,
    'Forest':   Icons.forest_rounded,
    'Sunset':   Icons.wb_sunny_rounded,
    'Crimson':  Icons.local_fire_department_rounded,
    'Midnight': Icons.nights_stay_rounded,
    'Teal':     Icons.spa_rounded,
    'Sakura':   Icons.local_florist_rounded,
    'Slate':    Icons.layers_rounded,
    'Amber':    Icons.star_rounded,
    'Lime':     Icons.eco_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7367F0), Color(0xFFFF3D8F)]), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Chat Theme', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
              Text('Choose your message bubble color', style: GoogleFonts.outfit(fontSize: 12, color: _T.tx2(context))),
            ])),
          ]),
        ),
        // Preview bubble
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.bg2(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _T.bdr2(context)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _chatThemes[_selected]!,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18), topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
                    boxShadow: [BoxShadow(color: _chatThemes[_selected]!.first.withOpacity(0.3), blurRadius: 12)],
                  ),
                  child: Text('Hey! This is your chat bubble 👋', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _T.inBubble(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18), topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
                    border: Border.all(color: _T.bdr2(context)),
                  ),
                  child: Text('Looks great! 😍', style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 13)),
                ),
              ]),
            ]),
          ),
        ),
        // Color grid
        Flexible(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4),
            itemCount: _chatThemes.length,
            itemBuilder: (_, i) {
              final name = _chatThemes.keys.elementAt(i);
              final colors = _chatThemes[name]!;
              final active = _selected == name;
              final icon = _themeIcons[name] ?? Icons.circle;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected = name);
                  _chatThemeNotifier.value = name;
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? Colors.white : Colors.transparent, width: 2.5),
                    boxShadow: active ? [BoxShadow(color: colors.first.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4))] : null,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, color: Colors.white.withOpacity(0.9), size: 14),
                    const SizedBox(width: 6),
                    Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
                      shadows: [const Shadow(color: Colors.black26, blurRadius: 4)])),
                    if (active) ...[const SizedBox(width: 4), const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14)],
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── PEER PROFILE SCREEN ─────────────────────────────────────
class PeerProfileScreen extends StatefulWidget {
  final String uid;
  const PeerProfileScreen({super.key, required this.uid});
  @override
  State<PeerProfileScreen> createState() => _PeerProfileScreenState();
}

class _PeerProfileScreenState extends State<PeerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isBlocked = false;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _loadMyUid().then((_) { _load(); _checkBlocked(); });
  }

  Future<void> _loadMyUid() async {
    final prefs = await SharedPreferences.getInstance();
    _myUid = prefs.getString('ng_uid');
  }

  Future<void> _load() async {
    final snap = await _ref('users/${widget.uid}').get();
    if (snap.exists) setState(() => _profile = Map<String, dynamic>.from(snap.value as Map));
  }

  Future<void> _checkBlocked() async {
    if (_myUid == null) return;
    final snap = await _ref('blocks/\$_myUid/${widget.uid}').get();
    if (mounted) setState(() => _isBlocked = snap.exists);
  }

  Future<void> _toggleBlock() async {
    if (_myUid == null) return;
    if (_isBlocked) {
      await _ref('blocks/\$_myUid/${widget.uid}').remove();
      setState(() => _isBlocked = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unblocked'), backgroundColor: _accent, behavior: SnackBarBehavior.floating));
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _T.bg1(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Block User', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700)),
          content: Text('Block \${_profile?["name"] ?? "this user"}? They won\'t be able to message you.', style: GoogleFonts.outfit(color: _T.tx1(context))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Block', style: GoogleFonts.outfit(color: _danger, fontWeight: FontWeight.w700))),
          ],
        ),
      );
      if (confirmed != true) return;
      await _ref('blocks/\$_myUid/${widget.uid}').set({'blockedAt': DateTime.now().millisecondsSinceEpoch, 'name': _profile?['name'] ?? ''});
      setState(() => _isBlocked = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked'), backgroundColor: _danger, behavior: SnackBarBehavior.floating));
    }
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length < 2) return email;
    final local = parts[0];
    final masked = local.length > 3 ? '${local.substring(0, 2)}***' : '***';
    return '$masked@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return Scaffold(backgroundColor: _T.bg0(context), body: const Center(child: CircularProgressIndicator(color: _accent)));
    final name = _profile!['name'] as String? ?? 'User';
    final username = _profile!['username'] as String? ?? '';
    final bio = _profile!['bio'] as String? ?? '';
    final email = _profile!['email'] as String? ?? '';
    final avatar = _profile!['avatar'] as String? ?? '';
    final online = _profile!['online'] == true;
    final lastSeen = _profile!['lastSeen'] as int?;
    final verified = _profile!['isVerified'] == true;

    return Scaffold(
      backgroundColor: _T.bg0(context),
      appBar: AppBar(backgroundColor: _T.bg1(context), elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: _T.tx0(context), size: 18), onPressed: () => Navigator.pop(context)),
        title: Text('Profile', style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(child: Column(children: [
        Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: [_avatarColor(name), _avatarColor(name).withOpacity(0.6)]))),
        Transform.translate(offset: const Offset(0, -40), child: Center(child: Stack(children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [_accent, _accentPink]), border: Border.all(color: _T.bg0(context), width: 4)),
            child: ClipOval(child: avatar.isNotEmpty
              ? (avatar.startsWith('http') ? Image.network(avatar, fit: BoxFit.cover) : Image.memory(base64Decode(avatar.split(',')[1]), fit: BoxFit.cover))
              : Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white))))),
          if (online) Positioned(right: 2, bottom: 2,
            child: Container(width: 16, height: 16, decoration: BoxDecoration(color: _online, shape: BoxShape.circle, border: Border.all(color: _T.bg0(context), width: 2)))),
        ]))),
        Transform.translate(offset: const Offset(0, -28), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: _T.tx0(context))),
            if (verified) ...[const SizedBox(width: 6), const _VerifiedBadge(size: 20)],
          ]),
          const SizedBox(height: 3),
          // Copy username button (NEW)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: '@$username'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('@username copied!'), backgroundColor: _accent, behavior: SnackBarBehavior.floating));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: _T.bdr(context)), borderRadius: BorderRadius.circular(50)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('@$username', style: GoogleFonts.spaceGrotesk(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Icon(Icons.copy_outlined, size: 12, color: _T.tx2(context)),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          Text(online ? '● Online' : _fmtLastSeen(lastSeen), style: GoogleFonts.outfit(fontSize: 12, color: online ? _online : _T.tx1(context))),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(bio, style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 13, height: 1.5), textAlign: TextAlign.center)),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_maskEmail(email), style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 12)),
          ],
          const SizedBox(height: 20),
          if (_myUid != null && _myUid != widget.uid)
            GestureDetector(
              onTap: _toggleBlock,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _isBlocked ? _danger.withOpacity(0.12) : _T.bg2(context),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _isBlocked ? _danger : _T.bdr(context)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
                    color: _isBlocked ? _danger : _T.tx1(context), size: 16),
                  const SizedBox(width: 8),
                  Text(_isBlocked ? 'Unblock User' : 'Block User',
                    style: GoogleFonts.outfit(color: _isBlocked ? _danger : _T.tx1(context), fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ])),
      ])),
    );
  }
}

// ─── PIN DIALOG ──────────────────────────────────────────────
enum PinMode { unlock, set, verify }

class PinDialog extends StatefulWidget {
  final PinMode mode;
  final String? chatId;
  final String chatName;
  final Function(String)? onVerify;
  const PinDialog({super.key, required this.mode, required this.chatId, required this.chatName, this.onVerify});
  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _buffer = '';
  bool _error = false;
  bool _processing = false;

  Future<void> _press(String key) async {
    if (_processing) return;
    if (key == 'del') { setState(() => _buffer = _buffer.isEmpty ? '' : _buffer.substring(0, _buffer.length - 1)); return; }
    if (_buffer.length >= 4) return;
    setState(() { _buffer += key; _error = false; });
    if (_buffer.length == 4) await _submit();
  }

  Future<void> _submit() async {
    setState(() => _processing = true);
    final pin = _buffer;
    try {
      if (widget.mode == PinMode.unlock && widget.chatId != null) {
        final snap = await _ref('chatLocks/${widget.chatId}/pin').get();
        final stored = snap.value as String?;
        if (stored != null && _sha256(pin) == stored) { if (!mounted) return; Navigator.pop(context, true); return; }
        await _shake();
      } else if (widget.mode == PinMode.set && widget.chatId != null) {
        await _ref('chatLocks/${widget.chatId}').set({'pin': _sha256(pin), 'chatName': widget.chatName, 'setAt': DateTime.now().millisecondsSinceEpoch});
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      } else if (widget.mode == PinMode.verify) {
        widget.onVerify?.call(pin);
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }
    } catch (_) { await _shake(); }
    setState(() => _processing = false);
  }

  Future<void> _shake() async {
    setState(() => _error = true);
    await Future.delayed(600.ms);
    if (mounted) setState(() { _buffer = ''; _error = false; });
  }

  @override
  Widget build(BuildContext context) {
    final titles = {PinMode.unlock: '🔒 Locked Chat', PinMode.set: '🔑 Set PIN', PinMode.verify: '🛡️ Verify Account'};
    final subs = {PinMode.unlock: 'Enter PIN to open "${widget.chatName}"', PinMode.set: 'Enter a new 4-digit PIN', PinMode.verify: 'Enter the admin verification PIN'};
    return Dialog(
      backgroundColor: _T.bg1(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(titles[widget.mode]!, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _T.tx0(context))),
        const SizedBox(height: 6),
        Text(subs[widget.mode]!, style: GoogleFonts.outfit(fontSize: 13, color: _T.tx1(context)), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
          final filled = i < _buffer.length;
          return AnimatedContainer(duration: 150.ms, width: 18, height: 18, margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: _error ? _danger : (filled ? _accent : Colors.transparent),
              border: Border.all(color: _error ? _danger : (filled ? _accent : _T.tx2(context)), width: 2)));
        })),
        const SizedBox(height: 28),
        for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','del']])
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row.map((k) => GestureDetector(
            onTap: k.isEmpty ? null : () => _press(k),
            child: Container(width: 70, height: 56, alignment: Alignment.center, margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(color: k.isEmpty ? Colors.transparent : _T.bg3(context), borderRadius: BorderRadius.circular(14)),
              child: k == 'del' ? Icon(Icons.backspace_outlined, color: _T.tx1(context), size: 20)
                : Text(k, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: _T.tx0(context)))),
          )).toList()),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.outfit(color: _T.tx1(context)))),
      ])),
    );
  }
}

// ─── SHARED WIDGETS ──────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color.withOpacity(0.35), shape: BoxShape.circle),
    child: ClipOval(child: Container(decoration: BoxDecoration(
      gradient: RadialGradient(colors: [color.withOpacity(0.5), color.withOpacity(0)])))),
  ).animate(onPlay: (c) => c.repeat(reverse: true))
    .moveX(end: 30, duration: 8.seconds, curve: Curves.easeInOut)
    .moveY(end: 20, duration: 10.seconds, curve: Curves.easeInOut);
}

class _GlassAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final List<Widget> actions;
  final bool showBack;
  const _GlassAppBar({required this.title, this.subtitle, this.subtitleColor, this.actions = const [], this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final isDark = _T.isDark(context);
    final canPop = Navigator.canPop(context);
    return Container(
      padding: EdgeInsets.fromLTRB(showBack && canPop ? 4 : 16, 12, 16, 12),
      decoration: BoxDecoration(color: _T.bg1(context).withOpacity(0.9), border: Border(bottom: BorderSide(color: _T.bdr2(context)))),
      child: Row(children: [
        if (showBack && canPop)
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: _T.tx0(context), size: 18),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(8),
          ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          isDark
            ? ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [Colors.white, _accentL]).createShader(b),
                child: Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)))
            : ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [_accent, _accentPink]).createShader(b),
                child: Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
          if (subtitle != null)
            Text(subtitle!, style: GoogleFonts.outfit(fontSize: 11, color: subtitleColor ?? _T.tx2(context))),
        ])),
        ...actions,
      ]),
    );
  }
}


class _SegBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SegBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(duration: 220.ms,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: active ? _accent : Colors.transparent, borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 16)] : null),
        child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : _T.tx1(context)))),
    ),
  );
}

class _NField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final TextInputType keyboard;
  final Widget? suffix;
  const _NField(this.label, this.ctrl, {this.hint = '', this.obscure = false, this.keyboard = TextInputType.text, this.suffix});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: _T.tx1(context), letterSpacing: 0.8)),
    const SizedBox(height: 5),
    TextField(controller: ctrl, obscureText: obscure, keyboardType: keyboard,
      style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 15),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(color: _T.tx2(context)),
        filled: true, fillColor: _T.input(context), suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _T.bdr(context))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _T.bdr(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13))),
  ]);
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: 200.ms,
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: onTap != null ? _primaryGrad : LinearGradient(colors: [_T.tx2(context), _T.tx2(context)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap != null ? [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 24)] : null),
      child: Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2))),
  );
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleBtn({this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(color: _T.bg2(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: _T.bdr(context))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: const Center(child: Text('G', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13)))),
        const SizedBox(width: 10),
        Text('Continue with Google', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _T.tx0(context))),
      ])),
  );
}

class _SearchField extends StatelessWidget {
  final String hint;
  final Function(String) onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _T.bg2(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.bdr2(context).withOpacity(0.6)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,2))],
    ),
    child: TextField(
      style: GoogleFonts.outfit(color: _T.tx0(context), fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: _T.tx2(context), size: 20),
        suffixIcon: Icon(Icons.tune_rounded, color: _T.tx2(context), size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13))),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 36, height: 36,
      decoration: BoxDecoration(color: _T.bg3(context), borderRadius: BorderRadius.circular(50)),
      child: Icon(icon, color: _T.tx1(context), size: 18)),
  );
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final Widget? trailing;
  const _UserTile({required this.user, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? 'User';
    final username = user['username'] as String? ?? '';
    final avatar = user['avatar'] as String? ?? '';
    final verified = user['isVerified'] == true;
    return ListTile(
      onTap: onTap,
      leading: _AvatarWidget(name: name, avatar: avatar, size: 44),
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text(name, style: GoogleFonts.outfit(color: _T.tx0(context), fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
        if (verified) ...[const SizedBox(width: 4), const _VerifiedBadge()],
      ]),
      subtitle: Text('@$username', style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 12)),
      trailing: trailing,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _EmptyState({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: _T.tx2(context), size: 52),
      const SizedBox(height: 14),
      Text(title, style: GoogleFonts.outfit(color: _T.tx1(context), fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(sub, style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 13), textAlign: TextAlign.center),
    ]),
  );
}

class _VerifiedBadge extends StatelessWidget {
  final double size;
  const _VerifiedBadge({this.size = 16});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF0097A7)])),
    child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.6),
  );
}

class _SetSection extends StatelessWidget {
  final String text;
  const _SetSection(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
    child: Text(text.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: _T.tx2(context), letterSpacing: 1)),
  );
}

class _SetItem extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGrad;
  final String label, sub;
  final VoidCallback onTap;
  final bool danger;
  const _SetItem({required this.icon, required this.iconGrad, required this.label, required this.sub, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: _T.card(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: _T.bdr2(context))),
        child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(gradient: LinearGradient(colors: iconGrad), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: danger ? _danger : _T.tx0(context), fontSize: 14)),
            Text(sub, style: GoogleFonts.outfit(color: _T.tx2(context), fontSize: 12)),
          ])),
          if (!danger) Icon(Icons.chevron_right_rounded, color: _T.tx2(context), size: 20),
        ])),
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ThemeOption({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: 200.ms,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: active ? _accent.withOpacity(0.1) : _T.bg2(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? _accent : _T.bdr2(context))),
      child: Row(children: [
        Icon(icon, color: active ? _accentL : _T.tx1(context), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.outfit(color: active ? _T.tx0(context) : _T.tx1(context), fontWeight: active ? FontWeight.w600 : FontWeight.normal))),
        if (active) const Icon(Icons.check_circle_rounded, color: _accent, size: 18),
      ])),
  );
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 4, width: 40, margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: _T.tx2(context), borderRadius: BorderRadius.circular(2)));
}