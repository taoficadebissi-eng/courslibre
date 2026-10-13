import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';

class SkeletonCarteWidget extends StatelessWidget {
  const SkeletonCarteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceAlt,
      highlightColor: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastille catégorie
            Container(width: 40, height: 40, color: AppColors.surfaceAlt),
            const SizedBox(height: 12),
            // Titre (2 lignes simulées)
            Container(
              height: 18,
              width: double.infinity,
              color: AppColors.surfaceAlt,
            ),
            const SizedBox(height: 6),
            Container(height: 18, width: 200, color: AppColors.surfaceAlt),
            const SizedBox(height: 8),
            // Fournisseur
            Container(height: 12, width: 100, color: AppColors.surfaceAlt),
            // Remplace l'ancien Spacer() (= Expanded, invalide dans une
            // hauteur non bornée) par un espacement fixe.
            const SizedBox(height: 16),
            // Badges
            Row(
              children: [
                Container(height: 20, width: 60, color: AppColors.surfaceAlt),
                const SizedBox(width: 8),
                Container(height: 20, width: 40, color: AppColors.surfaceAlt),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
