---
column: done
technical: true
refs:
  - requirements/rules#realtime-channel
drift: pxe7ywy2
proposal: 634nfp49
agent: false
created: 2026-10-17T13:11:54.262Z
finished: 2026-10-17T13:44:33.378Z
---
# Fix code to match the Requirements: Realtime echo check compares update times, not revisions

## What happens

Il canale ignora l'eco e le modifiche già viste confrontando updated_at con la copia locale. Le righe del cloud hanno la colonna revision, ma il dispositivo non conserva nessuna revisione nota: una modifica con revisione già nota non può essere scartata per revisione.

## What should happen

Il Requirement rules#realtime-channel dice che una modifica con revisione minore o uguale alla revisione nota è ignorata, e che la revisione nota è memorizzata sul dispositivo.

## Chosen option

**Usare lo storage locale della revisione**

Lasciare il controllo per revisione allo storage locale del Task mhb28mt0, che memorizza la revisione di ogni nota e cartella; questo Task resta in doing finché non c'è.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (confronto updatedAt con la copia locale) e handleRemoteNoteChange.
