# 📑 Índice de Documentação - Validação com Express-Validator

## 🎯 Por Onde Começar?

1. **Primeira vez?** → [`GUIA_RAPIDO.md`](#guia-rápido)
2. **Detalhes técnicos?** → [`IMPLEMENTACAO_VALIDACAO.md`](#implementação)
3. **Exemplos de API?** → [`VALIDACAO_EXEMPLOS.md`](#exemplos)
4. **Visão geral?** → [`README_VALIDACAO.md`](#readme)

---

## 📚 Todos os Ficheiros

### 📖 Documentação Markdown

#### 1. 🏃 [`GUIA_RAPIDO.md`](./GUIA_RAPIDO.md)
**Para**: Utilizadores com pressa  
**Contém**:
- Instalação em 1 minuto
- Como testar
- Casos de uso comuns
- Tabelas de referência rápida
- Debug básico
- Boas práticas

**Quando usar**: Primeira vez, setup inicial, debug rápido

---

#### 2. 🔧 [`IMPLEMENTACAO_VALIDACAO.md`](./IMPLEMENTACAO_VALIDACAO.md)
**Para**: Desenvolvedores que querem entender tudo  
**Contém**:
- Detalhes de cada ficheiro modificado
- Validadores criados
- Endpoints validados (tabelas)
- Tipos de validação usados
- Estatísticas de implementação
- Fluxo de validação completo
- Checklist de implementação

**Quando usar**: Compreensão profunda, manutenção futura

---

#### 3. 💡 [`VALIDACAO_EXEMPLOS.md`](./VALIDACAO_EXEMPLOS.md)
**Para**: Testers e integradores  
**Contém**:
- 50+ exemplos com curl
- Casos de erro para cada endpoint
- Respostas esperadas
- Tipos de campos dinâmicos
- Como testar em Postman
- Padrão de resposta
- Boas práticas de teste

**Quando usar**: Testes manuais, integração, Postman

---

#### 4. 📋 [`README_VALIDACAO.md`](./README_VALIDACAO.md)
**Para**: Visão geral do projeto  
**Contém**:
- Resumo executivo
- O que foi entregue
- Quick start
- Exemplos rápidos
- Benefícios
- Endpoints validados
- Checklist final

**Quando usar**: Apresentação, visão geral

---

### 🧪 Scripts de Teste

#### 5. 🪟 [`test-validation.ps1`](./test-validation.ps1)
**Plataforma**: Windows (PowerShell)  
**Uso**:
```powershell
.\test-validation.ps1 -Token "seu_jwt_token"
```

**Testa**:
- 10 endpoints com dados inválidos
- Todos devem retornar HTTP 400
- Validação da estrutura de erro

---

#### 6. 🐧 [`test-validation.sh`](./test-validation.sh)
**Plataforma**: Linux/Mac (Bash)  
**Uso**:
```bash
chmod +x test-validation.sh
./test-validation.sh
```

**Testa**: Mesmas 10 endpoints que PowerShell

---

### 💻 Código Fonte

#### 7. ✨ [`src/middleware/validate.js`](./src/middleware/validate.js)
**Novo ficheiro**  
**Função**: Middleware reutilizável para processar erros de validação

**Código**:
```javascript
const { validationResult } = require('express-validator');

function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array().map(e => ({
        campo: e.path,
        mensagem: e.msg,
        valor: e.value
      }))
    });
  }
  next();
}

module.exports = validate;
```

---

#### 8. 🔐 [`src/routes/auth.js`](./src/routes/auth.js)
**Modificado**  
**Validações**:
- Email válido
- Password mín. 4 caracteres

---

#### 9. 📊 [`src/routes/projetos.js`](./src/routes/projetos.js)
**Modificado**  
**Validações**:
- Nome obrigatório, máx 255
- Descrição opcional, máx 1000
- ID > 0

---

#### 10. 🗂️ [`src/routes/nos.js`](./src/routes/nos.js)
**Modificado**  
**Validações**:
- projeto_id > 0
- Nome obrigatório, máx 255
- pai_id opcional > 0

---

#### 11. 📋 [`src/routes/registos.js`](./src/routes/registos.js)
**Modificado**  
**Validações**:
- no_id > 0
- dados_json JSON válido
- Paginação: limit 1-100, page > 0

---

#### 12. 👥 [`src/routes/utilizadores.js`](./src/routes/utilizadores.js)
**Modificado**  
**Validações**:
- Email válido
- Password mín. 4
- Perfil enum (admin|trabalhador|utilizador)

---

#### 13. 🔧 [`src/routes/campos.js`](./src/routes/campos.js)
**Modificado**  
**Validações**:
- tipo_campo enum (8 tipos)
- Nome obrigatório, máx 255
- Ordem > 0

---

## 🗺️ Mapa de Navegação

```
Documentação/
├── 📖 GUIA_RAPIDO.md ..................... Início rápido
├── 🔧 IMPLEMENTACAO_VALIDACAO.md ........ Detalhes técnicos
├── 💡 VALIDACAO_EXEMPLOS.md ............ 50+ exemplos
├── 📋 README_VALIDACAO.md .............. Visão geral
├── 📑 INDEX.md (este ficheiro) ........ Navegação
│
├── 🧪 Scripts/
│   ├── test-validation.ps1 ............. Testes Windows
│   └── test-validation.sh .............. Testes Linux/Mac
│
└── 💻 Código/
    └── src/
        ├── middleware/
        │   └── validate.js ............ Novo middleware
        └── routes/
            ├── auth.js ................ ✏️ Modificado
            ├── projetos.js ............ ✏️ Modificado
            ├── nos.js ................. ✏️ Modificado
            ├── registos.js ............ ✏️ Modificado
            ├── utilizadores.js ........ ✏️ Modificado
            └── campos.js .............. ✏️ Modificado
```

---

## 🎯 Guia por Tarefa

### Quero...

**...começar rapidamente**
1. Leia [`GUIA_RAPIDO.md`](./GUIA_RAPIDO.md)
2. Execute `test-validation.ps1` ou `test-validation.sh`
3. Teste com curl

**...entender como funciona**
1. Leia [`IMPLEMENTACAO_VALIDACAO.md`](./IMPLEMENTACAO_VALIDACAO.md)
2. Veja [`src/middleware/validate.js`](./src/middleware/validate.js)
3. Consulte um ficheiro de rota modificado

**...testar a API**
1. Veja [`VALIDACAO_EXEMPLOS.md`](./VALIDACAO_EXEMPLOS.md)
2. Copie e execute exemplos com curl
3. Use Postman com os exemplos

**...fazer debug**
1. Consulte [`GUIA_RAPIDO.md`](./GUIA_RAPIDO.md#-debug)
2. Execute script de teste
3. Verifique logs da API

**...estender validações**
1. Veja [`IMPLEMENTACAO_VALIDACAO.md`](./IMPLEMENTACAO_VALIDACAO.md#-tipos-de-validação)
2. Modifique ficheiro de rota
3. Adicione novo validador
4. Teste com exemplos

---

## 📊 Resumo Estatístico

| Métrica | Valor |
|---------|-------|
| Ficheiros de documentação | 5 |
| Scripts de teste | 2 |
| Exemplos com curl | 50+ |
| Endpoints validados | 45+ |
| Tipos de validação | 20+ |
| Validadores criados | 30+ |
| Linhas de código novo | 500+ |

---

## ⏱️ Tempo de Leitura

| Ficheiro | Tempo |
|----------|-------|
| GUIA_RAPIDO | 5 min ⚡ |
| README_VALIDACAO | 10 min 📖 |
| VALIDACAO_EXEMPLOS | 15 min 💡 |
| IMPLEMENTACAO_VALIDACAO | 20 min 🔧 |
| **Total** | **50 min** |

---

## 🔗 Links Úteis

- [Express-Validator Docs](https://express-validator.github.io/)
- [Validadores Disponíveis](https://github.com/validatorjs/validator.js#validators)
- NPM: `npm install express-validator`

---

## ✅ Checklist de Leitura

- [ ] Leu `GUIA_RAPIDO.md`
- [ ] Executou um teste (PS1 ou SH)
- [ ] Testou com curl
- [ ] Leu `IMPLEMENTACAO_VALIDACAO.md`
- [ ] Viu o middleware `validate.js`
- [ ] Consultou `VALIDACAO_EXEMPLOS.md`
- [ ] Testou em Postman
- [ ] Entende o fluxo de validação
- [ ] Pode estender validações
- [ ] Pronto para produção ✨

---

## 🎓 Recursos de Aprendizagem

**Iniciante**: GUIA_RAPIDO + test-validation  
**Intermédio**: VALIDACAO_EXEMPLOS + curl  
**Avançado**: IMPLEMENTACAO_VALIDACAO + source code  

---

## 📞 Suporte Rápido

| Problema | Solução |
|----------|---------|
| Express-validator não encontrado | `npm install express-validator` |
| Script não executa (PS1) | `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned` |
| Script não executa (SH) | `chmod +x test-validation.sh` |
| Validação não funciona | Confirme middleware nos routes |
| HTTP 200 ao invés de 400 | Validador não aplicado |

---

## 🚀 Próximos Passos

1. ✅ Implementação completa
2. 📖 Documentação abrangente
3. 🧪 Testes funcionais
4. 🔄 Revisão em 1 semana
5. 📈 Monitoring de erros
6. 🛡️ Security audit

---

**Navegação**:
- ⬆️ Topo: [Índice](#-índice-de-documentação)
- 🏠 Home: [README_VALIDACAO.md](./README_VALIDACAO.md)
- ⚡ Rápido: [GUIA_RAPIDO.md](./GUIA_RAPIDO.md)

**Última atualização**: 2024  
**Status**: ✅ Completo
