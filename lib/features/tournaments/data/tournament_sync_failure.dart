import 'package:supabase_flutter/supabase_flutter.dart';

/// Keep server diagnostics separate from successful local persistence.
String tournamentSyncFailureMessage(PostgrestException error) {
  const preserved = 'Lokale Änderungen bleiben erhalten.';
  if (error.code == '40001') {
    return 'Konflikt: Online gibt es neuere Ergebnisse. Online-Stand laden; lokale Änderungen bleiben bis dahin erhalten.';
  }
  if (error.code == 'PGRST202' || error.code == '42883') {
    return 'Synchronisierung abgelehnt: Die Turnier-Speicherfunktion fehlt auf dem Server. Servermigrationen aktualisieren. $preserved';
  }
  final reason = error.message.replaceAll(RegExp(r'\s+'), ' ').trim();
  final shortReason = reason.length > 300
      ? '${reason.substring(0, 300)}…'
      : reason;
  return 'Synchronisierung abgelehnt (${error.code ?? 'Serverfehler'}): $shortReason $preserved';
}
