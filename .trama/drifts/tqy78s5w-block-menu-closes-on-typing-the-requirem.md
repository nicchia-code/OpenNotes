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
resolvedBy: uo2rau9q
created: 2026-10-17T12:45:08.973Z
---
# Block menu closes on typing, the Requirement closes it only when focus leaves

## What happens

Il menu rapido dei blocchi si chiude alla prima lettera digitata nella sezione, anche quando il focus resta lì. Succede sia con il menu aperto dal pulsante della barra (la sezione non comincia con una barra), sia con il menu aperto da una barra digitata quando la barra viene cancellata. Il menu scompare senza che il focus abbia lasciato la sezione.

## What should happen

Il Modello, nello stato Shown, chiude il menu con user.EDIT_NOTE_TEXT quando la sezione non comincia con una barra, e il menu dei blocchi aperto dal pulsante non ha altre regole di chiusura. Il Requisito dice che il menu compare con la barra o con il pulsante e si chiude quando il focus lascia la sezione, senza dire che la digitazione lo chiude: le due descrizioni non coincidono per il menu aperto dal pulsante e per la barra cancellata.

## Fix options

### Seguire il Modello: chiudere alla digitazione

Il codice resta com'è: il menu aperto dal pulsante o dalla barra si chiude alla prima modifica che fa sparire la barra o alla prima lettera scritta. Costo: il menu sparisce mentre l'utente scrive, contro la lettera del Requisito, che andrebbe chiarito.

### Tenere il menu aperto mentre il focus resta nella sezione

Il menu resta sotto la sezione finché il focus c'è o finché non si sceglie una voce, anche se la sezione smette di cominciare con la barra. Costo: il menu resta visibile sotto un testo che non è più un comando, e il Modello di Shown va in contrasto con questo comportamento.

### Distinguere i due modi di aprire il menu

Il menu aperto dal pulsante resta aperto mentre si scrive, mentre quello aperto da una barra digitata si chiude quando la barra scompare. Costo: due regole di chiusura da descrivere e da provare, e il Modello di Shown va diviso in due casi.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _handleTextChanged, ramo senza cancelletto che chiude _slashMenuBlock; _openBlockMenu
