import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/votazione_model.dart';
import '../../domain/entities/argomento.dart';
import '../../domain/entities/assemblea.dart';
import '../../domain/entities/condomino.dart';
import '../../domain/entities/votazione.dart';
import '../../domain/logic/argomento_logic.dart';
import '../cubit/assemblee_cubit.dart';
import '../cubit/condomini_cubit.dart';
import '../cubit/condomini_state.dart';

class AssembleaFormPage extends StatefulWidget {
  final Assemblea? assemblea;

  const AssembleaFormPage({super.key, this.assemblea});

  @override
  State<AssembleaFormPage> createState() => _AssembleaFormPageState();
}

class _AssembleaFormPageState extends State<AssembleaFormPage> {
  late DateTime _dataPrima;
  late DateTime _dataSeconda;
  DateTime? _dataFine;
  late String _luogo;
  late AssembleaStato _stato;
  late List<int> _partecipantiIds;
  int? _presidenteId;
  int? _segretarioId;
  late List<Argomento> _argomenti;
  final _formKey = GlobalKey<FormState>();

  bool _isDirty = false;
  final Map<int, bool> _argomentiEspansi = {};

  @override
  void initState() {
    super.initState();
    _dataPrima = widget.assemblea?.dataPrimaConvocazione ?? DateTime.now();
    _dataSeconda = widget.assemblea?.dataSecondaConvocazione ?? DateTime.now().add(const Duration(days: 1));
    _dataFine = widget.assemblea?.dataFine;
    _luogo = widget.assemblea?.luogo ?? "";
    _stato = widget.assemblea?.stato ?? AssembleaStato.nonAvvenuta;
    _partecipantiIds = List.from(widget.assemblea?.partecipantiIds ?? []);
    _presidenteId = widget.assemblea?.presidenteId;
    _segretarioId = widget.assemblea?.segretarioId;
    _argomenti = List.from(widget.assemblea?.argomenti ?? []);

    for (int i = 0; i < _argomenti.length; i++) {
      _argomentiEspansi[i] = widget.assemblea == null;
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _save(List<Condomino> allCondomini) {
    if (!_formKey.currentState!.validate()) return;

    if (_stato == AssembleaStato.avvenuta) {
      if (_partecipantiIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserire almeno un partecipante")));
        return;
      }
      if (_dataFine == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserire ora di fine")));
        return;
      }
      if (_presidenteId == null || _segretarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selezionare Presidente e Segretario")));
        return;
      }
    }

    final partecipanti = allCondomini.where((c) => _partecipantiIds.contains(c.id)).toList();

    final argomentiAggiornati = _argomenti.map((arg) {
      return Argomento(
        id: arg.id,
        titolo: arg.titolo,
        tipo: arg.tipo,
        metadata: arg.metadata,
        votazioni: arg.votazioni,
        testo: ArgomentoLogic.generaTesto(arg, partecipanti),
      );
    }).toList();

    final newAssemblea = Assemblea(
      id: widget.assemblea?.id,
      dataPrimaConvocazione: _dataPrima,
      dataSecondaConvocazione: _dataSeconda,
      dataFine: _dataFine,
      luogo: _luogo,
      stato: _stato,
      partecipantiIds: _partecipantiIds,
      presidenteId: _presidenteId,
      segretarioId: _segretarioId,
      argomenti: argomentiAggiornati,
    );

    context.read<AssembleeCubit>().saveAssemblea(newAssemblea);
    setState(() => _isDirty = false);
    Navigator.pop(context);
  }

  Future<void> _handlePop(List<Condomino> allCondomini) async {
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifiche non salvate"),
        content: const Text("Vuoi salvare le modifiche prima di uscire?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'exit'), child: const Text("Esci senza salvare")),
          TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text("Annulla")),
          ElevatedButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text("Salva")),
        ],
      ),
    );

    if (result == 'save') {
      _save(allCondomini);
    } else if (result == 'exit') {
      setState(() => _isDirty = false);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CondominiCubit, CondominiState>(
      builder: (context, condominiState) {
        final allCondomini = condominiState is CondominiLoaded ? condominiState.condomini : <Condomino>[];
        final partecipanti = allCondomini.where((c) => _partecipantiIds.contains(c.id)).toList();

        return PopScope(
          canPop: !_isDirty,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handlePop(allCondomini);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.assemblea == null ? "Nuova Assemblea" : "Modifica Assemblea"),
              actions: [IconButton(icon: const Icon(Icons.check), onPressed: () => _save(allCondomini))],
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _luogo,
                      decoration: const InputDecoration(labelText: "Luogo *", border: OutlineInputBorder()),
                      onChanged: (val) {
                        _luogo = val;
                        _markDirty();
                      },
                      validator: (val) => val == null || val.isEmpty ? "Campo obbligatorio" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDateTile("Prima Convocazione", _dataPrima, (d) {
                      setState(() => _dataPrima = d);
                      _markDirty();
                    }),
                    _buildDateTile("Seconda Convocazione", _dataSeconda, (d) {
                      setState(() => _dataSeconda = d);
                      _markDirty();
                    }),
                    SwitchListTile(
                      title: const Text("Assemblea Avvenuta"),
                      value: _stato == AssembleaStato.avvenuta,
                      onChanged: (val) {
                        setState(() => _stato = val ? AssembleaStato.avvenuta : AssembleaStato.nonAvvenuta);
                        _markDirty();
                      },
                    ),
                    if (_stato == AssembleaStato.avvenuta) ...[
                      _buildTimeTile("Ora di Fine", _dataFine ?? _dataSeconda, (d) {
                        setState(() => _dataFine = d);
                        _markDirty();
                      }),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _presidenteId,
                        decoration: const InputDecoration(labelText: "Presidente *", border: OutlineInputBorder()),
                        items: partecipanti.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                        onChanged: (val) {
                          setState(() => _presidenteId = val);
                          _markDirty();
                        },
                        validator: (val) => _stato == AssembleaStato.avvenuta && val == null ? "Selezionare presidente" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _segretarioId,
                        decoration: const InputDecoration(labelText: "Segretario *", border: OutlineInputBorder()),
                        items: partecipanti.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                        onChanged: (val) {
                          setState(() => _segretarioId = val);
                          _markDirty();
                        },
                        validator: (val) => _stato == AssembleaStato.avvenuta && val == null ? "Selezionare segretario" : null,
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text("Partecipanti", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Wrap(
                      spacing: 8,
                      children: allCondomini.map((c) {
                        final isSelected = _partecipantiIds.contains(c.id);
                        return FilterChip(
                          label: Text(c.nome),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _partecipantiIds.add(c.id!);
                              } else {
                                _partecipantiIds.remove(c.id);
                                if (_presidenteId == c.id) _presidenteId = null;
                                if (_segretarioId == c.id) _segretarioId = null;
                                for (var arg in _argomenti) {
                                  arg.votazioni.removeWhere((v) => v.condominoId == c.id);
                                }
                              }
                            });
                            _markDirty();
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Ordine del Giorno", style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle), onPressed: () => _addArgomento(allCondomini)),
                      ],
                    ),
                    ..._argomenti.asMap().entries.map((entry) => _buildArgomentoTile(entry.key, entry.value, allCondomini)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTile(String label, DateTime value, Function(DateTime) onSelected) {
    return ListTile(
      title: Text(label),
      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(value)),
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (date != null) {
          final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
          if (time != null) {
            onSelected(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      },
    );
  }

  Widget _buildTimeTile(String label, DateTime value, Function(DateTime) onSelected) {
    return ListTile(
      title: Text(label),
      subtitle: Text(DateFormat('HH:mm').format(value)),
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time != null) {
          onSelected(DateTime(value.year, value.month, value.day, time.hour, time.minute));
        }
      },
    );
  }

  Widget _buildArgomentoTile(int index, Argomento argomento, List<Condomino> allCondomini) {
    final partecipanti = allCondomini.where((c) => _partecipantiIds.contains(c.id)).toList();
    final testoGenerato = ArgomentoLogic.generaTesto(argomento, partecipanti);
    final isEspanso = _argomentiEspansi[index] ?? true;

    final bool richiedeVotazione = argomento.tipo != TipoArgomento.custom || (argomento.metadata['richiedeVotazione'] ?? true);

    return Card(
      color: Colors.grey[100],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(argomento.titolo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: isEspanso ? null : Text(testoGenerato, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showDatiArgomentoDialog(argomento.tipo, existingArgomento: argomento, index: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    setState(() => _argomenti.removeAt(index));
                    _markDirty();
                  },
                ),
                Icon(isEspanso ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => setState(() => _argomentiEspansi[index] = !isEspanso),
          ),
          if (isEspanso)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(testoGenerato, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  if (richiedeVotazione && partecipanti.isNotEmpty) ...[
                    const Divider(),
                    const Text("Votazioni:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...partecipanti.map((p) {
                      final votazione = argomento.votazioni.firstWhere(
                        (v) => v.condominoId == p.id,
                        orElse: () => VotazioneModel(condominoId: p.id!, esito: EsitoVotazione.astenuto),
                      );
                      return Row(
                        children: [
                          Expanded(child: Text(p.nome, style: const TextStyle(fontSize: 13))),
                          SegmentedButton<EsitoVotazione>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: EsitoVotazione.favorevole,
                                label: Text("F", style: TextStyle(fontSize: 10)),
                              ),
                              ButtonSegment(
                                value: EsitoVotazione.contrario,
                                label: Text("C", style: TextStyle(fontSize: 10)),
                              ),
                              ButtonSegment(
                                value: EsitoVotazione.astenuto,
                                label: Text("A", style: TextStyle(fontSize: 10)),
                              ),
                            ],
                            selected: {votazione.esito},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                final newVot = VotazioneModel(condominoId: p.id!, esito: newSelection.first);
                                final existingIndex = argomento.votazioni.indexWhere((v) => v.condominoId == p.id);
                                if (existingIndex != -1) {
                                  argomento.votazioni[existingIndex] = newVot;
                                } else {
                                  argomento.votazioni.add(newVot);
                                }
                              });
                              _markDirty();
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _addArgomento(List<Condomino> allCondomini) {
    showDialog(
      context: context,
      builder: (dContext) => SimpleDialog(
        title: const Text("Seleziona Tipo Argomento"),
        children: [
          _dialogOption(dContext, "Approvazione Consuntivo", TipoArgomento.consuntivo),
          _dialogOption(dContext, "Approvazione Preventivo", TipoArgomento.preventivo),
          _dialogOption(dContext, "Dimissioni Amministratore", TipoArgomento.dimissioni),
          _dialogOption(dContext, "Elezione Amministratore", TipoArgomento.elezione),
          _dialogOption(dContext, "Altro (Custom)", TipoArgomento.custom),
        ],
      ),
    );
  }

  Widget _dialogOption(BuildContext dContext, String label, TipoArgomento tipo) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(dContext);
        _showDatiArgomentoDialog(tipo);
      },
      child: Text(label),
    );
  }

  void _showDatiArgomentoDialog(TipoArgomento tipo, {Argomento? existingArgomento, int? index}) {
    final controllers = <String, TextEditingController>{};
    final metadata = existingArgomento != null ? Map<String, dynamic>.from(existingArgomento.metadata) : <String, dynamic>{};
    final List<Map<String, dynamic>> candidati = metadata['candidati'] != null ? List<Map<String, dynamic>>.from(metadata['candidati']) : [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          List<Widget> fields = [];
          String titoloFinestra = "";

          if (tipo == TipoArgomento.consuntivo || tipo == TipoArgomento.preventivo) {
            titoloFinestra = tipo == TipoArgomento.consuntivo ? "Approvazione bilancio consuntivo" : "Approvazione bilancio preventivo";
            String initialAnno =
                metadata['anno']?.toString() ?? (tipo == TipoArgomento.consuntivo ? (_dataPrima.year - 1).toString() : _dataPrima.year.toString());
            controllers.putIfAbsent('anno', () => TextEditingController(text: initialAnno));
            fields.add(
              TextField(
                controller: controllers['anno'],
                decoration: const InputDecoration(labelText: "Anno esercizio"),
              ),
            );
          } else if (tipo == TipoArgomento.dimissioni) {
            titoloFinestra = "Dimissioni amministratore";
            controllers.putIfAbsent('nome', () => TextEditingController(text: metadata['nomeAmministratore'] ?? ""));
            controllers.putIfAbsent('motivi', () => TextEditingController(text: metadata['motivi'] ?? ""));
            fields.add(
              TextField(
                controller: controllers['nome'],
                decoration: const InputDecoration(labelText: "Nome Amministratore"),
              ),
            );
            fields.add(
              TextField(
                controller: controllers['motivi'],
                decoration: const InputDecoration(labelText: "Motivi"),
              ),
            );
          } else if (tipo == TipoArgomento.elezione) {
            titoloFinestra = "Elezione nuovo amministratore";
            controllers.putIfAbsent('luogo', () => TextEditingController(text: metadata['luogoRegistri'] ?? ""));
            controllers.putIfAbsent('date', () => TextEditingController(text: metadata['dateVisione'] ?? ""));
            metadata.putIfAbsent('polizza', () => true);

            fields.add(const Text("Candidati:", style: TextStyle(fontWeight: FontWeight.bold)));
            for (var i = 0; i < candidati.length; i++) {
              fields.add(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(candidati[i]['nome'], style: const TextStyle(fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddCandidatoDialog((c) => setDialogState(() => candidati[i] = c), existingCandidato: candidati[i]),
                      ),
                      IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => setDialogState(() => candidati.removeAt(i))),
                    ],
                  ),
                ),
              );
            }
            fields.add(
              ElevatedButton(
                onPressed: () => _showAddCandidatoDialog((c) => setDialogState(() => candidati.add(c))),
                child: const Text("Aggiungi Candidato"),
              ),
            );

            if (candidati.isNotEmpty) {
              metadata['elettoNome'] ??= candidati.first['nome'];
              fields.add(
                DropdownButtonFormField<String>(
                  value: metadata['elettoNome'],
                  items: candidati.map((c) => DropdownMenuItem(value: c['nome'] as String, child: Text(c['nome']))).toList(),
                  onChanged: (val) => setDialogState(() => metadata['elettoNome'] = val),
                  decoration: const InputDecoration(labelText: "Eletto"),
                ),
              );
            }

            fields.add(
              TextField(
                controller: controllers['luogo'],
                decoration: const InputDecoration(labelText: "Luogo Registri"),
              ),
            );
            fields.add(
              TextField(
                controller: controllers['date'],
                decoration: const InputDecoration(labelText: "Date/Ore Visione"),
              ),
            );
            fields.add(
              SwitchListTile(
                title: const Text("Richiesta Polizza"),
                value: metadata['polizza'],
                onChanged: (val) => setDialogState(() => metadata['polizza'] = val),
              ),
            );
          } else {
            titoloFinestra = "Argomento Custom";
            controllers.putIfAbsent('titolo', () => TextEditingController(text: existingArgomento?.titolo ?? ""));
            controllers.putIfAbsent('testo', () => TextEditingController(text: existingArgomento?.testo ?? ""));
            metadata.putIfAbsent('richiedeVotazione', () => true);

            fields.add(
              TextField(
                controller: controllers['titolo'],
                decoration: const InputDecoration(labelText: "Titolo"),
              ),
            );
            fields.add(
              TextField(
                controller: controllers['testo'],
                maxLines: 5,
                decoration: const InputDecoration(labelText: "Testo"),
              ),
            );
            fields.add(
              SwitchListTile(
                title: const Text("Richiede Votazione"),
                value: metadata['richiedeVotazione'],
                onChanged: (val) => setDialogState(() => metadata['richiedeVotazione'] = val),
              ),
            );
          }

          return AlertDialog(
            title: Text(existingArgomento == null ? titoloFinestra : "Modifica $titoloFinestra"),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: fields),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
              TextButton(
                onPressed: () {
                  final Map<String, dynamic> finalMetadata = Map.from(metadata);
                  String finalTitolo = existingArgomento?.titolo ?? titoloFinestra;
                  String finalTesto = existingArgomento?.testo ?? "";

                  if (tipo == TipoArgomento.consuntivo || tipo == TipoArgomento.preventivo) {
                    finalMetadata['anno'] = controllers['anno']!.text;
                  } else if (tipo == TipoArgomento.dimissioni) {
                    finalMetadata['nomeAmministratore'] = controllers['nome']!.text;
                    finalMetadata['motivi'] = controllers['motivi']!.text;
                  } else if (tipo == TipoArgomento.elezione) {
                    finalMetadata['candidati'] = candidati;
                    finalMetadata['luogoRegistri'] = controllers['luogo']!.text;
                    finalMetadata['dateVisione'] = controllers['date']!.text;
                  } else {
                    finalTitolo = controllers['titolo']!.text;
                    finalTesto = controllers['testo']!.text;
                  }

                  setState(() {
                    final nuovoArg = Argomento(
                      id: existingArgomento?.id,
                      titolo: finalTitolo,
                      testo: finalTesto,
                      tipo: tipo,
                      metadata: finalMetadata,
                      votazioni: existingArgomento?.votazioni ?? [],
                    );

                    if (index != null) {
                      _argomenti[index] = nuovoArg;
                    } else {
                      _argomenti.add(nuovoArg);
                      _argomentiEspansi[_argomenti.length - 1] = true;
                    }
                  });
                  _markDirty();
                  Navigator.pop(ctx);
                },
                child: Text(existingArgomento == null ? "Aggiungi" : "Salva"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCandidatoDialog(Function(Map<String, dynamic>) onAdd, {Map<String, dynamic>? existingCandidato}) {
    final n = TextEditingController(text: existingCandidato?['nome'] ?? "");
    final c = TextEditingController(text: existingCandidato?['citta'] ?? "");
    final d = TextEditingController(text: existingCandidato?['dataNascita'] ?? "");
    final cf = TextEditingController(text: existingCandidato?['cf'] ?? "");
    final comp = TextEditingController(text: existingCandidato?['compenso'] ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingCandidato == null ? "Nuovo Candidato" : "Modifica Candidato"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: n,
                decoration: const InputDecoration(labelText: "Nome e Cognome"),
              ),
              TextField(
                controller: c,
                decoration: const InputDecoration(labelText: "Città di nascita"),
              ),
              TextField(
                controller: d,
                decoration: const InputDecoration(labelText: "Data di nascita"),
              ),
              TextField(
                controller: cf,
                decoration: const InputDecoration(labelText: "Codice Fiscale"),
              ),
              TextField(
                controller: comp,
                decoration: const InputDecoration(labelText: "Compenso richiesto"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () {
              onAdd({'nome': n.text, 'citta': c.text, 'dataNascita': d.text, 'cf': cf.text, 'compenso': comp.text});
              Navigator.pop(ctx);
            },
            child: Text(existingCandidato == null ? "Aggiungi" : "Salva"),
          ),
        ],
      ),
    );
  }
}
