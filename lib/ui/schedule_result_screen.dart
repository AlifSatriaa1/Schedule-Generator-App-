import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/schedule_model.dart';
import '../services/storage_service.dart';

class ScheduleResultScreen extends StatefulWidget {
  final String scheduleResult;
  final int taskCount;
  final int totalDuration;
  final String? existingId; // non-null when viewing from history

  const ScheduleResultScreen({
    super.key,
    required this.scheduleResult,
    this.taskCount = 0,
    this.totalDuration = 0,
    this.existingId,
  });

  @override
  State<ScheduleResultScreen> createState() => _ScheduleResultScreenState();
}

class _ScheduleResultScreenState extends State<ScheduleResultScreen> {
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.existingId != null;
  }

  Future<void> _saveToHistory() async {
    if (_isSaved || _isSaving) return;
    setState(() => _isSaving = true);

    final model = ScheduleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Jadwal ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      content: widget.scheduleResult,
      taskCount: widget.taskCount,
      totalDuration: widget.totalDuration,
      createdAt: DateTime.now(),
    );

    await StorageService.saveSchedule(model);

    if (mounted) {
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal berhasil disimpan ke riwayat! 🎉',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

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
                  color: primary.withAlpha(25),
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
                  'Jadwal Kamu',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: cs.onSurface),
                ),
                Text(
                  'Disusun oleh Gemini AI',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: primary.withAlpha(204),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Salin Jadwal',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.copy_rounded, color: primary, size: 18),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.scheduleResult));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jadwal disalin ke clipboard!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal AI siap! 🎯',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Disusun otomatis berdasarkan prioritas & durasi tugasmu.',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(153),
                      height: 1.4),
                ),
              ],
            ),
          ),
          if (widget.taskCount > 0) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.taskCount}',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primary),
                ),
                Text('Tugas',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: cs.onSurface.withAlpha(128))),
              ],
            ),
          ],
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
          data: widget.scheduleResult,
          selectable: true,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.inter(
                fontSize: 14,
                height: 1.7,
                color: cs.onSurface.withAlpha(217)),
            h1: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700, color: primary),
            h2: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface),
            h3: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: primary),
            strong: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: cs.onSurface),
            em: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                color: cs.onSurface.withAlpha(178)),
            blockquote: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withAlpha(153),
                fontStyle: FontStyle.italic),
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
            tablePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            tableHead: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 13, color: primary),
            tableBody: GoogleFonts.inter(
                fontSize: 13, color: cs.onSurface.withAlpha(204)),
            listBullet:
                GoogleFonts.inter(color: primary, fontSize: 14),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildActionBar(
      BuildContext context, ColorScheme cs, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0E17) : const Color(0xFFF5F3FF),
        border: Border(
          top: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : primary.withAlpha(25)),
        ),
      ),
      child: Row(
        children: [
          // Share
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                    text: widget.scheduleResult, subject: 'Jadwal Harianku'),
              ),
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Bagikan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withAlpha(102)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Save
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: OutlinedButton.icon(
                onPressed: _isSaved ? null : _saveToHistory,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        _isSaved
                            ? Icons.check_circle_rounded
                            : Icons.bookmark_add_rounded,
                        size: 16),
                label: Text(_isSaved ? 'Tersimpan' : 'Simpan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _isSaved ? Colors.green : primary,
                  side: BorderSide(
                      color: _isSaved
                          ? Colors.green.withAlpha(102)
                          : primary.withAlpha(102)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // New
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Jadwal Baru'),
            ),
          ),
        ],
      ),
    );
  }
}
