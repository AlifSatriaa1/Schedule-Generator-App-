import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class ScheduleResultScreen extends StatelessWidget {
  final String scheduleResult;
  const ScheduleResultScreen({super.key, required this.scheduleResult});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final primary = cs.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_rounded, color: primary, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jadwal Kamu",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17, color: cs.onSurface),
                ),
                Text(
                  "Disusun oleh AI",
                  style: GoogleFonts.inter(fontSize: 11, color: primary.withAlpha(204), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Salin Jadwal",
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.copy_rounded, color: primary, size: 18),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: scheduleResult));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jadwal berhasil disalin!")),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  _buildInfoBanner(cs, isDark, primary),
                  const SizedBox(height: 16),
                  _buildResultCard(cs, isDark, primary),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context, cs, isDark, primary),
    );
  }

  Widget _buildInfoBanner(ColorScheme cs, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A0A3D), const Color(0xFF16213E)]
              : [primary.withAlpha(20), const Color(0xFFEDE7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withAlpha(38)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Jadwal disusun otomatis oleh AI sesuai prioritas & durasi tugasmu.",
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(178), height: 1.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildResultCard(ColorScheme cs, bool isDark, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(isDark ? 25 : 15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Markdown(
          data: scheduleResult,
          selectable: true,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.inter(fontSize: 14, height: 1.7, color: cs.onSurface.withAlpha(217)),
            h1: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: primary),
            h2: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            h3: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
            strong: GoogleFonts.inter(fontWeight: FontWeight.w700, color: cs.onSurface),
            em: GoogleFonts.inter(fontStyle: FontStyle.italic, color: cs.onSurface.withAlpha(178)),
            blockquote: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(153), fontStyle: FontStyle.italic),
            blockquoteDecoration: BoxDecoration(
              color: primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: primary, width: 3)),
            ),
            tableBorder: TableBorder.all(
              color: isDark ? Colors.white.withAlpha(25) : Colors.grey.shade200,
              width: 1,
            ),
            tableHeadAlign: TextAlign.center,
            tablePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            tableHead: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: primary),
            tableBody: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withAlpha(204)),
            listBullet: GoogleFonts.inter(color: primary, fontSize: 14),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
          ),
          builders: {'table': TableBuilder()},
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildActionBar(BuildContext context, ColorScheme cs, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0E17) : const Color(0xFFF5F3FF),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white.withAlpha(15) : primary.withAlpha(25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: scheduleResult, subject: "Jadwal Harianku"),
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text("Bagikan"),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withAlpha(102)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Buat Jadwal Baru"),
            ),
          ),
        ],
      ),
    );
  }
}

class TableBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    dynamic element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return null;
  }
}
