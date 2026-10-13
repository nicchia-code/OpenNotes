---
status: resolved
resolution: fix-code
refs:
  - note-browser/Browsing
  - requirements/rules#note-browser
proposal: null
task: zp77w0hc
origin: null
critical: false
option: 1
note: null
resolvedBy: 32w3ze0y
created: 2026-10-12T18:15:51.632Z
---
# Duplicating a note also clears the search text, the Model says only creation does

## What happens

Quando l'utente duplica una nota mentre la ricerca è attiva, il testo di ricerca viene svuotato, così la copia compare nell'elenco e viene aperta nell'editor. Il comportamento è già nel sistema, ma non è scritto da nessuna parte nel Model.

## What should happen

Il Model della vista Browsing dice che il testo di ricerca resta attivo quando si cambia vista e si svuota solo quando si crea una nota. Il Requirement sulla ricerca dice la stessa cosa: solo la creazione svuota il testo. La duplicazione non è nominata.

## Fix options

### Il Model e il Requirement includono anche la duplicazione

Il Model e il Requirement dicono che anche duplicare una nota svuota il testo di ricerca, come la creazione. La copia è sempre visibile e aperta, come oggi nel codice. Costo: la ricerca attiva si perde a ogni duplicazione, e il Requirement va aggiornato insieme al Model.

### La duplicazione non svuota la ricerca

La ricerca resta attiva anche dopo la duplicazione. Se la copia non rientra nella ricerca, non compare nell'elenco e nell'editor si apre la prima nota della vista, mentre la copia resta salvata. Costo: l'utente può non trovare subito la copia e deve cambiare la ricerca per vederla; il codice va riportato al comportamento precedente.

## Where in the code

lib/core/state/notes_provider.dart, duplicateNote: azzera il testo di ricerca prima di ricaricare l'elenco.
