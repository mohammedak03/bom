import 'package:bomb_questions/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows setup screen as the app entry point', (tester) async {
    await tester.pumpWidget(const BombQuestionsApp());
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump();

    expect(find.text('قنبلة الأسئلة'), findsOneWidget);
    expect(find.text('مين باللمّة؟'), findsOneWidget);
    expect(find.text('نختار المواضيع'), findsOneWidget);
  });

  testWidgets('help explains the rules and closes back to setup', (
    tester,
  ) async {
    await tester.pumpWidget(const BombQuestionsApp());
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump();

    await tester.tap(find.byTooltip('كيف نلعب؟'));
    await tester.pumpAndSettle();

    expect(find.text('جاوب بصوت عالي'), findsOneWidget);
    expect(find.text('اضغط ومرّر الموبايل'), findsOneWidget);
    expect(
      find.text('اللي تنفجر عنده بياخد خسارة. والأقل خسائر يفوز.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('وصلت، يلا!'));
    await tester.tap(find.text('وصلت، يلا!'));
    await tester.pumpAndSettle();

    expect(find.text('سهلة… بس بدها سرعة.'), findsNothing);
    expect(find.text('نختار المواضيع'), findsOneWidget);
  });
}
