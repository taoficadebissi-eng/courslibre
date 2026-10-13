import 'package:flutter/material.dart';
import '../models/cours_gratuit_model.dart';

Color getCouleurNiveau(NiveauCours niveau) {
  switch (niveau) {
    case NiveauCours.debutant:
      return const Color(0xFF22C55E);
    case NiveauCours.intermediaire:
      return const Color(0xFFF59E0B);
    case NiveauCours.avance:
      return const Color(0xFF8B5CF6);
  }
}