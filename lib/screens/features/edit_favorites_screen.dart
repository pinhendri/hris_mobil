import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/favorite_provider.dart';

class EditFavoritesScreen extends StatelessWidget {
  const EditFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Favorites',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select between 1 and 5 features to display on your dashboard.',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.allFeatures.length,
                  itemBuilder: (context, index) {
                    final feature = provider.allFeatures[index];
                    final isFavorite = provider.isFavorite(feature.id);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isFavorite
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: feature.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            feature.icon,
                            color: feature.color,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          feature.label,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: Switch(
                          value: isFavorite,
                          activeThumbColor: feature.color,
                          onChanged: (value) async {
                            final error = await provider.toggleFavorite(
                              feature.id,
                            );
                            if (error != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.error,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          final error = await provider.toggleFavorite(
                            feature.id,
                          );
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
