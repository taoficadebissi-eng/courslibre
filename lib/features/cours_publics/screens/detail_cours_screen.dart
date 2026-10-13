import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cours_gratuit_model.dart';
import '../utils/couleurs_niveau.dart';
import '../../../widgets/blurred_toast.dart';

class DetailCoursScreen extends StatefulWidget {
  final CoursGratuit cours;

  const DetailCoursScreen({super.key, required this.cours});

  @override
  State<DetailCoursScreen> createState() => _DetailCoursScreenState();
}

class _DetailCoursScreenState extends State<DetailCoursScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeBanner;
  late final Animation<Offset> _slideBanner;
  late final Animation<double> _fadeInfo;
  late final Animation<Offset> _slideInfo;
  late final Animation<double> _fadeDescription;
  late final Animation<Offset> _slideDescription;
  late final Animation<double> _fadeButton;
  late final Animation<Offset> _slideButton;

  bool _hoverButton = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeBanner = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _slideBanner = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeBanner);

    _fadeInfo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.70, curve: Curves.easeOut),
    );
    _slideInfo = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeInfo);

    _fadeDescription = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOut),
    );
    _slideDescription = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeDescription);

    _fadeButton = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _slideButton = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeButton);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ouvrirLien(BuildContext context) async {
    final uri = Uri.parse(widget.cours.lienCours);
    try {
      // Important (web) : ne PAS faire de `await canLaunchUrl(...)` avant.
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!ok && context.mounted) {
        BlurredToast.show(
          context,
          'Impossible d\'ouvrir ce lien',
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      if (context.mounted) {
        BlurredToast.show(context, 'Erreur : $e', icon: Icons.error_outline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cours = widget.cours;
    final couleurNiveau = getCouleurNiveau(cours.niveau);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF1E293B),
              ),
              tooltip: 'Retour',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Détails du cours',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // 1. BANNIÈRE : photo du cours (ou dégradé de secours)
                  // ========================================================
                  FadeTransition(
                    opacity: _fadeBanner,
                    child: SlideTransition(
                      position: _slideBanner,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (cours.lienImage != null &&
                                  cours.lienImage!.trim().isNotEmpty)
                                Image.network(
                                  cours.lienImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      _bannerFallback(couleurNiveau),
                                )
                              else
                                _bannerFallback(couleurNiveau),

                              // Voile dégradé pour la lisibilité du texte
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xCC0F172A),
                                    ],
                                  ),
                                ),
                              ),

                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cours.titre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cours.fournisseur,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ========================================================
                  // 2. COMPOSANTS CLÉS / INFORMATIONS EN GRILLE
                  // ========================================================
                  FadeTransition(
                    opacity: _fadeInfo,
                    child: SlideTransition(
                      position: _slideInfo,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.bar_chart_rounded,
                              'Niveau',
                              cours.niveau.label,
                              couleurNiveau,
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            if (cours.duree != null) ...[
                              _buildInfoRow(
                                Icons.schedule_rounded,
                                'Durée estimée',
                                cours.duree!,
                                const Color(0xFF475569),
                              ),
                              const Divider(
                                height: 24,
                                color: Color(0xFFF1F5F9),
                              ),
                            ],
                            _buildInfoRow(
                              Icons.translate_rounded,
                              'Langue d\'apprentissage',
                              cours.langue,
                              const Color(0xFF475569),
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _buildInfoRow(
                              Icons.verified_outlined,
                              'Certification',
                              cours.certificatDisponible
                                  ? (cours.certificatPayant
                                        ? 'Option payante'
                                        : 'Gratuite incluse')
                                  : 'Non disponible',
                              cours.certificatDisponible
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ========================================================
                  // 3. SECTION "À PROPOS"
                  // ========================================================
                  FadeTransition(
                    opacity: _fadeDescription,
                    child: SlideTransition(
                      position: _slideDescription,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'À propos de ce cours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.02),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              cours.descriptionDetaillee.isNotEmpty
                                  ? cours.descriptionDetaillee
                                  : cours.description,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ========================================================
                  // 4. ACTION PRINCIPALE : ACCÉDER AU COURS
                  // ========================================================
                  FadeTransition(
                    opacity: _fadeButton,
                    child: SlideTransition(
                      position: _slideButton,
                      child: Column(
                        children: [
                          MouseRegion(
                            onEnter: (_) => setState(() => _hoverButton = true),
                            onExit: (_) => setState(() => _hoverButton = false),
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              width: double.infinity,
                              height: 56,
                              transform: Matrix4.translationValues(
                                0,
                                _hoverButton ? -3 : 0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF0F766E),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E3A8A).withValues(
                                      alpha: _hoverButton ? 0.35 : 0.18,
                                    ),
                                    blurRadius: _hoverButton ? 24 : 12,
                                    offset: Offset(0, _hoverButton ? 10 : 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _ouvrirLien(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Accéder au cours',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedSlide(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        offset: _hoverButton
                                            ? const Offset(0.3, 0)
                                            : Offset.zero,
                                        child: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ouvre le site officiel dans un nouvel onglet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Bannière de secours quand le cours n'a pas d'image : dégradé teinté par
  // la couleur du niveau, cohérent avec le fallback des cartes de la liste.
  Widget _bannerFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.85),
            const Color(0xFF1E3A8A).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_outlined, size: 48, color: Colors.white),
      ),
    );
  }

  // Widget utilitaire pour générer des lignes d'information propres
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String val,
    Color highlightColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: highlightColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlightColor,
            ),
          ),
        ),
      ],
    );
  }
}
