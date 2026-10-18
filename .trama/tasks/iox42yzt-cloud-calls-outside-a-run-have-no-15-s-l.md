---
column: done
technical: false
refs:
  - sync-run/Waiting to retry/pending-change.CLOUD_VERSION_REQUESTED
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-18T20:14:41.897Z
finished: 2026-10-18T20:17:00.513Z
---
# Cloud calls outside a run have no 15 s limit

Every request to the cloud must give up after 15 s, whether it is part of a sync run or not. Two calls made outside a run still wait without limit: checking whether the cloud still holds the note or folder of a set-aside change before the user picks its cloud version (useCloudVersion), and reading the cloud title of each set-aside change for the settings window (setAsideChanges). When the 15 s pass, the request must fail, as a request inside a run fails with the category tempo scaduto. The settings window must not stay waiting on the cloud.
