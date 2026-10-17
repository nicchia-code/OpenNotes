---
status: resolved
resolution: proposal
refs:
  - note-editor/Open/user.NAVIGATE_BACK
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:24:25.509Z
---
# Edit typed just before going back is saved, the Model says it is discarded

## What happens

Sul mobile, se l'utente torna indietro mentre c'è una modifica di testo in attesa di essere consegnata (pulsante Indietro, gesto o tasto di sistema), la modifica viene comunque salvata. L'attesa di 300 ms scade mentre la schermata sta ancora uscendo, perché l'uscita dura circa mezzo secondo: il testo digitato nell'ultimo tratto prima di tornare indietro resta nella nota.

## What should happen

Il Model dice che, quando l'utente torna all'elenco dall'editor mobile, l'editor si chiude e **scarta** la modifica in attesa, senza salvarla. Il Requirement non chiede di consegnarla in quel caso: dice solo di consegnare subito al passaggio in secondo piano e prima dei comandi sulla nota.

## Fix options

### Discard the waiting edit when going back starts

Appena l'utente avvia l'uscita dall'editor mobile, l'editor annulla l'attesa e il testo digitato nell'ultimo mezzo secondo non viene scritto, come dice il Model. La schermata può uscire con l'animazione di oggi. Costo: caratteri recenti persi senza alcun avviso, anche quando l'utente si aspetta che restino. Il cestino e gli altri comandi sulla nota continuano a consegnare il testo prima di agire.

### Close the mobile editor without the slide-out animation

Il ritorno all'elenco avviene subito, senza la transizione di circa mezzo secondo: l'editor viene smontato prima che scada l'attesa di 300 ms, e la modifica in attesa si perde come dice il Model. Costo: sul mobile il ritorno non scorre più, diversamente dalle altre schermate; il comportamento dipende dal fatto che la transizione non sia animata.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart: _leave; lib/ui/editor/notion_document_editor.dart: dispose e attesa di 300 ms in _serializeAndSave
