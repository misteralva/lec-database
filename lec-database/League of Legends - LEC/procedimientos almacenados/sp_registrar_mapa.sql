USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_mapa;
DELIMITER $$
CREATE PROCEDURE sp_registrar_mapa(
    IN  p_id_partido  INT,
    IN  p_numero_mapa INT,
    IN  p_duracion    INT,
    IN  p_ganador     INT,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_finalizado BOOLEAN;
    DECLARE v_eq1        INT;
    DECLARE v_eq2        INT;
    DECLARE v_mapa_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT finalizado, id_historial_equipo_1, id_historial_equipo_2
    INTO v_finalizado, v_eq1, v_eq2
    FROM partido WHERE id_partido = p_id_partido;

    IF v_finalizado IS NULL THEN
        SET p_mensaje = 'Error: el partido indicado no existe.';

    ELSEIF v_finalizado = TRUE THEN
        SET p_mensaje = 'Error: el partido ya está finalizado.';

    ELSEIF p_numero_mapa < 1 OR p_numero_mapa > 5 THEN
        SET p_mensaje = 'Error: el número de mapa debe estar entre 1 y 5.';

    ELSEIF p_ganador <> v_eq1 AND p_ganador <> v_eq2 THEN
        SET p_mensaje = 'Error: el equipo ganador no participa en este partido.';

    ELSE
        SELECT COUNT(*) INTO v_mapa_existe
        FROM mapa
        WHERE id_partido = p_id_partido AND numero_mapa = p_numero_mapa;

        IF v_mapa_existe > 0 THEN
            SET p_mensaje = 'Error: ya existe ese mapa en este partido.';

        ELSE
            START TRANSACTION;
                INSERT INTO mapa (id_partido, numero_mapa, duracion_minutos, ganador)
                VALUES (p_id_partido, p_numero_mapa, p_duracion, p_ganador);
            COMMIT;

            SET p_mensaje = CONCAT('Mapa ', p_numero_mapa, ' registrado correctamente.');

        END IF;
    END IF;

END$$
DELIMITER ;