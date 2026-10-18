---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_DELETED
drift: null
proposal: null
agent: false
created: 2026-10-18T19:45:57.680Z
finished: 2026-10-18T19:50:49.490Z
---
# Remote delete of a system folder keeps the folder and its notes

Il Model dice che una cartella eliminata nel cloud viene eliminata localmente salvo che sia di sistema. Il codice (_removeRemoteFolder in sync_service.dart) sposta comunque le note della cartella di sistema nella cartella Note e riscrive i loro file nel vault, anche se la cartella di sistema resta. Correggere: per una cartella di sistema la cartella e le sue note restano invariate, la copia locale resta.
