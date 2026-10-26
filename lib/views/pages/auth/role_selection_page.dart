import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'owner_setup_page.dart';
import 'student_setup_page.dart';
import 'login_page.dart';
import '../owner/owner_main_page.dart';
import '../student/student_main_page.dart';
import '../student/student_pending_approval_page.dart';
import '../../widgets/mezzo_logo.dart';

/// Complete High-Aesthetic Onboarding Experience:
/// Stage 0: 3-Slide Vibrant Editorial Feature Showcase Carousel
/// Stage 1: Warm Walnut Bilingual Language Selection (English / हिंदी)
/// Stage 2: Editorial Role Selection (Mess Owner vs Diner/Student Member)
class RoleSelectionPage extends ConsumerStatefulWidget {
  final int initialStep;
  const RoleSelectionPage({super.key, this.initialStep = 0});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  late int _currentStep; // 0: Carousel, 1: Language, 2: Role
  final PageController _carouselCtrl = PageController();
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (_currentStep == 2) {
      _markOnboardingDone();
    }
  }

  Future<void> _markOnboardingDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      if (_currentStep == 2) {
        _markOnboardingDone();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > widget.initialStep) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(localizationProvider);
    final isHindi = currentLang == 'hi';

    return PopScope(
      canPop: _currentStep == widget.initialStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > widget.initialStep) {
          _prevStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF140F0C),
        body: Stack(
          children: [
            // Dark Walnut Gradient Canvas
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1E1712),
                      Color(0xFF120E0B),
                    ],
                  ),
                ),
              ),
            ),

            // Top-Left Warm Amber Ambient Glow
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF09E38).withValues(alpha: 0.16),
                ),
              ),
            ),

            // Bottom-Right Ambient Warm Glow
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                ),
              ),
            ),

            // Backdrop Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: const SizedBox.expand(),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Navigation Header
                  _buildHeader(isHindi),

                  // Stage Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _currentStep == 0
                          ? _buildCarouselStage(isHindi)
                          : _currentStep == 1
                              ? _buildLanguageStage(isHindi)
                              : _buildRoleStage(isHindi),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentStep > widget.initialStep
              ? InkWell(
                  onTap: _prevStep,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFAF8F3),
                      size: 18,
                    ),
                  ),
                )
              : Row(
                  children: [
                    const MezzoLogo(
                      size: 34,
                      showSquircle: true,
                      showShadow: false,
                      backgroundColor: Color(0xFF281C14),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mezzo',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF8F3),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

          Row(
            children: [
              // Language Switcher Pill
              InkWell(
                onTap: () {
                  ref
                      .read(localizationProvider.notifier)
                      .toggleLanguage(isHindi ? 'en' : 'hi');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C221B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    isHindi ? 'हिंदी' : 'English',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFAF8F3),
                    ),
                  ),
                ),
              ),
              if (_currentStep == 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _markOnboardingDone();
                    setState(() => _currentStep = 1);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        const Color(0xFFFAF8F3).withValues(alpha: 0.7),
                  ),
                  child: Text(
                    isHindi ? 'छोड़ें' : 'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAGE 0: Vibrant Editorial Feature Showcase Carousel
  // ============================================================
  Widget _buildCarouselStage(bool isHindi) {
    final slides = [
      _SlideData(
        badge: isHindi ? 'स्मार्ट व फ्लेक्सिबल' : 'SMART & FLEXIBLE',
        title: isHindi ? 'स्मार्ट मील्स और तुरंत स्किप' : 'Smart meals & instant skip',
        description: isHindi
            ? 'अपनी पसंद का मील चुनें (नाश्ता या लंच) और समय से पहले स्किप करें।'
            : 'Personalize daily meal choices (Breakfast vs Lunch) and skip ahead of time.',
        imageAsset: 'assets/images/onboard_smart_meals.jpg',
        highlights: isHindi
            ? ['चॉइस ग्रुप मील्स', 'कटऑफ टाइमर सुरक्षा', 'फेयर बिलिंग रिबेट']
            : ['Choice group meals', 'Cutoff timer security', 'Fair billing rebates'],
      ),
      _SlideData(
        badge: isHindi ? 'लाइव हेडकाउंट व बिलिंग' : 'LIVE HEADCOUNT & BILLING',
        title: isHindi ? 'लाइव किचन और पारदर्शी पासबुक' : 'Live kitchen & fair passbook',
        description: isHindi
            ? 'मेस संचालक के लिए सटीक कुकिंग हेडकाउंट, और मेंबर्स के लिए डिजिटल पासबुक।'
            : 'Real-time cooking counts for owners, and a transparent digital ledger for diners.',
        imageAsset: 'assets/images/onboard_live_headcount.jpg',
        highlights: isHindi
            ? ['रियल-टाइम कुकिंग काउंट', 'पारदर्शी पासबुक', 'ऑटोमैटिक मंथली बिल']
            : ['Real-time cooking count', 'Transparent passbook', 'Automated monthly bills'],
      ),
      _SlideData(
        badge: isHindi ? 'टॉप मेस खोजें' : 'DISCOVER TOP MESSES',
        title: isHindi ? 'वेरिफाइड मेस खोजें व जुड़ें' : 'Discover & join verified messes',
        description: isHindi
            ? 'दूरी, रेटिंग, वेज बैज और डिशेज़ देखकर आसानी से अपनी मनपसंद मेस से जुड़ें।'
            : 'Explore nearby messes by distance, ratings, Veg badges and dishes. Join with one tap.',
        imageAsset: 'assets/images/onboard_discover_messes.jpg',
        highlights: isHindi
            ? ['दूरी व स्टार रेटिंग', 'प्योर वेज बैज', 'एक टैप में जॉइन रिक्वेस्ट']
            : ['Distance & star rating', 'Pure Veg badges', 'One-tap join requests'],
      ),
    ];

    return Column(
      children: [
        // Carousel View
        Expanded(
          child: PageView.builder(
            controller: _carouselCtrl,
            itemCount: slides.length,
            onPageChanged: (idx) => setState(() => _carouselIndex = idx),
            itemBuilder: (context, i) {
              final s = slides[i];
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF221A15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Illustration Card Area with 16:9 Aspect Ratio
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                s.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF38483B),
                                        Color(0xFF243026),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      color: Color(0xFFF09E38),
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Card Body
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cream Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF8F3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  s.badge,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF231A14),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Serif Title
                              Text(
                                s.title,
                                style: GoogleFonts.newsreader(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFAF8F3),
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                s.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFD6CEB8)
                                      .withValues(alpha: 0.85),
                                  height: 1.45,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Checkmark Points
                              ...s.highlights.map((h) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Color(0xFFF09E38),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          h,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFFAF8F3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Controls: Animated Dots & Amber Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              // 3-Dot Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (idx) {
                  final isActive = _carouselIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFF09E38)
                          : const Color(0xFF382B21),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Golden Amber Next Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF09E38),
                    foregroundColor: const Color(0xFF231A14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  onPressed: () {
                    if (_carouselIndex < slides.length - 1) {
                      _carouselCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _nextStep();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _carouselIndex == slides.length - 1
                            ? (isHindi ? 'शुरू करें! →' : "Let's get started! →")
                            : (isHindi ? 'अगला →' : 'Next →'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231A14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    _markOnboardingDone();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Text(
                    isHindi ? 'पहले से खाता है? लॉगिन करें →' : 'Already have an account? Log In →',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD6CEB8).withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAGE 1: Bilingual Language Selection
  // ============================================================
  Widget _buildLanguageStage(bool isHindi) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Intro Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF221A15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isHindi ? 'Mezzo में स्वागत है' : 'Welcome to Mezzo',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isHindi ? 'अपनी भाषा चुनें' : 'Choose your\nlanguage',
                  style: GoogleFonts.newsreader(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAF8F3),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHindi
                      ? 'भारत में मेस संचालकों और भोजनकर्ताओं के लिए विशेष रूप से तैयार।'
                      : 'Tailored for mess owners and diners in India.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFD6CEB8).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // English Card
          _buildLanguageOptionCard(
            title: 'English',
            subtitle: 'Default language across all menus, reports and billing',
            badgeText: 'Global',
            iconText: 'EN',
            iconBgColor: const Color(0xFF4E654F),
            isSelected: !isHindi,
            onTap: () {
              ref.read(localizationProvider.notifier).toggleLanguage('en');
            },
          ),
          const SizedBox(height: 14),

          // Hindi Card
          _buildLanguageOptionCard(
            title: 'हिंदी (Hindi)',
            subtitle: 'मेन्यू, दैनिक उपस्थिति, प्लान और बिलिंग सब अपनी भाषा में',
            badgeText: 'देसी व सरल',
            iconText: 'अ',
            iconBgColor: const Color(0xFFF09E38),
            isSelected: isHindi,
            onTap: () {
              ref.read(localizationProvider.notifier).toggleLanguage('hi');
            },
          ),

          const SizedBox(height: 20),

          // Note Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              isHindi
                  ? 'चिंता न करें, आप ऐप में कभी भी एक टैप से भाषा बदल सकते हैं।'
                  : "Don't worry, you can switch language anytime with one tap.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFD6CEB8).withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Golden Amber Continue Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF09E38),
                foregroundColor: const Color(0xFF231A14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              onPressed: _nextStep,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isHindi ? 'आगे बढ़ें →' : 'Continue →',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF231A14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required String iconText,
    required Color iconBgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF221A15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF09E38)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF09E38).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  iconText,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFAF8F3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFAF8F3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFAF8F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFD6CEB8).withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF8F3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF231A14),
                    size: 18,
                  ),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAGE 2: Editorial Role Selection
  // ============================================================
  Widget _buildRoleStage(bool isHindi) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            isHindi ? 'अपना रोल चुनें' : 'Choose your role',
            style: GoogleFonts.newsreader(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFAF8F3),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isHindi
                ? 'वह रोल चुनें जो आपके रोज़मर्रा के मेस रूटीन के लिए उपयुक्त हो।'
                : 'Pick the role that fits your everyday mess routine.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFD6CEB8).withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),

          // Card 1: Mess & Tiffin Owner
          _buildRoleCard(
            badge: isHindi ? 'संचालक / वेंडर' : 'OWNER / VENDOR',
            title: isHindi ? 'मेस व टिफिन संचालक' : 'Mess & Tiffin Owner',
            subtitle: isHindi
                ? 'मेस संचालक, कुक और टिफिन सेवाओं के लिए। समय, हेडकाउंट और बिल संभालें।'
                : 'For mess owners, cooks and tiffin services. Manage timings, headcount & bills.',
            imageAsset: 'assets/images/role_owner_chef.jpg',
            features: isHindi
                ? ['लाइव कुकिंग हेडकाउंट', 'कस्टम मील प्लान्स', 'मंथली बिलिंग व एक्स्ट्रा फीस']
                : ['Live cooking headcount', 'Custom meal plans', 'Monthly billing & extra fees'],
            onTap: () => _handleRoleSelection(context, ref, AuthRole.owner),
          ),

          const SizedBox(height: 18),

          // Card 2: Diner & Student Member
          _buildRoleCard(
            badge: isHindi ? 'भोजनकर्ता / छात्र' : 'DINER / STUDENT',
            title: isHindi ? 'भोजनकर्ता व छात्र मेंबर' : 'Diner & Student Member',
            subtitle: isHindi
                ? 'छात्रों, कामकाजी प्रोफेशनल्स और पीजी निवासियों के लिए। दैनिक भोजन और छुट्टियां ट्रैक करें।'
                : 'For students, working professionals and PG residents. Track daily meals & leaves.',
            imageAsset: 'assets/images/role_student_diner.jpg',
            features: isHindi
                ? ['दैनिक चयन व स्किप', 'डिजिटल पासबुक', 'छुट्टियां व गेस्ट मील्स']
                : ['Daily choice & skips', 'Digital passbook', 'Leaves & guest meals'],
            onTap: () => _handleRoleSelection(context, ref, AuthRole.student),
          ),

          if (FirebaseAuth.instance.currentUser == null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFD6CEB8).withValues(alpha: 0.85),
                    ),
                    children: [
                      TextSpan(
                        text: isHindi
                            ? 'पहले से खाता है? '
                            : 'Already have an account? ',
                      ),
                      TextSpan(
                        text: isHindi ? 'लॉगिन करें →' : 'Log In →',
                        style: const TextStyle(
                          color: Color(0xFFF09E38),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String badge,
    required String title,
    required String subtitle,
    required String imageAsset,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF221A15),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 16:9 Illustration Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF2D231C),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFF09E38),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content Details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8F3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF231A14),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAF8F3),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFD6CEB8).withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Feature Pill Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: features.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFAF8F3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRoleSelection(
    BuildContext context,
    WidgetRef ref,
    AuthRole role,
  ) async {
    ref.read(authProvider.notifier).setRole(role);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // If not logged in, take the user to LoginPage with the chosen role!
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(initialRole: role)),
      );
      return;
    }

    // If logged in, check profile
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF221A15),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 20)
            ],
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFF09E38),
          ),
        ),
      ),
    );

    try {
      if (role == AuthRole.owner) {
        final mess = await ref.read(appServiceProvider).getMessByOwnerId(uid);
        if (context.mounted) {
          Navigator.pop(context);
          if (mess == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OwnerSetupPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OwnerMainPage()),
            );
          }
        }
      } else {
        final student = await ref.read(appServiceProvider).getStudentById(uid);
        if (context.mounted) {
          Navigator.pop(context);
          if (student == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentSetupPage()),
            );
          } else if (student.status == 'active' ||
              student.status == 'approved') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentMainPage()),
            );
          } else if (student.status == 'left' || student.messId.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentSetupPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StudentPendingApprovalPage(
                  initialMessName: student.messId.isNotEmpty
                      ? (ref.read(localizationProvider) == 'hi'
                          ? 'मेस'
                          : 'Mess')
                      : null,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _SlideData {
  final String badge;
  final String title;
  final String description;
  final String imageAsset;
  final List<String> highlights;

  const _SlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.highlights,
  });
}
