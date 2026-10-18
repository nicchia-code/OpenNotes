---
column: done
technical: false
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
drift: y8iuj9nq
proposal: null
agent: false
created: 2026-10-18T19:36:44.008Z
finished: 2026-10-18T19:38:06.528Z
---
# Fix code to match the Model: Shared text drops the part of a long first line beyond the 60-character title

## What happens

Quando la prima riga della nota è più lunga di 60 caratteri, il titolo viene troncato a 60 caratteri (regola del titolo) e il testo condiviso usa solo questa parte come titolo. Il codice toglie però l'intera prima riga dal corpo, quindi i caratteri oltre il sessantesimo non arrivano mai alla condivisione.

## What should happen

Il testo condiviso deve contenere ogni riga scritta dall'utente tranne la riga del titolo; il titolo troncato resta in testa, e i caratteri oltre i 60 non devono sparire senza che il Model e il Requisito lo dicano.

## Chosen option

**Mantenere la prima riga intera nella condivisione**

Il titolo in testa resta troncato a 60 caratteri, ma nel corpo condiviso viene messa la prima riga per intero, così nessun carattere si perde. Costo: il titolo compare due volte per le righe lunghe, e la regola di rimozione della riga del titolo va riscritta.

## Where in the code

lib/core/models/note_model.dart (_clipTitle, _markdownWithoutTitle, _blockWithoutTitleLine); lib/ui/notes_list/note_actions.dart (testo della condivisione)
