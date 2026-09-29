import '../entities/argomento.dart';
import '../entities/condomino.dart';
import '../entities/votazione.dart';

class ArgomentoLogic {
  static String generaTesto(Argomento argomento, List<Condomino> condominiPartecipanti) {
    // Se è un argomento custom e non è richiesta votazione, restituiamo il testo originale
    if (argomento.tipo == TipoArgomento.custom && argomento.metadata['richiedeVotazione'] == false) {
      return argomento.testo;
    }

    final votazioni = argomento.votazioni;

    double millesimiFavorevoli = 0;
    double millesimiContrari = 0;
    double millesimiAstenuti = 0;
    int numFavorevoli = 0;
    int numPartecipanti = condominiPartecipanti.length;

    // Calcoliamo i risultati solo se ci sono partecipanti
    if (numPartecipanti > 0) {
      for (var condomino in condominiPartecipanti) {
        // Cerchiamo la votazione per questo condomino, default astenuto se non trovata
        final v =
            votazioni.where((v) => v.condominoId == condomino.id).firstOrNull ??
            Votazione(condominoId: condomino.id!, esito: EsitoVotazione.astenuto);

        if (v.esito == EsitoVotazione.favorevole) {
          millesimiFavorevoli += condomino.millesimi;
          numFavorevoli++;
        } else if (v.esito == EsitoVotazione.contrario) {
          millesimiContrari += condomino.millesimi;
        } else {
          millesimiAstenuti += condomino.millesimi;
        }
      }
    }

    final bool unanimita = numFavorevoli == numPartecipanti && numPartecipanti > 0;
    // Approvato solo se favorevoli > contrari (gli astenuti non contano per la maggioranza ma impediscono l'unanimità)
    final bool approvato = millesimiFavorevoli > millesimiContrari && millesimiFavorevoli > 0;

    final String modalita = unanimita ? "all'unanimità" : "a maggioranza";
    final String esito = approvato ? "approvare" : "respingere";

    switch (argomento.tipo) {
      case TipoArgomento.consuntivo:
        final anno = argomento.metadata['anno'] ?? "";
        return "L'assemblea delibera $modalita di $esito il bilancio consuntivo dell'esercizio $anno, nonché la relativa ripartizione.";

      case TipoArgomento.preventivo:
        final anno = argomento.metadata['anno'] ?? "";
        return "L'assemblea delibera $modalita di $esito il bilancio preventivo dell'esercizio $anno, nonché la relativa ripartizione.";

      case TipoArgomento.dimissioni:
        final nome = argomento.metadata['nomeAmministratore'] ?? "";
        final motivi = argomento.metadata['motivi'] ?? "";
        final esitoDimissioni = approvato ? "SI accettano" : "SI respingono";
        return "$esitoDimissioni le dimissioni da amministratore del condominio del sig. $nome per $motivi.";

      case TipoArgomento.elezione:
        final candidati = (argomento.metadata['candidati'] as List? ?? []);
        String elencoCandidati = candidati
            .map((c) => "${c['nome']} (nato a ${c['citta']} il ${c['dataNascita']}, CF: ${c['cf']}, compenso: ${c['compenso']}€)")
            .join(", ");

        final elettoNome = argomento.metadata['elettoNome'] ?? "";
        final luogo = argomento.metadata['luogoRegistri'] ?? "";
        final dateVisione = argomento.metadata['dateVisione'] ?? "";
        final polizza = argomento.metadata['polizza'] == true ? "" : "non ";

        return "Si candidano come nuovo amministratore del condominio le seguenti persone: $elencoCandidati.\n"
            "L'assemblea delibera $modalita di eleggere $elettoNome come nuovo amministratore di condominio.\n"
            "Ai sensi del codice civile art. 1129, il nuovo amministratore comunica che i registri condominiali di cui all'art. 1130 c.c. saranno disponibili presso $luogo, e che gli interessati possono prenderne gratuitamente visione e ottenere, previo rimborso della spesa, una copia firmata, $dateVisione.\n"
            "L'assemblea sceglie di ${polizza}subordinare la nomina dell'amministratore alla presentazione di una polizza individuale di assicurazione per la responsabilità civile per gli atti compiuti nell'esercizio del mandato (art. 1129 c.c.).";

      case TipoArgomento.custom:
        if (argomento.metadata['richiedeVotazione'] == true) {
          String testoPulito = argomento.testo;
          final regexPrefix = RegExp(
              r"^L'assemblea delibera (all'unanimità|a maggioranza) di (accogliere|respingere) la proposta:\s*", caseSensitive: false);
          while (regexPrefix.hasMatch(testoPulito)) {
            testoPulito = testoPulito.replaceFirst(regexPrefix, '');
          }
          return "L'assemblea delibera $modalita di ${approvato ? 'accogliere' : 'respingere'} la proposta: $testoPulito";
        }
        return argomento.testo;

      default:
        return argomento.testo;
    }
  }
}
