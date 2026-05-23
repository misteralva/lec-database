USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_splits;

DELIMITER $$
CREATE PROCEDURE sp_listar_splits(
    IN p_solo_abiertos BOOLEAN  
)
BEGIN
    SELECT
        id_split,
        nombre,
        año,
        fecha_inicio,
        fecha_fin,
        fecha_fin IS NULL AS esta_abierto,
        
        CASE nombre
            WHEN 'Winter' THEN 'LEC Versus'
            ELSE nombre
        END AS nombre_display,
        CONCAT(
            CASE nombre WHEN 'Winter' THEN 'LEC Versus' ELSE nombre END,
            ' ', año
        ) AS nombre_completo

    FROM split
    WHERE (p_solo_abiertos IS NULL OR p_solo_abiertos = FALSE
           OR fecha_fin IS NULL)
    ORDER BY año DESC, FIELD(nombre, 'Summer', 'Spring', 'Winter');
END$$
DELIMITER ;


