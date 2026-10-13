---
status: resolved
resolution: proposal
refs:
  - note/Active
  - account/Signed in
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: ep2ayt04
created: 2026-10-12T08:26:56.840Z
---
# Account switch removes synced notes, missing from the note Model

## What happens

Quando si accede con un altro account Google, le note del dispositivo che erano già sincronizzate con il primo account vengono tolte dal dispositivo insieme al loro file nell'archivio Markdown, senza accodare nulla nel cloud. Per la Note questo è un passaggio a eliminata che il Diagramma non mostra: nessuna Transition della Note verso eliminata dipende dal cambio di account.

## What should happen

Il Model della Note non prevede alcuna Transition verso eliminata legata al cambio di account. Il Model dell'account dice solo che ogni utente vede sul cloud le proprie righe, senza dire che cosa succede alle note del dispositivo. La scelta è stata presa nel Drift 8t136rfu ("Local notes follow the account that signs in"), ma il Diagramma della Note non la registra, quindi chi legge il Model non può saperla.

## Fix options

### Record the removal in the note Model

Aggiungere alla Note una Transition verso eliminata, quando cambia l'account, per le sole note già sincronizzate con l'account precedente, senza accodare nulla nel cloud. Il comportamento del codice resta com'è e il Diagramma dice ciò che accade. Costo: una Proposal sul Model della Note e una riga in più nel Diagramma.

### Keep synced notes on the device

Le note già sincronizzate non vengono più tolte quando accede un altro account: restano sul dispositivo finché non torna il loro account. Il Model della Note resta com'è. Costo: il nuovo utente vede note scritte da un altro, cosa che il Model dell'account non prevede, e la sincronizzazione va cambiata e testata.

## Where in the code

lib/core/services/sync_service.dart (syncNow, _adoptAccount)
