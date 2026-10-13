---
column: done
technical: false
refs:
  - realtime-channel/Listening
  - realtime-channel.CLOUD_NOTE_APPLIED
  - realtime-channel.CLOUD_NOTE_REMOVED
drift: null
proposal: null
agent: false
created: 2026-10-12T07:26:44.638Z
finished: 2026-10-12T10:27:09.814Z
---
# Reload lists during a full sync when a remote change is applied

Quando una modifica remota viene applicata mentre è in corso una sincronizzazione completa, l'app deve mostrare subito il risultato: cartelle, tag ed elenco delle note si ricaricano al momento dell'applicazione, senza attendere la fine della sincronizzazione. Oggi il ricaricamento viene saltato finché la sincronizzazione è attiva e avviene solo alla sua conclusione.
