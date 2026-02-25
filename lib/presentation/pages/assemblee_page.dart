import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/assemblea.dart';
import '../../domain/logic/pdf_generator.dart';
import '../../domain/logic/verbale_formatter.dart';
import '../../injection_container.dart';
import '../cubit/assemblee_cubit.dart';
import '../cubit/assemblee_state.dart';
import '../cubit/condomini_cubit.dart';
import 'assemblea_form_page.dart';

class AssembleePage extends StatelessWidget {
  const AssembleePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
      sl<AssembleeCubit>()
        ..fetchAssemblee(),
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
                  child: ExpansionTile(
                    title: Text("Assemblea del ${DateFormat('dd/MM/yyyy').format(assemblea.dataSecondaConvocazione)}"),
                    subtitle: Text("Luogo: ${assemblea.luogo} - ${assemblea.stato == AssembleaStato.avvenuta ? 'Avvenuta' : 'Non avvenuta'}"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openAssembleaForm(context, assemblea: assemblea),
                              icon: const Icon(Icons.edit),
                              label: const Text("Modifica"),
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(context, assemblea),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text("Esporta Verbale:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _copyToClipboard(context, assemblea),
                                    icon: const Icon(Icons.copy),
                                    label: const Text("Copia Testo"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
                                    onPressed: () => _generatePdf(context, assemblea),
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    label: const Text("PDF", style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
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
            return FloatingActionButton(
              onPressed: () => _openAssembleaForm(context),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openAssembleaForm(BuildContext context, {Assemblea? assemblea}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AssembleeCubit>()),
                BlocProvider(create: (_) =>
                sl<CondominiCubit>()
                  ..fetchCondomini()),
              ],
              child: AssembleaFormPage(assemblea: assemblea),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Assemblea assemblea) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text("Elimina Assemblea"),
        content: const Text("Sei sicuro di voler eliminare questa assemblea?"),
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

  void _copyToClipboard(BuildContext context, Assemblea assemblea) async {
    final condomini = await sl<CondominiCubit>().fetchCondomini();
    final text = VerbaleFormatter.generatePlainText(assemblea, condomini);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verbale copiato negli appunti")));
  }

  void _generatePdf(BuildContext context, Assemblea assemblea) async {
    final condomini = await sl<CondominiCubit>().fetchCondomini();
    PdfGenerator.generateAndShare(assemblea, condomini);
  }
}
