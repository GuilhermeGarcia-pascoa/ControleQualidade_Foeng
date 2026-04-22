-- ============================================================
-- migrate_cascade.sql
-- Adiciona ON DELETE CASCADE nas foreign keys relevantes
-- FAZER BACKUP ANTES DE CORRER ESTE SCRIPT
--
-- Uso:
--   mysql -u root -p foeng_db < migrate_cascade.sql
-- ============================================================

-- PASSO 0: Ver os nomes reais das foreign keys (corre isto primeiro!)
-- SHOW CREATE TABLE nos;
-- SHOW CREATE TABLE registos;
-- SHOW CREATE TABLE campos_dinamicos;
-- SHOW CREATE TABLE utilizador_no;
-- SHOW CREATE TABLE utilizador_projeto;

-- ============================================================
-- PASSO 1: nos → projetos
-- ============================================================
-- Ver o nome da FK com: SHOW CREATE TABLE nos;
-- O nome típico gerado pelo MySQL é algo como 'nos_ibfk_1'
-- Substitui abaixo pelo nome real se for diferente.

ALTER TABLE nos
  DROP FOREIGN KEY nos_ibfk_1;   -- ← substitui pelo nome real

ALTER TABLE nos
  ADD CONSTRAINT fk_nos_projeto
    FOREIGN KEY (projeto_id) REFERENCES projetos(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- ============================================================
-- PASSO 2: registos → nos
-- ============================================================
ALTER TABLE registos
  DROP FOREIGN KEY registos_ibfk_1;   -- ← substitui pelo nome real

ALTER TABLE registos
  ADD CONSTRAINT fk_registos_no
    FOREIGN KEY (no_id) REFERENCES nos(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- ============================================================
-- PASSO 3: campos_dinamicos → nos
-- ============================================================
ALTER TABLE campos_dinamicos
  DROP FOREIGN KEY campos_dinamicos_ibfk_1;   -- ← substitui pelo nome real

ALTER TABLE campos_dinamicos
  ADD CONSTRAINT fk_campos_no
    FOREIGN KEY (no_id) REFERENCES nos(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- ============================================================
-- PASSO 4: utilizador_no → nos
-- ============================================================
ALTER TABLE utilizador_no
  DROP FOREIGN KEY utilizador_no_ibfk_2;   -- ← substitui pelo nome real (FK para nos)

ALTER TABLE utilizador_no
  ADD CONSTRAINT fk_utilizador_no_no
    FOREIGN KEY (no_id) REFERENCES nos(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- ============================================================
-- PASSO 5: utilizador_projeto → projetos
-- ============================================================
ALTER TABLE utilizador_projeto
  DROP FOREIGN KEY utilizador_projeto_ibfk_1;   -- ← substitui pelo nome real

ALTER TABLE utilizador_projeto
  ADD CONSTRAINT fk_utilizador_projeto_projeto
    FOREIGN KEY (projeto_id) REFERENCES projetos(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- ============================================================
-- VERIFICAÇÃO: Confirmar que o CASCADE está ativo
-- ============================================================
SELECT
  TABLE_NAME,
  CONSTRAINT_NAME,
  REFERENCED_TABLE_NAME,
  DELETE_RULE
FROM
  information_schema.REFERENTIAL_CONSTRAINTS
WHERE
  CONSTRAINT_SCHEMA = DATABASE()
ORDER BY
  TABLE_NAME;

-- ============================================================
-- COMO DESCOBRIR OS NOMES REAIS DAS FKs
-- ============================================================
-- Corre este SELECT para ver todos os nomes de FK da tua BD:
--
-- SELECT
--   TABLE_NAME,
--   CONSTRAINT_NAME,
--   REFERENCED_TABLE_NAME
-- FROM
--   information_schema.KEY_COLUMN_USAGE
-- WHERE
--   CONSTRAINT_SCHEMA = DATABASE()
--   AND REFERENCED_TABLE_NAME IS NOT NULL
-- ORDER BY TABLE_NAME;