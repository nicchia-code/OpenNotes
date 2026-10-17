---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#pending-change/Set aside
proposal: null
task: vh6ionib
origin: null
critical: false
option: 1
note: null
resolvedBy: 4bde0hn9
created: 2026-10-17T19:25:17.417Z
---
# Set-aside note marker is not the cloud-with-slash icon of the icon family

## What happens

Una nota la cui modifica è messa da parte mostra accanto alla data una piccola nuvola barrata di un'altra famiglia di icone, diversa da quella usata dal resto dell'app e dall'indicatore della sincronizzazione.

## What should happen

La riga di una nota messa da parte mostra accanto alla data una piccola icona di nuvola barrata della famiglia di icone dell'app, la stessa usata dallo stato offline dell'indicatore della sincronizzazione.

## Fix options

### Usare l'icona offline dell'indicatore

Il marcatore della nota riprende esattamente l'icona di nuvola con cerchio barrato che l'indicatore mostra quando la rete manca. Il disegno è identico in tutta l'app e nessun nuovo widget va mantenuto. Costo: il segno è più grande di una barra semplice, quindi va verificato che resti piccolo accanto alla data su desktop e mobile.

### Disegnare la nuvola barrata con la famiglia dell'app

Il marcatore compone una nuvola di CupertinoIcons con una barra sopra, come l'indicatore compone le sue icone con un distintivo. Il segno resta sottile accanto alla data. Costo: una piccola costruzione da mantenere a mano, perché la famiglia non ha una nuvola barrata già pronta con questo nome.

## Where in the code

lib/ui/notes_list/note_card.dart (icona Icons.cloud_off accanto alla data; lib/ui/sync/sync_state_glyph.dart per l'icona offline dell'indicatore)
