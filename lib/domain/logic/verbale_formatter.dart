import 'package:intl/intl.dart';

import '../entities/argomento.dart';
import '../entities/assemblea.dart';
import '../entities/condomino.dart';
import '../entities/votazione.dart';

class VerbaleFormatter {
  static String formatMonth(int month) {
    const months = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"];
    return months[month - 1];
  }

  static String generatePlainText(Assemblea assemblea, List<Condomino> allCondomini) {
    final df = DateFormat('dd/MM/yyyy');
    final tf = DateFormat('HH:mm');
    final partecipanti = allCondomini.where((c) => assemblea.partecipantiIds.contains(c.id)).toList();
    final presidente = allCondomini.firstWhere(
      (c) => c.id == assemblea.presidenteId,
      orElse: () => const Condomino(nome: "___", indirizzo: "", millesimi: 0),
    );
    final segretario = allCondomini.firstWhere(
      (c) => c.id == assemblea.segretarioId,
      orElse: () => const Condomino(nome: "___", indirizzo: "", millesimi: 0),
    );
    final totalMill = partecipanti.fold(0.0, (sum, c) => sum + c.millesimi);

    StringBuffer sb = StringBuffer();
    sb.writeln("CONDOMINIO Via Colli 4, C.F. 92049260422");
    sb.writeln("Indirizzo: Via dei Colli 4, Jesi (AN)");
    sb.writeln("");
    sb.writeln("VERBALE DI ASSEMBLEA ORDINARIA DEL ${df.format(assemblea.dataSecondaConvocazione)}");
    sb.writeln("");
    sb.writeln(
      "L'anno ${assemblea.dataSecondaConvocazione.year}, il giorno ${assemblea.dataSecondaConvocazione.day} del mese di ${formatMonth(assemblea.dataSecondaConvocazione.month)} alle ore ${tf.format(assemblea.dataSecondaConvocazione)}, in ${assemblea.luogo} si è riunita in seconda convocazione l'assemblea ordinaria del condominio in epigrafe, per discutere e deliberare sul seguente ordine del giorno:",
    );
    for (var arg in assemblea.argomenti) {
      sb.writeln("● ${arg.titolo}");
    }
    sb.writeln("");
    sb.writeln("Sono presenti i sigg. condòmini:");
    for (var c in partecipanti) {
      sb.writeln("● ${c.nome}, millesimi ${c.millesimi.toStringAsFixed(1)}/1000");
    }
    sb.writeln("il tutto per un totale di n. ${partecipanti.length} condòmini e n. ${totalMill.toStringAsFixed(1)}/1000 millesimi.");
    sb.writeln("");
    sb.writeln("NOMINA PRESIDENTE E SEGRETARIO");
    sb.writeln("I presenti nominano Presidente il sig. ${presidente.nome} il quale designa come Segretario il sig. ${segretario.nome}.");
    sb.writeln(
      "Il Presidente constata l'avvenuta convocazione di tutti i condomini, la sussistenza dei quorum di legge e dichiara l'assemblea validamente costituita e atta a discutere e deliberare.",
    );
    sb.writeln("");
    sb.writeln("DELIBERAZIONI");

    for (int i = 0; i < assemblea.argomenti.length; i++) {
      final arg = assemblea.argomenti[i];
      sb.writeln("${i + 1}) ${arg.titolo}");
      sb.writeln(arg.testo);

      if (arg.tipo != TipoArgomento.custom || arg.metadata['richiedeVotazione'] == true) {
        sb.writeln("Esito votazione:");
        final fav = arg.votazioni.where((v) => v.esito == EsitoVotazione.favorevole).toList();
        final con = arg.votazioni.where((v) => v.esito == EsitoVotazione.contrario).toList();
        final ast = arg.votazioni.where((v) => v.esito == EsitoVotazione.astenuto).toList();

        double millFav = 0;
        sb.writeln("Favorevoli: ${fav.length}");
        for (var v in fav) {
          final c = partecipanti.firstWhere((p) => p.id == v.condominoId);
          sb.writeln("● ${c.nome}, millesimi ${c.millesimi.toStringAsFixed(1)}/1000");
          millFav += c.millesimi;
        }
        sb.writeln("Contrari: ${con.length}");
        for (var v in con) {
          final c = partecipanti.firstWhere((p) => p.id == v.condominoId);
          sb.writeln("● ${c.nome}, millesimi ${c.millesimi.toStringAsFixed(1)}/1000");
        }
        sb.writeln("Astenuti: ${ast.length}");
        for (var v in ast) {
          final c = partecipanti.firstWhere((p) => p.id == v.condominoId);
          sb.writeln("● ${c.nome}, millesimi ${c.millesimi.toStringAsFixed(1)}/1000");
        }
        sb.writeln("Millesimi favorevoli: ${millFav.toStringAsFixed(1)}/1000");
      }
      sb.writeln("");
    }

    sb.writeln(
      "Alle ore ${assemblea.dataFine != null ? tf.format(assemblea.dataFine!) : '___'}, esauriti gli argomenti, il Presidente dichiara sciolta la riunione.",
    );
    sb.writeln("Letto, confermato e sottoscritto.");
    sb.writeln("");
    sb.writeln("Jesi, ${df.format(assemblea.dataSecondaConvocazione)}");
    sb.writeln("Firma del Presidente");
    sb.writeln("Firma del Segretario");

    return sb.toString();
  }
}
