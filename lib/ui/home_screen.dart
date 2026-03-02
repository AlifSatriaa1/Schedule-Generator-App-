import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../services/gemini_service.dart';
import 'history_screen.dart';
import 'schedule_result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController _taskCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  String? _priority;
  bool _isLoading = false;
  int _navIndex = 0;
  TimeOfDay _startTime = TimeOfDay.now();

  // For edit dialog
  int? _editingIndex;

  @override
  void dispose() {
    _taskCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  // ─── Greeting ─────────────────────────────────────────────────
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  String get _dateString {
    return DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now());
  }

  String get _startTimeLabel {
    final hour = _startTime.hour.toString().padLeft(2, '0');
    final min = _startTime.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  // ─── Actions ──────────────────────────────────────────────────
  void _addTask() {
    final name = _taskCtrl.text.trim();
    final dur = int.tryParse(_durationCtrl.text.trim()) ?? 0;

    if (name.isEmpty || dur <= 0 || _priority == null) {
      _showSnackBar('Isi semua field dengan benar!', isError: true);
      return;
    }

    if (_editingIndex != null) {
      setState(() {
        tasks[_editingIndex!] = {
          'name': name,
          'priority': _priority!,
          'duration': dur,
        };
        _editingIndex = null;
      });
      _showSnackBar('Tugas berhasil diperbarui ✓');
    } else {
      setState(() {
        tasks.add({
          'name': name,
          'priority': _priority!,
          'duration': dur,
        });
      });
      _showSnackBar('Tugas ditambahkan ✓');
    }
    _clearForm();
  }

  void _clearForm() {
    _taskCtrl.clear();
    _durationCtrl.clear();
    setState(() {
      _priority = null;
      _editingIndex = null;
    });
  }

  void _editTask(int index) {
    final task = tasks[index];
    setState(() {
      _taskCtrl.text = task['name'];
      _durationCtrl.text = task['duration'].toString();
      _priority = task['priority'];
      _editingIndex = index;
    });
    // Scroll to top
    PrimaryScrollController.maybeOf(context)?.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  void _generateSchedule() async {
    if (tasks.isEmpty) {
      _showSnackBar('Harap tambahkan tugas dulu!', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final schedule = await GeminiService.generateSchedule(
        tasks,
        startTime: _startTimeLabel,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx2, animation, sb) => ScheduleResultScreen(
            scheduleResult: schedule,
            taskCount: tasks.length,
            totalDuration: _totalDuration,
          ),
          transitionsBuilder: (ctx2, animation, sb, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  int get _totalDuration =>
      tasks.fold(0, (sum, t) => sum + (t['duration'] as int));

  Color _priorityColor(String p) {
    return p == 'Tinggi'
        ? const Color(0xFFFF5252)
        : p == 'Sedang'
            ? const Color(0xFFFFAB40)
            : const Color(0xFF69F0AE);
  }

  Color _priorityBg(String p, bool isDark) {
    return p == 'Tinggi'
        ? (isDark ? const Color(0xFF3D0E0E) : const Color(0xFFFFF3F3))
        : p == 'Sedang'
            ? (isDark ? const Color(0xFF3D2A00) : const Color(0xFFFFF8EE))
            : (isDark ? const Color(0xFF0D2E1A) : const Color(0xFFF0FFF6));
  }

  IconData _priorityIcon(String p) {
    return p == 'Tinggi'
        ? Icons.local_fire_department_rounded
        : p == 'Sedang'
            ? Icons.bolt_rounded
            : Icons.eco_rounded;
  }

  // ─── Navigation ───────────────────────────────────────────────
  Widget _buildCurrentTab() {
    switch (_navIndex) {
      case 1:
        return const HistoryScreen();
      case 2:
        return SettingsScreen(themeNotifier: themeNotifier);
      default:
        return _buildHomeTab();
    }
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_navIndex),
          child: _buildCurrentTab(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(cs, isDark),
      floatingActionButton:
          _navIndex == 0 ? _buildFAB(isDark, cs) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHomeTab() {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        _buildAppBar(cs, isDark),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormCard(cs, isDark),
                const SizedBox(height: 20),
                if (tasks.isNotEmpty) ...[
                  _buildStatsBar(cs, isDark),
                  const SizedBox(height: 16),
                ],
                _buildSectionHeader(cs),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                sliver: SliverList.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _buildTaskCard(i, isDark, cs)
                      .animate(delay: (50 * i).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),
                ),
              ),
      ],
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────
  Widget _buildAppBar(ColorScheme cs, bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
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
                  : [const Color(0xFF6C3CE1), const Color(0xFF9B6DFF)],
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
                      const SizedBox(width: 10),
                      Text(
                        'AI Schedule',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 16),
                  Text(
                    _greeting,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 4),
                  Text(
                    _dateString,
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(178),
                      fontSize: 13,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Form Card ────────────────────────────────────────────────
  Widget _buildFormCard(ColorScheme cs, bool isDark) {
    final isEditing = _editingIndex != null;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(isDark ? 38 : 20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
                  color: cs.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Tugas' : 'Tambah Tugas Baru',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
              if (isEditing) ...[
                const Spacer(),
                TextButton(
                  onPressed: _clearForm,
                  child: Text('Batal',
                      style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _taskCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Tugas',
              prefixIcon: Icon(Icons.task_alt_rounded),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durasi (Menit)',
                    prefixIcon: Icon(Icons.timer_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Start time chip
              GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF0EEFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.primary.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: cs.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _startTimeLabel,
                        style: GoogleFonts.poppins(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Prioritas',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurface.withAlpha(153),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildPriorityChips(isDark, cs),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addTask,
              icon: Icon(
                  isEditing ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                  size: 20),
              label: Text(isEditing ? 'Simpan Perubahan' : 'Tambah ke Daftar'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildPriorityChips(bool isDark, ColorScheme cs) {
    final options = [
      ('Tinggi', const Color(0xFFFF5252), Icons.local_fire_department_rounded),
      ('Sedang', const Color(0xFFFFAB40), Icons.bolt_rounded),
      ('Rendah', const Color(0xFF69F0AE), Icons.eco_rounded),
    ];
    return Row(
      children: options.map((opt) {
        final selected = _priority == opt.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _priority = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? opt.$2.withAlpha(isDark ? 64 : 38)
                      : (isDark
                          ? const Color(0xFF252540)
                          : const Color(0xFFF0EEFE)),
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

  // ─── Stats Bar ────────────────────────────────────────────────
  Widget _buildStatsBar(ColorScheme cs, bool isDark) {
    final highCount =
        tasks.where((t) => t['priority'] == 'Tinggi').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(isDark ? 51 : 20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _StatChip(
              icon: Icons.list_alt_rounded,
              label: '${tasks.length} Tugas',
              color: cs.primary),
          const SizedBox(width: 16),
          _StatChip(
              icon: Icons.schedule_rounded,
              label: '$_totalDuration mnt',
              color: const Color(0xFFFFAB40)),
          if (highCount > 0) ...[
            const SizedBox(width: 16),
            _StatChip(
                icon: Icons.local_fire_department_rounded,
                label: '$highCount Penting',
                color: const Color(0xFFFF5252)),
          ],
          const Spacer(),
          // Start time display
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_rounded,
                  size: 14, color: cs.onSurface.withAlpha(102)),
              const SizedBox(width: 4),
              Text(
                _startTimeLabel,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withAlpha(153)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Section Header ───────────────────────────────────────────
  Widget _buildSectionHeader(ColorScheme cs) {
    return Row(
      children: [
        Text(
          'Daftar Tugas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        if (tasks.isNotEmpty)
          TextButton.icon(
            onPressed: () => setState(() {
              tasks.clear();
              _clearForm();
            }),
            icon: const Icon(Icons.delete_sweep_rounded,
                size: 16, color: Colors.red),
            label: Text(
              'Hapus Semua',
              style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ─── Task Card ────────────────────────────────────────────────
  Widget _buildTaskCard(int index, bool isDark, ColorScheme cs) {
    final task = tasks[index];
    final pColor = _priorityColor(task['priority']);
    final pBg = _priorityBg(task['priority'], isDark);
    final pIcon = _priorityIcon(task['priority']);

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
            Text('Hapus',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      onDismissed: (_) => setState(() => tasks.removeAt(index)),
      child: GestureDetector(
        onLongPress: () => _editTask(index),
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
                decoration: BoxDecoration(
                    color: pBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(pIcon, color: pColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['name'],
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: cs.onSurface.withAlpha(102)),
                        const SizedBox(width: 4),
                        Text(
                          '${task['duration']} menit',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(128)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            task['priority'],
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: pColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: Icon(Icons.edit_rounded,
                    color: cs.onSurface.withAlpha(77), size: 18),
                onPressed: () => _editTask(index),
                tooltip: 'Edit',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────
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
          child:
              Icon(Icons.playlist_add_rounded, size: 56, color: cs.primary.withAlpha(128)),
        ),
        const SizedBox(height: 20),
        Text(
          'Belum ada tugas',
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Tambahkan tugasmu di atas, lalu\nbiarkan AI menyusun jadwal terbaik!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withAlpha(128),
              height: 1.6),
        ),
        const SizedBox(height: 24),
        Text(
          '💡 Tip: Long press kartu tugas untuk edit',
          style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurface.withAlpha(90),
              fontStyle: FontStyle.italic),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  // ─── FAB ──────────────────────────────────────────────────────
  Widget _buildFAB(bool isDark, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: GestureDetector(
          onTap: _isLoading ? null : _generateSchedule,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF9B6DFF), const Color(0xFF6C3CE1)]
                          : [const Color(0xFF6C3CE1), const Color(0xFF9B6DFF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: _isLoading ? cs.primary.withAlpha(128) : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: cs.primary.withAlpha(102),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                else
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  _isLoading ? 'AI sedang menyusun...' : 'Buat Jadwal AI',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                if (!_isLoading && tasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────
  Widget _buildBottomNav(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(isDark ? 25 : 15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
              color: cs.primary.withAlpha(isDark ? 25 : 20), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isActive: _navIndex == 0,
                cs: cs,
                onTap: () => setState(() => _navIndex = 0),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                isActive: _navIndex == 1,
                cs: cs,
                onTap: () => setState(() => _navIndex = 1),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Pengaturan',
                isActive: _navIndex == 2,
                cs: cs,
                onTap: () => setState(() => _navIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: cs.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? cs.primary : cs.onSurface.withAlpha(102),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? cs.primary
                    : cs.onSurface.withAlpha(102),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
