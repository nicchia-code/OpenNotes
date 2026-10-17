---
status: approved
kind: resolution
drifts:
  - drift: 0i085zsy
    decision: fix-code
    option: 1
  - drift: 398nzl7k
    decision: proposal
base:
  cloud-sync/account.md: 9ece57d0cd8ce2e8030234260f262d16439f222182c4c953c636673355074305
delete: []
created: 2026-10-17T07:44:48.004Z
---
# Resolve Linux title bar and sign-in messages drifts

Risolve due Drift:
- 0i085zsy Linux window keeps the compositor title bar on COSMIC: si corregge il codice; su Wayland la finestra concorda con il compositore che la cornice la disegna lei, così COSMIC non aggiunge la propria barra del titolo.
- 398nzl7k Sign-in messages appear only after the browser returns: si tiene il comportamento attuale; durante l'attesa del ritorno da Google la finestra delle impostazioni mostra solo che il browser si sta aprendo, e i messaggi di accesso e di sincronizzazione compaiono dopo il ritorno, con una sincronizzazione vera.
