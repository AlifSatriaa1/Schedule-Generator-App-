import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      emoji: '🧠',
      title: 'Biarkan AI Bekerja',
      subtitle:
          'Cukup masukkan daftar tugasmu, dan AI Gemini akan menyusun jadwal harian yang optimal untukmu secara otomatis.',
      gradient: [Color(0xFF6C3CE1), Color(0xFF9B6DFF)],
    ),
    _OnboardingPage(
      emoji: '⚡',
      title: 'Efisien & Terstruktur',
      subtitle:
          'Jadwal dibuat berdasarkan prioritas dan durasi. Tidak ada waktu yang terbuang sia-sia.',
      gradient: [Color(0xFFFF6B6B), Color(0xFFFFAB40)],
    ),
    _OnboardingPage(
      emoji: '📋',
      title: 'Simpan & Bagikan',
      subtitle:
          'Simpan jadwal ke riwayat, bagikan ke teman, atau salin ke clipboard dengan sekali klik.',
      gradient: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await StorageService.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a2, sb) => const HomeScreen(),
        transitionsBuilder: (ctx, animation, sb2, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _pages[i],
          ),
          // Bottom UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                              _currentPage == i ? 255 : 128),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  Row(
                    children: [
                      if (_currentPage < _pages.length - 1) ...[
                        TextButton(
                          onPressed: _finish,
                          child: Text(
                            'Lewati',
                            style: GoogleFonts.inter(
                              color: Colors.white.withAlpha(178),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                      Expanded(
                        flex: _currentPage < _pages.length - 1 ? 0 : 1,
                        child: GestureDetector(
                          onTap: _next,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.white.withAlpha(102)),
                            ),
                            child: Center(
                              child: Text(
                                _currentPage < _pages.length - 1
                                    ? 'Berikutnya →'
                                    : 'Mulai Sekarang 🚀',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 96),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.elasticOut,
                      duration: 700.ms)
                  .fadeIn(),
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 20),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withAlpha(204),
                  height: 1.7,
                ),
              ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}
