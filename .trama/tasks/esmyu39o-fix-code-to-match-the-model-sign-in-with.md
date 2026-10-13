---
column: done
technical: false
refs:
  - account/Signed out/user.SIGN_IN_WITH_GOOGLE
drift: null
proposal: null
agent: false
created: 2026-10-12T14:49:47.776Z
finished: 2026-10-12T16:27:45.306Z
---
# Fix code to match the Model: Sign-in with a browser that cannot open shows a raw error, not "Accesso Google non completato"

Quando il browser non puo essere aperto su Linux, il plugin url_launcher lancia una PlatformException invece di restituire false. AuthService.signInWithGoogle (lib/core/services/auth_service.dart) chiude il ricevitore, esce dallo stato di attesa e ripropaga l'eccezione con rethrow; la finestra delle impostazioni (_handleGoogleSignIn in supabase_settings_dialog.dart) mostra quindi 'Errore: Failed to launch URL: ...'. Il Model dice che in questo caso l'app torna Signed out e mostra 'Accesso Google non completato'. Lo stato interno e gia corretto: manca solo il messaggio. Correggere: un fallimento nell'apertura del browser deve avere lo stesso esito del caso in cui l'apertura restituisce false (Signed out, messaggio 'Accesso Google non completato'). L'errore 'Supabase non e ancora configurato' deve restare com'e.
