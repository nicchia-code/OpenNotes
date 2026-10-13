---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: f50dbt0k
origin: 2r8qieru
critical: false
option: 1
note: null
resolvedBy: ep2ayt04
created: 2026-10-12T08:10:41.883Z
---
# Block menu opening from the toolbar still missing from the Model

## What happens

Il pulsante della barra degli strumenti sulla tastiera del telefono non apre il menu rapido dei blocchi: mostra il suo elenco di formati, con voci diverse. Il menu compare solo quando la sezione di testo comincia con una barra digitata a mano. Il Task chiede di aprire il menu dalla barra, come deciso nella risoluzione del Drift h21uc379.

## What should happen

Il Modello non ha nessuna transizione che apra il menu dalla barra: il menu si raggiunge solo digitando la barra all'inizio della sezione. La scelta approvata nel Drift h21uc379 era completare il Modello con questa apertura, ma la risoluzione (Proposal p136jufl) non ha modificato il Modello, quindi la transizione manca ancora. Senza di essa il comportamento richiesto non è definito e il codice non può essere scritto senza inventarlo.

## Fix options

### Completare il Modello con l'apertura dalla barra

Si aggiunge al Modello una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. Poi si implementa il pulsante. Costo: un pulsante in più sulla barra e una transizione nuova da mantenere, con il rischio di sovrapporsi al pulsante Aa che oggi apre un altro elenco.

### Togliere l'apertura dalla barra dalla richiesta

Il menu resta aperto solo digitando la barra all'inizio della sezione, come oggi. Il Task viene chiuso senza modifiche al codice della barra e il pulsante Aa resta un elenco di formati separato. Costo: sulla tastiera del telefono non c'è un modo rapido per raggiungere le sette voci del menu.

### Sostituire l'elenco Aa con il menu rapido

Il pulsante Aa apre direttamente le sette voci del menu rapido, al posto dell'elenco di formati attuale. Il Modello va completato con questa apertura. Costo: le voci di formato Titolo, Corpo e Sottolineato non sarebbero più raggiungibili dalla barra, e questo cambia un comportamento che l'utente conosce.

## Where in the code

lib/ui/editor/notion_document_editor.dart (apertura del menu in _handleTextChanged); lib/ui/mobile/mobile_keyboard_accessory_bar.dart (menu Aa)
