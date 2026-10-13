---
column: done
technical: false
refs:
  - pending-change
  - requirements/data#pending-change
drift: odoeb8h7
proposal: null
agent: false
created: 2026-10-12T07:38:53.717Z
finished: 2026-10-12T07:41:15.466Z
---
# Fix code to match the Model: Folder changes on the device never reach the cloud

## What happens

Creare, rinominare o eliminare una cartella sul dispositivo salva solo in locale: il cambiamento non entra nella coda e non viene mai inviato al cloud. Le cartelle arrivano sul dispositivo solo dal cloud.

## What should happen

La sincronizzazione è bidirezionale tra note e cartelle del dispositivo e del cloud, e la coda può contenere cambiamenti di note o di cartelle. Il modello dei cambiamenti in attesa, però, fa nascere i cambiamenti solo dalle operazioni sulle note: non dice se anche le modifiche alle cartelle vadano inviate.

## Chosen option

**Accodare anche le cartelle**

Creazione, rinomina ed eliminazione di una cartella entrano nella stessa coda delle note e vengono inviate, in ordine, alla sincronizzazione successiva. Le cartelle arrivano così al cloud come le note. Costa qualche voce in più in coda e un aggiornamento del modello, che deve elencare le cartelle tra le nascite di un cambiamento in attesa.

## Where in the code

lib/core/state/notes_provider.dart (createFolder, renameFolder, deleteFolder: solo salvataggio locale); lib/core/services/sync_service.dart (syncNow: ramo delle cartelle nella coda, mai alimentato)
