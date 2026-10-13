import 'package:flutter/material.dart';

class ModernCourseCard extends StatefulWidget {
  final dynamic cours;
  final VoidCallback onTap;

  const ModernCourseCard({super.key, required this.cours, required this.onTap});

  @override
  State<ModernCourseCard> createState() => _ModernCourseCardState();
}

class _ModernCourseCardState extends State<ModernCourseCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cours = widget.cours;

    String titre = 'Sans titre';
    String fournisseur = 'Inconnu';
    String description = '';
    String niveau = 'Débutant';
    String duree = 'Durée à consulter';
    bool aCertificat = false;
    String? lienImage;

    try {
      titre = (cours.titre ?? 'Sans titre').toString();
    } catch (_) {}
    try {
      fournisseur = (cours.fournisseur ?? 'Inconnu').toString();
    } catch (_) {}
    try {
      description = (cours.description ?? cours.descriptionCourte ?? '')
          .toString();
    } catch (_) {}
    try {
      // cours.niveau peut être un enum (NiveauCours) et non une String :
      // on force toujours le passage par toString() pour éviter tout crash
      // du type "method not found: toLowerCase" en build release.
      final rawNiveau = cours.niveau;
      if (rawNiveau != null) {
        try {
          niveau = (rawNiveau.libelle ?? rawNiveau.label ?? rawNiveau)
              .toString();
        } catch (_) {
          niveau = rawNiveau.toString();
        }
      }
    } catch (_) {}
    try {
      duree = (cours.duree ?? 'Durée à consulter').toString();
    } catch (_) {}
    try {
      aCertificat = cours.aCertificat ?? cours.certificat ?? true;
    } catch (_) {}
    try {
      final rawImage = cours.lienImage;
      if (rawImage != null && rawImage.toString().trim().isNotEmpty) {
        lienImage = rawImage.toString();
      }
    } catch (_) {}

    Color niveauColor = const Color(0xFF10B981);
    final niveauLower = niveau.toLowerCase();
    if (niveauLower.contains('inter')) {
      niveauColor = const Color(0xFFF59E0B);
    } else if (niveauLower.contains('avan')) {
      niveauColor = const Color(0xFF6366F1);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 18),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF0F172A,
              ).withValues(alpha: _hover ? 0.12 : 0.05),
              blurRadius: _hover ? 24 : 12,
              offset: Offset(0, _hover ? 12 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================
                // EN-TÊTE : image du cours ou dégradé de secours
                // ============================================
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (lienImage != null)
                          Image.network(
                            lienImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                _headerFallback(niveauColor),
                          )
                        else
                          _headerFallback(niveauColor),

                        // Voile dégradé bas pour la lisibilité du badge fournisseur
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Badge certificat (haut droite)
                        if (aCertificat)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Certificat gratuit',
                                    style: TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Fournisseur en overlay bas gauche
                        Positioned(
                          left: 14,
                          bottom: 10,
                          child: Text(
                            fournisseur,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ============================================
                // CORPS DE LA CARTE
                // ============================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: niveauColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              niveau,
                              style: TextStyle(
                                color: niveauColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              duree,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _hover
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(
                                      0xFF1E3A8A,
                                    ).withValues(alpha: 0.0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Voir le cours',
                                  style: TextStyle(
                                    color: _hover
                                        ? Colors.white
                                        : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: _hover
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // En-tête de secours quand aucune image n'est disponible pour le cours :
  // dégradé teinté par la couleur du niveau, avec icône centrale.
  Widget _headerFallback(Color accent) {
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
        child: Icon(Icons.school_outlined, size: 40, color: Colors.white),
      ),
    );
  }
}
