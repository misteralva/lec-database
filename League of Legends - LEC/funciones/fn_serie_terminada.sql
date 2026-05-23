DELIMITER $$
CREATE FUNCTION fn_serie_terminada(
    p_mapas_eq1  TINYINT UNSIGNED,
    p_mapas_eq2  TINYINT UNSIGNED,
    p_tipo_serie VARCHAR(5)
)
RETURNS BOOLEAN
NO SQL
DETERMINISTIC
COMMENT 'TRUE si la serie ya tiene un ganador según Bo1/Bo3/Bo5'
BEGIN
    DECLARE v_victorias_necesarias TINYINT;

    SET v_victorias_necesarias = CASE p_tipo_serie
        WHEN 'Bo1' THEN 1
        WHEN 'Bo3' THEN 2
        WHEN 'Bo5' THEN 3
        ELSE NULL
    END;
    
    IF v_victorias_necesarias IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN (p_mapas_eq1 >= v_victorias_necesarias
         OR p_mapas_eq2 >= v_victorias_necesarias);
END$$
DELIMITER ;