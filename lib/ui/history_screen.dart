import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';
import '../services/storage_service.dart';
import 'schedule_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScheduleModel> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    final histories = await StorageService.getHistories();
    setState(() {
      _histories = histories;
      _isLoading = false;
    });
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteSchedule(id);
    await _loadHistories();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal dihapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A0A3D), const Color(0xFF0F0E17)]
                        : [const Color(0xFF6C3CE1), const Color(0xFF9B6DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Jadwal',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          '${_histories.length} jadwal tersimpan',
                          style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(178),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_histories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(cs, isDark),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.builder(
                itemCount: _histories.length,
                itemBuilder: (_, i) =>
                    _buildHistoryCard(_histories[i], cs, isDark, i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      ScheduleModel item, ColorScheme cs, bool isDark, int index) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm', 'id').format(item.createdAt);
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(height: 2),
            Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleResultScreen(
                scheduleResult: item.content,
                existingId: item.id,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border(
                left: BorderSide(color: cs.primary, width: 3.5)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: cs.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: cs.onSurface.withAlpha(102)),
                        const SizedBox(width: 4),
                        Text(
                          '${ item.taskCount } tugas • ${ item.totalDuration } mnt',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurface.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: cs.onSurface.withAlpha(90),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(77)),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFF5F3FF),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.history_rounded,
              size: 64, color: cs.primary.withAlpha(128)),
        ),
        const SizedBox(height: 24),
        Text(
          'Belum ada riwayat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buat jadwal pertamamu dan simpan\nuntuk dilihat kembali kapan saja.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurface.withAlpha(128),
            height: 1.6,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.95, 0.95),
        );
  }
}
