USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_clasificacion;

DELIMITER $$
CREATE PROCEDURE sp_listar_clasificacion(IN p_año YEAR)
BEGIN
    SELECT
        e.id_equipo,
        e.nombre                                AS equipo,
        e.pais,
        COALESCE(ca.puntos_totales, 0)          AS puntos_totales,
        ca.seed_worlds,
        (SELECT he.puntos_campeonato FROM historial_equipo he
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo AND s.nombre = 'Spring' AND s.año = p_año
         LIMIT 1)                               AS puntos_spring,
        (SELECT he.puntos_campeonato FROM historial_equipo he
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo AND s.nombre = 'Summer' AND s.año = p_año
         LIMIT 1)                               AS puntos_summer,
        EXISTS (SELECT 1 FROM historial_equipo he
                JOIN split s ON he.id_split = s.id_split
                WHERE he.id_equipo = e.id_equipo AND s.nombre = 'Winter' AND s.año = p_año
               )                               AS jugo_versus,
        (SELECT he.clasificado_msi FROM historial_equipo he
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo AND s.nombre = 'Spring' AND s.año = p_año
         LIMIT 1)                               AS clasificado_msi,
        (SELECT he.posicion_playoffs FROM historial_equipo he
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo AND s.nombre = 'Summer' AND s.año = p_año
         LIMIT 1)                               AS posicion_summer

    FROM equipo e
    LEFT JOIN clasificacion_anual ca
        ON ca.id_equipo = e.id_equipo AND ca.año = p_año

    WHERE EXISTS (
        SELECT 1 FROM historial_equipo he
        JOIN split s ON he.id_split = s.id_split
        WHERE he.id_equipo = e.id_equipo AND s.año = p_año
    )
    ORDER BY
        COALESCE(ca.puntos_totales, 0) DESC,
        posicion_summer ASC;
END$$
DELIMITER ;

