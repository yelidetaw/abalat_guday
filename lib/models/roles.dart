// lib/models/roles.dart

enum AppDepartment {
  // ... (no changes here)
  temehertKefel('ትምህርት ክፍል'),
  mezmurKefel('መዝሙር ክፍል'),
  kinetibebKefel('ኪነጥበብ ክፍል'),
  lematKefel('ልማት ክፍል'),
  kuteterKefel('ቁጥጥር ክፍል'),
  mebanaMestenagedo('መብዓና መስተነግዶ'),
  abalatGuday('አባላት ጉዳይ'),
  hesabKefel('ሂሳብ ክፍል'),
  tsehfetBet('ፅህፈት ቤት'),
  genunetKefel('ግንኙነት ክፍል'),
  betemetsahftKefel('ቤተ መጻሕፍት ክፍል'),
  nebretKefel('ንብረት ክፍል'),
  other('Other');

  final String name;
  const AppDepartment(this.name);

  static AppDepartment fromString(String name) {
    return AppDepartment.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppDepartment.other,
    );
  }
}

enum AppPosition {
  // English Identifier ('Amharic Display Name')

  // Office Roles
  sebsabi('ሰብሳቢ'), // Chairperson
  sebsabiMeketel('ምክትል ሰብሳቢ'), // Vice Chairperson
  tsehafi('ፀሀፊ'), // Secretary

  // Department Leadership Roles
  neus('ንዑስ'), // Sub-committee leader
  hailafi('ኃላፊ'), // --- ADDED: Responsible Head (often paired with neus) ---

  // General Roles
  abal('አባል'), // General Member
  temporaryAccess('ተጠባባቂ'), // Stand-in / Temporary
  other('Other');

  final String name;
  const AppPosition(this.name);

  // --- ADDED: Helper getter for easier checks ---
  bool get isLeader => this == AppPosition.neus || this == AppPosition.hailafi;

  static AppPosition fromString(String name) {
    return AppPosition.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppPosition.abal,
    );
  }
}

// This function provides the list of allowed positions for a given department
List<AppPosition> positionsForDepartment(AppDepartment department) {
  if (department == AppDepartment.tsehfetBet) {
    // Special roles ONLY for the Office department
    return [
      AppPosition.sebsabi,
      AppPosition.sebsabiMeketel,
      AppPosition.tsehafi,
      AppPosition.other,
    ];
  } else if (department == AppDepartment.hesabKefel) {
    // Finance department has no sub-committee, only members
    return [AppPosition.abal, AppPosition.other];
  } else {
    // --- UPDATED: All other departments can have these leadership roles ---
    return [
      AppPosition.neus,
      AppPosition.hailafi,
      AppPosition.abal,
      AppPosition.other
    ];
  }
}
