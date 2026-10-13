---
status: approved
kind: import
requires:
  - eibfecxn
base:
  cloud-sync/feature.md: new
  cloud-sync/cloud-connection.md: new
  cloud-sync/account.md: new
  cloud-sync/sync-run.md: new
  cloud-sync/pending-change.md: new
  cloud-sync/realtime-channel.md: new
  requirements/data/cloud-sync.md: new
  requirements/rules/cloud-sync.md: new
delete: []
created: 2026-10-12T06:57:34.520Z
---
# Import: Cloud sync

Importazione della Feature cloud-sync dal codice: collegamento a Supabase, accesso con Google, sincronizzazione completa bidirezionale, coda delle modifiche locali e canale in tempo reale. Fonti: lib/core/services/sync_service.dart, auth_service.dart, database_service.dart, lib/ui/settings/supabase_settings_dialog.dart, lib/main.dart, lib/core/state/notes_provider.dart, supabase/schema.sql, test/sync_service_test.dart, macos/Runner/*.entitlements.

## Doubts

- Le cartelle non vengono mai accodate: creazione, rinomina ed eliminazione di cartelle locali non creano cambiamenti (lib/core/state/notes_provider.dart:465-499), quindi il ramo di invio cartelle è codice morto (lib/core/services/sync_service.dart:272-282); le cartelle locali non arrivano mai al cloud, mentre quelle del cloud sovrascrivono le locali.
- Errori di sincronizzazione inghiottiti: solo una riga di log (lib/core/services/sync_service.dart:344-345; anche lib/main.dart:66-68); l'utente non riceve mai un errore e la finestra dice comunque "Sincronizzazione completata con successo" (lib/ui/settings/supabase_settings_dialog.dart:41-46).
- Un cambiamento in coda rifiutato in modo permanente (es. payload non valido o violazione delle policy) interrompe ogni sincronizzazione per sempre: il ciclo si ferma al primo errore e l'elemento non viene mai scartato, quindi anche il download resta bloccato (lib/core/services/sync_service.dart:236-287).
- URL di progetto e chiave anonima di default incorporati nel codice sorgente (lib/core/services/sync_service.dart:45-53): ogni build senza variabili d'ambiente punta al progetto dello sviluppatore.
- Bucket `note-attachments` pubblico in lettura per chiunque (supabase/schema.sql:102-114) ma mai usato dall'app: immagini e disegni restano solo nel vault locale e non vengono sincronizzati.
- La sincronizzazione chiesta durante la preparazione del collegamento è sempre ignorata, perché il segnale di occupato è già attivo (lib/core/services/sync_service.dart:72,94,228). Non determinato se l'evento di sessione iniziale arrivi prima o dopo lo spegnimento del segnale; all'avvio la sincronizzazione esplicita di lib/main.dart:63-69 la sostituisce.
- Dopo l'apertura del browser la finestra annuncia "Accesso completato!" e sincronizzazione riuscita, anche se l'utente non ha ancora completato l'accesso: la sincronizzazione chiesta non parte (lib/ui/settings/supabase_settings_dialog.dart:34-46).
- Il collegamento `opennotes://login-callback` non è registrato né in android/app/src/main/AndroidManifest.xml:23-26 né in ios/Runner/Info.plist: su mobile (e su desktop se la porta 3000 è occupata) il ritorno dall'accesso Google non può raggiungere l'app [INFERENCE]. Inoltre il manifest Android principale non dichiara il permesso INTERNET (presente solo in debug/profile), quindi una build release Android non raggiungerebbe il cloud [INFERENCE].
- Pulizia delle note di benvenuto inefficace: alla creazione vengono accodate (lib/main.dart:209-218 → lib/core/state/notes_provider.dart:259), il passo 1 le invia al cloud prima del controllo del passo 3, che poi le elimina in locale (il cloud ora ha note) e il passo 4 le riscarica; restano duplicate nel cloud per ogni dispositivo (lib/core/services/sync_service.dart:236-335).
- Le note di benvenuto sono riconosciute solo dal titolo: qualunque nota mai sincronizzata e non in coda con quei titoli (es. letta dal vault) verrebbe eliminata definitivamente (lib/core/services/sync_service.dart:309-316).
- Le note inviate dalla coda non vengono segnate come sincronizzate (lib/core/services/sync_service.dart:268,286): il passo 3 le reinvia una seconda volta nella stessa sincronizzazione.
- La data di modifica sul cloud viene riscritta dall'orologio del server a ogni aggiornamento (supabase/schema.sql:37-54): la regola "vince l'ultima modifica" confronta orologio del server con orologio del dispositivo, e l'eco in tempo reale del proprio invio risulta sempre più recente e sovrascrive la copia locale, con possibile perdita di modifiche fatte nel frattempo (lib/core/services/sync_service.dart:191-200).
- Il download completo non propaga le eliminazioni: note e cartelle eliminate sul cloud mentre l'app era chiusa restano sul dispositivo (lib/core/services/sync_service.dart:327-341); solo il canale in tempo reale elimina.
- L'eliminazione locale di una cartella sposta le note nella cartella "Note" senza cambiarne la data di modifica né accodarle (lib/core/services/database_service.dart:230-239), quindi al download successivo il cloud (a parità di data) le riporta nella cartella eliminata; lo stesso spostamento avviene anche se la cartella remota eliminata è di sistema e non viene cancellata.
- Il contenuto delle note bloccate viene inviato in chiaro al cloud: nessuna cifratura nel codice (lib/core/models/note_model.dart:529-544).
- Il percorso del file nel vault restituito al salvataggio non viene mai memorizzato per le note create o scaricate (lib/core/services/vault_service.dart:137-161; Note.fromSupabaseJson in lib/core/models/note_model.dart:546-575 non lo imposta), quindi le eliminazioni da cloud non cancellano il file del vault (lib/core/services/sync_service.dart:182-184,313-316) [INFERENCE].
- La coda non fonde i cambiamenti: ogni salvataggio dopo la pausa di 400 ms aggiunge un elemento con la nota intera; offline la coda cresce senza limite (lib/core/services/sync_service.dart:353-376).
- La disconnessione non svuota la coda: i cambiamenti accodati con un account vengono inviati assegnandoli all'utente connesso al momento dell'invio, anche se diverso (lib/core/services/sync_service.dart:247,275; lib/core/services/auth_service.dart:108-114).
- Riconfigurare il collegamento con un altro progetto non ha effetto: la seconda preparazione fallisce, l'errore viene ignorato e le nuove impostazioni vengono salvate come attive (lib/core/services/sync_service.dart:75-88); comunque nessuna interfaccia permette di cambiarle, e le proprietà indirizzo, chiave, configurato e ora dell'ultima sincronizzazione non vengono mai mostrate (lib/core/services/sync_service.dart:27-31).
- All'avvio con utente connesso possono partire due sincronizzazioni (esplicita in lib/main.dart:63-69 e da sessione iniziale in lib/core/services/sync_service.dart:119-124); la seconda viene scartata se la prima è in corso.
- Le modifiche in tempo reale vengono applicate anche durante una sincronizzazione completa, senza coordinamento (lib/core/services/sync_service.dart:134-172).
