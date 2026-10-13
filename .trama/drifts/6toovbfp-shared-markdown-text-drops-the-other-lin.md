---
status: resolved
resolution: fix-code
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
proposal: null
task: 5saf90mg
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:42:09.118Z
---
# Shared Markdown text drops the other lines of the title block

## What happens

Quando il titolo della nota viene dalla prima riga di un blocco di testo che contiene più righe (succede se manca un blocco titolo dedicato, o se il titolo è uno stile applicato a una riga di un paragrafo), il testo condiviso toglie l'intero blocco per ricavare il titolo. Il titolo compare in testa, quindi la condivisione sembra corretta, ma tutte le altre righe di quel blocco non arrivano al testo condiviso.

## What should happen

Il testo condiviso deve essere il titolo, una riga vuota e il contenuto della nota convertito in Markdown, senza ripetere il titolo. Il contenuto include ogni riga della nota diversa dalla riga del titolo: nessuna riga scritta dall'utente deve sparire dalla condivisione.

## Fix options

### Togliere dal testo solo la riga del titolo

Dal blocco che fornisce il titolo viene tolta soltanto la riga del titolo; le righe successive restano nel testo, convertite come le altre, con i loro stili di riga. Costa: la preparazione del testo condiviso deve riconoscere la riga del titolo dentro il blocco e spostare gli stili delle righe rimaste. Il titolo mostrato nell'elenco e i dati salvati non cambiano.

### Separare il titolo dal corpo al salvataggio

Quando una nota viene salvata, la riga del titolo che si trova dentro un blocco di testo con più righe viene messa in un blocco a sé, così che la condivisione tolga un blocco intero come oggi, e il formato resta un blocco per riga. Costa: cambia il formato salvato di queste note; le note già salvate restano come sono finché non vengono salvate di nuovo, e il testo condiviso di quelle note resta incompleto fino ad allora.

## Where in the code

lib/core/models/note_model.dart (costruzione del testo senza titolo, blocco del titolo); lib/ui/notes_list/note_actions.dart (ramo della condivisione)
