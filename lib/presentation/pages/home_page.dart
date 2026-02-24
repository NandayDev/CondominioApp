import 'package:condominio_app/presentation/pages/assemblee_page.dart';
import 'package:flutter/material.dart';

import 'condomini_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _title = "Dashboard";
  Widget _currentBody = const Center(child: Text("Dashboard"));

  void _onSelectItem(String title, Widget body) {
    setState(() {
      _title = title;
      _currentBody = body;
    });
    Navigator.of(context).pop(); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Condominio App',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => _onSelectItem("Dashboard", const Center(child: Text("Dashboard"))),
            ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Assemblee'),
              onTap: () => _onSelectItem("Assemblee", const AssembleePage()),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Condòmini'),
              onTap: () => _onSelectItem("Condòmini", const CondominiPage()),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Fatture e pagamenti'),
              onTap: () => _onSelectItem("Fatture e pagamenti", const Center(child: Text("Fatture e pagamenti"))),
            ),
          ],
        ),
      ),
      body: _currentBody,
    );
  }
}
