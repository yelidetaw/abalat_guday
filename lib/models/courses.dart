// This file acts as a single source of truth for the entire app's curriculum.

// =========================================================================
// THE CURRICULUM MAP
// Defines which courses belong to which spiritual grade.
// =========================================================================
final Map<String, List<String>> spiritualGradeCurriculum = {
  // Example for non-grade classes
  // The structured Grade 1-12 curriculum
  'Grade 1': [
    'Basic Faith',
    'Old Testament Stories',
    'Saints Introduction',
    'Church Manners',
    'Simple Chants',
    'Iconography Basics',
  ],
  'Grade 2': [
    'The Creed',
    'New Testament Stories',
    'Lives of Martyrs',
    'Prayer Basics',
    'Intermediate Chants',
    'Feast Days 101',
  ],
  'Grade 3': [
    'The Sacraments',
    'Journeys of St. Paul',
    'Ethiopian Saints I',
    'Fasting Rules',
    'Advanced Chants',
    'Church Symbolism',
  ],
  // ... continue for Grade 4 through 12, defining the 6 courses for each.
  // Add all 12 grades here for a complete system.
  'Grade 4': [
    'Course 4A',
    'Course 4B',
    'Course 4C',
    'Course 4D',
    'Course 4E',
    'Course 4F',
  ],
  'Grade 5': [
    'Course 5A',
    'Course 5B',
    'Course 5C',
    'Course 5D',
    'Course 5E',
    'Course 5F',
  ],
  'Grade 6': [
    'Course 6A',
    'Course 6B',
    'Course 6C',
    'Course 6D',
    'Course 6E',
    'Course 6F',
  ],
  'Grade 7': [
    'Course 7A',
    'Course 7B',
    'Course 7C',
    'Course 7D',
    'Course 7E',
    'Course 7F',
  ],
  'Grade 8': [
    'Course 8A',
    'Course 8B',
    'Course 8C',
    'Course 8D',
    'Course 8E',
    'Course 8F',
  ],
  'Grade 9': [
    'Course 9A',
    'Course 9B',
    'Course 9C',
    'Course 9D',
    'Course 9E',
    'Course 9F',
  ],
  'Grade 10': [
    'Course 10A',
    'Course 10B',
    'Course 10C',
    'Course 10D',
    'Course 10E',
    'Course 10F',
  ],
  'Grade 11': [
    'Course 11A',
    'Course 11B',
    'Course 11C',
    'Course 11D',
    'Course 11E',
    'Course 11F',
  ],
  'Grade 12': [
    'Course 12A',
    'Course 12B',
    'Course 12C',
    'Course 12D',
    'Course 12E',
    'Course 12F',
  ],

  'Other': [], // 'Other' has no predefined courses
};

// The list of spiritual classes is now dynamically generated from the curriculum keys.
// This ensures the dropdowns always match the defined curriculum.
final List<String> spiritualClassOptions =
    spiritualGradeCurriculum.keys.toList();

// The list of semesters remains the same.
const List<String> semesterOptions = ['1st Semester', '2nd Semester'];
