import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Nouvelle identité : fond crème/sable, primaire orange profond (décliné
  // en dégradé "multicolore" du brûlé à l'ambre), encre bleu nuit pour le
  // texte, accent vert feuille comme unique couleur de contraste. Rupture
  // volontaire avec l'ancienne palette bleu/teal, jugée trop corporate.
  static const Color primary = Color(0xFFC6511B);
  static const Color primaryLight = Color(0xFFE8792F);
  static const Color primaryDark = Color(0xFF973D12);

  static const Color secondary = Color(0xFF2F7D4F);
  static const Color secondaryLight = Color(0xFF4CA873);
  static const Color secondaryDark = Color(0xFF1F5936);

  // Vert plus vif que "secondary", réservé aux CTA/badges qui doivent se
  // détacher franchement de l'orange.
  static const Color accent = Color(0xFF3FA968);
  static const Color accentLight = Color(0xFF6BC98D);

  static const Color roleAdmin = Color(0xFF8C3B4A);
  static const Color roleFormateur = Color(0xFFC6511B);
  static const Color roleApprenant = Color(0xFF2F7D4F);

  static const Color background = Color(0xFFF7ECD9);
  static const Color surface = Color(0xFFFFFCF6);
  static const Color surfaceAlt = Color(0xFFF1E4C8);
  static const Color textPrimary = Color(0xFF16223D);
  static const Color textSecondary = Color(0xFF5C6478);
  static const Color border = Color(0xFFE6D8B8);

  static const Color success = Color(0xFF2F7D4F);
  static const Color warning = Color(0xFFD69E2E);
  static const Color error = Color(0xFFB3261E);
  static const Color info = Color(0xFF2B5FA8);

  // Dégradé encre (bleu nuit) — fonds sombres (login, splash)
  static const Color darkGradientStart = Color(0xFF16223D);
  static const Color darkGradientMid = Color(0xFF1B2C4D);
  static const Color darkGradientEnd = Color(0xFF22375F);

  // Dégradé de marque "multicolore" : brûlé -> orange -> ambre. Réutilisable
  // pour hero, boutons mis en avant, en-têtes.
  static const List<Color> brandGradient = [primaryDark, primary, Color(0xFFF2A93C)];
}
