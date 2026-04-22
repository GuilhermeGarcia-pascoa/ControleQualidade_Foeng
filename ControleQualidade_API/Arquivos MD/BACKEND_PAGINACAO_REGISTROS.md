# Implementação de Paginação no Backend - Registros

## Alterações Realizadas

### Endpoint GET /registos/:noId
- **Arquivo modificado**: `src/routes/registos.js`
- **Parâmetros de query adicionados**:
  - `limit` (padrão: 50, máximo: 100)
  - `offset` (padrão: 0)

### Estrutura da Resposta
```json
{
  "success": true,
  "registos": [...],
  "total": 150
}
```

### Validações
- Limit máximo de 100 registros por página
- Offset deve ser um número inteiro não negativo
- Mantém compatibilidade com chamadas sem parâmetros (retorna primeiros 50 registros)

### Queries SQL
1. **Registros paginados**:
   ```sql
   SELECT r.*, u.nome as nome_utilizador
   FROM registos r
   JOIN utilizadores u ON r.utilizador_id = u.id
   WHERE r.no_id = ?
   ORDER BY r.criado_em DESC
   LIMIT ? OFFSET ?
   ```

2. **Contagem total**:
   ```sql
   SELECT COUNT(*) as total FROM registos WHERE no_id = ?
   ```

## Como Testar
1. **Sem paginação** (compatibilidade):
   ```
   GET /api/registos/1
   ```
   Retorna primeiros 50 registros + total

2. **Com paginação**:
   ```
   GET /api/registos/1?limit=20&offset=0
   GET /api/registos/1?limit=20&offset=20
   ```

3. **Limite máximo**:
   ```
   GET /api/registos/1?limit=150
   ```
   Será limitado a 100

## Benefícios
- Redução no tempo de resposta para listas grandes
- Menor uso de memória no servidor
- Melhor experiência para usuários com muitos registros
- Preparado para escalabilidade