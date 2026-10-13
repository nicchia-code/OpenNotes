---
status: approved
base:
  cloud-sync/cloud-connection.md: 258fe3801d2b3887ec625a9f3f0e33d98e044712b142640d6b767e7e2de0116c
  cloud-sync/account.md: 79dadb7d827e558e745658065d5220139d221fdd74f292bedf3c2392d5489d58
  requirements/rules/cloud-sync.md: b7dd5ae214e613889ca195f9e55b2d735f2363b5594404ad55ff86fde0d471ce
  requirements/data/cloud-sync.md: 027bda47aaeadcd12ffad251d1c248f44f32638b27031c662333c7c3d5c23c31
  requirements/data/general.md: e47932acfc1286381763ab3fbd10974a11aaaa5f43cef9fcfb76e1eb8e296654
  requirements/tech/general.md: 48b865ef4ca4a2d62864cf275997254b6c71aa9b5a21a294297899ccab7eb0a4
delete: []
created: 2026-10-12T19:41:54.459Z
scanScope:
  - ref: account/Signed out/user.SIGN_IN_WITH_GOOGLE
    reason: changed
  - ref: cloud-connection
    reason: changed
  - ref: cloud-connection/Not configured/operating-system.APP_LAUNCHED
    reason: changed
  - ref: cloud-connection/Configuring/cloud-connection.CONFIGURED
    reason: changed
  - ref: cloud-connection.CONFIGURATION_FAILED
    reason: changed
  - ref: cloud-connection/Configuring/cloud-connection.CONFIGURATION_FAILED
    reason: leads into a change
  - ref: requirements/data#cloud-connection
    reason: changed
  - ref: requirements/data#General
    reason: changed
  - ref: requirements/rules#cloud-connection
    reason: changed
  - ref: requirements/tech#General
    reason: changed
---
# Require Supabase build variables without embedded defaults

Togliere indirizzo e chiave del progetto cloud incorporati nel codice: il collegamento al cloud deve venire solo dalle variabili di build, e una build in cui ne manca una deve dirlo chiaramente invece di usare in silenzio un progetto predefinito.

Decisioni:
- Nessun valore incorporato: indirizzo e chiave vengono solo dalle variabili di build SUPABASE_URL e SUPABASE_ANON_KEY.
- Una variabile conta come mancante se non è passata, è vuota o è fatta di soli spazi; nessun altro controllo sul formato.
- Se ne manca almeno una, all'avvio l'app resta usabile in locale e mostra una volta una barra temporanea che nomina la variabile o le variabili mancanti; il cloud resta non configurato.
- L'accesso Google, in quel caso, mostra lo stesso messaggio.
- Indirizzo e chiave non vengono più salvati né letti dalle preferenze del dispositivo; i valori scritti da versioni precedenti restano lì, ignorati.
- CI: le pull request da fork compilano senza valori (l'app prodotta mostrerà l'avviso); per gli altri eventi i segreti restano obbligatori.
- Sviluppo locale: i valori si passano a mano con --dart-define, nessun file nuovo.

Scelta mia da verificare: testo esatto del messaggio "Cloud non configurato: manca SUPABASE_URL.", "Cloud non configurato: manca SUPABASE_ANON_KEY.", "Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY."; se le variabili ci sono ma la preparazione fallisce, l'accesso continua a mostrare "Supabase non è ancora configurato".
