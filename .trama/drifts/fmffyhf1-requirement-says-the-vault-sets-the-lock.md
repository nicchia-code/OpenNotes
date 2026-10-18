---
status: resolved
resolution: proposal
refs:
  - requirements/data#note-access
proposal: null
task: null
origin: null
previous: gj6o3a5s
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:27:54.619Z
---
# Requirement says the vault sets the lock on reading, the app never reads the vault

## What happens

Il Requirement del lucchetto dice che il front matter del file Markdown nel vault è letto e che l'intestazione locked, oppure is_locked, può impostare il lucchetto di una nota. Il codice invece scrive il file del vault a ogni salvataggio e non rilegge mai quei file: nessuna nota entra nell'app da un file, quindi nessuna nota nasce protetta per la sua copia nel vault. Il Model dell'accesso non descrive più questa lettura, come deciso con il Drift gj6o3a5s, quindi Model e Requirement dicono cose diverse sullo stesso punto.

## What should happen

Il Requirement del lucchetto nei dati dovrebbe dire che il lucchetto è salvato in locale, nel vault e sul cloud, senza una lettura del vault che lo imposti. Il Model del vault dice che l'app non rilegge mai il vault. Il comportamento osservato coincide con il Model del vault e con la decisione del Drift gj6o3a5s; resta solo la frase del Requirement da allineare.

## Fix options

### Remove the vault reading from the Requirement (recommended)

Si toglie dal Requirement del lucchetto la lettura dell'intestazione del vault, cioè la frase sul campo locked letto dal file e sull'accettazione di is_locked in lettura. Il codice non cambia e il Model resta com'è. Costo: una frase del Requirement, nessun effetto per l'utente, perché l'app non legge mai i file del vault. Va tolta anche la lettura di is_pinned, is_locked e is_deleted nel Requirement dell'export, se corrisponde.

### Read the vault back to set the lock

Si aggiunge la lettura dell'intestazione dei file del vault, così il campo locked può impostare il lucchetto di una nota al suo ritorno nell'app. Costo: il vault diventa una fonte di dati, contro il Model del vault che dice che l'app non lo rilegge mai. La scelta del Drift gj6o3a5s va riaperta e vanno riscritte le regole di lettura del vault e del Model dell'accesso.

## Where in the code

lib/core/services/vault_service.dart (solo scrittura del file, con il campo locked; nessuna funzione di lettura del front matter)
