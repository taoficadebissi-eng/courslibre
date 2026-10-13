import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:courslibre/core/constants/app_colors.dart';
import 'package:courslibre/core/config/app_config.dart';
import 'package:courslibre/core/widgets/wave_clipper.dart';
import 'package:courslibre/features/cours_publics/providers/cours_publics_provider.dart';
import 'package:courslibre/features/cours_publics/widgets/modern_top_bar.dart';
import 'package:courslibre/features/cours_publics/widgets/modern_filter_bar.dart';
import 'package:courslibre/features/cours_publics/widgets/modern_course_card.dart';
import 'package:courslibre/features/cours_publics/widgets/skeleton_carte_widget.dart';
import 'package:courslibre/features/cours_publics/widgets/footer_widget.dart';
import 'package:courslibre/features/cours_publics/providers/visiteur_provider.dart';
import 'package:courslibre/features/cours_publics/screens/detail_cours_screen.dart';

class AccueilPublicScreen extends ConsumerStatefulWidget {
  const AccueilPublicScreen({super.key});

  @override
  ConsumerState<AccueilPublicScreen> createState() =>
      _AccueilPublicScreenState();
}

class _AccueilPublicScreenState extends ConsumerState<AccueilPublicScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Comptage 1x/jour/appareil : voir VisiteurService pour la logique de
    // déduplication (shared_preferences) et la garde silencieuse en cas
    // d'échec réseau/règles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visiteurServiceProvider).enregistrerVisiteSiNecessaire();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coursAsync = ref.watch(coursPublicsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(refreshCoursProvider)(),
        edgeOffset: 120,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ========================================================
            // 1. HERO — typo + couleur portent le hero (plus de photo ni
            // de voile sombre), vague décorative en bas.
            // ========================================================
            SliverToBoxAdapter(
              child: ClipPath(
                clipper: const WaveClipper(),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.brandGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 60, bottom: 96),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 12,
                        top: 4,
                        child: Transform.rotate(
                          angle: 0.16,
                          child: Container(
                            width: 78,
                            height: 78,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1.4,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Text(
                              '100%\nGratuit',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barre supérieure intégrée (avec bouton rafraîchir)
                          ModernTopBar(
                            onSearchChanged: (value) => setState(
                              () => _searchQuery = value.toLowerCase(),
                            ),
                            onFilterPressed: () {},
                            onConnexionPressed: ouvrirGestionFormation,
                            onRefreshPressed: () =>
                                ref.read(refreshCoursProvider)(),
                          ),
                          const SizedBox(height: 40),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Boostez vos compétences\ngrâce à des cours gratuits',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Découvrez des centaines de cours gratuits, sélectionnés pour vous.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDark.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.toLowerCase();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un cours...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.surfaceAlt,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.tune_rounded,
                                        color: AppColors.textPrimary,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Filtrer',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ========================================================
            // 2. BARRE DE FILTRES PAR CATÉGORIES
            // ========================================================
            coursAsync.when(
              data: (cours) {
                // Conversion défensive : toString() garantit qu'on ne
                // transmet jamais autre chose qu'une String à
                // ModernFilterBar, quel que soit le type réel stocké
                // côté Firestore/modèle.
                final categories = cours
                    .map((c) => c.categorie.toString())
                    .where((c) => c.trim().isNotEmpty)
                    .toSet()
                    .toList();
                return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ModernFilterBar(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                );
              },
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox(height: 70)),
              error: (error, stack) => const SliverToBoxAdapter(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ========================================================
            // 3. LISTE DES CARTES DE COURS MODERNES
            // ========================================================
            coursAsync.when(
              data: (cours) {
                final filteredCours = cours.where((c) {
                  final titre = c.titre.toString().toLowerCase();
                  final fournisseur = c.fournisseur
                      .toString()
                      .toLowerCase();
                  final categorie = c.categorie.toString();

                  final matchesSearch =
                      titre.contains(_searchQuery) ||
                      fournisseur.contains(_searchQuery);
                  final matchesCategory =
                      _selectedCategory == null ||
                      categorie == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredCours.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: Text(
                          'Aucun cours trouvé',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final unCours = filteredCours[index];
                      return ModernCourseCard(
                        cours: unCours,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailCoursScreen(cours: unCours),
                            ),
                          );
                        },
                      );
                    }, childCount: filteredCours.length),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: SkeletonCarteWidget(),
                    ),
                    childCount: 3,
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Erreur de récupération : $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // ========================================================
            // 4. FOOTER
            // ========================================================
            const SliverToBoxAdapter(child: FooterWidget()),
          ],
        ),
      ),
    );
  }
}
