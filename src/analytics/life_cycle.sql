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
    WHERE DtCriacao < '{date}'
),

tb_idade AS (
    SELECT 
        IdCliente,
        
        -- MIN(dtDia) AS dtPrimeiraTransacao,
        CAST(max(julianday('{date}') - julianday(dtDia)) as int) AS qtdDiasPrimTransacao,
        
        -- MAX(dtDia) AS dtUltimaTransacao,
        CAST(min(julianday('{date}') - julianday(dtDia)) as int) AS qtdDiasUltTransacao
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
        CAST(julianday('{date}') - julianday(dtDia) as int) AS qtdeDiasPenultimaTransacao
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
            WHEN qtdDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdDiasUltTransacao BETWEEN 15 AND 27 THEN '02-RECONQUISTADO'
            WHEN qtdDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdDiasUltTransacao > 28 THEN '02-REBORN'
        END AS descLifeCycle
    FROM tb_idade AS t1
    LEFT JOIN tb_penultima_ativacao AS t2
        ON t1.IdCliente = t2.IdCliente
),

tb_freq_valor AS (
    SELECT 
        IdCliente,
        COUNT(DISTINCT substr(DtCriacao, 0, 11)) AS qtdeFrequencia,
        sum(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS qtdePontos,
        sum(ABS(QtdePontos)) AS qtdePontosAbs
    FROM transacoes

    WHERE dtCriacao < '{date}'
    AND DtCriacao >= date('{date}', '-28 day')

    GROUP BY IdCliente

    ORDER BY qtdeFrequencia DESC
),

tb_cluster AS (
    SELECT *,
        CASE
            WHEN qtdeFrequencia <= 10 AND qtdePontos > 1500 THEN '12 - Hypers'
            WHEN qtdeFrequencia > 10 AND qtdePontos >= 1500 THEN '22 - Eicientes'
            WHEN qtdeFrequencia <= 10 AND qtdePontos >= 750 THEN '11 - Indecisos'
            WHEN qtdeFrequencia > 10 AND qtdePontos >= 750 THEN '21 - Esforçados'
            WHEN qtdeFrequencia < 5 THEN '00 - Lurkers'
            WHEN qtdeFrequencia <= 10 THEN '01 - Preguiçoses'
            WHEN qtdeFrequencia > 10 THEN '20 - Potencial'
        END AS cluster
    FROM tb_freq_valor
)

SELECT date('{date}', '-1 day') AS dtRef,
       t1.*,
       t2.qtdeFrequencia,
       t2.qtdePontos,
       t2.cluster
FROM tb_life_cycle AS t1
LEFT JOIN tb_cluster AS t2
    ON t1.IdCliente = t2.IdCliente
