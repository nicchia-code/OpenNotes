---
column: done
technical: false
refs:
  - note/In trash/user.DELETE_NOTE_PERMANENTLY
drift: null
proposal: null
agent: false
created: 2026-10-18T18:29:51.146Z
finished: 2026-10-18T19:38:00.435Z
---
# Fix code to match the Model: Permanent deletion of a protected note skips the PIN when the session already unlocked it

Eliminare definitivamente una nota protetta deve chiedere ogni volta il PIN corretto, anche quando la nota è già stata sbloccata in questa sessione. Oggi, se la nota è già sbloccata, il PIN non viene chiesto e la nota viene eliminata dopo la sola conferma dell'azione. Secondo il Model (note, In trash, user.DELETE_NOTE_PERMANENTLY) il PIN va inserito dopo la conferma, senza eccezioni per lo sblocco di sessione. Il Requirement delle regole sulle note protette (rules#note, sezione protezione con PIN) dice lo stesso: eliminare definitivamente una nota protetta richiede il PIN corretto ogni volta, a prescindere dallo sblocco di sessione. Il flusso va allineato sia per il menu della lista che per il cestino su desktop e mobile, lasciando invariato l'ordine già concordato: prima la conferma, poi il PIN.
