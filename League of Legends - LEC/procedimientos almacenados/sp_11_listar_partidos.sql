DROP PROCEDURE IF EXISTS sp_listar_partidos;

DELIMITER $$
CREATE PROCEDURE sp_listar_partidos(
    IN p_id_split INT UNSIGNED,
    IN p_finalizado BOOLEAN,
    IN p_año YEAR,
    IN p_split_nombre VARCHAR(10)  
)
BEGIN
    SELECT
        p.id_partido,
        eq1.nombre AS equipo_1,
        eq2.nombre AS equipo_2,
        p.mapas_eq1,
        p.mapas_eq2,
        p.tipo_serie,
        p.fecha_hora,
        p.finalizado,
        fs.tipo AS fase,
        s.nombre AS split,
        s.año AS año,
        s.id_split AS id_split,
        he1.id_equipo AS id_equipo_1,
        he2.id_equipo AS id_equipo_2,
        CASE
            WHEN p.finalizado = TRUE AND p.mapas_eq1 > p.mapas_eq2 THEN eq1.nombre
            WHEN p.finalizado = TRUE AND p.mapas_eq2 > p.mapas_eq1 THEN eq2.nombre
            ELSE NULL
        END AS ganador

    FROM partido p
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split

    WHERE
        (p_id_split IS NULL OR s.id_split = p_id_split)
        AND (p_finalizado IS NULL OR p.finalizado = p_finalizado)
        AND (p_año IS NULL OR s.año = p_año)
        AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)

    ORDER BY p.fecha_hora DESC;
END$$
DELIMITER ;