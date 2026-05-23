USE LEC;

DROP PROCEDURE IF EXISTS sp_asignar_clasificacion_internacional;

DELIMITER $$
CREATE PROCEDURE sp_asignar_clasificacion_internacional(
    IN  p_año       YEAR,
    OUT p_mensaje   VARCHAR(200)
)
sp_asignar_clasificacion_internacional: BEGIN

    DECLARE v_id_spring         INT UNSIGNED;
    DECLARE v_id_summer         INT UNSIGNED;
    DECLARE v_campeon_spring    INT UNSIGNED;
    DECLARE v_subcampeon_spring INT UNSIGNED;
    DECLARE v_campeon_summer    INT UNSIGNED;
    DECLARE v_hist_verano       INT UNSIGNED;
    DECLARE v_seed2             INT UNSIGNED;
    DECLARE v_seed3             INT UNSIGNED;
    DECLARE v_registros         INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_registros FROM clasificacion_anual WHERE año = p_año;
    IF v_registros = 0 THEN
        SET p_mensaje = 'Error: no hay registros para ese año.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT id_split INTO v_id_spring FROM split
    WHERE nombre = 'Spring' AND año = p_año LIMIT 1;
    IF v_id_spring IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el Spring Split.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT he.id_equipo INTO v_campeon_spring FROM historial_equipo he
    WHERE he.id_split = v_id_spring AND he.posicion_playoffs = 1 LIMIT 1;
    IF v_campeon_spring IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el campeón del Spring.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT he.id_equipo INTO v_subcampeon_spring FROM historial_equipo he
    WHERE he.id_split = v_id_spring AND he.posicion_playoffs = 2 LIMIT 1;
    IF v_subcampeon_spring IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el subcampeón del Spring.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT id_split INTO v_id_summer FROM split
    WHERE nombre = 'Summer' AND año = p_año LIMIT 1;
    IF v_id_summer IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el Summer Split.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT he.id_equipo, he.id_historial_equipo
    INTO v_campeon_summer, v_hist_verano
    FROM historial_equipo he
    WHERE he.id_split = v_id_summer AND he.posicion_playoffs = 1 LIMIT 1;
    IF v_campeon_summer IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el campeón del Summer.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT id_equipo INTO v_seed2 FROM clasificacion_anual
    WHERE año = p_año AND id_equipo <> v_campeon_summer
    ORDER BY puntos_totales DESC LIMIT 1;

    SELECT id_equipo INTO v_seed3 FROM clasificacion_anual
    WHERE año = p_año AND id_equipo <> v_campeon_summer AND id_equipo <> v_seed2
    ORDER BY puntos_totales DESC LIMIT 1;

    IF v_seed2 IS NULL OR v_seed3 IS NULL THEN
        SET p_mensaje = 'Error: empate sin desempate claro, requiere intervención manual.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    START TRANSACTION;
        UPDATE historial_equipo SET clasificado_msi = TRUE
        WHERE id_split = v_id_spring
          AND id_equipo IN (v_campeon_spring, v_subcampeon_spring);

        UPDATE historial_equipo SET seed_worlds = 1
        WHERE id_historial_equipo = v_hist_verano;

        UPDATE clasificacion_anual SET seed_worlds = 1
        WHERE año = p_año AND id_equipo = v_campeon_summer;

        UPDATE clasificacion_anual SET seed_worlds = 2
        WHERE año = p_año AND id_equipo = v_seed2;

        UPDATE clasificacion_anual SET seed_worlds = 3
        WHERE año = p_año AND id_equipo = v_seed3;
    COMMIT;

    SET p_mensaje = CONCAT('Clasificación del año ', p_año, ' asignada correctamente.');
END$$
DELIMITER ;