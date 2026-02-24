import 'schedule_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_schedule_generator/services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? priority;
  bool isLoading = false;

  @override
  void dispose() {
    taskController.dispose();
    durationController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null) {
      setState(() {
        tasks.add({
          "name": taskController.text.trim(),
          "priority": priority!,
          "duration": int.tryParse(durationController.text) ?? 30,
        });
      });
      taskController.clear();
      durationController.clear();
      setState(() => priority = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi semua field terlebih dahulu!")),
      );
    }
  }

  void _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap tambahkan tugas dulu!")),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      String schedule = await GeminiService.generateSchedule(tasks);
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) =>
              ScheduleResultScreen(scheduleResult: schedule),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get _totalDuration =>
      tasks.fold(0, (sum, t) => sum + (t['duration'] as int));

  Color _getPriorityColor(String p) {
    switch (p) {
      case "Tinggi": return const Color(0xFFFF5252);
      case "Sedang": return const Color(0xFFFFAB40);
      default: return const Color(0xFF69F0AE);
    }
  }

  Color _getPriorityBg(String p, bool isDark) {
    switch (p) {
      case "Tinggi": return isDark ? const Color(0xFF3D0E0E) : const Color(0xFFFFF3F3);
      case "Sedang": return isDark ? const Color(0xFF3D2A00) : const Color(0xFFFFF8EE);
      default: return isDark ? const Color(0xFF0D2E1A) : const Color(0xFFF0FFF6);
    }
  }

  IconData _getPriorityIcon(String p) {
    switch (p) {
      case "Tinggi": return Icons.local_fire_department_rounded;
      case "Sedang": return Icons.bolt_rounded;
      default: return Icons.eco_rounded;
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
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A0A3D), const Color(0xFF0F0E17)]
                        : [primary, const Color(0xFF9B6DFF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "AI Schedule",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Atur harimu,\nbiarkan AI yang susun.",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withAlpha(230),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormCard(cs, isDark, primary),
                  const SizedBox(height: 24),
                  if (tasks.isNotEmpty) ...[
                    _buildStatsBar(cs, isDark, primary),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Text(
                        "Daftar Tugas",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (tasks.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => tasks.clear()),
                          child: Text(
                            "Hapus Semua",
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          tasks.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(cs, isDark),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) =>
                        _buildTaskCard(index, isDark, cs)
                            .animate(delay: (50 * index).ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOut),
                  ),
                ),
        ],
      ),
      floatingActionButton: _buildGenerateFAB(isDark, primary),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFormCard(ColorScheme cs, bool isDark, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(isDark ? 38 : 20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tambah Tugas Baru",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: taskController,
            decoration: const InputDecoration(
              labelText: "Nama Tugas",
              prefixIcon: Icon(Icons.task_alt_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Durasi (Menit)",
              prefixIcon: Icon(Icons.timer_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Prioritas",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurface.withAlpha(153),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildPriorityChips(isDark),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: const Text("Tambah ke Daftar"),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildPriorityChips(bool isDark) {
    final options = [
      ("Tinggi", const Color(0xFFFF5252), Icons.local_fire_department_rounded),
      ("Sedang", const Color(0xFFFFAB40), Icons.bolt_rounded),
      ("Rendah", const Color(0xFF69F0AE), Icons.eco_rounded),
    ];
    return Row(
      children: options.map((opt) {
        final selected = priority == opt.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => priority = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? opt.$2.withAlpha(isDark ? 64 : 38)
                      : (isDark ? const Color(0xFF252540) : const Color(0xFFF0EEFE)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? opt.$2 : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(opt.$3, color: opt.$2, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      opt.$1,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: opt.$2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsBar(ColorScheme cs, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withAlpha(isDark ? 51 : 20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatChip(icon: Icons.list_alt_rounded, label: "${tasks.length} Tugas", color: primary),
          const SizedBox(width: 16),
          _StatChip(icon: Icons.schedule_rounded, label: "$_totalDuration Menit", color: const Color(0xFFFFAB40)),
          const Spacer(),
          Text(
            "Total estimasi",
            style: GoogleFonts.inter(fontSize: 11, color: cs.onSurface.withAlpha(128)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTaskCard(int index, bool isDark, ColorScheme cs) {
    final task = tasks[index];
    final pColor = _getPriorityColor(task['priority']);
    final pBg = _getPriorityBg(task['priority'], isDark);
    final pIcon = _getPriorityIcon(task['priority']);
    return Dismissible(
      key: Key('${task["name"]}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(height: 2),
            Text("Hapus", style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      onDismissed: (_) => setState(() => tasks.removeAt(index)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: pColor, width: 3.5)),
          boxShadow: [
            BoxShadow(
              color: pColor.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: pBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(pIcon, color: pColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['name'],
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: cs.onSurface.withAlpha(102)),
                      const SizedBox(width: 4),
                      Text(
                        "${task['duration']} menit",
                        style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withAlpha(128)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task['priority'],
                          style: GoogleFonts.inter(fontSize: 11, color: pColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurface.withAlpha(77), size: 20),
              onPressed: () => setState(() => tasks.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F3FF),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.playlist_add_rounded, size: 56, color: cs.primary.withAlpha(128)),
        ),
        const SizedBox(height: 20),
        Text(
          "Belum ada tugas",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          "Tambahkan tugasmu di atas, lalu biarkan\nAI menyusun jadwal terbaik untukmu!",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface.withAlpha(128), height: 1.6),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildGenerateFAB(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: GestureDetector(
          onTap: isLoading ? null : _generateSchedule,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isLoading ? null : LinearGradient(
                colors: isDark
                    ? [const Color(0xFF9B6DFF), const Color(0xFF6C3CE1)]
                    : [const Color(0xFF6C3CE1), const Color(0xFF9B6DFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              color: isLoading ? primary.withAlpha(128) : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isLoading ? [] : [
                BoxShadow(color: primary.withAlpha(102), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                else
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  isLoading ? "AI sedang menyusun..." : "Buat Jadwal AI",
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      ],
    );
  }
}
