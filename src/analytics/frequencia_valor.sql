SELECT 
    IdCliente,
    COUNT(DISTINCT substr(DtCriacao, 0, 11)) AS qtdeFreqeuencia,
    sum(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS qtdePontos,
    sum(ABS(QtdePontos)) AS qtdePontosAbs
FROM transacoes

WHERE dtCriacao < '2025-09-01'
AND DtCriacao >= date('2025-09-01', '-28 day')

GROUP BY 1

ORDER BY qtdeFreqeuencia DESC