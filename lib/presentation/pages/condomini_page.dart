import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CondominiCubit, CondominiState>(
      builder: (context, state) {
        if (state is CondominiLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CondominiLoaded) {
          return ListView.builder(
            itemCount: state.condomini.length,
            itemBuilder: (context, index) {
              final condomino = state.condomini[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(condomino.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(condomino.indirizzo),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Millesimi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(condomino.millesimi.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (state is CondominiError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text("Nessun condòmino trovato."));
      },
    );
  }
}
