---
column: done
technical: false
refs:
  - realtime-channel
  - supabase
  - requirements/rules#realtime-channel
drift: null
proposal: 634nfp49
agent: false
created: 2026-10-17T10:33:15.023Z
finished: 2026-10-17T13:50:26.748Z
---
# Realtime channel recovery

Il canale in tempo reale segue la macchina `realtime-channel` aggiornata.

- Iscrizione con callback di stato: dopo un'interruzione (REALTIME_INTERRUPTED), il ricollegamento (REALTIME_CONNECTED) emette RECONNECTED e chiede un giro incrementale; il primo collegamento no.
- Al rinnovo del token il canale resta aperto.
- Modifiche applicate una alla volta in ordine di arrivo; quelle con revisione già nota (anche l'eco dei propri invii) ignorate; "vince l'ultima modifica" rispetto alle modifiche in attesa, anche per le eliminazioni: un'eliminazione più recente rimuove la nota e ne scarta subito le modifiche in attesa, una modifica locale più recente la fa restare e rinascere sul cloud; i segnaposti trattati come eliminazioni (REMOTE_NOTE_DELETED, REMOTE_FOLDER_DELETED); allegati mancanti scaricati; un errore di applicazione annotato e seguito da CHANGE_NOT_APPLIED.

Fatto quando un'eliminazione fatta su un altro dispositivo arriva in tempo reale, l'eco di un proprio invio non sovrascrive una modifica locale più recente e, dopo un'interruzione del canale, le modifiche fatte altrove nel frattempo arrivano con il giro di recupero.
