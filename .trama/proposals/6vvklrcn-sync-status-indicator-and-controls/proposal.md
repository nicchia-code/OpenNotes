---
status: rejected
requires:
  - dmplcaed
base:
  requirements/ui/cloud-sync.md: new
delete: []
created: 2026-10-17T09:24:28.684Z
---
# Sync status indicator and controls

Perché: oggi lo stato della sincronizzazione è quasi invisibile (una rotellina solo su desktop, errori solo nel registro, ora dell'ultimo sync mai mostrata) e su mobile non c'è modo di aggiornare a mano. Questa Proposal dà forma all'interfaccia delle decisioni della Proposal dmplcaed.

Decisioni prese nell'intervista:
- Indicatore sempre visibile con un utente connesso: icona nuvola accanto all'ingranaggio, nella barra laterale desktop e nella schermata Cartelle su mobile; stati sincronizzato, in corso, offline, errore; suggerimento con stato e ultima sincronizzazione; un tocco apre le impostazioni del cloud.
- Impostazioni del cloud con stato completo: stato attuale, ultima sincronizzazione in forma relativa, modifiche in attesa, ultimo errore con il prossimo tentativo, elenco delle note e cartelle non sincronizzate con "Riprova" e "Usa la versione del cloud".
- Una nota messa da parte mostra anche una piccola nuvola barrata nella sua riga dell'elenco.
- Trascina-per-aggiornare su mobile nella schermata Cartelle e nella lista note.
- Errori descritti per categoria; testi approvati: "Sincronizzato", "Sincronizzazione in corso…", "Offline: le modifiche verranno inviate al ritorno della rete", "Sincronizzazione non riuscita", "Alcune modifiche non si sincronizzano", "Ultima sincronizzazione: …", "Mai sincronizzato", "Modifiche in attesa: N", "Non sincronizzate", "Riprova", "Usa la versione del cloud"; categorie "Rete non raggiungibile", "Il cloud non risponde", "Accesso scaduto: accedi di nuovo", "Il cloud ha rifiutato la modifica", "Errore imprevisto".

Scelte di dettaglio derivate, da verificare: icone CupertinoIcons (`checkmark_icloud`, `icloud_slash`, `exclamationmark_icloud`) e rotellina `CupertinoActivityIndicator` come il resto dell'app; tempo scaduto e cloud non disponibile condividono il testo "Il cloud non risponde"; il controllo di aggiornamento su mobile è quello in stile iOS di Flutter; "1 minuto fa" al singolare e ore in formato 24 h; l'indicatore non compare senza utente connesso o con il cloud non configurato; l'icona della nota messa da parte sta accanto alla data nella riga; "Modifiche in attesa" non conta gli elementi messi da parte; la finestra delle impostazioni si aggiorna da sola mentre è aperta; dopo un accesso con sincronizzazione fallita compare "Sincronizzazione non riuscita: <categoria>. Nuovo tentativo tra N s".

## Feedback

Sostituita dalla Proposal 634nfp49, che la riunisce con dmplcaed sul Model attuale.
