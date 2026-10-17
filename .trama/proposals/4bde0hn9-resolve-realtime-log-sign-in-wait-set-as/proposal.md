---
status: approved
kind: resolution
drifts:
  - drift: sxfv96ob
    decision: fix-code
    option: 1
  - drift: 89w5h3g4
    decision: fix-code
    option: 1
  - drift: zvj3b3j1
    decision: fix-code
    option: 1
  - drift: h4kt62zv
    decision: proposal
base:
  notes/note.md: 40d57d03935cff2f1e3801a37ac9811e5ff575396be6f6a18e2bc5015fa317e3
delete: []
created: 2026-10-17T19:46:00.191Z
---
# Resolve realtime log, sign-in wait, set-aside icon and moved notes drifts

Risolve quattro Drift:

- Drift sxfv96ob «Realtime failures have no app log to write to yet»: correggere il codice; l'errore di una modifica ricevuta in tempo reale che non si applica viene annotato nel registro dell'app, che ora esiste.
- Drift 89w5h3g4 «Sign-in window waits for the whole sync chain, the Requirement waits for the first run»: correggere il codice; il motore di sincronizzazione segnala la fine del primo giro avviato dall'accesso e la finestra delle impostazioni annuncia l'esito in quel momento.
- Drift zvj3b3j1 «Set-aside note marker is not the cloud-with-slash icon of the icon family»: correggere il codice; la riga di una nota messa da parte riusa, in piccolo, l'icona offline dell'indicatore di sincronizzazione.
- Drift h4kt62zv «Moved notes rewrite their vault copy, the note Model says they do not»: aggiornare il Model; quando una cartella viene eliminata, la copia nel vault di ogni nota spostata nella cartella Note viene riscritta con la cartella nuova.
