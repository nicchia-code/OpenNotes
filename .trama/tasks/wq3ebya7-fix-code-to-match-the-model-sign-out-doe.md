---
column: done
technical: false
refs:
  - realtime-channel/Open/supabase.SIGNED_OUT
drift: null
proposal: null
agent: false
created: 2026-10-17T11:30:21.559Z
finished: 2026-10-17T11:36:01.540Z
---
# Fix code to match the Model: Sign-out does not close the realtime channel

Il Model dice che, con il canale aperto, supabase.SIGNED_OUT chiude il canale e torna in Closed; le note e le cartelle locali restano. Oggi il ramo di sessione non ha un caso per SIGNED_OUT (sync_service.dart, _setupAuthListener): il canale resta collegato dopo l'uscita dall'account e continua a ricevere modifiche. Va aggiunto il ramo che fa unsubscribe del canale e lo azzera. Di conseguenza il ramo TOKEN_REFRESHED, che riapre il canale solo se _realtimeChannel è null, deve poter riaprire un canale chiuso dal sign-out: oggi la condizione non si verifica mai dopo la prima apertura.
