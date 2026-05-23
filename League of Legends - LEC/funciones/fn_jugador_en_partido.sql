DELIMITER $$
CREATE FUNCTION fn_jugador_en_partido(
    p_id_jugador INT UNSIGNED,
    p_id_partido INT UNSIGNED
)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
COMMENT 'TRUE si el jugador pertenece a algún equipo del partido'
BEGIN
    DECLARE v_existe BOOLEAN DEFAULT FALSE;

    SELECT TRUE INTO v_existe
    FROM jugador_equipo_historial jeh
    JOIN partido p
        ON jeh.id_historial_equipo = p.id_historial_equipo_1
        OR jeh.id_historial_equipo = p.id_historial_equipo_2
    WHERE p.id_partido   = p_id_partido
      AND jeh.id_jugador = p_id_jugador
    LIMIT 1;

    RETURN IFNULL(v_existe, FALSE);
END$$
DELIMITER ;