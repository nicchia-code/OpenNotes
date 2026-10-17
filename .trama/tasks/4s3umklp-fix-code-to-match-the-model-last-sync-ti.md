---
column: done
technical: false
refs:
  - sync-run/Pulling
  - requirements/data#sync-run
  - requirements/ui#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-17T14:13:05.049Z
finished: 2026-10-17T15:44:36.645Z
---
# Fix code to match the Model: Last sync time is lost when the app restarts

Ogni giro completato registra l'ora dell'ultima sincronizzazione e la conserva tra un avvio e l'altro. Oggi l'ora vive solo in memoria: dopo un riavvio la finestra del cloud e il suggerimento dell'indicatore mostrano "Mai sincronizzato" anche se il dispositivo ha già completato sincronizzazioni. Quando un giro completa, l'ora va salvata nelle preferenze locali con la chiave prevista dal Requirement, e all'avvio va ripresa da lì. Fatto quando: dopo un giro completato e un riavvio dell'app, la finestra del cloud e il suggerimento dell'indicatore mostrano l'ora di quella sincronizzazione, non "Mai sincronizzato".
