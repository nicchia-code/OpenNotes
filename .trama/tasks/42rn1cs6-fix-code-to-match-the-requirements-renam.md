---
column: done
technical: false
refs:
  - folder/User folder/user.RENAME_FOLDER
drift: null
proposal: null
agent: false
created: 2026-10-13T12:45:00.706Z
finished: 2026-10-13T13:16:59.973Z
---
# Fix code to match the Requirements: Renamed subfolder keeps a deleted parent and blocks every sync

## What happens

La cartella locale conserva la cartella superiore fino alla sincronizzazione successiva, come vuole il Requirement. Se però una sottocartella con cartella superiore eliminata ha una modifica in coda (rinomina, creazione), il payload accodato contiene ancora parent_id della cartella eliminata. Quando la coda arriva a quel elemento, il cloud rifiuta l'inserimento o l'aggiornamento per la chiave esterna parent_id (la cartella superiore non esiste più, o è stata azzerata dalla cancellazione). Il primo errore interrompe l'intera sincronizzazione: l'elemento resta in coda, e ogni sincronizzazione successiva fallisce allo stesso punto, senza scaricare cartelle e note.

## What should happen

Il Requirement dice che la cartella superiore resta sul dispositivo fino alla sincronizzazione successiva, quando la sottocartella diventa di primo livello anche sul dispositivo. Con il codice attuale quella sincronizzazione non può completarsi, quindi il Requirement non è rispettato.

## Where in the code

lib/core/models/folder_model.dart (toSupabaseJson include parent_id); lib/core/services/sync_service.dart (sync di coda, ramo folder upsert; il primo errore interrompe la sincronizzazione).

## Acceptance

Una sottocartella con cartella superiore eliminata e una rinomina in coda viene inviata al cloud senza errore; la sincronizzazione completa termina; la sottocartella risulta di primo livello sia sul cloud sia sul dispositivo. Il dispositivo non cambia la cartella superiore locale prima della sincronizzazione.
