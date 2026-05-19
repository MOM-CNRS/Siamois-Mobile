import 'package:flutter/material.dart';

/// Palette Siamois — "Journal de Fouille" : tons chauds crème + terre cuite.
abstract final class SiamoisColors {
  // Bleu archéologique profond
  static const primary = Color(0xFF1A4D63);
  static const primaryDark = Color(0xFF0E3045);
  static const primaryLight = Color(0xFF2A6B8A);
  static const primaryContainer = Color(0xFFC8DDE8);

  // Terre cuite / ambre — couleur des fouilles
  static const accent = Color(0xFFC4752B);
  static const accentLight = Color(0xFFDB9A5A);
  static const accentMuted = Color(0xFFF0E2CF);

  // Surfaces crème chaudes (vs gris froid)
  static const surface = Color(0xFFF5F1EC);
  static const surfaceCard = Color(0xFFFDFAF7);
  static const surfaceMuted = Color(0xFFEDE8E0);

  // Bordures tons chauds
  static const border = Color(0xFFDDD6CB);
  static const borderSubtle = Color(0xFFE8E2DA);

  // Texte
  static const textPrimary = Color(0xFF1A2230);
  static const textSecondary = Color(0xFF5A6472);
  static const textTertiary = Color(0xFF8B9199);

  // États sémantiques
  static const success = Color(0xFF2D6A4F);
  static const error = Color(0xFFB3261E);
  static const warning = Color(0xFFB45309);

  static const shadow = Color(0x161A2230);
}
