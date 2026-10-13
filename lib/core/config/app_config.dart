import 'package:url_launcher/url_launcher.dart';

/// Adresse de l'application Gestion Formation (projet séparé).
/// Les liens "Connexion" / "Gestion Formation" de la vitrine y mènent.
const String urlGestionFormation = 'https://gestion-de-formation-5b049.web.app';

/// E-mail du super-admin de CoursLibre. Le compte doit exister dans Firebase
/// Auth avec l'e-mail vérifié : les règles Firestore appliquent la même
/// vérification, cette constante ne sert qu'à afficher/masquer l'interface.
const String superAdminEmail = 'taoficadebissi@gmail.com';

/// Ouvre Gestion Formation dans un nouvel onglet. Pas de `canLaunchUrl`
/// avant : sur le web il casse la chaîne de geste utilisateur.
Future<void> ouvrirGestionFormation() async {
  await launchUrl(
    Uri.parse(urlGestionFormation),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}
