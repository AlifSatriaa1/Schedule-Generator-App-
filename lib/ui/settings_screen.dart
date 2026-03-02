import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTheme = 0; // 0=system, 1=light, 2=dark

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await StorageService.getThemeMode();
    setState(() => _selectedTheme = mode);
  }

  Future<void> _setTheme(int mode) async {
    setState(() => _selectedTheme = mode);
    await StorageService.setThemeMode(mode);
    widget.themeNotifier.value = [
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ][mode];
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Semua Riwayat?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Semua jadwal yang tersimpan akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.clearAllHistories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Riwayat berhasil dihapus',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
                    child: Text(
                      'Pengaturan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Tema ─────────────────────────────────────
                _buildSectionHeader('Tampilan', cs),
                _buildCard(isDark, cs, [
                  _buildThemeRow(isDark, cs),
                ]).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // ─── Data ─────────────────────────────────────
                _buildSectionHeader('Data', cs),
                _buildCard(isDark, cs, [
                  _buildActionTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: Colors.red,
                    title: 'Hapus Semua Riwayat',
                    subtitle: 'Hapus seluruh jadwal yang tersimpan',
                    onTap: _clearHistory,
                    cs: cs,
                    isDark: isDark,
                  ),
                ]).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // ─── Tentang ──────────────────────────────────
                _buildSectionHeader('Tentang', cs),
                _buildCard(isDark, cs, [
                  _buildInfoTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Schedule Generator',
                    value: 'v2.0.0',
                    cs: cs,
                    isDark: isDark,
                  ),
                  _Divider(cs: cs),
                  _buildInfoTile(
                    icon: Icons.psychology_rounded,
                    title: 'Powered by',
                    value: 'Google Gemini',
                    cs: cs,
                    isDark: isDark,
                  ),
                ]).animate(delay: 200.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, ColorScheme cs, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(isDark ? 25 : 15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildThemeRow(bool isDark, ColorScheme cs) {
    final options = [
      (icon: Icons.brightness_auto_rounded, label: 'Sistem', value: 0),
      (icon: Icons.light_mode_rounded, label: 'Terang', value: 1),
      (icon: Icons.dark_mode_rounded, label: 'Gelap', value: 2),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Mode Tampilan',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: options.map((opt) {
              final selected = _selectedTheme == opt.value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setTheme(opt.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withAlpha(30)
                            : (isDark
                                ? const Color(0xFF252540)
                                : const Color(0xFFF5F3FF)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? cs.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(opt.icon,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withAlpha(102),
                              size: 20),
                          const SizedBox(height: 4),
                          Text(
                            opt.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: iconColor)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(128))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withAlpha(77)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(153))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme cs;
  const _Divider({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: cs.onSurface.withAlpha(20),
    );
  }
}
