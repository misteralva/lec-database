USE LEC;
DROP PROCEDURE IF EXISTS sp_actualizar_resultado;
DELIMITER $$
CREATE PROCEDURE sp_actualizar_resultado(
    IN  p_id_partido    INT UNSIGNED,
    IN  p_mapas_eq1     TINYINT UNSIGNED,
    IN  p_mapas_eq2     TINYINT UNSIGNED,
    OUT p_mensaje       VARCHAR(200)
)
sp_actualizar_resultado: BEGIN
    DECLARE v_tipo_serie    VARCHAR(5);
    DECLARE v_id_split      INT UNSIGNED;
    DECLARE v_split_cerrado DATE;
    DECLARE v_finalizado    BOOLEAN;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT p.tipo_serie, p.finalizado, s.fecha_fin, s.id_split
    INTO v_tipo_serie, v_finalizado, v_split_cerrado, v_id_split
    FROM partido p
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split
    WHERE p.id_partido = p_id_partido;

    IF v_tipo_serie IS NULL THEN
        SET p_mensaje = 'Error: el partido indicado no existe.';
        LEAVE sp_actualizar_resultado;
    END IF;

    IF v_split_cerrado IS NOT NULL THEN
        SET p_mensaje = 'Error: no se puede modificar un partido de una temporada cerrada.';
        LEAVE sp_actualizar_resultado;
    END IF;

    -- ↓ Cambiado p_tipo_serie por v_tipo_serie en los tres IF
    IF v_tipo_serie = 'Bo1' AND (p_mapas_eq1 > 1 OR p_mapas_eq2 > 1) THEN
        SET p_mensaje = 'Error: en un Bo1 el máximo de mapas por equipo es 1.';
        LEAVE sp_actualizar_resultado;
    END IF;

    IF v_tipo_serie = 'Bo3' AND (p_mapas_eq1 > 2 OR p_mapas_eq2 > 2) THEN
        SET p_mensaje = 'Error: en un Bo3 el máximo de mapas por equipo es 2.';
        LEAVE sp_actualizar_resultado;
    END IF;

    IF v_tipo_serie = 'Bo5' AND (p_mapas_eq1 > 3 OR p_mapas_eq2 > 3) THEN
        SET p_mensaje = 'Error: en un Bo5 el máximo de mapas por equipo es 3.';
        LEAVE sp_actualizar_resultado;
    END IF;

    START TRANSACTION;
        UPDATE partido
        SET mapas_eq1  = p_mapas_eq1,
            mapas_eq2  = p_mapas_eq2,
            finalizado = fn_serie_terminada(p_mapas_eq1, p_mapas_eq2, v_tipo_serie)
        WHERE id_partido = p_id_partido;
    COMMIT;

    SET p_mensaje = CONCAT('Resultado del partido ', p_id_partido, ' actualizado correctamente.');

END$$
DELIMITER ;