USE LEC;

DROP PROCEDURE IF EXISTS sp_buscar_jugador;

DELIMITER $$
CREATE PROCEDURE sp_buscar_jugador(
    IN p_nickname       VARCHAR(30),   
    IN p_nacionalidad   VARCHAR(50),    
    IN p_rol            VARCHAR(10)     
)
BEGIN
    SELECT
        j.id_jugador,
        j.nickname,
        j.nombre_real,
        j.nacionalidad,
        j.rol_principal,
        j.activo,
        TIMESTAMPDIFF(YEAR, j.fecha_nacimiento, CURDATE()) AS edad,
   
        (SELECT e.nombre FROM jugador_equipo_historial jeh
         JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
         JOIN equipo e ON he.id_equipo = e.id_equipo
         WHERE jeh.id_jugador = j.id_jugador AND jeh.fecha_fin IS NULL
         LIMIT 1)                                           AS equipo_actual,
 
        (SELECT CONCAT(CASE s.nombre WHEN 'Winter' THEN 'LEC Versus' ELSE s.nombre END, ' ', s.año)
         FROM jugador_equipo_historial jeh
         JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
         JOIN split s ON he.id_split = s.id_split
         WHERE jeh.id_jugador = j.id_jugador AND jeh.fecha_fin IS NULL
         LIMIT 1)                                           AS split_actual

    FROM jugador j
    WHERE (p_nickname     IS NULL OR j.nickname LIKE CONCAT('%', p_nickname, '%'))
      AND (p_nacionalidad IS NULL OR j.nacionalidad = p_nacionalidad)
      AND (p_rol          IS NULL OR j.rol_principal = p_rol)
    ORDER BY j.nickname ASC;
END$$
DELIMITER ;

