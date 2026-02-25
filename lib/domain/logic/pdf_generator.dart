import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../entities/argomento.dart';
import '../entities/assemblea.dart';
import '../entities/condomino.dart';
import '../entities/votazione.dart';

class PdfGenerator {
  static Future<void> generateAndShare(Assemblea assemblea, List<Condomino> allCondomini) async {
    final pdf = pw.Document();

    final partecipanti = allCondomini.where((c) => assemblea.partecipantiIds.contains(c.id)).toList();
    final presidente = allCondomini.firstWhere((c) => c.id == assemblea.presidenteId);
    final segretario = allCondomini.firstWhere((c) => c.id == assemblea.segretarioId);

    final totalMillesimi = partecipanti.fold(0.0, (sum, c) => sum + c.millesimi);
    final df = DateFormat('dd/MM/yyyy');
    final tf = DateFormat('HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("CONDOMINIO Via Colli 4, C.F. 92049260422", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Indirizzo: Via dei Colli 4, Jesi (AN)"),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      "VERBALE DI ASSEMBLEA ORDINARIA DEL ${df.format(assemblea.dataSecondaConvocazione)}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            pw.Paragraph(
              text:
                  "L'anno ${assemblea.dataSecondaConvocazione.year}, il giorno ${assemblea.dataSecondaConvocazione.day} del mese di ${_getMonthName(assemblea.dataSecondaConvocazione.month)} alle ore ${tf.format(assemblea.dataSecondaConvocazione)}, in ${assemblea.luogo} si è riunita in seconda convocazione l'assemblea ordinaria del condominio in epigrafe, per discutere e deliberare sul seguente ordine del giorno:",
            ),

            ...assemblea.argomenti.map((a) => pw.Bullet(text: a.titolo)),

            pw.SizedBox(height: 10),
            pw.Text("Sono presenti i sigg. condòmini:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...partecipanti.map((c) => pw.Bullet(text: "${c.nome}, millesimi ${c.millesimi.toStringAsFixed(1)}/1000")),

            pw.Paragraph(
              text: "il tutto per un totale di n. ${partecipanti.length} condòmini e n. ${totalMillesimi.toStringAsFixed(1)}/1000 millesimi.",
            ),

            pw.Header(
              level: 1,
              text: "NOMINA PRESIDENTE E SEGRETARIO",
              textStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Paragraph(
              text: "I presenti nominano Presidente il sig. ${presidente.nome} il quale designa come Segretario il sig. ${segretario.nome}.",
            ),
            pw.Paragraph(
              text:
                  "Il Presidente constata l'avvenuta convocazione di tutti i condomini, la sussistenza dei quorum di legge e dichiara l'assemblea validamente costituita e atta a discutere e deliberare.",
            ),

            pw.Header(
              level: 1,
              text: "DELIBERAZIONI",
              textStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            ...assemblea.argomenti.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final arg = entry.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text("$i) ${arg.titolo}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Paragraph(text: arg.testo),
                  if (arg.tipo != TipoArgomento.custom || arg.metadata['richiedeVotazione'] == true) _buildVotazionePdf(arg, partecipanti),
                ],
              );
            }),

            pw.SizedBox(height: 20),
            pw.Paragraph(
              text:
                  "Alle ore ${assemblea.dataFine != null ? tf.format(assemblea.dataFine!) : '___'}, esauriti gli argomenti, il Presidente dichiara sciolta la riunione.",
            ),
            pw.Text("Letto, confermato e sottoscritto."),
            pw.SizedBox(height: 10),
            pw.Text("Jesi, ${df.format(assemblea.dataSecondaConvocazione)}"),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(children: [pw.Text("____________________"), pw.Text("Firma del Presidente")]),
                pw.Column(children: [pw.Text("____________________"), pw.Text("Firma del Segretario")]),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'verbale_${df.format(assemblea.dataSecondaConvocazione).replaceAll('/', '-')}.pdf');
  }

  static pw.Widget _buildVotazionePdf(Argomento arg, List<Condomino> partecipanti) {
    final fav = arg.votazioni.where((v) => v.esito == EsitoVotazione.favorevole).toList();
    final con = arg.votazioni.where((v) => v.esito == EsitoVotazione.contrario).toList();
    final ast = arg.votazioni.where((v) => v.esito == EsitoVotazione.astenuto).toList();

    double millFav = 0;
    for (var v in fav) {
      millFav += partecipanti.firstWhere((c) => c.id == v.condominoId).millesimi;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Esito votazione:", style: pw.TextStyle(decoration: pw.TextDecoration.underline, fontSize: 10)),
        pw.Text("Favorevoli: ${fav.length}", style: pw.TextStyle(fontSize: 10)),
        ...fav.map((v) => pw.Text("- ${partecipanti.firstWhere((c) => c.id == v.condominoId).nome}", style: pw.TextStyle(fontSize: 9))),
        pw.Text("Contrari: ${con.length}", style: pw.TextStyle(fontSize: 10)),
        ...con.map((v) => pw.Text("- ${partecipanti.firstWhere((c) => c.id == v.condominoId).nome}", style: pw.TextStyle(fontSize: 9))),
        pw.Text("Astenuti: ${ast.length}", style: pw.TextStyle(fontSize: 10)),
        ...ast.map((v) => pw.Text("- ${partecipanti.firstWhere((c) => c.id == v.condominoId).nome}", style: pw.TextStyle(fontSize: 9))),
        pw.Text("Millesimi favorevoli: ${millFav.toStringAsFixed(1)}/1000", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  static String _getMonthName(int month) {
    const months = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"];
    return months[month - 1];
  }
}
