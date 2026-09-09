/// Represents a continuous range of text with rich typography attributes.
class StyleSpan {
  int start;
  int end;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough;

  StyleSpan({
    required this.start,
    required this.end,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
  });

  bool get isEmpty => start >= end;
  bool get hasAnyStyle => isBold || isItalic || isUnderline || isStrikethrough;

  StyleSpan copyWith({
    int? start,
    int? end,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
  }) {
    return StyleSpan(
      start: start ?? this.start,
      end: end ?? this.end,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        if (isBold) 'bold': true,
        if (isItalic) 'italic': true,
        if (isUnderline) 'underline': true,
        if (isStrikethrough) 'strikethrough': true,
      };

  factory StyleSpan.fromJson(Map<String, dynamic> json) => StyleSpan(
        start: json['start'] as int? ?? 0,
        end: json['end'] as int? ?? 0,
        isBold: json['bold'] as bool? ?? false,
        isItalic: json['italic'] as bool? ?? false,
        isUnderline: json['underline'] as bool? ?? false,
        isStrikethrough: json['strikethrough'] as bool? ?? false,
      );
}
