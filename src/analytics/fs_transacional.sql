WITH tb_transacao AS (
    SELECT *,
        substr(DtCriacao, 0, 11) AS dtDia
    FROM transacoes
    WHERE dtCriacao < '2025-09-01'
),

tb_agg_transacao AS (
    SELECT IdCliente,
        COUNT(DISTINCT dtDia) AS qtdeAtivacaoVida,
        COUNT(DISTINCT CASE WHEN dtDia > date('2025-09-01', '-7 days') THEN dtDia END) AS qtdeAtivacaoD7,
        COUNT(DISTINCT CASE WHEN dtDia > date('2025-09-01', '-14 days') THEN dtDia END) AS qtdeAtivacaoD14,
        COUNT(DISTINCT CASE WHEN dtDia > date('2025-09-01', '-28 days') THEN dtDia END) AS qtdeAtivacaoD28,
        COUNT(DISTINCT CASE WHEN dtDia > date('2025-09-01', '-56 days') THEN dtDia END) AS qtdeAtivacaoD56,

        COUNT(DISTINCT IdTransacao) AS qtdeTransacaoVida,
        COUNT(DISTINCT CASE WHEN IdTransacao > date('2025-09-01', '-7 days') THEN IdTransacao END) AS qtdeTransacaoD7,
        COUNT(DISTINCT CASE WHEN IdTransacao > date('2025-09-01', '-14 days') THEN IdTransacao END) AS qtdeTransacaoD14,
        COUNT(DISTINCT CASE WHEN IdTransacao > date('2025-09-01', '-28 days') THEN IdTransacao END) AS qtdeTransacaoD28,
        COUNT(DISTINCT CASE WHEN IdTransacao > date('2025-09-01', '-56 days') THEN IdTransacao END) AS qtdeTransacaoD56,

        SUM(qtdePontos) AS saldoVida,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-7 days') THEN  qtdePontos ELSE 0 END) AS saldoD7,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-14 days') THEN qtdePontos ELSE 0 END) AS saldoD14,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-28 days') THEN qtdePontos ELSE 0 END) AS saldoD28,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-56 days') THEN qtdePontos ELSE 0 END) AS saldoD56,

        SUM(CASE WHEN qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPositivosVida,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-7 days') AND qtdePontos > 0 THEN  qtdePontos ELSE 0 END) AS qtdPontosPositivosD7,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-14 days') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPositivosD14,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-28 days') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPositivosD28,
        SUM(CASE WHEN dtDia > date('2025-09-01', '-56 days') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPositivosD56,

        SUM(CASE WHEN qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegativosVida,
        SUM(CASE WHEN dtDia < date('2025-09-01', '-7 days') AND qtdePontos < 0 THEN  qtdePontos ELSE 0 END) AS qtdPontosNegativosD7,
        SUM(CASE WHEN dtDia < date('2025-09-01', '-14 days') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegativosD14,
        SUM(CASE WHEN dtDia < date('2025-09-01', '-28 days') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegativosD28,
        SUM(CASE WHEN dtDia < date('2025-09-01', '-56 days') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegativosD56
    FROM tb_transacao
    GROUP BY IdCliente
),

tb_agg_calc AS (
    SELECT 
        *,
        COALESCE(1.0 * qtdeTransacaoVida / qtdeAtivacaoVida, 0) AS QtdeTransacaoDia,
        COALESCE(1.0 * qtdeTransacaoD7 / qtdeAtivacaoD7, 0) AS QtdeTransacaoDiaD7,
        COALESCE(1.0 * qtdeTransacaoD14 / qtdeAtivacaoD14, 0) AS QtdeTransacaoDiaD14,
        COALESCE(1.0 * qtdeTransacaoD28 / qtdeAtivacaoD28, 0) AS QtdeTransacaoDiaD28,
        COALESCE(1.0 * qtdeTransacaoD56 / qtdeAtivacaoD56, 0) AS QtdeTransacaoDiaD56,

        COALESCE(1.0 * qtdeAtivacaoD28 / 28, 0) AS pctAtivacaoMau
    FROM tb_agg_transacao
),

tb_horas_dia AS (
    SELECT
        IdCliente,
        dtDia,
        24 * (MAX(julianday(DtCriacao)) - MIN(julianday(DtCriacao))) AS duracao

    FROM tb_transacao
    GROUP BY IdCliente, dtDia
),

tb_hora_cliente AS (
    SELECT
        IdCliente,
        SUM(duracao) AS qtdeHorasVida,
        SUM(CASE WHEN dtDia >= date('2025-09-01', '-7 days') THEN duracao ELSE 0 END) AS qtdeHorasD7,
        SUM(CASE WHEN dtDia >= date('2025-09-01', '-14 days') THEN duracao ELSE 0 END) AS qtdeHorasD14,
        SUM(CASE WHEN dtDia >= date('2025-09-01', '-28 days') THEN duracao ELSE 0 END) AS qtdeHorasD28,
        SUM(CASE WHEN dtDia >= date('2025-09-01', '-56 days') THEN duracao ELSE 0 END) AS qtdeHorasD56

    FROM tb_horas_dia
    GROUP BY IdCliente
),

tb_lag_dia AS (
    SELECT
        IdCliente,
        dtDia,
        LAG(dtDia) OVER (PARTITION BY IdCliente ORDER BY dtDia) AS lagDia
    FROM tb_horas_dia
),

tb_intervalo_dias AS (
    SELECT 
        IdCliente,
        AVG(julianday(dtDia) - julianday(lagDia)) AS avgIntervaloDiasVida,
        AVG(CASE WHEN dtDia >= date('2025-09-01', '-28 days') THEN julianday(dtDia) - julianday(lagDia) END) AS avgIntervaloDiasD28
    FROM tb_lag_dia
    GROUP BY IdCliente
)

SELECT 
    t1.*,
    t2.qtdeHorasVida,
    t2.qtdeHorasD7,
    t2.qtdeHorasD14,
    t2.qtdeHorasD28,
    t2.qtdeHorasD56,
    t3.avgIntervaloDiasVida,
    t3.avgIntervaloDiasD28
FROM tb_agg_calc AS t1

LEFT JOIN tb_hora_cliente AS t2
    ON t1.IdCliente = t2.IdCliente
LEFT JOIN tb_intervalo_dias AS t3
    ON t1.IdCliente = t3.IdCliente