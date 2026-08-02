import '../../models/academic_models.dart';
import '../../models/financial_models.dart';

/// Rule-based logic shared by every [StudentRepository] implementation
/// (mock, REST, and — if you build it — Firebase) so `askAssistant` and
/// `recommendElectives` behave identically no matter which backend is
/// active. Each implementation is responsible only for fetching the data
/// these functions need; the actual FAQ/recommendation logic lives here
/// exactly once.
///
/// This is a simple keyword-matched responder, not a real LLM — swap
/// [answerQuestion]'s body for a real API call (the Claude API works well
/// here) whenever you're ready to move past canned answers.
class AssistantRules {
  AssistantRules._();

  static String answerQuestion({
    required String question,
    required String term,
    required List<Section> enrolledSections,
    required TuitionLedger ledger,
  }) {
    final q = question.toLowerCase();

    if (q.contains('schedule')) {
      if (enrolledSections.isEmpty) {
        return "I don't see any enrolled sections yet for this term. Once enrollment is "
            'approved, ask me again and I\'ll list your schedule.';
      }
      final lines = enrolledSections
          .map((s) => '• ${s.subjectCode} (${s.sectionLabel}) — ${s.dayPattern} '
              '${s.startTime}–${s.endTime}, ${s.room}')
          .join('\n');
      return 'Here\'s your current schedule:\n$lines';
    }

    if (q.contains('tuition') || q.contains('balance') || q.contains('payment')) {
      return 'Your outstanding balance for $term is '
          '₱${ledger.balance.toStringAsFixed(2)}. You can settle this through the Cashier '
          'module or Tuition & Wallet screen.';
    }

    if (q.contains('requirement') || q.contains('enroll')) {
      return 'For enrollment you\'ll generally need: your Certificate of Registration from '
          'last term, a cleared account with Accounting, and — for new students — your '
          'Form 138 / Transcript of Records. Submit these through Smart Enrollment or bring '
          'them to the Registrar.';
    }

    if (q.contains('polic')) {
      return 'Policies are posted under Announcements and the Student Handbook. Tell me which '
          "one you're asking about (attendance, grading, clearance) and I'll point you to the "
          'right office.';
    }

    return 'I can help with class schedules, requirements, enrollment steps, and tuition '
        'questions. Try something like "What\'s my schedule?" or "How much is my balance?"';
  }

  /// Subjects the student hasn't taken whose prerequisites they've already
  /// passed (numeric grade ≤ 3.0 on the 1.00-highest/5.00-failing scale).
  static List<Subject> recommendElectives({
    required List<Grade> grades,
    required List<Subject> allSubjects,
  }) {
    final passedCodes = grades
        .where((g) => !g.isIncomplete && (g.numericGrade ?? 5.0) <= 3.0)
        .map((g) => g.subjectCode)
        .toSet();

    return allSubjects
        .where((s) =>
            s.isElective &&
            !passedCodes.contains(s.code) &&
            s.prerequisites.every((p) => passedCodes.contains(p)))
        .toList();
  }
}
