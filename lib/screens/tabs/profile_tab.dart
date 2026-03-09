import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../login_screen.dart'; // TAMBAHKAN IMPORT INI

import '../profile/personal_info_screen.dart';
import '../profile/employment_details_screen.dart';
import '../profile/change_password_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = auth.user;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(user, isDark),
            const SizedBox(height: 20),

            // Stats Cards
            _buildStatsCards(isDark),
            const SizedBox(height: 20),

            // Account Section
            _buildSection(context, 'Account', [
              _buildMenuItem(
                Icons.person_outline,
                'Personal Information',
                subtitle: 'Update your personal details',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.work_outline,
                'Employment Details',
                subtitle: 'View your job information',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmploymentDetailsScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.lock_outline,
                'Change Password',
                subtitle: 'Update your password',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 20),

            // App Settings Section with Dark Mode Toggle
            _buildSection(context, 'App Settings', [
              _buildMenuItem(
                Icons.dark_mode_outlined,
                'Dark Mode',
                subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                color: isDark ? Colors.amber : Colors.indigo,
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withOpacity(0.3),
                ),
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.notifications_none,
                'Notifications',
                subtitle: 'Manage your notifications',
                color: Colors.red,
                trailing: Switch(
                  value: true,
                  onChanged: (val) {},
                  activeColor: Colors.green,
                ),
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.language,
                'Language',
                subtitle: 'English (US)',
                color: Colors.teal,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public, size: 16, color: isDark ? Colors.white70 : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'English',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 20),

            // Support Section
            _buildSection(context, 'Support', [
              _buildMenuItem(
                Icons.help_outline,
                'Help Center',
                subtitle: 'Get help and support',
                color: Colors.blue,
                onTap: () {},
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.info_outline,
                'About App',
                subtitle: 'Version 1.0.0',
                color: Colors.purple,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                subtitle: 'Read our privacy policy',
                color: Colors.teal,
                onTap: () {},
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutDialog(context, auth, isDark);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.3),
                  ),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A237E), const Color(0xFF4A148C)]
              : [Colors.blue, Colors.purple],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.purple : Colors.blue).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                (user?.name.isNotEmpty ?? false) ? user!.name.substring(0, 1).toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  color: isDark ? const Color(0xFF1A237E) : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  user?.position ?? 'Employee',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: ${user?.uuid ?? "EMP-0000"}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.calendar_today_rounded,
            value: '12',
            label: 'Leave',
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.timer_rounded,
            value: '168h',
            label: 'Overtime',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.star_rounded,
            value: '4.5',
            label: 'Rating',
            gradient: const LinearGradient(
              colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      List<Widget> children,
      ) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title, {
        String? subtitle,
        Color? color,
        Widget? trailing,
        VoidCallback? onTap,
        required bool isDark,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color ?? Colors.blue,
                      (color ?? Colors.blue).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (color ?? Colors.blue).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log Out',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Tutup dialog konfirmasi
                          Navigator.pop(dialogContext);

                          // Tunggu sebentar untuk memastikan dialog benar-benar tertutup
                          await Future.delayed(const Duration(milliseconds: 100));

                          if (!context.mounted) return;

                          // Tampilkan loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (loadingContext) => WillPopScope(
                              onWillPop: () async => false,
                              child: Dialog(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Logging out...',
                                        style: GoogleFonts.poppins(
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          // Tunggu proses logout selesai
                          await auth.logout();

                          // Tambahkan delay kecil untuk memastikan state sudah diupdate
                          await Future.delayed(const Duration(milliseconds: 300));

                          if (context.mounted) {
                            // Tutup loading dialog jika masih ada
                            try {
                              Navigator.pop(context);
                            } catch (e) {
                              // Abaikan error jika dialog sudah tertutup
                            }

                            // Hapus semua route dan navigasi ke login
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()), // SEKARANG INI AKAN MENGARAH KE LOGIN_SCREEN YANG BENAR
                                  (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// HAPUS BAGIAN INI:
// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text('Login Screen'),
//       ),
//     );
//   }
// }