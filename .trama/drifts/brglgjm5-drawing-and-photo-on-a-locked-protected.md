---
status: resolved
resolution: proposal
refs:
  - mobile-navigation
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:27:49.322Z
---
# Drawing and photo on a locked protected note

## What happens

Nella barra degli strumenti sopra la tastiera dell'editor mobile, con una nota protetta e ancora bloccata, i pulsanti Disegno, Foto, Checklist e Tabella restano attivi: il Model dice solo che Disegno apre la tela (Editing from list / Editing from folders, OPEN_DRAWING), senza condizioni, mentre il codice disabilita solo il menu dei blocchi. Il codice di inserimento immagine (insertImage nell'editor) non controlla il blocco e salva il documento: non ho verificato se con la nota bloccata il contenuto è caricato, quindi il rischio di sovrascrivere il contenuto protetto è [INFERENCE].

## What should happen

Con la nota protetta e ancora bloccata la barra non deve modificare il contenuto nascosto: la scelta da prendere è se disabilitare i pulsanti che inseriscono blocchi (Disegno, Foto, Checklist, Tabella) come il menu dei blocchi, oppure se consentirli e dichiarare nel Model il comportamento.

## Fix options

### Disabilitare i pulsanti di inserimento

Disabilitare Disegno, Foto, Checklist e Tabella finché la nota non è sbloccata, come già accade per il menu dei blocchi; il Model aggiunge la condizione su OPEN_DRAWING.

### Consentire e descrivere nel Model

Lasciare i pulsanti attivi e descrivere nel Model che il disegno e la foto si inseriscono anche con la nota protetta, con i suoi effetti sul contenuto.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (build, MobileKeyboardAccessoryBar); lib/ui/editor/notion_document_editor.dart (insertImage, insertChecklist, insertTable)
