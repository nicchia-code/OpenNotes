---
status: resolved
resolution: fix-code
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
proposal: null
task: 86zrkpz9
origin: null
critical: false
option: 1
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:27:40.808Z
---
# Shared text drops the part of a long first line beyond the 60-character title

## What happens

Quando la prima riga della nota è più lunga di 60 caratteri, il titolo viene troncato a 60 caratteri (regola del titolo) e il testo condiviso usa solo questa parte come titolo. Il codice toglie però l'intera prima riga dal corpo, quindi i caratteri oltre il sessantesimo non arrivano mai alla condivisione.

## What should happen

Il testo condiviso deve contenere ogni riga scritta dall'utente tranne la riga del titolo; il titolo troncato resta in testa, e i caratteri oltre i 60 non devono sparire senza che il Model e il Requisito lo dicano.

## Fix options

### Mantenere la prima riga intera nella condivisione

Il titolo in testa resta troncato a 60 caratteri, ma nel corpo condiviso viene messa la prima riga per intero, così nessun carattere si perde. Costo: il titolo compare due volte per le righe lunghe, e la regola di rimozione della riga del titolo va riscritta.

### Accettare il troncamento e dirlo nel Model e nel Requisito

Il codice non cambia: il Model e il Requisito della condivisione dicono che il titolo è troncato a 60 caratteri e che il resto della prima riga non viene condiviso. Costo: l'utente perde i caratteri oltre il sessantesimo senza avviso, e la specifica va aggiornata.

## Where in the code

lib/core/models/note_model.dart (_clipTitle, _markdownWithoutTitle, _blockWithoutTitleLine); lib/ui/notes_list/note_actions.dart (testo della condivisione)
