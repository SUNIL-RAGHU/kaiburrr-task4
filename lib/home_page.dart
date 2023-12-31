import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'serverclass.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController idController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController languageController = TextEditingController();
  TextEditingController frameworkController = TextEditingController();
  List<Serverclass> Servers = [];

  late StreamController<List<Serverclass>> _streamController;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<Serverclass>>();
    _fetchData();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:9090/servers/get'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _streamController.add(data.map((item) {
          return Serverclass(
            id: item['id'],
            name: item['name'],
            language: item['language'],
            framework: item['framework'],
          );
        }).toList());
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      _streamController.addError('Failed to load data');
    }
  }

  Future<void> _saveContact(String id, String name, String language, String framework) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:9090/servers/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': id,
          'name': name,
          'language': language,
          'framework': framework,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          Servers.add(Serverclass(
            id: data['id'],
            name: data['name'],
            language: data['language'],
            framework: data['framework'],
          ));
          idController.text = '';
          nameController.text = '';
          languageController.text = '';
          frameworkController.text = '';
        });
      } else {
        throw Exception('Failed to save contact');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      final response = await http.delete(Uri.parse('http://localhost:9090/servers/$id'));
      if (response.statusCode == 200) {
        setState(() {
          Servers.removeWhere((contact) => contact.id == id);
        });
      } else {
        throw Exception('Failed to delete contact');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Server List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                      hintText: 'Server ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Server Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: languageController,
                    keyboardType: TextInputType.text,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      hintText: 'Language',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: frameworkController,
                    decoration: const InputDecoration(
                      hintText: 'Framework',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    String id = idController.text.trim();
                    String name = nameController.text.trim();
                    String language = languageController.text.trim();
                    String framework = frameworkController.text.trim();
                    if (id.isNotEmpty && name.isNotEmpty && language.isNotEmpty && framework.isNotEmpty) {
                      _saveContact(id, name, language, framework);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StreamBuilder<List<Serverclass>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    Servers = snapshot.data!;
                    return DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Language')),
                        DataColumn(label: Text('Framework')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: Servers.map((server) {
                        return DataRow(cells: [
                          DataCell(Text(server.id)),
                          DataCell(Text(server.name)),
                          DataCell(Text(server.language)),
                          DataCell(Text(server.framework)),
                          DataCell(
                            IconButton(
                              onPressed: () {
                                _deleteContact(server.id);
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ),
                        ]);
                      }).toList(),
                    );
                  } else {
                    return Text('No Servers yet..');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


