---
column: done
technical: false
refs:
  - cloud-connection/Not configured
drift: null
proposal: null
agent: false
created: 2026-10-13T05:23:19.318Z
finished: 2026-10-13T05:35:32.439Z
---
# Fix code to match the Requirements: Google sign-in shows the missing-variable notice with an extra prefix

Il Requirement requirements/rules#cloud-connection dice che il tentativo di accesso Google, con il collegamento non configurato, mostra lo stesso testo dell'avviso ("Cloud non configurato: manca SUPABASE_URL.", "Cloud non configurato: manca SUPABASE_ANON_KEY." o "Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY."). Il codice invece mostra "Errore:  Cloud non configurato: ..." con uno spazio in più: AuthService.signInWithGoogle lancia Exception(notConfiguredMessage), e in SupabaseSettingsDialog._handleGoogleSignIn il catch generico antepone "Errore: " e toglie "Exception:" lasciando lo spazio iniziale del messaggio.

## Cosa deve succedere
Con il collegamento non configurato, il tentativo di accesso Google mostra esattamente il testo di notConfiguredMessage, senza prefisso "Errore:" e senza spazi aggiunti. Gli altri errori di accesso mantengono il comportamento attuale.

## Dove nel codice
lib/ui/settings/supabase_settings_dialog.dart (_handleGoogleSignIn); lib/core/services/auth_service.dart (signInWithGoogle).
