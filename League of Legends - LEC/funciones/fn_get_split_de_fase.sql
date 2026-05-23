DELIMITER $$
CREATE FUNCTION fn_get_split_de_fase(p_id_fase INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
COMMENT 'Devuelve el id_split asociado a una fase'
BEGIN
    DECLARE v_id_split INT UNSIGNED;

    SELECT id_split INTO v_id_split
    FROM fase_split
    WHERE id_fase = p_id_fase;

    RETURN v_id_split;
END$$
DELIMITER ;