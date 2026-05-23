USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_jugadores_equipo;

DELIMITER $$
CREATE PROCEDURE sp_listar_jugadores_equipo(
    IN p_id_equipo INT,
    IN p_id_split INT,  
    IN p_año YEAR,       
    IN p_split_nombre VARCHAR(10)   
)
BEGIN
    SELECT
        j.id_jugador,
        j.nickname,
        j.nombre_real,
        j.nacionalidad,
        j.fecha_nacimiento,
        jeh.rol,
        jeh.es_titular,
        jeh.fecha_inicio,
        jeh.fecha_fin,
        TIMESTAMPDIFF(YEAR, j.fecha_nacimiento, CURDATE()) AS edad

    FROM jugador j
    JOIN jugador_equipo_historial jeh ON j.id_jugador = jeh.id_jugador
    JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
    JOIN split s ON he.id_split = s.id_split

    WHERE he.id_equipo = p_id_equipo
      AND j.activo = TRUE
      AND (
  
          (p_id_split IS NULL AND p_año IS NULL AND p_split_nombre IS NULL
           AND jeh.fecha_fin IS NULL)
          OR

          (
              (p_id_split IS NULL OR he.id_split = p_id_split)
              AND (p_año IS NULL OR s.año = p_año)
              AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
              AND (p_id_split IS NOT NULL OR p_año IS NOT NULL OR p_split_nombre IS NOT NULL)
          )
      )

    ORDER BY
        jeh.es_titular DESC,
        FIELD(jeh.rol, 'Top', 'Jungle', 'Mid', 'ADC', 'Support'),
        j.nickname ASC;
END$$
DELIMITER ;
