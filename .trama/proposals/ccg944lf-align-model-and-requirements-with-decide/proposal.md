---
status: approved
kind: resolution
drifts:
  - drift: qwpmhpqe
    decision: fix-code
    option: 1
    note: "Il codice elimina già la cartella nel cloud. In più: un'eliminazione di cartella in coda viene scartata se la cartella del cloud è stata modificata dopo il momento dell'eliminazione; nella sincronizzazione completa le cartelle si scaricano prima delle note."
  - drift: 2tbpiuf1
    decision: proposal
  - drift: x583dq3d
    decision: fix-code
    option: 1
    note: "Una modifica di cartella in coda sovrascrive la cartella del cloud anche se il cloud la ha già: va tolto il controllo che oggi la scarta."
  - drift: dpp54haj
    decision: proposal
  - drift: hvdlwnl6
    decision: proposal
  - drift: qk19azhx
    decision: proposal
  - drift: n84o2yme
    decision: fix-code
    option: 1
    note: Quando l'app va in secondo piano o si chiude (anche chiudendo la finestra desktop) l'editor consegna subito le modifiche in attesa e la scrittura su disco parte subito.
  - drift: dq6kgy0j
    decision: proposal
  - drift: 80pfpybi
    decision: proposal
  - drift: lwf8h1nn
    decision: proposal
base:
  organization/folder.md: 92d062d8121bf22b5e19373df6e9616871deacc5c1650fa2883fd9b845f62ee9
  cloud-sync/pending-change.md: 8bb9d8394cad8d785a40b776f0ff1a8efeb0040db44374b1814bf92e8d8c3972
  cloud-sync/sync-run.md: 9376c1e89dc480bea7aa4f04312c057d052f2e059050f486c8773d7d35aa0b6a
  cloud-sync/realtime-channel.md: 18ecc5e3bc94fb27741a98a9bd260644d8f96f0926b39b92f7d27d23bf4db782
  cloud-sync/account.md: fe84045a7fb14c9de74510e6578a37d997b21d97a328dbdfd9c867d52bb1bacc
  notes/note.md: 92c40bb53c8cb7c298bd35291c91db8ad1653f9aa8c7bb2bd07174f4ea372b1f
  export/vault-file.md: e8d27406de2ee0328b6623c94ca5da6f9b46e3e11afa345a1396572cc19ced1b
  editor/note-content-save.md: 85ed4cee8f42e171b875ec3b455de73663363d205d6e8cdb25b2282dc4c7c5f5
  actors/operating-system.md: b53e7069d2616ad8eb0bf15d8e28467092ed8a28b001c3590080e7ee7b033a88
  actors/user.md: 1f35abf7f7aa31dc9ffb7993f7ea81be0d539adbb5ec971df0861e4276c3bbc5
  editor/note-editor.md: 0b9a0fe7da661eec8e0545fcc9a56230a45eefab880c1057025228638e865a82
  editor/editor-suggestions.md: fd0670ca6fd336d13176a12a41d80143fb680bbb111fbaf1dc9777f675acaa59
  editor/text-line.md: 189a21b4f60386674106eb126a6a2d6b4a4a53810f0417182ae802950ea2b428
  editor/drawing-canvas.md: 95191cfd54238c2a8f696b1c9d7462db624dc09e76208ab5540bae3c19184fc0
  navigation/mobile-navigation.md: 2c39488d71b4b7a4f63b04086be6d1d7a7ebf13cbf5955b94fa3f4a6d05decef
  organization/note-browser.md: c9a7224007f04cdf796c0c6aa4d068808f52fb5cdd4133e14584d5b066c1c36e
  navigation/desktop-layout.md: 20aeb6f209a1c6aa6424db56a91318bdee2ce56337c1978532bbc6ce37e1d3d4
  navigation/app-window.md: 23c6d304abf78f31e9502f67d7d657b8abf1ae7bfdbd93c4aeb34186870fc58e
  requirements/rules/organization.md: 5f987ce92e878639db606d8980802c031ead95e38e7721917a0b50fc0cbe8fe5
  requirements/rules/cloud-sync.md: 0ee3e4a1d018d5a81587d2b38c3781ed5957bb65757394be2c2ce4cdccbe66b5
  requirements/data/cloud-sync.md: 7b33008bd108d02244d0f8826b1d2409cbf00d3bd04ce2f36e7d766c8e994ca4
  requirements/data/organization.md: 18fafbea7ab1ce49fc7a8234bfff6b9f271f2ed196654e733d1bc828e7cb6038
  requirements/rules/notes.md: ad74657cb715c32f297fcb992b340b1e93058c805942972116702120b4ec7732
  requirements/rules/editor.md: 761e1b92f02af857ad1f38a405396c3fa783b4295357fed4706f3891960201ef
  requirements/rules/export.md: 307a507599797a57d473500e11761ade1d27dac7a25f94d4db16510aa0230bb1
  requirements/rules/navigation.md: 1a226d9eb3086281113e20b6163e7ffb1826fb53edf6f6e40d6f5cd4fd7f60ea
  requirements/tech/general.md: e8a4a87a1f591c264222e558f35d4a363711c92c7237240608f742a8f129ffd5
  requirements/data/editor.md: ed4574c296d148bf2903d0864189a4ec628bbf40532d9021964066822ae14435
delete: []
created: 2026-10-12T13:43:36.473Z
---
# Align Model and Requirements with decided fixes

Correzione unica: allinea Model e Requirement al codice e alle decisioni già prese, così tutti i Drift aperti si chiudono e i Task «Fix code» diventano realizzabili. Decisioni del developer:

- Cartelle: creazione, rinomina ed eliminazione entrano in coda e partono alla sincronizzazione (qwpmhpqe, 2tbpiuf1, x583dq3d, pb2g9hf1, fz6fdbib).
- Cartella in coda già presente nel cloud: vince l'invio; il codice smette di scartarla.
- Eliminazione di cartella in coda: scartata se la cartella del cloud è stata modificata dopo; la cartella torna dal download.
- Sottocartelle di una cartella eliminata: diventano di primo livello (nel cloud subito, sul dispositivo dopo la sincronizzazione).
- Note di una cartella eliminata: nessun invio dello spostamento; al download una nota la cui cartella non esiste va in «Note» senza cambiare data (ry8lis4b, 59mfpbei).
- Sincronizzazione completa: le cartelle si scaricano prima delle note.
- Note di benvenuto mai sincronizzate: i loro salvataggi non entrano in coda (dpp54haj).
- Coda: nuovo esito finale «Scartato» per salvataggio non più recente del cloud, modifica di nota eliminata nel cloud, cambio di account, eliminazione più vecchia del cloud (hvdlwnl6, ru28nuer, x603i4hv, r6bi0p5m, ko9uuu3w).
- Modifica scartata di una nota eliminata nel cloud: la nota viene tolta con il suo file (bhdix46l).
- Eliminazione di nota fatta offline: scartata se il cloud è più recente; la nota torna con il download (ko9uuu3w).
- Eliminazioni dal cloud in tempo reale: le tabelle pubblicano la riga completa; filtro per utente invariato (0a3m6q0o).
- File del vault condiviso: si cancella solo se nessun'altra nota lo usa, in ogni rimozione; le note tolte nella stessa operazione non contano (yhz4j29v, rtzyskeq).
- La nota ricorda il percorso del suo file nel vault.
- Modifiche in attesa: quando l'app va in secondo piano o si chiude, editor e scrittura su disco consegnano e scrivono subito (n84o2yme).
- La scrittura in attesa riporta solo i campi del contenuto.
- PDF: corpo dalla conversione Markdown, senza la riga o il blocco del titolo (qk19azhx).
- Nota protetta nascosta: riceve le versioni remote come una nota aperta (dq6kgy0j).
- Checklist su nota nascosta: «mai mostrato» vale per la sessione dell'app (19b1oaw3).
- Titolo di un testo che comincia con «[» non JSON: la prima riga (80pfpybi).
- Anteprima: salta sempre il blocco da cui nasce il titolo (lwf8h1nn).
- Documento a blocchi: solo un elenco JSON di soli oggetti (tdzgvg5p).
- Tag: lettere e cifre di qualunque alfabeto (yck4ny7a; s01d7fus decade).
- Unico tag selezionato toccato di nuovo: toglie il filtro, tranne nella schermata Cartelle su mobile; il tag in Cartelle si applica una volta sola (tox25dpt, 2i7zc3sl, moxqr0lf).
- Stile «Aa» e pulsante checklist tolgono solo segni seguiti da spazio (56s33wvd, y2aw3iw3).
- Righe numerate, citazioni e monospazio rientrate mantengono il tipo (6e5vyttx, 5d3rt8xa).
- Menu rapido: si chiude quando il focus lascia la sua sezione (3cvm53vs); la voce Tabella toglie solo «/» (4yq7xbae).
- Disegno: nuovo stato «Salvataggio» (doppio tocco ignorato, errore con tela aperta); tela 4:3 sulla larghezza (y74iv1zv).
- Desktop: nel cestino la barra mostra menu azioni, protezione ed eliminazione (ps6i7ioy); larghezza minima 680×480; su macOS chiudere la finestra termina l'app.
- Account: ogni accesso con sessione porta a «connesso», anche fuori dall'attesa del login (sogqn8i2, trmcoco3).

Nessuna domanda è stata saltata.
