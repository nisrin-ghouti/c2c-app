/// The predefined selectable lists an admin can curate (`option_lists.list_type`
/// in Supabase) — faculties, hobbies, interests, etc. shown as dropdown/chip
/// choices throughout the app instead of being hardcoded in Dart.
enum OptionListType {
  faculty,
  fieldOfStudy,
  hobby,
  interest,
  language,
  degree,
  eventCategory,
  benefitCategory,
  campusLocation;

  String get dbValue => switch (this) {
    OptionListType.faculty => 'faculty',
    OptionListType.fieldOfStudy => 'field_of_study',
    OptionListType.hobby => 'hobby',
    OptionListType.interest => 'interest',
    OptionListType.language => 'language',
    OptionListType.degree => 'degree',
    OptionListType.eventCategory => 'event_category',
    OptionListType.benefitCategory => 'benefit_category',
    OptionListType.campusLocation => 'campus_location',
  };

  static OptionListType fromDbValue(String value) => switch (value) {
    'faculty' => OptionListType.faculty,
    'field_of_study' => OptionListType.fieldOfStudy,
    'hobby' => OptionListType.hobby,
    'interest' => OptionListType.interest,
    'language' => OptionListType.language,
    'degree' => OptionListType.degree,
    'event_category' => OptionListType.eventCategory,
    'benefit_category' => OptionListType.benefitCategory,
    'campus_location' => OptionListType.campusLocation,
    _ => throw ArgumentError('Unknown option list type: $value'),
  };
}
