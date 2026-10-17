---
status: approved
base:
  actors/operating-system.md: 73088e57ae16e8faedab428afaff4a42b43c12195e826cbd6750c1bd42ebda23
  actors/supabase.md: 4b2788d70e085bf0f4df4852eea37b8a5e4d22346c49da52bc44926d6452ea0b
  actors/time.md: 764e80a3d4fdae598247fbda5337e68d681e6aad56b0ef9182e8e02526ad03be
  actors/user.md: 49ceb3480c8a32815432dbba8dab9fa5372ac984be4f295be65cd0bf9c87ba53
  cloud-sync/account.md: 2df9da0d82e781fe649d05468e51d4186fe4edd94992f3aac9226a42945209e0
  cloud-sync/cloud-connection.md: 8ce371786a57c6c7464f80ad66ddc3e53b07722cc30170f22b56bcf9a5b1049b
  cloud-sync/feature.md: 4768f08561ab6122960de022bab68b6feee71e13e1b4c343bfe86ea5d5392fc0
  cloud-sync/pending-change.md: 8c51cec5ce415778f716a40de194985188280f53c234e8bc1bbc2d04d735c215
  cloud-sync/realtime-channel.md: fa8e5787a3293a898c2e51c43dbc24b5d332311ec975ad208a53f84a1397a74b
  cloud-sync/sync-run.md: ee2271fb46e72f5d25c3850da0c6d0776dfbde0ce06b2e38eb0abc8a23fbafe0
  editor/note-editor.md: d01906ccb0d7fd0cafe78e0653ad79f7430b1b6e1ffab56ceb708342a9e0fe51
  navigation/desktop-layout.md: 29ca2bd29216d69ce3ba0f6fc9ec13b537470cb0edf2aecdb6e93d2ed00b5494
  notes/note.md: eb637aecbe47993a0845382e024977e78248986745a3f8fb2df34ff333ad064c
  organization/folder.md: 61ed0f99c8ed27482babad0a04e6aec54b9102640b11b9330f5a9cc05d2cf96c
  requirements/data/cloud-sync.md: 7d245d931c57eddbd67094a477079014b2401d8fd147cfcbe14af2a8ab6a0968
  requirements/data/general.md: 90a1a4ab4b7e1377934c48ddafdd093d26d1fbb5b4b22253c1086b2e9486bd40
  requirements/data/notes.md: fdc09982e965eca95817eab9de5366923bea782e45a1161a6b9d141b0ecc6b76
  requirements/data/organization.md: 18fafbea7ab1ce49fc7a8234bfff6b9f271f2ed196654e733d1bc828e7cb6038
  requirements/rules/cloud-sync.md: 69099e2b06cad3c20e3333768f17df566026894b270141ce589d9bf6ac2a7674
  requirements/rules/notes.md: 024f6ea4b9e7b7172f311b292d54016c6a71d5e4301b713cc335a13a44131098
  requirements/rules/organization.md: 9b7c2ecdac0b7da42b47c0a41350b6562b9cd1e88c7bd6465e4662978568d9cd
  requirements/rules/sync-run.md: new
  requirements/tech/general.md: 62880e373c38f9d4b34ba5981006efd678a760f4d4bfcb7106f2f113a4a5ed54
  requirements/ui/cloud-sync.md: new
delete: []
created: 2026-10-17T10:30:03.906Z
---
# Reliable cloud sync with status indicator

Questa Proposal riunisce in un'unica modifica le Proposal dmplcaed "Reliable, aggressive cloud sync" e 6vvklrcn "Sync status indicator and controls", riportate sul Model attuale: dmplcaed non era più approvabile perché nel frattempo la Proposal 1mjjves7 ha cambiato account, coda dei cambiamenti, canale in tempo reale e regole del cloud, e 6vvklrcn dipendeva da lei.

Perché: il sync è lento e spesso non porta le modifiche a destinazione. L'esplorazione del codice ha trovato le cause: le richieste arrivate durante un sync vengono ignorate senza essere ripetute; ogni salvataggio avvia un sync completo che scarica e riscrive tutte le note; non si sincronizza al ritorno in primo piano, al ritorno della rete né dopo un'interruzione del canale in tempo reale; dopo un errore nessuno riprova e una richiesta appesa blocca tutto fino al riavvio; un cambiamento rifiutato blocca la coda per sempre; si confrontano ora del dispositivo e ora del server, quindi modifiche valide vengono scartate e l'eco dei propri invii sovrascrive modifiche locali; le eliminazioni fatte altrove spesso non arrivano mai.

Inoltre oggi lo stato della sincronizzazione è quasi invisibile (una rotellina solo su desktop, errori solo nel registro, ora dell'ultimo sync mai mostrata) e su mobile non c'è modo di aggiornare a mano.

Decisioni prese nell'intervista (sincronizzazione):
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

Decisioni prese nell'intervista (interfaccia):
- Indicatore sempre visibile con un utente connesso: icona nuvola accanto all'ingranaggio, nella barra laterale desktop e nella schermata Cartelle su mobile; stati sincronizzato, in corso, offline, errore; suggerimento con stato e ultima sincronizzazione; un tocco apre le impostazioni del cloud.
- Impostazioni del cloud con stato completo: stato attuale, ultima sincronizzazione in forma relativa, modifiche in attesa, ultimo errore con il prossimo tentativo, elenco delle note e cartelle non sincronizzate con "Riprova" e "Usa la versione del cloud".
- Una nota messa da parte mostra anche una piccola nuvola barrata nella sua riga dell'elenco.
- Trascina-per-aggiornare su mobile nella schermata Cartelle e nella lista note.
- Errori descritti per categoria; testi approvati: "Sincronizzato", "Sincronizzazione in corso…", "Offline: le modifiche verranno inviate al ritorno della rete", "Sincronizzazione non riuscita", "Alcune modifiche non si sincronizzano", "Ultima sincronizzazione: …", "Mai sincronizzato", "Modifiche in attesa: N", "Non sincronizzate", "Riprova", "Usa la versione del cloud"; categorie "Rete non raggiungibile", "Il cloud non risponde", "Accesso scaduto: accedi di nuovo", "Il cloud ha rifiutato la modifica", "Errore imprevisto".

Decisioni prese nell'intervista per l'unione con il Model attuale:
- Eliminazione ricevuta in tempo reale di una nota con una modifica in attesa più recente: vince l'ultima modifica, come per il giro di sync; la copia locale resta e rinasce sul cloud. Quando invece l'eliminazione è più recente, le modifiche in attesa vengono scartate subito, senza attendere la sincronizzazione (come oggi).
- Restano le regole approvate dopo dmplcaed: errore imprevisto all'avvio dell'accesso e ritorno con errore tramite il collegamento dell'app riportano l'account senza accesso, con "Accesso Google non completato" e "Accesso non completato:" seguito dal messaggio; anteprima e titolo per righe dei blocchi; avvio in sviluppo con `--dart-define-from-file=.env`.

Scelte di dettaglio derivate dalle decisioni, da verificare: la revisione è un numero unico crescente su tutto il progetto, che fa anche da cursore del download incrementale; l'ora di modifica sul cloud è quella del dispositivo (il server non la riscrive più); un'eliminazione definitiva in coda sostituisce il salvataggio in attesa della stessa nota; l'eliminazione di una cartella sul cloud porta le sue sottocartelle al primo livello; il sync dell'avvio parte dalla sessione iniziale, non più dall'avvio dell'app; icone CupertinoIcons (`checkmark_icloud`, `icloud_slash`, `exclamationmark_icloud`) e rotellina `CupertinoActivityIndicator` come il resto dell'app; tempo scaduto e cloud non disponibile condividono il testo "Il cloud non risponde"; il controllo di aggiornamento su mobile è quello in stile iOS di Flutter; "1 minuto fa" al singolare e ore in formato 24 h; l'indicatore non compare senza utente connesso o con il cloud non configurato; l'icona della nota messa da parte sta accanto alla data nella riga; "Modifiche in attesa" non conta gli elementi messi da parte; la finestra delle impostazioni si aggiorna da sola mentre è aperta; dopo un accesso con sincronizzazione fallita compare "Sincronizzazione non riuscita: <categoria>. Nuovo tentativo tra N s".

## Already present
- `vault-file/Absent/note.SAVED` — `lib/core/services/vault_service.dart` (`VaultService.saveNote`)
- `vault-file/Written/note.SAVED` — `lib/core/services/vault_service.dart` (`VaultService.saveNote`)
- `vault-file/Written/note.PERMANENTLY_DELETED` — `lib/core/services/vault_service.dart` (`VaultService.deleteNoteFileIfUnused`)
