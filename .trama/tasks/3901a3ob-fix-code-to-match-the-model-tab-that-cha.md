---
column: done
technical: false
refs:
  - editor-suggestions/Block menu/user.PRESS_TAB_IN_TEXT
  - requirements/rules#editor-suggestions
drift: d8vm6j1d
proposal: null
agent: false
created: 2026-10-18T20:03:12.581Z
finished: 2026-10-18T20:07:45.856Z
---
# Fix code to match the Model: Tab that changes no text still refreshes the menus

## What happens

Con il menu dei blocchi aperto dal pulsante della barra su una sezione che non comincia con «/», un Tab o un Maiuscole+Tab che non cambia il testo della sezione (per esempio su una riga di intestazione, o un Maiuscole+Tab a inizio riga senza rientro) chiude il menu. Lo stesso ricalcolo avviene anche quando il testo non cambia: su una sezione che comincia con «/» e il cui menu è chiuso, un Tab senza modifiche lo riapre.

## What should happen

Il Modello dice che Tab e Maiuscole+Tab cambiano il menu rapido e i suggerimenti di tag solo quando cambiano il testo della sezione. Un tasto che non cambia il testo non deve né chiudere né aprire il menu, né cambiare i suggerimenti di tag: il menu resta com'è.

## Chosen option

**Refresh the menus only when the key changes the text**

Il ricalcolo dei menu dopo Tab e Maiuscole+Tab avviene solo se il tasto cambia il testo della sezione; un tasto che non cambia nulla lascia menu e suggerimenti come sono. Costo: il codice deve confrontare il testo prima e dopo il tasto, ma il Modello e il Requisito restano invariati.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _refreshSuggestionsAfterKeyEdit, chiamato dopo Tab; lib/ui/editor/rich_text_editing_controller.dart: handleTabKey restituisce vero anche quando il testo resta uguale
