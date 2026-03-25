class Utilizador {
  int? id;
  String nome;
  String email;
  String perfil;

  Utilizador({this.id, required this.nome, required this.email, required this.perfil});

  factory Utilizador.fromMap(Map<String, dynamic> map) {
    return Utilizador(id: map['id'], nome: map['nome'], email: map['email'], perfil: map['perfil']);
  }
}

class Projeto {
  int? id;
  String nome;
  String descricao;

  Projeto({this.id, required this.nome, required this.descricao});

  factory Projeto.fromMap(Map<String, dynamic> map) {
    return Projeto(id: map['id'], nome: map['nome'], descricao: map['descricao'] ?? '');
  }
}

class No {
  int? id;
  int projetoId;
  int? paiId;
  String nome;

  No({this.id, required this.projetoId, this.paiId, required this.nome});

  factory No.fromMap(Map<String, dynamic> map) {
    return No(
      id: map['id'],
      projetoId: map['projeto_id'],
      paiId: map['pai_id'],
      nome: map['nome'],
    );
  }
}

class CampoDinamico {
  int? id;
  int noId;
  String nomeCampo;
  String tipoCampo;
  String? opcoes;
  int obrigatorio;
  int ordem;

  CampoDinamico({
    this.id,
    required this.noId,
    required this.nomeCampo,
    required this.tipoCampo,
    this.opcoes,
    required this.obrigatorio,
    required this.ordem,
  });

  factory CampoDinamico.fromMap(Map<String, dynamic> map) {
    return CampoDinamico(
      id: map['id'],
      noId: map['no_id'],
      nomeCampo: map['nome_campo'],
      tipoCampo: map['tipo_campo'],
      opcoes: map['opcoes'],
      obrigatorio: map['obrigatorio'],
      ordem: map['ordem'] ?? 0,
    );
  }
}