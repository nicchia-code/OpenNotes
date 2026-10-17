---
status: approved
base:
  requirements/docs/area.md: new
  requirements/docs/readme.md: new
  requirements/tech/general.md: 1905e9b37594f4d894c399fb9be7bca2c6e1e1944bf2102c4ba945b8dc08daa7
delete: []
created: 2026-10-17T09:00:13.358Z
---
# Inviting README

Il README attuale è il modello generato da Flutter e non dice niente di OpenNotes. Questa Proposal descrive un README breve e invitante, una licenza e un file di esempio per l'avvio in locale.

Decisioni prese con il developer:
- Nuova Area «docs» per la documentazione del progetto, con un frammento per README, licenza e file di esempio.
- README in inglese, rivolto prima agli utenti e poi agli sviluppatori, in stile minimale.
- Apertura: titolo, frase «A local-first notes app inspired by Apple Notes, for desktop and mobile.» e due badge (CI e licenza).
- Due screenshot della finestra desktop, tema chiaro e scuro, con note di esempio inventate e mai con le note del developer.
- Installazione: pagina GitHub Releases per Windows, macOS e Linux; Android e iOS solo compilando dal sorgente.
- Sincronizzazione cloud presentata come anteprima sperimentale: nelle Release funziona con il progetto Supabase del developer, sconsigliata per dati sensibili.
- Sezione «Known limitations» con: note protette non cifrate; pacchetti non firmati o non pronti (niente build Android/iOS, dmg non notarizzato, AppImage senza GTK 3).
- Sezioni per sviluppatori: solo avvio in locale e configurazione di un proprio Supabase.
- Versione di Flutter: il README rimanda a «.fvmrc» senza scrivere un numero.
- Chiavi Supabase in locale con «--dart-define-from-file=.env», un «.env.example» nel repository e «.env» escluso da git; cambia il Requirement tech che diceva di passarle a mano.
- Licenza MIT intestata a Luca Soda.

Assunzioni da verificare:
- L'elenco delle funzioni non promette l'esportazione PDF, che nessuna schermata offre, e non descrive i file del vault come Markdown leggibile, perché contengono il documento a blocchi.
- La lingua delle note di esempio negli screenshot non è fissata.
