---
status: resolved
resolution: fix-code
refs:
  - sync-run/Sending unsynced notes
  - requirements/rules#sync-run
proposal: null
task: 1mijxbxh
origin: null
critical: false
option: 1
note: null
resolvedBy: nztyyq3m
created: 2026-10-13T06:35:43.526Z
---
# Edits made while unsynced notes are being sent are lost

## What happens

Quando una sincronizzazione invia le note mai sincronizzate, può capitare che l'utente modifichi una di quelle note mentre il suo invio è in corso. Il dispositivo però riscrive la nota con la copia di prima dell'invio, quindi la modifica sparisce anche dalla vista locale. Il cloud riceve la copia vecchia con l'orario del momento dell'invio. Alla sincronizzazione successiva la modifica, rimasta in coda, risulta più vecchia del cloud e viene scartata: il testo scritto dall'utente va perso sia sul dispositivo sia nel cloud.

## What should happen

La regola di sincronizzazione dice che vince l'ultimo che ha scritto. Una modifica fatta dall'utente durante la sincronizzazione è più recente della copia inviata, quindi non deve essere sostituita da una copia più vecchia né sul dispositivo né nel cloud. La nota deve essere segnata come sincronizzata solo quando la copia inviata è ancora quella attuale, e la modifica deve arrivare al cloud senza essere scartata.

## Fix options

### Reinviare la nota finché resta invariata

Prima di ogni invio la nota viene riletta dal dispositivo. Se è cambiata mentre veniva inviata, viene inviata di nuovo nella stessa sincronizzazione, e solo a invio concluso con una copia invariata viene segnata come sincronizzata. Costo: un invio in più quando una nota viene modificata durante la sincronizzazione. Resta una finestra minima se la modifica cade proprio tra la lettura e l'invio.

### Bloccare il salvataggio durante l'invio

Mentre una nota mai sincronizzata viene inviata, i salvataggi di quella nota aspettano la fine dell'invio prima di scrivere sul dispositivo e in coda. Così la copia inviata è sempre quella attuale e nessuna modifica viene sovrascritta. Costo: un salvataggio può attendere il tempo di un invio, e l'editor deve gestire questa attesa senza perdere il testo digitato.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo 3 (invio delle note mai sincronizzate); lib/core/state/notes_provider.dart: salvataggi delle note
