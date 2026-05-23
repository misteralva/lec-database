USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_equipos;

DELIMITER $$
CREATE PROCEDURE sp_listar_equipos(
    IN p_id_split       INT UNSIGNED,
    IN p_año            YEAR,
    IN p_split_nombre   VARCHAR(10)
)
BEGIN
    SELECT
        e.id_equipo,
        e.nombre,
        e.pais,
        e.fundacion,
        e.activo,
        (SELECT COUNT(*)
         FROM jugador_equipo_historial jeh
         JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo
           AND jeh.es_titular = TRUE
           AND jeh.fecha_fin IS NULL
           AND (p_id_split     IS NULL OR he.id_split = p_id_split)
           AND (p_año          IS NULL OR s.año = p_año)
           AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
        ) AS titulares,
        (SELECT he.id_historial_equipo
         FROM historial_equipo he
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo
           AND (p_id_split     IS NULL OR he.id_split = p_id_split)
           AND (p_año          IS NULL OR s.año = p_año)
           AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
         ORDER BY he.id_historial_equipo DESC
         LIMIT 1
        ) AS id_historial

    FROM equipo e
    WHERE e.activo = TRUE
      AND EXISTS (
          SELECT 1 FROM historial_equipo he
          JOIN split s ON he.id_split = s.id_split
          WHERE he.id_equipo = e.id_equipo
            AND (p_id_split     IS NULL OR he.id_split = p_id_split)
            AND (p_año          IS NULL OR s.año = p_año)
            AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
      )
    ORDER BY e.nombre ASC;
END$$
DELIMITER ;
