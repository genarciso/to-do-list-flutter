import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


void main() {
  runApp(MaterialApp(title: "Lista de tarefas", home: Main()));
}

class Main extends StatefulWidget {
  @override
  MainState createState() => MainState();
}

class MainState extends State<Main> {
  List listaTarefas = [];
  List listaTarefasFeitas = [];
  Map<String, dynamic> ultimoRemovido = Map();
  int posicaoUltimoRemovido;

  TextEditingController _listaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _leituraArquivo().then((dados) {
      setState(() {
        listaTarefas = json.decode(dados);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Scaffold tela = Scaffold(
      appBar: AppBar(
          title: Text("Minha lista de tarefas"),
          backgroundColor: Colors.black54,
          centerTitle: true
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(child: TextField(
                  controller: _listaController,
                  decoration: InputDecoration(
                    labelText: "Nova tarefa",
                    labelStyle: TextStyle(color: Colors.black54),
                  ),
                )),
                RaisedButton(
                    color: Colors.black54,
                    child: Text("+ Add"),
                    textColor: Colors.white,
                    onPressed: adicionarTarefa
                )
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(onRefresh: aoAtualizar,
            child: Column(children: <Widget>[
              Row(
                children: <Widget>[
                  Text("Tarefas pendentes")
                ],
              ),
              Expanded(child: ListView.builder(itemBuilder: buildItemNOK,
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: listaTarefas.where((element) => !element["ok"]).toList().length)),
              Row(
                children: <Widget>[
                  Text("Tarefas feitas")
                ],
              ),
              Expanded(child: ListView.builder(itemBuilder: buildItemOK,
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: listaTarefas.where((element) => element["ok"]).toList().length),)
            ]),
          ))
        ],
      ),
    );

    return tela;
  }

  Widget buildItemNOK(context, index) {
    return buildItem(context, index, listaTarefas.where((element) => !element["ok"]).toList());
  }

  Widget buildItemOK(context, index) {
    return buildItem(context, index, listaTarefas.where((element) => element["ok"]).toList());
  }

  Widget buildItem(context, index, lista) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(lista[index]["titulo"]),
        value: lista[index]["ok"],
        secondary: CircleAvatar(
          backgroundColor: Colors.black54,
          child: Icon(lista[index]["ok"] ? Icons.check : Icons.alarm),
        ),
        onChanged: (c) {
          confirmarTarefa(index, c);
        },
      ),
      onDismissed: (direcao) {
        setState(() {
          ultimoRemovido = Map.from(lista[index]);
          posicaoUltimoRemovido = index;
          lista.removeAt(index);
          salvarTarefas();

          final snack = SnackBar(
            content: Text("Tarefa ${ultimoRemovido["title"]} removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    lista.insert(posicaoUltimoRemovido, ultimoRemovido);
                    salvarTarefas();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<String> _leituraArquivo() async {
    try {
      final arquivo = await _getArquivo();
      return arquivo.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<File> _getArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/data.json");
  }

  void adicionarTarefa() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["titulo"] = _listaController.text;
      novaTarefa["ok"] = false;
      _listaController.text = "";
      listaTarefas.add(novaTarefa);
      salvarTarefas();

    });
  }

  Future<File> salvarTarefas() async {
    String dados = json.encode(listaTarefas);
    final file = await _getArquivo();
    return file.writeAsString(dados);
  }

  Future<Null> aoAtualizar() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      listaTarefas.sort((a, b) {
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      salvarTarefas();
    });
    return null;
  }

  void confirmarTarefa(index, c) {
    setState(() {
      listaTarefas[index]["ok"] = c;
      salvarTarefas();
    });
  }

}


