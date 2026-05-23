DELIMITER $$
CREATE FUNCTION fn_split_en_curso(p_id_split INT UNSIGNED)
RETURNS BOOLEAN
READS SQL DATA
NOT DETERMINISTIC
COMMENT 'TRUE si el split está activo a fecha de hoy'
BEGIN
    DECLARE v_resultado BOOLEAN DEFAULT FALSE;

    SELECT TRUE INTO v_resultado
    FROM split
    WHERE id_split = p_id_split
      AND CURDATE() BETWEEN fecha_inicio AND IFNULL(fecha_fin, '9999-12-31')
    LIMIT 1;

    RETURN IFNULL(v_resultado, FALSE);
END$$
DELIMITER ;