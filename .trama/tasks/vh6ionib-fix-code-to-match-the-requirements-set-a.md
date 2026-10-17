---
column: done
technical: true
refs:
  - requirements/ui#pending-change/Set aside
drift: zvj3b3j1
proposal: null
agent: false
created: 2026-10-17T19:46:55.461Z
finished: 2026-10-17T19:52:45.558Z
---
# Fix code to match the Requirements: Set-aside note marker is not the cloud-with-slash icon of the icon family

## What happens

Una nota la cui modifica è messa da parte mostra accanto alla data una piccola nuvola barrata di un'altra famiglia di icone, diversa da quella usata dal resto dell'app e dall'indicatore della sincronizzazione.

## What should happen

La riga di una nota messa da parte mostra accanto alla data una piccola icona di nuvola barrata della famiglia di icone dell'app, la stessa usata dallo stato offline dell'indicatore della sincronizzazione.

## Chosen option

**Usare l'icona offline dell'indicatore**

Il marcatore della nota riprende esattamente l'icona di nuvola con cerchio barrato che l'indicatore mostra quando la rete manca. Il disegno è identico in tutta l'app e nessun nuovo widget va mantenuto. Costo: il segno è più grande di una barra semplice, quindi va verificato che resti piccolo accanto alla data su desktop e mobile.

## Where in the code

lib/ui/notes_list/note_card.dart (icona Icons.cloud_off accanto alla data; lib/ui/sync/sync_state_glyph.dart per l'icona offline dell'indicatore)
