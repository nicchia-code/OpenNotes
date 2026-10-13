---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Tag suggestions
  - requirements/rules#editor-suggestions
proposal: null
task: yck4ny7a
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:46:03.837Z
---
# Tag suggestions accept any letter, not only Latin ones

## What happens

Il menu dei tag compare anche quando il tag è scritto con lettere di altri alfabeti, per esempio cirillico o greco, e propone quei tag; il salvataggio riconosce gli stessi tag. Il menu rapido invece toglie il comando dalla riga solo se la parola è fatta di lettere senza accenti: con «/caffè» dopo la scelta resta la «è» nel testo.

## What should happen

Il Modello dice che un tag, quando si scrive, è fatto di lettere latine, cifre, trattini o trattini bassi, e la Requirement lo scrive come lettere ASCII. Il comando rapido, secondo la Requirement, toglie «/» seguito da lettere e cifre. Le lettere accentate sono già state accettate come parte del tag, ma gli altri alfabeti no.

## Fix options

### Accettare ogni lettera, anche nel comando rapido

Il menu dei tag e il comando rapido riconoscono ogni lettera, come già fa il salvataggio dei tag. Il Modello e le Requirement dicono «lettere» invece di «lettere latine» o «ASCII», anche per le note e l'organizzazione. Costo: una modifica al Modello e alle Requirement di più Area, e tag in alfabeti diversi compaiono nei suggerimenti e nel filtro.

### Solo lettere latine, anche nel salvataggio

Il menu, il comando rapido e il salvataggio dei tag riconoscono solo lettere latine, come dice il Modello. I tag scritti con altri alfabeti non sono più tag: spariscono dall'elenco e dal filtro, e le note già salvate con quei tag cambiano alla prossima modifica. Costo: una regola diversa da quella che il codice usa oggi per i tag, e la perdita di tag già in uso.

### Solo il menu segue il Modello

Il menu dei tag e il comando rapido riconoscono solo lettere latine, mentre il salvataggio dei tag resta com'è. Un tag con altri alfabeti resta valido e filtrabile, ma non propone suggerimenti né la voce per crearlo. Costo: l'editor non contraddice più il Modello, ma il menu e il salvataggio ragionano con regole diverse.

## Where in the code

lib/ui/editor/notion_document_editor.dart (riconoscimento del tag in _handleTextChanged; _removeSlashCommand); lib/core/models/note_model.dart (regex dei tag salvati)
