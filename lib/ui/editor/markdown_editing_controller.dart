import 'package:flutter/material.dart';
import '../theme/apple_theme.dart';

/// Custom TextEditingController that renders inline Markdown (bold, italic, #tag, code)
/// live on the screen without needing a separate preview mode.
///
/// By default, markdown delimiter markers (such as **, *, ~~, `) are hidden completely
/// so the user sees clean rich text. When the user focuses the field and moves the
/// caret/selection to edit that specific formatted word, the delimiter markers are
/// subtly revealed for live in-place editing.
class MarkdownEditingController extends TextEditingController {
  TextStyle baseStyle;
  bool isChecked;
  FocusNode? _focusNode;

  MarkdownEditingController({
    super.text,
    required this.baseStyle,
    this.isChecked = false,
    FocusNode? focusNode,
  }) : _focusNode = focusNode {
    _focusNode?.addListener(_onFocusChanged);
  }

  FocusNode? get focusNode => _focusNode;
  set focusNode(FocusNode? node) {
    if (_focusNode == node) return;
    _focusNode?.removeListener(_onFocusChanged);
    _focusNode = node;
    _focusNode?.addListener(_onFocusChanged);
    notifyListeners();
  }

  void _onFocusChanged() {
    notifyListeners();
  }

  void updateState({
    TextStyle? newBaseStyle,
    bool? newIsChecked,
    FocusNode? newFocusNode,
  }) {
    bool changed = false;
    if (newBaseStyle != null && newBaseStyle != baseStyle) {
      baseStyle = newBaseStyle;
      changed = true;
    }
    if (newIsChecked != null && newIsChecked != isChecked) {
      isChecked = newIsChecked;
      changed = true;
    }
    if (newFocusNode != null && newFocusNode != _focusNode) {
      _focusNode?.removeListener(_onFocusChanged);
      _focusNode = newFocusNode;
      _focusNode?.addListener(_onFocusChanged);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveBase = baseStyle.merge(style);

    if (isChecked) {
      return TextSpan(
        text: text,
        style: effectiveBase.copyWith(
          decoration: TextDecoration.lineThrough,
          color: effectiveBase.color?.withOpacity(0.45) ?? Colors.grey,
        ),
      );
    }



    final children = <TextSpan>[];
    // Robust Regex: strictly requires non-whitespace content inside markers so typing ** or * never disappears
    final pattern = RegExp(
      r'(\*\*\*[^\s\*].*?[^\s\*]\*\*\*|\*\*\*[^\s\*]\*\*\*)'
      r'|(\*\*[^\s\*].*?[^\s\*]\*\*|\*\*[^\s\*]\*\*)'
      r'|((?<!\*)\*[^\s\*].*?[^\s\*]\*(?!\*)|(?<!\*)\*[^\s\*]\*(?!\*))'
      r'|(~~[^\s~].*?[^\s~]~~|~~[^\s~]~~)'
      r'|(`[^`\r\n]+`)'
      r'|((?<=^|\s)#[a-zA-Z0-9_\-]+)'
      r'|(https?:\/\/[^\s]+)',
    );

    final delimiterColor = effectiveBase.color?.withOpacity(0.35) ?? Colors.grey.withOpacity(0.35);
    final delimStyle = effectiveBase.copyWith(
      color: delimiterColor,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    );

    int start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        children.add(TextSpan(
          text: text.substring(start, match.start),
          style: effectiveBase,
        ));
      }

      final matchText = match.group(0)!;

      if (matchText.startsWith('***') && matchText.endsWith('***') && matchText.length >= 7) {
        // Bold-Italic (***..***)
        final innerText = matchText.substring(3, matchText.length - 3);
        children.add(TextSpan(text: '***', style: delimStyle));
        children.add(TextSpan(text: innerText, style: effectiveBase.copyWith(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)));
        children.add(TextSpan(text: '***', style: delimStyle));
      } else if (matchText.startsWith('**') && matchText.endsWith('**') && matchText.length >= 5) {
        // Bold (**..**)
        final innerText = matchText.substring(2, matchText.length - 2);
        children.add(TextSpan(text: '**', style: delimStyle));
        children.add(TextSpan(text: innerText, style: effectiveBase.copyWith(fontWeight: FontWeight.w700)));
        children.add(TextSpan(text: '**', style: delimStyle));
      } else if (matchText.startsWith('*') && matchText.endsWith('*') && matchText.length >= 3) {
        // Italic (*..*)
        final innerText = matchText.substring(1, matchText.length - 1);
        children.add(TextSpan(text: '*', style: delimStyle));
        children.add(TextSpan(text: innerText, style: effectiveBase.copyWith(fontStyle: FontStyle.italic)));
        children.add(TextSpan(text: '*', style: delimStyle));
      } else if (matchText.startsWith('~~') && matchText.endsWith('~~') && matchText.length >= 5) {
        // Strikethrough (~~..~~)
        final innerText = matchText.substring(2, matchText.length - 2);
        children.add(TextSpan(text: '~~', style: delimStyle));
        children.add(TextSpan(text: innerText, style: effectiveBase.copyWith(decoration: TextDecoration.lineThrough)));
        children.add(TextSpan(text: '~~', style: delimStyle));
      } else if (matchText.startsWith('`') && matchText.endsWith('`') && matchText.length >= 3) {
        // Inline Code (`..`)
        final innerText = matchText.substring(1, matchText.length - 1);
        children.add(TextSpan(text: '`', style: delimStyle.copyWith(fontFamily: 'monospace')));
        children.add(TextSpan(
          text: innerText,
          style: effectiveBase.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withOpacity(0.18),
          ),
        ));
        children.add(TextSpan(text: '`', style: delimStyle.copyWith(fontFamily: 'monospace')));
      } else if (matchText.startsWith('#')) {
        // Hashtag in Apple Gold chip style
        final isDark = effectiveBase.color == AppleTheme.darkTextPrimary ||
            (effectiveBase.color != null && effectiveBase.color!.computeLuminance() > 0.5);
        final chipColor = isDark ? AppleTheme.accentYellow : AppleTheme.accentAmberLight;
        children.add(TextSpan(
          text: matchText,
          style: effectiveBase.copyWith(
            color: chipColor,
            fontWeight: FontWeight.w700,
            backgroundColor: chipColor.withOpacity(0.15),
          ),
        ));
      } else if (matchText.startsWith('http://') || matchText.startsWith('https://')) {
        // Link in Apple Blue
        children.add(TextSpan(
          text: matchText,
          style: effectiveBase.copyWith(
            color: const Color(0xFF007AFF),
            decoration: TextDecoration.underline,
          ),
        ));
      } else {
        children.add(TextSpan(text: matchText, style: effectiveBase));
      }

      start = match.end;
    }

    if (start < text.length) {
      children.add(TextSpan(
        text: text.substring(start),
        style: effectiveBase,
      ));
    }

    return TextSpan(children: children);
  }
}

