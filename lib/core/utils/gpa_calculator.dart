import '../../models/academic_models.dart';

/// Weighted average of (grade × units) / total units, skipping subjects
/// that are marked incomplete or have no recorded grade yet.
///
/// Works with whichever numeric scale the grades are recorded in (PGPC's
/// mock data uses the 1.00-highest / 5.00-failing scale common across
/// Philippine colleges) — the math itself is scale-agnostic.
class GpaCalculator {
  GpaCalculator._();

  static double? compute(List<Grade> grades) {
    final graded = grades.where((g) => !g.isIncomplete && g.numericGrade != null).toList();
    if (graded.isEmpty) return null;

    final totalUnits = graded.fold<double>(0, (sum, g) => sum + g.units);
    if (totalUnits == 0) return null;

    final weightedSum = graded.fold<double>(
      0,
      (sum, g) => sum + (g.numericGrade! * g.units),
    );

    return weightedSum / totalUnits;
  }

  /// Same computation, restricted to a single term.
  static double? computeForTerm(List<Grade> grades, String term) {
    return compute(grades.where((g) => g.term == term).toList());
  }
}
