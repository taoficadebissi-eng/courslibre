import 'package:flutter/material.dart';

class ModernFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const ModernFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  // Accepte dynamic pour ne JAMAIS planter, même si une valeur non-String
  // remonte depuis Firestore (champ absent, mal typé, etc.)
  IconData _getCategoryIcon(dynamic category) {
    final catLower = (category ?? '').toString().toLowerCase();
    if (catLower.contains('code') || catLower.contains('dev')) {
      return Icons.code_rounded;
    } else if (catLower.contains('design') || catLower.contains('art')) {
      return Icons.palette_rounded;
    } else if (catLower.contains('market')) {
      return Icons.campaign_rounded;
    } else if (catLower.contains('lang')) {
      return Icons.translate_rounded;
    } else if (catLower.contains('biz') || catLower.contains('business')) {
      return Icons.business_center_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // On nettoie la liste ici aussi : chaque entrée passe par toString()
    // et les entrées vides sont écartées. Ceinture + bretelles avec le
    // nettoyage déjà fait côté AccueilPublicScreen.
    final safeCategories = categories
        .map((c) => c.toString())
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: safeCategories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : safeCategories[index - 1];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onCategorySelected(category),
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAll
                          ? Icons.grid_view_rounded
                          : _getCategoryIcon(category),
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAll ? 'Tous' : (category ?? ''),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
