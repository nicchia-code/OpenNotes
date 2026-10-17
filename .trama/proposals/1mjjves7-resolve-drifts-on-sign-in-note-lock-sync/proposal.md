---
status: approved
kind: resolution
drifts:
  - drift: nlxz5961
    decision: proposal
  - drift: j79776a3
    decision: proposal
  - drift: 3pmjq4b3
    decision: proposal
  - drift: cgeauhd2
    decision: fix-code
    option: 1
  - drift: 4cmkmlr2
    decision: proposal
  - drift: 94f8qgwb
    decision: fix-code
    option: 1
  - drift: tmqlmwhd
    decision: proposal
  - drift: x026fp6p
    decision: proposal
base:
  requirements/docs/readme.md: 5947c7b9511da5fc14d4cf22af63ba9c6dc4fed1048415021f3a03d995a2b4be
  cloud-sync/account.md: b15b341440acad22929625f0078128dc771d6796b3bad70e8d5fa6f3efe0112f
  actors/supabase.md: b8c4e53cdb0a5fac261243aebcb5406a169d884de6f3c83fed6cfcd9eb0601ef
  note-lock/note-access.md: 9b496cc14af48e30f123b1b3c4a5863d6d53d2148f1a1793773e5b2ae96a620f
  cloud-sync/pending-change.md: 6f018911ae80b10e0a1eb7175cf816b39c25a066df677bb9c966ec993adaf040
  cloud-sync/realtime-channel.md: 11d0bb8cd391638d7621616638a8b6d1b532dade4865b5232701f3113c397d06
  requirements/rules/cloud-sync.md: f9facdb3c0a3634513b232b1cc660c40c345d9aab33bb83d1c4bf6b4a373f3ef
  editor/text-line.md: 49a65e2eeb460789e1f8a8628ab53187babe6022776d9965728e1546a85c31aa
  requirements/rules/editor.md: eff22bfa8f0195ed0fb63e8cfafcee9e44fe71936b08a92b8b9a4dfda1fe74b4
delete: []
created: 2026-10-17T10:00:35.842Z
---
# Resolve Drifts on sign-in, note lock, sync queue, editor rules and screenshots

Risolve otto Drift secondo le risposte del developer:
- nlxz5961 – Dark theme screenshot cannot be produced on Linux: proposal. Il README mostra solo la cattura in tema chiaro; il Requirement della documentazione lo dice.
- j79776a3 – App-link sign-in error ends Signed out, the Model does not say so: proposal. Il Model descrive il ritorno con errore tramite il collegamento dell'app, che riporta l'account senza accesso con il messaggio di errore.
- 3pmjq4b3 – Unexpected sign-in start error ends Signed out, the Model says Awaiting login: proposal. Il Model descrive l'errore imprevisto all'avvio dell'accesso, che lascia l'account senza accesso.
- cgeauhd2 – Re-protected note stays visible when it was unlocked earlier in the session: fix-code. Mettere il lucchetto nasconde subito quella nota; il Model toglie la transizione che la lasciava sbloccata per la sessione.
- 4cmkmlr2 – Realtime cloud delete of a synced note drops its queued saves at once: proposal. Il Model e il Requirement degli scarti dicono che i salvataggi in coda vengono tolti subito.
- 94f8qgwb – Lock toggle can save an older text over a newer one still being written again: fix-code. Il cambio del lucchetto salva prima il testo in attesa.
- tmqlmwhd – Requirement and Model still say the Elenco menu sets a fixed «• » symbol: proposal. Menu Aa e menu rapido mettono il simbolo del livello di rientro.
- x026fp6p – Requirement says a checklist tap counts up to the first letter of the item, the Model says the circle only: proposal. Il tocco conta solo sul cerchio e sul carattere subito dopo.
