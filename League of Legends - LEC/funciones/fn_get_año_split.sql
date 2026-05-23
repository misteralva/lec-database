DELIMITER $$
CREATE FUNCTION fn_get_año_split(p_id_split INT UNSIGNED)
RETURNS INT
READS SQL DATA
NOT DETERMINISTIC
COMMENT 'Devuelve el año de un split dado su id'
BEGIN
    DECLARE v_año INT;
 
    SELECT año INTO v_año
    FROM split
    WHERE id_split = p_id_split;
 
    RETURN IFNULL(v_año, 0);
END$$
DELIMITER ;