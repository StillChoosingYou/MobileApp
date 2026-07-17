import 'package:flutter_test/flutter_test.dart';
import 'package:pgpc_campus_app/core/utils/gpa_calculator.dart';
import 'package:pgpc_campus_app/models/academic_models.dart';

void main() {
  group('GpaCalculator', () {
    test('returns null for an empty grade list', () {
      expect(GpaCalculator.compute([]), isNull);
    });

    test('returns null when every grade is incomplete', () {
      const grades = [
        Grade(subjectCode: 'IT101', subjectTitle: 'Intro', units: 3, term: 'T1', isIncomplete: true),
      ];
      expect(GpaCalculator.compute(grades), isNull);
    });

    test('computes a simple unit-weighted average', () {
      const grades = [
        Grade(subjectCode: 'A', subjectTitle: 'A', units: 3, term: 'T1', numericGrade: 1.0),
        Grade(subjectCode: 'B', subjectTitle: 'B', units: 3, term: 'T1', numericGrade: 2.0),
      ];
      // (1.0*3 + 2.0*3) / 6 = 1.5
      expect(GpaCalculator.compute(grades), closeTo(1.5, 0.0001));
    });

    test('weights subjects with more units more heavily', () {
      const grades = [
        Grade(subjectCode: 'A', subjectTitle: 'A', units: 1, term: 'T1', numericGrade: 1.0),
        Grade(subjectCode: 'B', subjectTitle: 'B', units: 5, term: 'T1', numericGrade: 3.0),
      ];
      // (1.0*1 + 3.0*5) / 6 = 2.6667
      expect(GpaCalculator.compute(grades), closeTo(2.6667, 0.001));
    });

    test('skips incomplete grades when averaging', () {
      const grades = [
        Grade(subjectCode: 'A', subjectTitle: 'A', units: 3, term: 'T1', numericGrade: 1.0),
        Grade(subjectCode: 'B', subjectTitle: 'B', units: 3, term: 'T1', isIncomplete: true),
      ];
      expect(GpaCalculator.compute(grades), closeTo(1.0, 0.0001));
    });

    test('computeForTerm filters by term first', () {
      const grades = [
        Grade(subjectCode: 'A', subjectTitle: 'A', units: 3, term: 'T1', numericGrade: 1.0),
        Grade(subjectCode: 'B', subjectTitle: 'B', units: 3, term: 'T2', numericGrade: 5.0),
      ];
      expect(GpaCalculator.computeForTerm(grades, 'T1'), closeTo(1.0, 0.0001));
    });
  });
}
