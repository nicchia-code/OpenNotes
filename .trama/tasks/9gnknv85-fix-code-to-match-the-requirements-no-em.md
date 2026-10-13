---
column: done
technical: false
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
  - requirements/rules#cloud-connection
  - requirements/data#cloud-connection
  - requirements/tech#General
drift: null
proposal: llyxqjwk
agent: false
created: 2026-10-12T19:46:07.388Z
finished: 2026-10-13T05:08:50.709Z
---
# Fix code to match the Requirements: no embedded Supabase address or key

Indirizzo e chiave del progetto cloud devono venire solo dalle variabili di build SUPABASE_URL e SUPABASE_ANON_KEY: nel codice non deve restare nessun valore predefinito (oggi lib/core/services/sync_service.dart ha un progetto incorporato come fallback), quindi il collegamento non si prepara mai senza variabili. Una variabile conta come mancante se non è passata, è vuota o è fatta solo di spazi; spazi iniziali e finali si tolgono prima dell'uso; il formato non viene controllato. Il collegamento si prepara solo se nessuna delle due manca. Indirizzo e chiave non vengono più letti né scritti nelle preferenze del dispositivo (oggi le chiavi supabase_url e supabase_anon_key vengono lette all'avvio e riscritte a ogni preparazione): i valori scritti da versioni precedenti restano sul dispositivo ma sono ignorati e non vengono cancellati. Effetto sull'accesso Google: senza variabili valide non parte alcun accesso verso un progetto predefinito.
