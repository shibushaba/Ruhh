import 'package:flutter/material.dart';

/// Saturated accent palette for custom categories (rotation).
const movieCategoryPalette = <Color>[
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFFFACC15),
  Color(0xFF22C55E),
  Color(0xFF3B82F6),
  Color(0xFF7C3AED),
  Color(0xFFF97316),
  Color(0xFF06B6D4),
  Color(0xFFA855F7),
  Color(0xFF6B7280),
];

const defaultMovieCategoryNames = <String>[
  'Thriller',
  'Romance',
  'Comedy',
  'Action',
  'Drama',
  'Horror',
  'Sci-Fi',
  'Documentary',
  'Anime',
  'Other',
];

/// Fixed color per default genre (seed + display fallback).
const defaultMovieCategoryColors = <Color>[
  Color(0xFF7C3AED), // Thriller
  Color(0xFFEC4899), // Romance
  Color(0xFFFACC15), // Comedy
  Color(0xFFEF4444), // Action
  Color(0xFF3B82F6), // Drama
  Color(0xFFEA580C), // Horror
  Color(0xFF06B6D4), // Sci-Fi
  Color(0xFF22C55E), // Documentary
  Color(0xFFA855F7), // Anime
  Color(0xFF6B7280), // Other
];

Color movieCategoryColorForName(String name) {
  final idx = defaultMovieCategoryNames.indexOf(name);
  if (idx >= 0) return defaultMovieCategoryColors[idx];
  return movieCategoryPalette[name.hashCode.abs() % movieCategoryPalette.length];
}

String movieCategoryEmojiForName(String name) {
  switch (name) {
    case 'Thriller':
      return '😱';
    case 'Romance':
      return '💕';
    case 'Comedy':
      return '😂';
    case 'Action':
      return '💥';
    case 'Drama':
      return '🎭';
    case 'Horror':
      return '👻';
    case 'Sci-Fi':
      return '🚀';
    case 'Documentary':
      return '📽️';
    case 'Anime':
      return '🎌';
    case 'Other':
      return '🎬';
    default:
      return '🎬';
  }
}
