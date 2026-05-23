DELIMITER $$
CREATE FUNCTION fn_get_split_de_historial(p_id_historial INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
COMMENT 'Devuelve el id_split de un registro historial_equipo'
BEGIN
    DECLARE v_id_split INT UNSIGNED;

    SELECT id_split INTO v_id_split
    FROM historial_equipo
    WHERE id_historial_equipo = p_id_historial;

    RETURN v_id_split;
END$$
DELIMITER ;