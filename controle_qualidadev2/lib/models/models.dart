// ─── UTILIZADOR ───────────────────────────────────────────
class Utilizador {
  int? id;
  String nome;
  String email;
  String perfil;

  Utilizador({
    this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  factory Utilizador.fromMap(Map<String, dynamic> map) {
    return Utilizador(
      id: map['id'],
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      perfil: map['perfil'] ?? 'trabalhador', // Valor por defeito seguro
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'email': email,
      'perfil': perfil,
    };
  }
}

// ─── PROJETO ──────────────────────────────────────────────
class Projeto {
  int? id;
  String nome;
  String descricao;

  Projeto({
    this.id,
    required this.nome,
    required this.descricao,
  });

  factory Projeto.fromMap(Map<String, dynamic> map) {
    return Projeto(
      id: map['id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
    };
  }
}

// ─── NÓ ───────────────────────────────────────────────────
class No {
  int? id;
  int projetoId;
  int? paiId;
  String nome;

  No({
    this.id,
    required this.projetoId,
    this.paiId,
    required this.nome,
  });

  factory No.fromMap(Map<String, dynamic> map) {
    return No(
      id: map['id'],
      projetoId: map['projeto_id'] ?? 0,
      paiId: map['pai_id'],
      nome: map['nome'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'projeto_id': projetoId,
      'pai_id': paiId,
      'nome': nome,
    };
  }
}

// ─── NÓ PARTILHADO ────────────────────────────────────────
class NoPartilhado {
  final int id;
  final int projetoId;
  final int? paiId;
  final String nome;
  final String projetoNome;
  final List<String> breadcrumb;

  NoPartilhado({
    required this.id,
    required this.projetoId,
    this.paiId,
    required this.nome,
    required this.projetoNome,
    required this.breadcrumb,
  });

  factory NoPartilhado.fromMap(Map<String, dynamic> map) {
    return NoPartilhado(
      id: map['id'],
      projetoId: map['projeto_id'] ?? 0,
      paiId: map['pai_id'],
      nome: map['nome'] ?? '',
      projetoNome: map['projeto_nome'] ?? '',
      // Leitura extra segura da lista para evitar erros de casting:
      breadcrumb: (map['breadcrumb'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  // Converte para um No normal para usar no NosScreen
  No toNo() => No(
        id: id,
        projetoId: projetoId,
        paiId: paiId,
        nome: nome,
      );

  // Converte para um Projeto para usar no NosScreen
  Projeto toProjeto() => Projeto(
        id: projetoId,
        nome: projetoNome,
        descricao: '',
      );
}

// ─── CAMPO DINÂMICO ───────────────────────────────────────
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
      noId: map['no_id'] ?? 0,
      nomeCampo: map['nome_campo'] ?? '',
      tipoCampo: map['tipo_campo'] ?? 'texto',
      opcoes: map['opcoes'],
      obrigatorio: map['obrigatorio'] ?? 0,
      ordem: map['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'no_id': noId,
      'nome_campo': nomeCampo,
      'tipo_campo': tipoCampo,
      'opcoes': opcoes,
      'obrigatorio': obrigatorio,
      'ordem': ordem,
    };
  }
}