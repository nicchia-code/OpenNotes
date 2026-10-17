---
status: resolved
resolution: fix-code
refs:
  - requirements/ui#sync-run
proposal: null
task: qejqg8ze
origin: nazhstc0
critical: false
option: 1
note: null
resolvedBy: awa4vyj9
created: 2026-10-17T13:48:18.082Z
---
# Sync status icons missing from CupertinoIcons

## What happens

Il Requirement chiede per lo stato di sincronizzazione le icone **nuvola con segno di spunta**, **nuvola con punto esclamativo** e **nuvola barrata**. La famiglia di icone dell'app (CupertinoIcons, versione 1.0.9 con Flutter 3.47.7) non contiene nessuna icona nuvola con segno di spunta, punto esclamativo o barra: non esiste nulla da mostrare con quel nome. L'indicatore oggi usa un cerchio con spunta, un cerchio con esclamativo e un Wi-Fi barrato, cioè forme diverse da quelle richieste.

## What should happen

Il Requirement dice che l'indicatore mostra le icone di nuvola della famiglia CupertinoIcons, come nel resto dell'app. Queste tre icone non esistono in quella famiglia, quindi il Requirement non può essere seguito alla lettera e la scelta di forma non è mia da fare.

## Fix options

### Comporre la nuvola con il segno di spunta, esclamativo o barra

Si usa l'icona nuvola della famiglia CupertinoIcons con una piccola icona di stato sovrapposta (spunta, esclamativo o barra), tutte della stessa famiglia. Il risultato somiglia alle icone richieste, senza nuove dipendenze. Costa un po' di lavoro di disegno per il layout nelle due dimensioni (barra laterale e schermata Cartelle).

### Tenere le icone a cerchio già presenti

Si mantengono le icone attuali: cerchio con spunta, cerchio con esclamativo e Wi-Fi barrato. Non serve nessun disegno nuovo e il codice resta com'è. Però le forme non corrispondono al Requirement e l'utente vede un simbolo diverso da quello descritto.

### Disegnare le tre icone nuvola con CustomPaint

Si disegnano a mano le tre nuvole (spunta, esclamativo, barra) con un pittore personalizzato, con l'aspetto richiesto. Corrisponde al Requirement nella forma, ma le icone non fanno parte della famiglia CupertinoIcons e vanno mantenute a mano, con il rischio di un aspetto leggermente diverso dal resto dell'app.

## Where in the code

lib/ui/sync/sync_status_indicator.dart; lib/ui/settings/supabase_settings_dialog.dart (_syncStateIcon)
