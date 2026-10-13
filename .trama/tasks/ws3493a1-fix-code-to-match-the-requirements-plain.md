---
column: done
technical: true
refs:
  - requirements/rules#note-content-save
drift: bm26p0up
proposal: null
agent: false
created: 2026-10-12T10:59:40.545Z
finished: 2026-10-12T11:05:51.040Z
---
# Fix code to match the Requirements: Plain-text note starting with [ gets the default title

## What happens

Una nota in testo semplice la cui prima riga inizia con «[», per esempio «[Spesa] latte», non riceve quella riga come titolo: riceve «Nuova nota». Il sistema prova a leggere il testo come documento a blocchi, la lettura fallisce, e invece di passare alle righe restituisce il titolo di default.

## What should happen

Il titolo è la prima riga con testo, anche nei testi semplici: «[Spesa] latte» deve diventare il titolo della nota. «Nuova nota» vale solo quando non c'è nessuna riga con testo.

## Chosen option

**Passare alle righe quando il testo non è un documento a blocchi**

Il sistema prova a leggere il contenuto come blocchi e, se la lettura fallisce, usa le righe come per ogni altro testo semplice. La prima riga torna titolo anche quando inizia con «[». Costa: un solo cambiamento nel punto dove si decide il titolo; anteprima e tag già passano alle righe in questo caso.

## Where in the code

lib/core/models/note_model.dart: Note.extractTitle, ramo del testo che inizia con «[».
