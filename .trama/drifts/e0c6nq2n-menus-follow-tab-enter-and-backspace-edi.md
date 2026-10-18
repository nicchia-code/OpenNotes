---
status: resolved
resolution: proposal
refs:
  - editor-suggestions/Shown/user.EDIT_NOTE_TEXT
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:31:49.463Z
---
# Menus follow Tab, Enter and Backspace edits, the Model lists only typing

## What happens

Con il menu rapido aperto su una sezione che comincia con «/», un Tab in testa alla sezione aggiunge il rientro: la sezione non comincia più con la barra e il menu si chiude, come dopo una digitazione. Lo stesso accade con Invio e Backspace quando l'editor gestisce da sé la modifica, e i suggerimenti di tag si aprono anche quando una di queste modifiche crea un «#» prima del cursore. Il Modello collega questi aggiornamenti solo a user.EDIT_NOTE_TEXT, cioè alla digitazione, all'incolla e alla cancellazione, e non ne tiene conto.

## What should happen

Il Modello deve descrivere quali tasti aggiornano il menu rapido e i suggerimenti di tag con le stesse transizioni della digitazione. Il Requisito chiude il menu appena una modifica del testo lascia la sezione senza barra iniziale, e Tab, Invio e Backspace sono modifiche del testo. Finché il Modello tace su questi tasti, il comportamento osservato non è quello che il Modello descrive.

## Fix options

### Il Modello conta anche Tab, Invio e Backspace

Aggiungere al Modello gli eventi PRESS_TAB_IN_TEXT, PRESS_ENTER_IN_TEXT e PRESS_BACKSPACE_IN_TEXT come eventi che, quando cambiano il testo della sezione, seguono le stesse transizioni di EDIT_NOTE_TEXT negli stati Shown, Tag suggestions e Block menu. Costo: più archi nel Diagramma e un evento in più da descrivere in ogni stato interessato.

### Il menu si aggiorna solo con la digitazione

Il codice smette di aggiornare il menu rapido e i suggerimenti dopo Tab, Invio e Backspace, e il Requisito va riscritto perché conti solo la digitazione. Costo: su una riga rientrata con Tab il menu resta aperto anche se la sezione non comincia più con la barra, contro la regola attuale del Requisito.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _refreshSuggestionsAfterKeyEdit, chiamato dopo Tab, Invio e Backspace gestiti dal controller di testo
