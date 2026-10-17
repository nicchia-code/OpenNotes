---
status: rejected
base:
  cloud-sync/feature.md: 4768f08561ab6122960de022bab68b6feee71e13e1b4c343bfe86ea5d5392fc0
  cloud-sync/sync-run.md: ee2271fb46e72f5d25c3850da0c6d0776dfbde0ce06b2e38eb0abc8a23fbafe0
  cloud-sync/pending-change.md: 6f018911ae80b10e0a1eb7175cf816b39c25a066df677bb9c966ec993adaf040
  cloud-sync/realtime-channel.md: 11d0bb8cd391638d7621616638a8b6d1b532dade4865b5232701f3113c397d06
  cloud-sync/account.md: b15b341440acad22929625f0078128dc771d6796b3bad70e8d5fa6f3efe0112f
  cloud-sync/cloud-connection.md: 8ce371786a57c6c7464f80ad66ddc3e53b07722cc30170f22b56bcf9a5b1049b
  actors/operating-system.md: 73088e57ae16e8faedab428afaff4a42b43c12195e826cbd6750c1bd42ebda23
  actors/time.md: 764e80a3d4fdae598247fbda5337e68d681e6aad56b0ef9182e8e02526ad03be
  actors/supabase.md: b8c4e53cdb0a5fac261243aebcb5406a169d884de6f3c83fed6cfcd9eb0601ef
  actors/user.md: 49ceb3480c8a32815432dbba8dab9fa5372ac984be4f295be65cd0bf9c87ba53
  notes/note.md: eb637aecbe47993a0845382e024977e78248986745a3f8fb2df34ff333ad064c
  organization/folder.md: 61ed0f99c8ed27482babad0a04e6aec54b9102640b11b9330f5a9cc05d2cf96c
  editor/note-editor.md: d01906ccb0d7fd0cafe78e0653ad79f7430b1b6e1ffab56ceb708342a9e0fe51
  navigation/desktop-layout.md: 29ca2bd29216d69ce3ba0f6fc9ec13b537470cb0edf2aecdb6e93d2ed00b5494
  requirements/rules/cloud-sync.md: f9facdb3c0a3634513b232b1cc660c40c345d9aab33bb83d1c4bf6b4a373f3ef
  requirements/rules/notes.md: a66ec9d57b66296871b0876f2abb0e0f9ed56ce6bf26398a29ccb8317c06f865
  requirements/rules/organization.md: 9b7c2ecdac0b7da42b47c0a41350b6562b9cd1e88c7bd6465e4662978568d9cd
  requirements/data/cloud-sync.md: 7d245d931c57eddbd67094a477079014b2401d8fd147cfcbe14af2a8ab6a0968
  requirements/data/notes.md: fdc09982e965eca95817eab9de5366923bea782e45a1161a6b9d141b0ecc6b76
  requirements/data/organization.md: 18fafbea7ab1ce49fc7a8234bfff6b9f271f2ed196654e733d1bc828e7cb6038
  requirements/data/general.md: 90a1a4ab4b7e1377934c48ddafdd093d26d1fbb5b4b22253c1086b2e9486bd40
  requirements/tech/general.md: 1905e9b37594f4d894c399fb9be7bca2c6e1e1944bf2102c4ba945b8dc08daa7
  requirements/rules/sync-run.md: new
delete: []
request: 2026-10-17T10-48-54
created: 2026-10-17T09:13:43.848Z
---
# Reliable, aggressive cloud sync

Perché: il sync è lento e spesso non porta le modifiche a destinazione. L'esplorazione del codice ha trovato le cause: le richieste arrivate durante un sync vengono ignorate senza essere ripetute; ogni salvataggio avvia un sync completo che scarica e riscrive tutte le note; non si sincronizza al ritorno in primo piano, al ritorno della rete né dopo un'interruzione del canale in tempo reale; dopo un errore nessuno riprova e una richiesta appesa blocca tutto fino al riavvio; un cambiamento rifiutato blocca la coda per sempre; si confrontano ora del dispositivo e ora del server, quindi modifiche valide vengono scartate e l'eco dei propri invii sovrascrive modifiche locali; le eliminazioni fatte altrove spesso non arrivano mai.

Decisioni prese nell'intervista:
- Richieste durante un sync: ricordate, un solo nuovo giro alla fine.
- Ogni avvio fa un sync incrementale (invio della coda + download delle sole modifiche dall'ultima revisione scaricata); controllo completo all'avvio, all'accesso, con "Sincronizza Adesso" e con il trascina-per-aggiornare.
- Rilevamento delle modifiche con una revisione assegnata dal cloud; scritture solo tramite una funzione del database che rifiuta in modo atomico un invio basato su una revisione vecchia; le versioni vecchie dell'app non possono più scrivere.
- Conflitti veri: vince l'ultima modifica secondo l'ora di modifica sul dispositivo che l'ha fatta; lo stesso vale tra eliminazione e modifica.
- Eliminazioni come segnaposto sul cloud, conservati per sempre; il controllo completo elimina dal dispositivo note e cartelle già sincronizzate che il cloud non ha più.
- Primo sync dopo l'aggiornamento: controllo completo; copie uguali adottano la revisione, copie diverse seguono "vince l'ultima modifica".
- Nuovi avvii: ritorno in primo piano, ritorno della rete (connectivity_plus), ricollegamento del canale in tempo reale, sync periodico ogni minuto finché l'app è visibile, trascina-per-aggiornare su mobile; il rinnovo del token avvia solo un sync, senza riaprire il canale.
- Senza rete il sync si ferma e aspetta la rete; le richieste a mano provano comunque.
- Tempi massimi: 15 s per richiesta, 2 min per sync; nuovi tentativi dopo 2 s, 5 s, 15 s, 30 s, poi ogni 60 s; ogni nuovo avvio riprova subito.
- Un cambiamento rifiutato 3 volte di fila dal cloud viene messo da parte senza bloccare gli altri; l'utente può "Riprova" o "Usa la versione del cloud"; un nuovo salvataggio lo rimette in coda.
- Al più un cambiamento in coda per nota o cartella.
- Modifiche in tempo reale applicate una alla volta; se una non si applica parte un sync.
- La nota aperta senza modifiche in attesa si ricarica subito anche con il focus, mantenendo il cursore; con modifiche in attesa vale "vince l'ultima modifica".
- Allegati: si caricano solo quelli che il cloud non ha, si scaricano quelli mancanti a ogni sync, permessi di sovrascrittura ed eliminazione nella cartella dell'utente.
- Le cartelle seguono le stesse regole; le note spostate da un'eliminazione di cartella vengono inviate.
- L'app si apre subito e sincronizza in sottofondo.
- Dopo l'accesso "Sincronizzazione completata con successo." compare alla vera fine del sync; errori descritti per categoria.
- Schema cloud portato con migrazioni Supabase versionate.

Scelte di dettaglio derivate dalle decisioni, da verificare: la revisione è un numero unico crescente su tutto il progetto, che fa anche da cursore del download incrementale; l'ora di modifica sul cloud è quella del dispositivo (il server non la riscrive più); un'eliminazione definitiva in coda sostituisce il salvataggio in attesa della stessa nota; l'eliminazione di una cartella sul cloud porta le sue sottocartelle al primo livello; il sync dell'avvio parte dalla sessione iniziale, non più dall'avvio dell'app.

L'aspetto di indicatore, impostazioni e testi è nella Proposal successiva "Sync status indicator and controls".

## Already present
- `vault-file/Absent/note.SAVED` — `lib/core/services/vault_service.dart` (`VaultService.saveNote`)
- `vault-file/Written/note.SAVED` — `lib/core/services/vault_service.dart` (`VaultService.saveNote`)
- `vault-file/Written/note.PERMANENTLY_DELETED` — `lib/core/services/vault_service.dart` (`VaultService.deleteNoteFileIfUnused`)

## Feedback

Sostituita dalla Proposal 634nfp49, che la riporta sul Model attuale insieme a 6vvklrcn.
