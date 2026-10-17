---
status: approved
kind: resolution
drifts:
  - drift: 84ymfebe
    decision: proposal
  - drift: 3yj68v5k
    decision: fix-code
    option: 1
  - drift: f6zha77x
    decision: proposal
  - drift: 2jgk8b4t
    decision: proposal
  - drift: nmye93fq
    decision: fix-code
    option: 1
  - drift: 1ufwn1xw
    decision: fix-code
    option: 1
  - drift: 0k2ttes0
    decision: fix-code
    option: 1
  - drift: 2263mz3e
    decision: fix-code
    option: 1
  - drift: ghj7qtkr
    decision: fix-code
    option: 1
  - drift: q8ltod50
    decision: fix-code
    option: 1
  - drift: o5w5sfaw
    decision: proposal
base:
  requirements/tech/general.md: 7c6879eff992aee0270d7ca31275691b3e6ac75498147a4e832fbdce96976898
  editor/editor-suggestions.md: 3c991cf3380d3efb40d1fbc173f5886dd670879977189df6755f95baeb918ac0
  editor/note-content-save.md: e9d2c7ca1d1c77204de8c8b7b2f7f78895406ea2398dcf82d25b68e1dd09c542
  editor/note-editor.md: 69f4bf931fc8dec84b76cafe975b06409d4e77e73856e6f4d13ff3bbaed5dfad
  requirements/rules/editor.md: 797781f4ea705fd7f6078ddb22bdaccc6fc6ff17d5628ee86a184ba3e757e12b
  requirements/rules/editor-text.md: new
delete: []
created: 2026-10-17T17:36:54.096Z
---
# Resolve editor, sync and icon Drifts

Risoluzione di undici Drift secondo le risposte del developer.

- 84ymfebe «Full-bleed icon cannot be 1024 px»: si adottano le modifiche della Proposal allegata; l'icona a tutta superficie diventa il quadrato pieno più grande che sta nel riquadro, circa 876×876 px, centrato.
- 3yj68v5k «Realtime note change does not download its missing attachments»: correzione del codice; una nota arrivata in tempo reale scarica subito, dentro la modifica, le immagini e i disegni che mancano.
- f6zha77x «Tag suggestions open after a line break again»: Model e Requisito si adeguano; il menu dei tag si apre anche per un cancelletto dopo un a capo o una tabulazione.
- 2jgk8b4t «Failed save of a note is lost when another note is edited meanwhile»: Model e Requisito descrivono il fallimento di una scrittura; la versione non scritta torna in attesa, ma viene scartata se un'altra versione è già in attesa.
- nmye93fq «Settings window waits for a sign-in sync that already started»: correzione del codice; la finestra delle impostazioni riconosce la fine del giro avviato dall'accesso, avvisata alla fine di ogni giro.
- 1ufwn1xw «Queued folder or note delete loses to a cloud copy with the same time»: correzione del codice; nel download e nel tempo reale, a parità d'ora con un'eliminazione in coda, la copia del cloud vince subito, come all'invio.
- 0k2ttes0 «Folder delete is queued after its row is removed, without its cloud revision»: correzione del codice; l'eliminazione di una cartella entra in coda prima che la cartella sia tolta, con la revisione del cloud vista dal dispositivo.
- 2263mz3e «Cloud errors answered by the database are not sorted into their categories»: correzione del codice; anche le risposte di errore del database vengono classificate dal loro codice di stato.
- ghj7qtkr «A run past its time limit can still complete»: correzione del codice; se il tempo massimo del giro scade durante gli allegati, il giro fallisce con tempo scaduto.
- q8ltod50 «Duplicate of a Markdown note with an empty heading loses its first text line»: correzione del codice; nella copia cambia solo la riga dell'intestazione.
- o5w5sfaw «Edit typed just before going back is saved, the Model says it is discarded»: Model e Requisito si adeguano; tornando all'elenco su mobile la modifica in attesa viene salvata.
