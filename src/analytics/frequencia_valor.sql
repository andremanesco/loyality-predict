WITH tb_freq_valor AS (
    SELECT 
        IdCliente,
        COUNT(DISTINCT substr(DtCriacao, 0, 11)) AS qtdeFrequencia,
        sum(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS qtdePontos,
        sum(ABS(QtdePontos)) AS qtdePontosAbs
    FROM transacoes

    WHERE dtCriacao < '2025-09-01'
    AND DtCriacao >= date('2025-09-01', '-28 day')

    GROUP BY IdCliente

    ORDER BY qtdeFrequencia DESC
)

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