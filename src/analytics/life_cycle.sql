-- curiosa -> idade < 7
-- fiel -> recencia < 7 e recencia anterior < 15
-- turista -> recencia <= 14
-- desencantado -> 14 < recencia <= 28
-- zumbi -> recencia > 28
-- reconquistado -> recencia < 7 e 14 <= recencia anterior <= 28 
-- reborn -> recencia < 7 e recencia anterior > 28 

WITH tb_daily AS (
    SELECT
        DISTINCT
            IdCliente,
            substr(DtCriacao, 0, 11) AS dtDia
    FROM transacoes
),

tb_idade AS (
    SELECT 
        IdCliente,
        
        -- MIN(dtDia) AS dtPrimeiraTransacao,
        CAST(max(julianday('now') - julianday(dtDia)) as int) AS qtdDiasPrimTransacao,
        
        -- MAX(dtDia) AS dtUltimaTransacao,
        CAST(min(julianday('now') - julianday(dtDia)) as int) AS qtdDiasUltTransacao
    FROM tb_daily
    GROUP BY IdCliente
),

tb_rn AS (
    SELECT *,
        row_number() OVER (PARTITION BY IdCliente ORDER BY dtDia DESC) AS rnDia
    FROM tb_daily
),

tb_penultima_ativacao AS (
    SELECT *, 
        CAST(julianday('now') - julianday(dtDia) as int) AS qtdeDiasPenultimaTransacao
    FROM tb_rn
    WHERE rnDia = 2
),

tb_life_cycle AS (
    SELECT 
        t1.*,
        t2.qtdeDiasPenultimaTransacao,

        CASE
            WHEN qtdDiasPrimTransacao <= 7 THEN '01-CURIOSO'
            WHEN qtdDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdDiasUltTransacao <= 14 THEN '02-FIEL'
            WHEN qtdDiasUltTransacao BETWEEN 8 AND 14 THEN '03-TURISTA'
            WHEN qtdDiasUltTransacao BETWEEN 15 AND 28 THEN '04-DESENCANTADA'
            WHEN qtdDiasUltTransacao > 28 THEN '05-ZUMBI'
            WHEN qtdDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdDiasUltTransacao BETWEEN 15 AND 28 THEN '02-RECONQUISTADO'
            WHEN qtdDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdDiasUltTransacao > 28 THEN '02-REBORN'
        END AS descLifeCycle
    FROM tb_idade AS t1
    LEFT JOIN tb_penultima_ativacao AS t2
        ON t1.IdCliente = t2.IdCliente
)

SELECT * 
FROM tb_life_cycle
WHERE descLifeCycle = '02-RECONQUISTADO'


