DELIMITER $$
CREATE FUNCTION fn_ganador_partido(p_id_partido INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
COMMENT 'Devuelve el id_historial_equipo ganador, o NULL si no ha terminado'
BEGIN
    DECLARE v_eq1   INT UNSIGNED;
    DECLARE v_eq2   INT UNSIGNED;
    DECLARE v_m1    TINYINT UNSIGNED;
    DECLARE v_m2    TINYINT UNSIGNED;
    DECLARE v_tipo  VARCHAR(5);
    DECLARE v_final BOOLEAN;

    SELECT id_historial_equipo_1,
           id_historial_equipo_2,
           mapas_eq1,
           mapas_eq2,
           tipo_serie,
           finalizado
    INTO   v_eq1, v_eq2, v_m1, v_m2, v_tipo, v_final
    FROM   partido
    WHERE  id_partido = p_id_partido;

    IF NOT v_final OR NOT fn_serie_terminada(v_m1, v_m2, v_tipo) THEN
        RETURN NULL;
    END IF;
    
    RETURN IF(v_m1 > v_m2, v_eq1, v_eq2);
END$$
DELIMITER ;