---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu/user.PRESS_TAB_IN_TEXT
  - requirements/rules#editor-suggestions
proposal: null
task: 3901a3ob
origin: null
critical: false
option: 1
note: null
resolvedBy: 2ckxa2av
created: 2026-10-18T19:46:19.779Z
---
# Tab that changes no text still refreshes the menus

## What happens

Con il menu dei blocchi aperto dal pulsante della barra su una sezione che non comincia con «/», un Tab o un Maiuscole+Tab che non cambia il testo della sezione (per esempio su una riga di intestazione, o un Maiuscole+Tab a inizio riga senza rientro) chiude il menu. Lo stesso ricalcolo avviene anche quando il testo non cambia: su una sezione che comincia con «/» e il cui menu è chiuso, un Tab senza modifiche lo riapre.

## What should happen

Il Modello dice che Tab e Maiuscole+Tab cambiano il menu rapido e i suggerimenti di tag solo quando cambiano il testo della sezione. Un tasto che non cambia il testo non deve né chiudere né aprire il menu, né cambiare i suggerimenti di tag: il menu resta com'è.

## Fix options

### Refresh the menus only when the key changes the text

Il ricalcolo dei menu dopo Tab e Maiuscole+Tab avviene solo se il tasto cambia il testo della sezione; un tasto che non cambia nulla lascia menu e suggerimenti come sono. Costo: il codice deve confrontare il testo prima e dopo il tasto, ma il Modello e il Requisito restano invariati.

### The Model counts every Tab press as a refresh

Il Modello non chiede più che Tab e Maiuscole+Tab cambino il testo: ogni pressione ricalcola menu e suggerimenti, come oggi. Costo: il Modello e il Requisito vanno riscritti sulle transizioni di Tab, e il menu aperto dal pulsante si chiude anche su un Maiuscole+Tab che non sposta nulla.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _refreshSuggestionsAfterKeyEdit, chiamato dopo Tab; lib/ui/editor/rich_text_editing_controller.dart: handleTabKey restituisce vero anche quando il testo resta uguale
