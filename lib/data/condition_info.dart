/// Maps the trained model's class keys (from class_names.json, snake_case
/// folder names from the training dataset) to display text.
///
/// Keep this in sync with the backend's mock condition bank
/// (pupcheck_backend/app/models/prediction_service.py) — same five
/// conditions, same severities, same descriptions — so results look
/// identical to the person regardless of whether a given scan was
/// predicted on-device or (before a model existed) by the backend's
/// mock predictor.
class ConditionInfo {
  final String displayName;
  final String severity; // 'healthy' | 'mild' | 'moderate' | 'severe'
  final String description;

  const ConditionInfo({required this.displayName, required this.severity, required this.description});
}

const Map<String, ConditionInfo> kConditionInfo = {
  'healthy': ConditionInfo(
    displayName: 'Healthy Skin',
    severity: 'healthy',
    description:
        'No obvious signs of the skin conditions covered by PupCheck.',
  ),

  'bacterial_dermatosis': ConditionInfo(
    displayName: 'Bacterial Dermatosis',
    severity: 'moderate',
    description:
        'A bacterial skin infection that may cause redness, bumps, pustules, crusting, and itching. '
        'Often develops after scratching, allergies, wounds, or other skin problems. '
        'Keep the area clean and dry, prevent licking or scratching, and seek veterinary care.',
  ),

  'demodicosis': ConditionInfo(
    displayName: 'Demodicosis',
    severity: 'moderate',
    description:
        'A condition caused by an overgrowth of Demodex mites, often causing hair loss, redness, '
        'scaling, or crusting. Keep the skin clean and prevent scratching or licking. '
        'Veterinary examination is recommended for confirmation and treatment.',
  ),

  'ringworm': ConditionInfo(
    displayName: 'Ringworm',
    severity: 'moderate',
    description:
        'A contagious fungal infection that commonly causes circular hair loss, scaling, and redness. '
        'Limit contact with other pets, wash your hands after handling, and seek veterinary care.',
  ),

  'fungal_infection': ConditionInfo(
    displayName: 'Fungal Infection',
    severity: 'moderate',
    description:
        'A fungal skin infection that may cause hair loss, redness, scaling, or crusting. '
        'Keep affected areas clean and dry and avoid sharing bedding or grooming tools. '
        'Veterinary confirmation is recommended.',
  ),

  'hypersensitivity_dermatitis': ConditionInfo(
    displayName: 'Hypersensitivity Dermatitis',
    severity: 'moderate',
    description:
        'An allergic skin reaction that commonly causes itching, redness, and irritation. '
        'Common triggers include fleas, food, or environmental allergens. '
        'Avoid suspected triggers, prevent excessive scratching, and consult a veterinarian.',
  ),
};

ConditionInfo conditionInfoFor(String classKey) =>
    kConditionInfo[classKey] ??
    const ConditionInfo(displayName: 'Unknown', severity: 'moderate', description: 'Unrecognized condition.');
