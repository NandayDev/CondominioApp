import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/condomino.dart';
import '../../injection_container.dart';
import '../cubit/condomini_cubit.dart';
import '../cubit/condomini_state.dart';

class CondominiPage extends StatelessWidget {
  const CondominiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CondominiCubit>()..fetchCondomini(),
      child: const CondominiView(),
    );
  }
}

class CondominiView extends StatelessWidget {
  const CondominiView({super.key});

  void _showCondominoDialog(BuildContext context, {Condomino? condomino}) {
    final nomeController = TextEditingController(text: condomino?.nome ?? "");
    final indirizzoController = TextEditingController(text: condomino?.indirizzo ?? "");
    final millesimiController = TextEditingController(text: condomino?.millesimi.toString() ?? "");
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(condomino == null ? "Nuovo Condòmino" : "Modifica Condòmino"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: "Nome e Cognome"),
                    validator: (value) => value == null || value.isEmpty ? "Inserire il nome" : null,
                  ),
                  TextFormField(
                    controller: indirizzoController,
                    decoration: const InputDecoration(labelText: "Indirizzo"),
                    validator: (value) => value == null || value.isEmpty ? "Inserire l'indirizzo" : null,
                  ),
                  TextFormField(
                    controller: millesimiController,
                    decoration: const InputDecoration(labelText: "Millesimi"),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Inserire i millesimi";
                      if (double.tryParse(value) == null) return "Valore non valido";
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newCondomino = Condomino(
                    id: condomino?.id,
                    nome: nomeController.text,
                    indirizzo: indirizzoController.text,
                    millesimi: double.parse(millesimiController.text),
                  );

                  if (condomino == null) {
                    context.read<CondominiCubit>().addCondomino(newCondomino);
                  } else {
                    context.read<CondominiCubit>().updateCondomino(newCondomino);
                  }
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(condomino == null ? "Aggiungi" : "Salva"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CondominiCubit, CondominiState>(
        builder: (context, state) {
          if (state is CondominiLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CondominiLoaded) {
            if (state.condomini.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Nessun condòmino trovato.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCondominoDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Aggiungi il primo condòmino"),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.condomini.length,
              itemBuilder: (context, index) {
                final condomino = state.condomini[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(condomino.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(condomino.indirizzo),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Millesimi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(condomino.millesimi.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showCondominoDialog(context, condomino: condomino);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, condomino);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                          [
                            const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                            const PopupMenuItem(value: 'delete', child: Text('Elimina')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is CondominiError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<CondominiCubit, CondominiState>(
        builder: (context, state) {
          if (state is CondominiLoaded && state.condomini.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _showCondominoDialog(context),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Condomino condomino) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text("Conferma eliminazione"),
            content: Text("Sei sicuro di voler eliminare ${condomino.nome}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Annulla"),
              ),
              TextButton(
                onPressed: () {
                  context.read<CondominiCubit>().deleteCondomino(condomino.id!);
                  Navigator.pop(dialogContext);
            },
                child: const Text("Elimina", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
