---
column: done
technical: true
refs:
  - requirements/docs#General
  - requirements/tech#General
drift: null
proposal: ujrlb98a
agent: false
created: 2026-10-17T09:32:02.339Z
finished: 2026-10-17T10:07:09.823Z
---
# Write the README, the MIT license and the env example

Sostituire il `README.md` generato da Flutter con quello descritto nei Requirements della documentazione, con sezioni, ordine e contenuti indicati, in inglese e in stile minimale.

- Aggiungere `LICENSE` con il testo MIT intestato a Luca Soda, 2026.
- Aggiungere `.env.example` con `SUPABASE_URL=` e `SUPABASE_ANON_KEY=` vuoti ed escludere `.env` in `.gitignore`.
- Il comando di avvio in locale del README usa `--dart-define-from-file=.env`; verificare che funzioni con la versione di Flutter di `.fvmrc`.
- Il README mostra gli screenshot di `docs/screenshots/` e non contiene URL o chiavi Supabase reali.
