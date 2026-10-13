---
status: approved
kind: resolution
drifts:
  - drift: mmgf74kx
    decision: proposal
  - drift: 74heu6uj
    decision: proposal
  - drift: vs2z0lun
    decision: proposal
  - drift: s1joyu64
    decision: proposal
  - drift: c125tjpi
    decision: proposal
  - drift: 19uk21bm
    decision: fix-code
    option: 1
base:
  editor/editor-suggestions.md: feb6a44b7be2da0db06a59015f0bdb718719bd5c1b4793246d420f29c8c550a1
  organization/note-browser.md: f83e321a0107d229da80f9aba0f746f9637735d331f983e881a050e0811bbcd7
  cloud-sync/sync-run.md: 7ad760cc529aabc5dc85cf1e8ce5bd65b10e7187527ffd9f07101dcd137f2d17
  requirements/rules/organization.md: 7036b8269d344de953f2afe3f7c04402ce6cc6cbacb424deff2c26c0fb81dad1
  requirements/rules/cloud-sync.md: e957fe64e1e96d37dc77c1cdddc04b2144ab24d955f144598a7b05b164d66f0a
delete: []
created: 2026-10-12T16:24:25.074Z
---
# Resolve tag, search and sync Drifts

Risolve sei Drift:
- Drift mmgf74kx – Create-tag entry hidden when only letter case differs: il Model si adegua, la voce «Crea #testo» compare solo se nessun tag ha quel nome senza distinguere maiuscole e minuscole.
- Drift 74heu6uj – Tag filter matches whole tags, the Model says fragments: il Requirement si adegua, una nota corrisponde a un tag solo se ha quel tag intero.
- Drift vs2z0lun – Tag list refresh: trash, restore and move are not in the Model: il Model si adegua, l'elenco dei tag si aggiorna anche dopo cestino, ripristino, spostamento e duplicazione.
- Drift s1joyu64 – Creating a note clears the search text: il Model e il Requirement si adeguano, creare una nota svuota il testo di ricerca.
- Drift 19uk21bm – Later queued changes of a note already in the cloud are dropped by its own first send: si corregge il codice, i cambiamenti in coda si confrontano con le date del cloud lette all'inizio della sincronizzazione.
- Drift c125tjpi – Attachment download failure does not stop the sync run: il Model e il Requirement si adeguano, un'immagine che non si scarica non ferma la sincronizzazione e viene ritentata.
