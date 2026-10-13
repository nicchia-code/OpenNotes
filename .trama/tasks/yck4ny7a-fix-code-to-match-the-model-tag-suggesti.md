---
column: done
technical: false
refs:
  - editor-suggestions/Tag suggestions
  - requirements/rules#editor-suggestions
drift: 2vobzpuh
proposal: null
agent: false
created: 2026-10-12T10:59:40.515Z
finished: 2026-10-12T13:54:21.200Z
---
# Fix code to match the Model: Tag suggestions accept any letter, not only Latin ones

## What happens

Il menu dei tag compare anche quando il tag è scritto con lettere di altri alfabeti, per esempio cirillico o greco, e propone quei tag; il salvataggio riconosce gli stessi tag. Il menu rapido invece toglie il comando dalla riga solo se la parola è fatta di lettere senza accenti: con «/caffè» dopo la scelta resta la «è» nel testo.

## What should happen

Il Modello dice che un tag, quando si scrive, è fatto di lettere latine, cifre, trattini o trattini bassi, e la Requirement lo scrive come lettere ASCII. Il comando rapido, secondo la Requirement, toglie «/» seguito da lettere e cifre. Le lettere accentate sono già state accettate come parte del tag, ma gli altri alfabeti no.

## Chosen option

**Accettare ogni lettera, anche nel comando rapido**

Il menu dei tag e il comando rapido riconoscono ogni lettera, come già fa il salvataggio dei tag. Il Modello e le Requirement dicono «lettere» invece di «lettere latine» o «ASCII», anche per le note e l'organizzazione. Costo: una modifica al Modello e alle Requirement di più Area, e tag in alfabeti diversi compaiono nei suggerimenti e nel filtro.

## Where in the code

lib/ui/editor/notion_document_editor.dart (riconoscimento del tag in _handleTextChanged; _removeSlashCommand); lib/core/models/note_model.dart (regex dei tag salvati)
