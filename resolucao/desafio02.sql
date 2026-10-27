-- Resolução do Desafio de Programação 02 — Transações e concorrência
-- Execute conectado ao banco dvdrental.
-- A tabela customer relaciona o cliente a um endereço existente por address_id.

-- ============================================================
-- QUESTÃO 01 - Cadastro de cliente e perfil
-- ============================================================

BEGIN;

-- Cadastro válido: address_id 1 é um endereço já existente no dvdrental.
INSERT INTO customer (store_id, first_name, last_name, email, address_id)
VALUES (1, 'Cliente', 'Desafio 02', 'cliente.desafio02@example.com', 1);

-- ERRO intencional: first_name é obrigatório (NOT NULL).
-- No PostgreSQL, esse erro deixa a transação em estado abortado.
INSERT INTO customer (store_id, first_name, last_name, email, address_id)
VALUES (1, NULL, 'Cadastro Inválido', 'invalido.desafio02@example.com', 1);

-- Desfaz também o primeiro INSERT válido, pois a transação inteira falhou.
ROLLBACK;

-- Resultado esperado: nenhuma linha. O cliente do primeiro INSERT não existe,
-- pois o ROLLBACK desfaz todas as alterações ainda não confirmadas.
SELECT customer_id, first_name, last_name, email
FROM customer
WHERE email = 'cliente.desafio02@example.com';

-- Atomicidade: evita que o cadastro fique parcialmente gravado (por exemplo,
-- cliente sem algum dado obrigatório ou sem os registros relacionados).


-- ============================================================
-- QUESTÃO 02 - Gestão de estoque com SAVEPOINT
-- ============================================================

BEGIN;

-- Primeira unidade válida. Guarde o inventory_id retornado para a questão 3.
INSERT INTO inventory (film_id, store_id)
VALUES (1, 1)
RETURNING inventory_id;

SAVEPOINT estoque_atualizado;

-- ERRO intencional: film_id 999999 não existe e viola a chave estrangeira.
INSERT INTO inventory (film_id, store_id)
VALUES (999999, 1);

-- Recupera a transação após o erro e mantém o INSERT anterior ao savepoint.
ROLLBACK TO SAVEPOINT estoque_atualizado;

-- Segunda unidade válida; este inventory_id também pode ser usado na questão 3.
INSERT INTO inventory (film_id, store_id)
VALUES (2, 1)
RETURNING inventory_id;

-- Os dois INSERTs válidos são confirmados; o INSERT inválido não é gravado.
COMMIT;

-- Os inventory_id devolvidos pelos dois INSERTs identificam exatamente as
-- unidades criadas; use-os aqui para conferir após o COMMIT:
-- SELECT inventory_id, film_id, store_id
-- FROM inventory
-- WHERE inventory_id IN (ID_RETORNADO_1, ID_RETORNADO_2);

-- Depois do COMMIT ficam ambos os registros válidos (o anterior e o posterior
-- ao savepoint), mas não o registro inválido. O savepoint permite recuperar
-- apenas a parte posterior a ele, sem cancelar todo o trabalho da transação.


-- ============================================================
-- QUESTÃO 03 - Concorrência sobre a mesma unidade de estoque
-- ============================================================

-- Antes do teste, copie um inventory_id retornado na questão 2 e use o mesmo
-- valor nas duas sessões no lugar de 12345. Use uma unidade recém-cadastrada,
-- que ainda não tenha locações associadas. Abra duas conexões/sessões SQL.
-- store_id 2 representa a outra loja do dvdrental.
-- Importante: BEGIN sozinho não dá prioridade; a prioridade é de quem obtém
-- primeiro o bloqueio da linha (FOR UPDATE, UPDATE ou DELETE).

-- ------------------------------------------------------------
-- CENÁRIO A: a sessão A bloqueia/atualiza primeiro; a sessão B espera e exclui
-- ------------------------------------------------------------
-- Sessão A:
-- BEGIN;
-- SELECT inventory_id, store_id
-- FROM inventory
-- WHERE inventory_id = 12345
-- FOR UPDATE;
-- -- A linha fica bloqueada até COMMIT/ROLLBACK.
--
-- Sessão B (execute enquanto A ainda está aberta; ficará aguardando):
-- BEGIN;
-- DELETE FROM inventory WHERE inventory_id = 12345;
--
-- Sessão A (enquanto B aguarda):
-- UPDATE inventory SET store_id = 2 WHERE inventory_id = 12345;
-- COMMIT;
--
-- Após o COMMIT de A, o DELETE pendente da sessão B prossegue e remove a linha.
-- Conclua a sessão B:
-- COMMIT;
-- Resultado final: a unidade não existe. O UPDATE de A foi serializado antes
-- do DELETE de B; se a intenção for preservar a transferência, B deve revalidar
-- a decisão após o bloqueio, em vez de excluir incondicionalmente.

-- ------------------------------------------------------------
-- CENÁRIO B: a sessão B bloqueia/exclui primeiro; a sessão A espera
-- ------------------------------------------------------------
-- Sessão B:
-- BEGIN;
-- SELECT inventory_id, store_id
-- FROM inventory
-- WHERE inventory_id = 12345
-- FOR UPDATE;
-- DELETE FROM inventory WHERE inventory_id = 12345;
-- -- Não confirme ainda; mantenha a transação aberta.
--
-- Sessão A (execute enquanto B ainda está aberta; ficará aguardando):
-- BEGIN;
-- UPDATE inventory SET store_id = 2 WHERE inventory_id = 12345;
--
-- Sessão B:
-- COMMIT;
--
-- Após o COMMIT de B, o UPDATE de A termina sem alterar linhas, pois o registro
-- foi excluído. Confirme e verifique na sessão A:
-- SELECT inventory_id, store_id
-- FROM inventory
-- WHERE inventory_id = 12345;
-- COMMIT;
-- Resultado final: a unidade foi excluída e não pode ser transferida.
