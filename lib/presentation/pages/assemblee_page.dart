import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/argomento.dart';
import '../../domain/entities/assemblea.dart';
import '../../domain/entities/votazione.dart';
import '../../injection_container.dart';
import '../cubit/assemblee_cubit.dart';
import '../cubit/assemblee_state.dart';
import '../cubit/condomini_cubit.dart';
import '../cubit/condomini_state.dart';

class ArgomentoPredefinito {
  final String titolo;
  final String testo;

  const ArgomentoPredefinito(this.titolo, this.testo);
}

const List<ArgomentoPredefinito> argomentiPredefiniti = [
  ArgomentoPredefinito("Approvazione Bilancio Consuntivo", "Si approva il bilancio consuntivo dell'anno precedente..."),
  ArgomentoPredefinito("Approvazione Bilancio Preventivo", "Si approva il bilancio preventivo per l'anno corrente..."),
  ArgomentoPredefinito("Nomina/Riconferma Amministratore", "Discussione e votazione sulla nomina o riconferma dell'amministratore..."),
  ArgomentoPredefinito("Lavori Straordinari", "Valutazione e approvazione di lavori di manutenzione straordinaria..."),
  ArgomentoPredefinito("Revisione Tabelle Millesimali", "Discussione sulla necessità di revisionare le tabelle millesimali..."),
  ArgomentoPredefinito("Varie ed Eventuali", "Discussioni su argomenti non all'ordine del giorno."),
];

class AssembleePage extends StatelessWidget {
  const AssembleePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AssembleeCubit>()..fetchAssemblee()),
        BlocProvider(create: (_) => sl<CondominiCubit>()..fetchCondomini()),
      ],
      child: const AssembleeView(),
    );
  }
}

class AssembleeView extends StatelessWidget {
  const AssembleeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AssembleeCubit, AssembleeState>(
        builder: (context, state) {
          if (state is AssembleeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AssembleeLoaded) {
            if (state.assemblee.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Nessuna assemblea registrata.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openAssembleaForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Indici la prima assemblea"),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.assemblee.length,
              itemBuilder: (context, index) {
                final assemblea = state.assemblee[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text("Assemblea del ${DateFormat('dd/MM/yyyy').format(assemblea.dataSecondaConvocazione)}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Luogo: ${assemblea.luogo}"),
                        Text("Stato: ${assemblea.stato == AssembleaStato.avvenuta ? 'Avvenuta' : 'Non avvenuta'}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openAssembleaForm(context, assemblea: assemblea),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, assemblea),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is AssembleeError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<AssembleeCubit, AssembleeState>(
        builder: (context, state) {
          if (state is AssembleeLoaded && state.assemblee.isNotEmpty) {
            return FloatingActionButton(onPressed: () => _openAssembleaForm(context), child: const Icon(Icons.add));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openAssembleaForm(BuildContext context, {Assemblea? assemblea}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AssembleeCubit>(),
        child: BlocProvider.value(
          value: context.read<CondominiCubit>(),
          child: AssembleaForm(assemblea: assemblea),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Assemblea assemblea) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text("Elimina Assemblea"),
        content: const Text("Sei sicuro di voler eliminare questa assemblea e tutte le relative votazioni?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dContext), child: const Text("Annulla")),
          TextButton(
            onPressed: () {
              context.read<AssembleeCubit>().deleteAssemblea(assemblea.id!);
              Navigator.pop(dContext);
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AssembleaForm extends StatefulWidget {
  final Assemblea? assemblea;

  const AssembleaForm({super.key, this.assemblea});

  @override
  State<AssembleaForm> createState() => _AssembleaFormState();
}

class _AssembleaFormState extends State<AssembleaForm> {
  late DateTime _dataPrima;
  late DateTime _dataSeconda;
  DateTime? _dataFine;
  late String _luogo;
  late AssembleaStato _stato;
  late List<int> _partecipantiIds;
  late List<Argomento> _argomenti;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _dataPrima = widget.assemblea?.dataPrimaConvocazione ?? DateTime.now();
    _dataSeconda = widget.assemblea?.dataSecondaConvocazione ?? DateTime.now().add(const Duration(days: 1));
    _dataFine = widget.assemblea?.dataFine;
    _luogo = widget.assemblea?.luogo ?? "";
    _stato = widget.assemblea?.stato ?? AssembleaStato.nonAvvenuta;
    _partecipantiIds = List.from(widget.assemblea?.partecipantiIds ?? []);
    _argomenti = List.from(widget.assemblea?.argomenti ?? []);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_stato == AssembleaStato.avvenuta) {
      if (_partecipantiIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Un'assemblea avvenuta deve avere almeno un partecipante")));
        return;
      }
      if (_dataFine == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserire l'ora di fine per un'assemblea avvenuta")));
        return;
      }
    }

    final newAssemblea = Assemblea(
      id: widget.assemblea?.id,
      dataPrimaConvocazione: _dataPrima,
      dataSecondaConvocazione: _dataSeconda,
      dataFine: _dataFine,
      luogo: _luogo,
      stato: _stato,
      partecipantiIds: _partecipantiIds,
      argomenti: _argomenti,
    );

    context.read<AssembleeCubit>().saveAssemblea(newAssemblea);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.assemblea == null ? "Nuova Assemblea" : "Modifica Assemblea", style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              TextFormField(
                initialValue: _luogo,
                decoration: const InputDecoration(labelText: "Luogo dell'assemblea *"),
                onChanged: (val) => _luogo = val,
                validator: (val) => val == null || val.isEmpty ? "Campo obbligatorio" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Prima Convocazione"),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dataPrima)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _dataPrima, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dataPrima));
                    if (time != null) {
                      setState(() => _dataPrima = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
              ListTile(
                title: const Text("Seconda Convocazione"),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dataSeconda)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _dataSeconda, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dataSeconda));
                    if (time != null) {
                      setState(() => _dataSeconda = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
              SwitchListTile(
                title: const Text("Assemblea Avvenuta"),
                value: _stato == AssembleaStato.avvenuta,
                onChanged: (val) => setState(() => _stato = val ? AssembleaStato.avvenuta : AssembleaStato.nonAvvenuta),
              ),
              if (_stato == AssembleaStato.avvenuta)
                ListTile(
                  title: const Text("Ora di Fine *"),
                  subtitle: Text(_dataFine != null ? DateFormat('HH:mm').format(_dataFine!) : "Seleziona ora"),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _dataFine != null ? TimeOfDay.fromDateTime(_dataFine!) : TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _dataFine = DateTime(_dataSeconda.year, _dataSeconda.month, _dataSeconda.day, time.hour, time.minute);
                      });
                    }
                  },
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("Partecipanti", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              BlocBuilder<CondominiCubit, CondominiState>(
                builder: (context, state) {
                  if (state is CondominiLoaded) {
                    return Wrap(
                      spacing: 8,
                      children: state.condomini.map((c) {
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
                                for (var arg in _argomenti) {
                                  arg.votazioni.removeWhere((v) => v.condominoId == c.id);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  }
                  return const Text("Caricamento condomini...");
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ordine del Giorno", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle), onPressed: _addArgomento),
                ],
              ),
              ..._argomenti.asMap().entries.map((entry) => _buildArgomentoTile(entry.key, entry.value)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text("SALVA ASSEMBLEA")),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArgomentoTile(int index, Argomento argomento) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(argomento.titolo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(argomento.testo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => setState(() => _argomenti.removeAt(index))),
              ],
            ),
            if (_partecipantiIds.isNotEmpty) ...[
              const Text("Votazioni:", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              BlocBuilder<CondominiCubit, CondominiState>(
                builder: (context, state) {
                  if (state is CondominiLoaded) {
                    final partecipanti = state.condomini.where((c) => _partecipantiIds.contains(c.id)).toList();
                    return Column(
                      children: partecipanti.map((p) {
                        final votazione = argomento.votazioni.firstWhere(
                          (v) => v.condominoId == p.id,
                          orElse: () => Votazione(condominoId: p.id!, esito: EsitoVotazione.astenuto),
                        );
                        return Row(
                          children: [
                            Expanded(child: Text(p.nome, style: const TextStyle(fontSize: 13))),
                            SegmentedButton<EsitoVotazione>(
                              segments: const [
                                ButtonSegment(value: EsitoVotazione.favorevole, icon: Icon(Icons.thumb_up, size: 16)),
                                ButtonSegment(value: EsitoVotazione.contrario, icon: Icon(Icons.thumb_down, size: 16)),
                                ButtonSegment(value: EsitoVotazione.astenuto, icon: Icon(Icons.remove_circle_outline, size: 16)),
                              ],
                              selected: {votazione.esito},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  final newVot = Votazione(condominoId: p.id!, esito: newSelection.first);
                                  final existingIndex = argomento.votazioni.indexWhere((v) => v.condominoId == p.id);
                                  if (existingIndex != -1) {
                                    argomento.votazioni[existingIndex] = newVot;
                                  } else {
                                    argomento.votazioni.add(newVot);
                                  }
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ] else
              const Text("Aggiungi partecipanti per votare", style: TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  void _addArgomento() {
    ArgomentoPredefinito selected = argomentiPredefiniti.first;
    final customTitoloController = TextEditingController();
    final customTestoController = TextEditingController();
    bool isCustom = false;

    showDialog(
      context: context,
      builder: (dContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Aggiungi Argomento"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ArgomentoPredefinito?>(
                  isExpanded: true,
                  value: isCustom ? null : selected,
                  items: [
                    ...argomentiPredefiniti.map((a) => DropdownMenuItem(value: a, child: Text(a.titolo))),
                    const DropdownMenuItem(value: null, child: Text("Altro...")),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == null) {
                        isCustom = true;
                      } else {
                        isCustom = false;
                        selected = val;
                      }
                    });
                  },
                ),
                if (isCustom)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: customTitoloController,
                        decoration: const InputDecoration(labelText: "Titolo", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: customTestoController,
                        maxLines: 5,
                        minLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Testo",
                          hintText: "Scrivi il contenuto dell'argomento...",
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dContext), child: const Text("Annulla")),
            TextButton(
              onPressed: () {
                final Argomento nuovoArgomento;
                if (isCustom) {
                  if (customTitoloController.text.isNotEmpty) {
                    nuovoArgomento = Argomento(titolo: customTitoloController.text, testo: customTestoController.text, votazioni: []);
                  } else {
                    return;
                  }
                } else {
                  nuovoArgomento = Argomento(titolo: selected.titolo, testo: selected.testo, votazioni: []);
                }
                setState(() => _argomenti.add(nuovoArgomento));
                Navigator.pop(dContext);
              },
              child: const Text("Aggiungi"),
            ),
          ],
        ),
      ),
    );
  }
}
