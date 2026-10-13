---
column: done
technical: false
refs:
  - note-editor/Protected/user.TOGGLE_BOLD
  - note-editor/Protected/user.TOGGLE_ITALIC
  - note-editor/Protected/user.TOGGLE_UNDERLINE
  - note-editor/Protected/user.TOGGLE_CHECKLIST
  - requirements/rules#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-12T14:34:25.702Z
finished: 2026-10-12T16:28:48.564Z
---
# Fix code to match the Model: Hidden note formatting ignores whether its text was shown

Nella nota protetta e nascosta, i comandi grassetto, corsivo e sottolineato devono applicarsi solo se il testo della nota è già stato mostrato da quando l'app è aperta; altrimenti salvano soltanto il documento. Oggi il comando si applica a qualunque parte che abbia già un controllo di testo, quindi anche a un testo mai mostrato se prima è stato cambiato lo stile. Inoltre, dopo una ricarica remota della nota protetta il testo già mostrato non ha più il controllo di testo e il grassetto non ha effetto, mentre la checklist aggiunge una voce nuova dopo la parte attiva invece di alternare la riga. A fine lavoro: con testo già mostrato, grassetto/corsivo/sottolineato e checklist agiscono sulla parte attiva del documento nascosto anche dopo una ricarica remota; con testo mai mostrato, i tre stili non cambiano nulla e la checklist aggiunge la voce vuota in fondo alla nota.
