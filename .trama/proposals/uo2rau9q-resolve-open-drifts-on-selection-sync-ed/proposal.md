---
status: approved
kind: resolution
drifts:
  - drift: nxqato1u
    decision: fix-code
    option: 1
  - drift: k305l07x
    decision: fix-code
    option: 1
  - drift: tqy78s5w
    decision: proposal
  - drift: w5wxuj2f
    decision: fix-code
    option: 1
  - drift: 5l3vk4ae
    decision: fix-code
    option: 1
  - drift: n1lvn191
    decision: proposal
  - drift: 5wy1kjyy
    decision: proposal
  - drift: qf6ovb00
    decision: fix-code
    option: 1
  - drift: wf86lafo
    decision: fix-code
    option: 1
  - drift: imtfqodh
    decision: fix-code
    option: 2
  - drift: 5q024l63
    decision: fix-code
    option: 1
  - drift: plc2u598
    decision: fix-code
    option: 1
  - drift: iq0sfpit
    decision: fix-code
    option: 1
base:
  export/export-markdown-share.md: dc4ec107f17aa77941dfd84ef6cab25d7e48429cc369364425fcc5b535e401e9
  requirements/rules/editor.md: 8db2ad975f3c9258e5eb17abac4d96ae09b15da3404b79c949088deaa5146533
  requirements/rules/export.md: e102f0fc5aab9c2361054c602f54d056bd4dd35b401beb28c4638f7fc2685e31
delete: []
created: 2026-10-17T13:35:53.368Z
---
# Resolve open Drifts on selection, sync, editor, vault and share

Risoluzione di tredici Drift aperti, secondo le risposte dello sviluppatore.

- nxqato1u – Trash-view delete moves the selection to a neighbour although the note stays listed: si corregge il codice; nel Cestino la selezione resta sulla nota di cui si rinnova la data di eliminazione.
- k305l07x – Trashed note deleted in the cloud is kept, the Model removes it: si corregge il codice; la nota nel cestino eliminata nel cloud viene rimossa dal dispositivo con il suo file, come dice il Model.
- tqy78s5w – Block menu closes on typing, the Requirement closes it only when focus leaves: si aggiorna il Requirement; il menu rapido si chiude anche quando una modifica lascia la sezione senza «/» iniziale, come dice già il Model.
- w5wxuj2f – Note created in a folder view kept after a cloud deletion lands in a folder that no longer exists: si corregge il codice; creazione e copia verso una cartella che non esiste più usano la cartella Note.
- 5l3vk4ae – Changes received before sign-out keep being applied after it: si corregge il codice; alla chiusura del canale le modifiche ricevute e non ancora applicate vengono scartate.
- n1lvn191 – Share sheet failure is still not in the Model after its Drift was resolved: si aggiorna il Model; se il foglio di condivisione non si apre, l'app mostra un messaggio e torna a Idle.
- 5wy1kjyy – Title skips tag-only lines inside a block, the Requirement skips only tag-only blocks: si aggiorna il Requirement; il titolo salta le righe di soli tag anche dentro un blocco con altro testo, come dice già la regola del titolo delle note.
- qf6ovb00 – Background session refresh error shows as a failed sign-in while signed in: si corregge il codice; «Accesso non completato» compare solo per un errore arrivato mentre l'app attende il ritorno dall'accesso.
- wf86lafo – Open view of a folder deleted elsewhere is titled as another view: si corregge il codice; la vista tiene l'ultimo nome della cartella, su desktop e mobile.
- imtfqodh – Vault file: titles differing only by letter case share one file, and deleting one removes the other's copy: si corregge il codice; prima di cancellare un file del vault si verifica sul disco se un'altra nota punta allo stesso file.
- 5q024l63 – Protected note: the mobile Block menu button arms a menu that opens on unlock: si corregge il codice; con la nota protetta il pulsante non apre né prepara alcun menu.
- plc2u598 – Waiting edit when a cloud lock hides the open note: the Model has no exit for it: si corregge il codice; il lucchetto arrivato dal cloud consegna subito la modifica in attesa, poi nasconde la nota.
- iq0sfpit – Sign-out during a sync run: the Model does not say what the run does: si corregge il codice; senza sessione il giro si ferma, non programma tentativi e lascia la coda com'è.
