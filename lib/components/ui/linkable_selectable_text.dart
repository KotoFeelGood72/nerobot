import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Выделяемый текст со кликабельными URL и телефонами.
class LinkableSelectableText extends StatefulWidget {
  const LinkableSelectableText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  @override
  State<LinkableSelectableText> createState() => _LinkableSelectableTextState();
}

class _LinkableSelectableTextState extends State<LinkableSelectableText> {
  static final RegExp _pattern = RegExp(
    r'(https?:\/\/[^\s]+)|(www\.[^\s]+)|'
    r'((?:\+7|8)[\d\-\s\(\)]{8,}\d)|'
    r'(\+\d{1,3}[\d\-\s\(\)]{7,}\d)',
    caseSensitive: false,
  );

  static final RegExp _trailingPunctuation = RegExp(r'[.,;:!?)\]}>»"\x27]+$');

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _recognizer(VoidCallback onTap) {
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  Future<void> _openMatch(String raw, {required bool isPhone}) async {
    final cleaned = raw.replaceFirst(_trailingPunctuation, '');
    final Uri uri;
    if (isPhone) {
      final digits = cleaned.replaceAll(RegExp(r'[^\d+]'), '');
      uri = Uri(scheme: 'tel', path: digits);
    } else {
      final url =
          cleaned.toLowerCase().startsWith('http')
              ? cleaned
              : 'https://$cleaned';
      uri = Uri.parse(url);
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPhone ? 'Не удалось открыть номер' : 'Не удалось открыть ссылку',
          ),
        ),
      );
    }
  }

  List<InlineSpan> _buildSpans(TextStyle baseStyle, TextStyle linkStyle) {
    _disposeRecognizers();

    final text = widget.text;
    if (text.isEmpty) {
      return [TextSpan(text: '', style: baseStyle)];
    }

    final spans = <InlineSpan>[];
    var start = 0;

    for (final match in _pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: text.substring(start, match.start), style: baseStyle),
        );
      }

      final raw = match.group(0)!;
      final trailing = _trailingPunctuation.firstMatch(raw);
      final core = trailing == null ? raw : raw.substring(0, trailing.start);
      final suffix = trailing == null ? '' : trailing.group(0)!;
      final isPhone = match.group(3) != null || match.group(4) != null;

      spans.add(
        TextSpan(
          text: core,
          style: linkStyle,
          recognizer: _recognizer(() => _openMatch(core, isPhone: isPhone)),
          mouseCursor: SystemMouseCursors.click,
        ),
      );

      if (suffix.isNotEmpty) {
        spans.add(TextSpan(text: suffix, style: baseStyle));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        widget.style ??
        const TextStyle(fontSize: 14, color: AppColors.gray, height: 1.35);
    final linkStyle =
        widget.linkStyle ??
        baseStyle.copyWith(
          color: AppColors.violet,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.violet,
        );

    return SelectableText.rich(
      TextSpan(children: _buildSpans(baseStyle, linkStyle)),
      style: baseStyle,
    );
  }
}
