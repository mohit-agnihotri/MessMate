import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/localization_service.dart';
import '../../../viewmodels/all_viewmodels.dart';
import 'owner_setup_page.dart';
import 'student_setup_page.dart';
import 'login_page.dart';
import '../owner/owner_main_page.dart';
import '../student/student_main_page.dart';
import '../student/student_pending_approval_page.dart';

/// Complete High-Aesthetic Onboarding Experience:
/// Stage 0: 3-Slide Vibrant 3D Feature Showcase Carousel
/// Stage 1: Frosted Glass Bilingual Language Selection (English / हिंदी)
/// Stage 2: 3D Role Selection (Mess Owner vs Diner/Member) with Instant Demo Access
class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  int _currentStep = 0; // 0: Carousel, 1: Language, 2: Role
  final PageController _carouselCtrl = PageController();
  int _carouselIndex = 0;

  @override
  void dispose() {
    _carouselCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(localizationProvider);
    final isHindi = currentLang == 'hi';

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          _prevStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Stack(
          children: [
            // Ambient Radial Glow 1 (Emerald top-left)
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                ),
              ),
            ),
            // Ambient Radial Glow 2 (Warm Amber bottom-right)
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                ),
              ),
            ),
            // Backdrop Blur to diffuse ambient lights
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.expand(),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Navigation Header
                  _buildHeader(isHindi),

                  // Stage Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
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
          _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: _prevStep,
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'MessMate',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

          Row(
            children: [
              // Persistent Language Switcher Pill
              InkWell(
                onTap: () {
                  ref.read(localizationProvider.notifier).toggleLanguage(isHindi ? 'en' : 'hi');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 15, color: Color(0xFF34D399)),
                      const SizedBox(width: 6),
                      Text(
                        isHindi ? 'हिंदी' : 'English',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_currentStep == 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: Text(
                    isHindi ? 'छोड़ें (Skip)' : 'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
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
  // STAGE 0: Vibrant 3D Feature Showcase Carousel
  // ============================================================
  Widget _buildCarouselStage(bool isHindi) {
    final slides = [
      _SlideData(
        badge: isHindi ? '✨ स्मार्ट व फ्लेक्सिबल' : '✨ SMART & FLEXIBLE',
        title: isHindi ? 'खाने में पूरी आज़ादी' : 'Smart Meals & Instant Skip',
        description: isHindi
            ? 'अपनी पसंद का मील चुनें (ब्रेकफ़ास्ट या लंच), और जब खाना न खाना हो तो समय से पहले स्किप करें।'
            : 'Personalize daily meal choices (Breakfast vs Lunch) and easily skip ahead of time.',
        imageAsset: 'assets/images/onboard_smart_meals.jpg',
        glowColor: const Color(0xFF10B981),
        highlights: isHindi
            ? ['चॉइस ग्रुप मील्स', 'कटऑफ टाइमर सुरक्षा', 'फेयर बिलिंग रिबेट']
            : ['Choice Group Meals', 'Cutoff Timer Security', 'Fair Billing Rebates'],
      ),
      _SlideData(
        badge: isHindi ? '📊 लाइव हेडकाउंट व हिसाब' : '📊 LIVE HEADCOUNT & BILLING',
        title: isHindi ? 'सटीक हिसाब, ज़ीरो बर्बादी' : 'Live Kitchen & Fair Passbook',
        description: isHindi
            ? 'मेस संचालक के लिए किचन का सटीक लाइव खाना काउंट, और मेंबर्स के लिए पारदर्शी डिजिटल पासबुक।'
            : 'Real-time kitchen cooking counts for owners, and fully transparent digital ledger passbooks for diners.',
        imageAsset: 'assets/images/onboard_live_headcount.jpg',
        glowColor: const Color(0xFFF59E0B),
        highlights: isHindi
            ? ['रियल-टाइम कुकिंग काउंट', 'पारदर्शी पासबुक', 'ऑटोमैटिक मंथली बिल']
            : ['Real-Time Cooking Count', 'Transparent Passbook', 'Automated Monthly Bills'],
      ),
      _SlideData(
        badge: isHindi ? '🧭 टॉप मेस खोजें' : '🧭 DISCOVER TOP MESSES',
        title: isHindi ? 'आस-पास के बेस्ट मेस खोजें' : 'Discover & Join Verified Messes',
        description: isHindi
            ? 'दूरी, रेटिंग, वेज/नॉन-वेज बैज और मास्टर मेनू डिशेज़ देखकर आसानी से अपनी मनपसंद मेस से जुड़ें।'
            : 'Explore nearby verified messes by distance, ratings, Pure Veg badges, dishes, and join with one tap.',
        imageAsset: 'assets/images/onboard_discover_messes.jpg',
        glowColor: const Color(0xFF8B5CF6),
        highlights: isHindi
            ? ['दूरी व स्टार रेटिंग', 'प्योर वेज बैज', 'एक टैप में जॉइन']
            : ['Distance & Star Rating', 'Pure Veg Badges', 'One-Tap Join Requests'],
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: s.glowColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: s.glowColor.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top 3D Visual Scene with bottom gradient fade
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 1.25,
                              child: Image.asset(
                                s.imageAsset,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Gradient shadow fade over the image bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 90,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF131B2B).withValues(alpha: 0.95),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Top badge
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: s.glowColor.withValues(alpha: 0.6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: s.glowColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  s.badge,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Card Body
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Highlight Pills
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: s.highlights.map((h) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: s.glowColor.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: s.glowColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          h,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                      ],
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
            },
          ),
        ),

        // Bottom Controls: Animated Dots & Action Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              // Animated Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (idx) {
                  final isActive = _carouselIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Gradient CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              ? (isHindi ? 'आगे बढ़ें (Get Started)' : "Let's Get Started!")
                              : (isHindi ? 'अगला (Next)' : 'Next'),
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ],
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
  // STAGE 1: Frosted Glass Bilingual Language Selection
  // ============================================================
  Widget _buildLanguageStage(bool isHindi) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcoming Visual Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Subtle hospitality backdrop
                  Opacity(
                    opacity: 0.25,
                    child: Image.asset(
                      'assets/images/onboard_discover_messes.jpg',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.95),
                            const Color(0xFF0F172A).withValues(alpha: 0.6),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🇮🇳', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                isHindi ? 'नमस्ते एवं स्वागतम्' : 'Welcome to MessMate',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFBBF24),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isHindi ? 'अपनी पसंदीदा भाषा चुनें' : 'Choose Your Language',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHindi
                              ? 'मेस संचालक और छात्र दोनों के लिए आसान और पारदर्शी।'
                              : 'Tailored for both mess owners and diners in India.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // English Card
          _buildLanguageOptionCard(
            title: 'English',
            subtitle: 'Default language across all menus, reports and billing',
            badgeText: 'Global',
            iconText: 'EN',
            accentGradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            isSelected: !isHindi,
            onTap: () {
              ref.read(localizationProvider.notifier).toggleLanguage('en');
            },
          ),
          const SizedBox(height: 16),

          // Hindi Card
          _buildLanguageOptionCard(
            title: 'हिंदी (Hindi)',
            subtitle: 'मेन्यू, दैनिक उपस्थिति, प्लान और बिलिंग सब अपनी भाषा में',
            badgeText: 'देसी व सरल',
            iconText: 'अ',
            accentGradient: const [Color(0xFF10B981), Color(0xFF059669)],
            isSelected: isHindi,
            onTap: () {
              ref.read(localizationProvider.notifier).toggleLanguage('hi');
            },
          ),

          const SizedBox(height: 20),

          // Helpful Note Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isHindi
                        ? 'चिंता न करें, आप ऐप के अंदर कभी भी 1 टैप में भाषा बदल सकते हैं।'
                        : 'Don\'t worry, you can switch language anytime with one tap.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _nextStep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isHindi ? 'आगे बढ़ें (Continue)' : 'Continue',
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  ],
                ),
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
    required List<Color> accentGradient,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withValues(alpha: 0.12)
              : const Color(0xFF131B2B).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: accentGradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentGradient.first.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  iconText,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAGE 2: 3D Role Selection & Instant Demo Access Bar
  // ============================================================
  Widget _buildRoleStage(bool isHindi) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            isHindi ? 'आप ऐप कैसे इस्तेमाल करेंगे?' : 'Choose Your Role',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isHindi
                ? 'अपने हिसाब से सही प्रोफाइल चुनें ताकि आपको ज़रूरत के अनुसार फीचर्स मिलें।'
                : 'Select your role to access features tailored for your everyday mess routine.',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8), height: 1.45),
          ),
          const SizedBox(height: 20),

          // Option 1: Mess & Tiffin Owner (मेस संचालक) with 3D Chef Art
          _buildVibrantRoleCard(
            badge: isHindi ? '👑 संचालक / वेंडर' : '👑 OWNER / VENDOR',
            title: isHindi ? 'मेस व टिफिन संचालक' : 'Mess & Tiffin Owner',
            subtitle: isHindi
                ? 'मेस संचालक, कुक और टिफिन सर्विसेज के लिए। समय, लाइव हेडकाउंट, मेनू और बिलिंग मैनेज करें।'
                : 'For mess owners, cooks, and tiffin services. Manage timings, headcount & bills.',
            imageAsset: 'assets/images/role_owner_chef.jpg',
            accentColor: const Color(0xFF10B981),
            features: isHindi
                ? ['🍲 लाइव कुकिंग हेडकाउंट', '📋 फ्लेक्सिबल मील प्लान्स', '💰 मंथली बिलिंग व एक्स्ट्रा फीस']
                : ['🍲 Live Cooking Headcount', '📋 Custom Meal Plans', '💰 Monthly Billing & Extra Fees'],
            onTap: () => _handleRoleSelection(context, ref, AuthRole.owner),
          ),

          const SizedBox(height: 18),

          // Option 2: Diner / Member (भोजन सदस्य) with 3D Student Art
          _buildVibrantRoleCard(
            badge: isHindi ? '🎓 विद्यार्थी / कामकाजी' : '🎓 DINER / STUDENT',
            title: isHindi ? 'भोजन सदस्य / मेस मेंबर' : 'Diner & Student Member',
            subtitle: isHindi
                ? 'विद्यार्थी, कामकाजी और पीजी में रहने वालों के लिए। रोज़ाना खाना, छुट्टियां और हिसाब देखें।'
                : 'For students, working professionals, and PG residents. Track daily meals & leaves.',
            imageAsset: 'assets/images/role_student_diner.jpg',
            accentColor: const Color(0xFFF59E0B),
            features: isHindi
                ? ['🍱 रोज़ाना मील चॉइस व स्किप', '📖 डिजिटल पासबुक पारदर्शकता', '🌴 छुट्टी व गेस्ट मील']
                : ['🍱 Daily Choice & Skips', '📖 Digital Passbook', '🌴 Leaves & Guest Meals'],
            onTap: () => _handleRoleSelection(context, ref, AuthRole.student),
          ),

        ],
      ),
    );
  }

  Widget _buildVibrantRoleCard({
    required String badge,
    required String title,
    required String subtitle,
    required String imageAsset,
    required Color accentColor,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B2B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top 3D Character Illustration Scene
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.45,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF131B2B).withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content Details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: features.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE2E8F0),
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
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20)],
          ),
          child: const CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF10B981)),
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
          } else if (student.status == 'active' || student.status == 'approved') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentMainPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StudentPendingApprovalPage(
                  initialMessName: student.messId.isNotEmpty ? 'मेस' : null,
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
  final Color glowColor;
  final List<String> highlights;

  const _SlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.glowColor,
    required this.highlights,
  });
}
