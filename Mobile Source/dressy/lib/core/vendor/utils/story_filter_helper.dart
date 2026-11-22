import 'package:flutter/material.dart';

class StoryFilterPreset {
  const StoryFilterPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.matrix,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<double> matrix;
}

class StoryFilterHelper {
  const StoryFilterHelper._();

  static const List<double> matrixOriginal = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> matrixDressyGlow = <double>[
    1.12, 0.05, 0.02, 0, 12,
    0.03, 1.05, 0.02, 0, 6,
    0.02, 0.04, 0.94, 0, -4,
    0,    0,    0,    1, 0,
  ];

  static const List<double> matrixParisianChic = <double>[
    0.95, 0.08, 0.08, 0, 16,
    0.06, 0.94, 0.06, 0, 14,
    0.05, 0.06, 0.88, 0, 8,
    0,    0,    0,    1, 0,
  ];

  static const List<double> matrixGoldenHour = <double>[
    1.20, 0.05, 0.00, 0, 18,
    0.05, 1.10, 0.00, 0, 10,
    0.00, 0.04, 0.82, 0, -12,
    0,    0,    0,    1, 0,
  ];

  static const List<double> matrixNoirBlanc = <double>[
    0.33, 0.59, 0.11, 0, -10,
    0.33, 0.59, 0.11, 0, -10,
    0.33, 0.59, 0.11, 0, -10,
    0,    0,    0,    1, 0,
  ];

  static const List<double> matrixVividPop = <double>[
    1.25, -0.12, -0.05, 0, 2,
    -0.08, 1.25, -0.05, 0, 2,
    -0.08, -0.08, 1.25, 0, 2,
    0,     0,     0,    1, 0,
  ];

  static const List<StoryFilterPreset> presets = <StoryFilterPreset>[
    StoryFilterPreset(
      id: 'original',
      name: 'Original',
      subtitle: 'Naturel',
      matrix: matrixOriginal,
    ),
    StoryFilterPreset(
      id: 'dressy_glow',
      name: 'Dressy Glow',
      subtitle: 'Coral Warm',
      matrix: matrixDressyGlow,
    ),
    StoryFilterPreset(
      id: 'parisian_chic',
      name: 'Parisian Chic',
      subtitle: 'Éditorial',
      matrix: matrixParisianChic,
    ),
    StoryFilterPreset(
      id: 'golden_hour',
      name: 'Golden Hour',
      subtitle: 'Doré',
      matrix: matrixGoldenHour,
    ),
    StoryFilterPreset(
      id: 'noir_blanc',
      name: 'Noir & Blanc',
      subtitle: 'Classique',
      matrix: matrixNoirBlanc,
    ),
    StoryFilterPreset(
      id: 'vivid_pop',
      name: 'Vivid Pop',
      subtitle: 'Éclat',
      matrix: matrixVividPop,
    ),
  ];

  static List<double> getMatrix(String? presetId) {
    if (presetId == null || presetId.isEmpty) {
      return matrixOriginal;
    }
    for (final StoryFilterPreset p in presets) {
      if (p.id == presetId) {
        return p.matrix;
      }
    }
    return matrixOriginal;
  }

  static ColorFilter getColorFilter(String? presetId) {
    return ColorFilter.matrix(getMatrix(presetId));
  }
}
