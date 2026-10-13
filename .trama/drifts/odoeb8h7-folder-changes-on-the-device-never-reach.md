---
status: resolved
resolution: fix-code
refs:
  - pending-change
  - requirements/data#pending-change
proposal: null
task: dvqga73k
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:55.937Z
---
# Folder changes on the device never reach the cloud

## What happens

Creare, rinominare o eliminare una cartella sul dispositivo salva solo in locale: il cambiamento non entra nella coda e non viene mai inviato al cloud. Le cartelle arrivano sul dispositivo solo dal cloud.

## What should happen

La sincronizzazione è bidirezionale tra note e cartelle del dispositivo e del cloud, e la coda può contenere cambiamenti di note o di cartelle. Il modello dei cambiamenti in attesa, però, fa nascere i cambiamenti solo dalle operazioni sulle note: non dice se anche le modifiche alle cartelle vadano inviate.

## Fix options

### Accodare anche le cartelle

Creazione, rinomina ed eliminazione di una cartella entrano nella stessa coda delle note e vengono inviate, in ordine, alla sincronizzazione successiva. Le cartelle arrivano così al cloud come le note. Costa qualche voce in più in coda e un aggiornamento del modello, che deve elencare le cartelle tra le nascite di un cambiamento in attesa.

### Tenere le cartelle solo sul dispositivo

Le cartelle restano sul dispositivo e non vengono inviate: quelle create su un dispositivo non compaiono sugli altri. È la soluzione più semplice, ma il modello e i requisiti devono dirlo esplicitamente, e il ramo di invio delle cartelle nella sincronizzazione va tolto perché non serve.

## Where in the code

lib/core/state/notes_provider.dart (createFolder, renameFolder, deleteFolder: solo salvataggio locale); lib/core/services/sync_service.dart (syncNow: ramo delle cartelle nella coda, mai alimentato)
