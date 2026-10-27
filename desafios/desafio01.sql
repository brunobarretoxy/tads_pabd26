-- ============================================================
-- QUESTÃO 01 - Materialized View: Resumo por piloto/temporada
-- ============================================================

drop materialized view if exists mv_driver_season_summary;

create materialized view mv_driver_season_summary as
select
    r.year as season_year,
    rd.driver_id,
    d.full_name,
    count(*) as total_races,
    count(case when rd.position_number = 1 then 1 end) as wins,
    count(case when rd.position_number <= 3 then 1 end) as podiums,
    count(case when rd.race_reason_retired IS NOT NULL then 1 end) as dnf,
    coalesce(sum(rd.race_points), 0) as total_points
from race_data rd
join race r on r.id = rd.race_id
join driver d on d.id = rd.driver_id
where rd.type = 'RACE_RESULT'
group by r.year, rd.driver_id, d.full_name;

create unique index idx_mv_driver_season_summary
on mv_driver_season_summary(season_year, driver_id);

refresh materialized view concurrently mv_driver_season_summary;

select * from mv_driver_season_summary
where driver_id = 'ayrton-senna'
order by season_year desc
limit 10;

-- ============================================================
-- QUESTÃO 02 - Auditoria de pontos do campeonato
-- ============================================================

DROP TABLE IF EXISTS points_adjustment_audit;
CREATE TABLE points_adjustment_audit (
    id         SERIAL PRIMARY KEY,
    year       INT NOT NULL,
    driver_id  VARCHAR(100) NOT NULL,
    old_points DECIMAL(8,2),
    new_points DECIMAL(8,2),
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION fn_audit_points_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO points_adjustment_audit
        (year, driver_id, old_points, new_points)
    VALUES
        (NEW.year, NEW.driver_id, OLD.points, NEW.points);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_points_changes ON season_driver_standing;
CREATE TRIGGER trg_audit_points_changes
AFTER UPDATE ON season_driver_standing
FOR EACH ROW
WHEN (OLD.points IS DISTINCT FROM NEW.points)
EXECUTE FUNCTION fn_audit_points_changes();

-- * Testes

-- Ver auditoria vazia:
SELECT * FROM points_adjustment_audit;

-- SUCESSO: Alterar pontos (dispara a trigger)
UPDATE season_driver_standing
SET points = points + 100
WHERE year = 1993 AND driver_id = 'ayrton-senna';

-- NÃO DISPARA: Atualizar sem mudar pontos
UPDATE season_driver_standing
SET position_text = position_text
WHERE year = 1994 AND driver_id = 'ayrton-senna';

-- Ver auditoria preenchida:
SELECT * FROM points_adjustment_audit ORDER BY changed_at DESC;

-- ============================================================
-- QUESTÃO 03 - Impedir exclusão de piloto com histórico
-- ============================================================

CREATE OR REPLACE FUNCTION fn_prevent_driver_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM race_data
        WHERE driver_id = OLD.id
    ) THEN
        RAISE EXCEPTION
            'Integridade: Não é possível excluir o piloto "%" (id: %). Existem registros em race_data vinculados.',
            OLD.full_name, OLD.id;
    END IF;

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_driver_delete ON driver;
CREATE TRIGGER trg_prevent_driver_delete
BEFORE DELETE ON driver
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_driver_delete();

-- * Testes

-- FALHA: Tentar excluir um piloto com histórico
DELETE FROM driver WHERE id = 'ayrton-senna';

-- Teste: verificando piloto sem histórico em race_data
select d.id from driver d where not exists (select 1 from race_data r where r.driver_id = d.id);

-- SUCESSO: Excluir um piloto sem histórico

-- christophe-bouchut
-- matteo-bobbi
-- satoshi-motoyama
DELETE FROM driver WHERE id = 'piloto_sem_historico';