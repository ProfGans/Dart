# Repository-Wechsel am 16.10.2026

Aktives Repository: https://github.com/ProfGans/Dart

Der lokale Arbeitsstand inklusive vorher uncommitteter App-Aenderungen wird als master uebernommen. Die Git-Historie bleibt erhalten. Der neuere master des bisherigen Repositorys bleibt separat unter codex/source-master erhalten; er wird nicht automatisch in den lokalen Stand gemergt.

origin bezeichnet das neue Repository. legacy bleibt als lesende Referenz auf ProfGans/DartTunier erhalten; seine Push-URL ist lokal gesperrt. Das bisherige GitHub-Repository wird nicht veraendert.

Release-Workflow, Android-Signing-Secrets, Actions-Variable und Actions-Berechtigungen werden im neuen Repository eingerichtet. Update-URLs und neue Einladungslinks zeigen auf Dart. Die GitHub-Pages-Quelle bleibt codex/invitation-pages, Verzeichnis /.

Historische Release-Tags und Release-Dateien werden nicht erneut veroeffentlicht. Historische Dokumentationslinks und Issue-Audits bleiben als Herkunftsnachweis erhalten. Bestehende Issues und Pull Requests bleiben beim bisherigen Projekt.

App-ID, Signierschluessel, Deep-Link-Schema sowie Firebase-/Backend-Konfiguration bleiben beim Repository-Wechsel unveraendert. Dies ist noch keine Trennung der installierten App oder ihrer Backend-Daten. Fuer zwei parallel installierbare und datenmaessig unabhaengige Apps ist ein eigener Folgeschritt erforderlich.
