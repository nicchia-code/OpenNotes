---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: g8zt4e2u
origin: f50dbt0k
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:32:26.371Z
---
# Block menu opening from the toolbar missing from the Model

## What happens

Il pulsante Aa della barra sopra la tastiera del telefono apre un suo elenco di formati, con voci diverse dal menu rapido dei blocchi. Il menu rapido dei blocchi compare solo quando la sezione di testo comincia con una barra digitata a mano. Il Task non può quindi aprire il menu dalla barra senza inventare il comportamento.

## What should happen

Il Requisito di editor-suggestions dice che sul telefono il menu rapido compare quando si tocca il suo pulsante sulla barra sopra la tastiera, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. Il Modello di Block menu però non ha nessuna transizione che apra il menu dalla barra: il Drift h21uc379 aveva scelto di completare il Modello, ma la Proposal p136jufl non lo ha modificato. Senza questa transizione il comportamento non è definito nel Modello, che deve vincere sul codice.

## Fix options

### Completare il Modello con l'apertura dalla barra

Si aggiunge al Modello una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci. Poi si implementa il pulsante. Costo: un pulsante in più sulla barra e una transizione nuova da mantenere, con il rischio di sovrapporsi al pulsante Aa, che oggi apre un altro elenco.

### Far aprire dalla barra il menu esistente del pulsante Aa

Il pulsante Aa apre il menu rapido dei blocchi invece del suo elenco di formati. Nessuna transizione nuova, ma il Modello di Block menu va comunque aggiornato per dire che il pulsante della barra è un'apertura valida, e l'elenco di formati di Aa sparisce dal telefono.

### Lasciare il comportamento attuale e togliere il requisito

Il menu dei blocchi resta raggiungibile solo digitando la barra all'inizio della sezione. Il Requisito sul pulsante della barra viene rimosso o riformulato. Costo: il telefono non ha un accesso dalla barra al menu dei blocchi, come previsto dal Requisito oggi.

## Where in the code

lib/ui/editor/notion_document_editor.dart (apertura del menu in _handleTextChanged); lib/ui/mobile/mobile_keyboard_accessory_bar.dart (menu Aa)
