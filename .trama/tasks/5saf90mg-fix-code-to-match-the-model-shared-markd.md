---
column: done
technical: false
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
drift: 6toovbfp
proposal: null
agent: false
created: 2026-10-13T05:49:16.250Z
finished: 2026-10-13T05:52:13.324Z
---
# Fix code to match the Model: Shared Markdown text drops the other lines of the title block

## What happens

Quando il titolo della nota viene dalla prima riga di un blocco di testo che contiene più righe (succede se manca un blocco titolo dedicato, o se il titolo è uno stile applicato a una riga di un paragrafo), il testo condiviso toglie l'intero blocco per ricavare il titolo. Il titolo compare in testa, quindi la condivisione sembra corretta, ma tutte le altre righe di quel blocco non arrivano al testo condiviso.

## What should happen

Il testo condiviso deve essere il titolo, una riga vuota e il contenuto della nota convertito in Markdown, senza ripetere il titolo. Il contenuto include ogni riga della nota diversa dalla riga del titolo: nessuna riga scritta dall'utente deve sparire dalla condivisione.

## Chosen option

**Togliere dal testo solo la riga del titolo**

Dal blocco che fornisce il titolo viene tolta soltanto la riga del titolo; le righe successive restano nel testo, convertite come le altre, con i loro stili di riga. Costa: la preparazione del testo condiviso deve riconoscere la riga del titolo dentro il blocco e spostare gli stili delle righe rimaste. Il titolo mostrato nell'elenco e i dati salvati non cambiano.

## Where in the code

lib/core/models/note_model.dart (costruzione del testo senza titolo, blocco del titolo); lib/ui/notes_list/note_actions.dart (ramo della condivisione)
