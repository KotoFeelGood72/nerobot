import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nerobot/components/ui/linkable_selectable_text.dart';
import 'package:nerobot/constants/app_colors.dart';

void main() {
  Future<void> pumpText(WidgetTester tester, String text) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkableSelectableText(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  testWidgets('renders plain text as selectable', (tester) async {
    await pumpText(tester, 'Простое описание без ссылок');

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('Простое описание'), findsOneWidget);
  });

  testWidgets('highlights urls and phones as violet links', (tester) async {
    const text = '''
Тест кликабельных ссылок.
Пишите: https://max.ru/u/testLinkClickable123
Звоните: +7 913 123-45-67
Сайт: www.example.com
''';

    await pumpText(tester, text);

    final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
    final span = selectable.textSpan!;
    final linkSpans = <TextSpan>[];

    void collect(InlineSpan node) {
      if (node is TextSpan) {
        if (node.recognizer != null) {
          linkSpans.add(node);
        }
        if (node.children != null) {
          for (final child in node.children!) {
            collect(child);
          }
        }
      }
    }

    collect(span);

    expect(linkSpans.length, greaterThanOrEqualTo(3));

    final linkTexts = linkSpans.map((s) => s.text).toList();
    expect(
      linkTexts.any((t) => t != null && t.contains('https://max.ru')),
      isTrue,
    );
    expect(
      linkTexts.any((t) => t != null && t.contains('+7')),
      isTrue,
    );
    expect(
      linkTexts.any((t) => t != null && t.contains('www.example.com')),
      isTrue,
    );

    for (final link in linkSpans) {
      expect(link.style?.color, AppColors.violet);
      expect(link.style?.decoration, TextDecoration.underline);
    }
  });
}
