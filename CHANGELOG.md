# Changelog

## Unreleased
- Fixed rich-text formatting drift and line-style reconciliation after edits, including deletion, line-start Enter, and Markdown shortcuts.
- Corrected legacy prefix offset mapping and sanitized persisted formatting ranges when notes load.
- Preserved inline spans and the surviving line style when text blocks merge.
