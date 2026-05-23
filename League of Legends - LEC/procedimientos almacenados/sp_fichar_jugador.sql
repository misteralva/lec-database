USE LEC;
DROP PROCEDURE IF EXISTS sp_fichar_jugador;
DELIMITER $$
CREATE PROCEDURE sp_fichar_jugador(
    IN  p_nickname     VARCHAR(30),
    IN  p_nombre_real  VARCHAR(100),
    IN  p_nacionalidad VARCHAR(50),
    IN  p_fecha_nac    DATE,
    IN  p_rol          ENUM('Top','Jungle','Mid','ADC','Support'),
    IN  p_id_historial INT,
    IN  p_es_titular   BOOLEAN,
    IN  p_fecha_inicio DATE,
    OUT p_id_jugador   INT UNSIGNED,
    OUT p_mensaje      VARCHAR(200)
)
BEGIN
    DECLARE v_historial_existe INT DEFAULT 0;
    DECLARE v_id_split         INT;
    DECLARE v_contrato_activo  INT DEFAULT 0;
    DECLARE v_titular_existe   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_jugador = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_historial_existe
    FROM historial_equipo
    WHERE id_historial_equipo = p_id_historial;

    IF v_historial_existe = 0 THEN
        SET p_mensaje = 'Error: el historial de equipo indicado no existe.';

    ELSE
        SET v_id_split = fn_get_split_de_historial(p_id_historial);

        SELECT id_jugador INTO p_id_jugador
        FROM jugador
        WHERE nickname = p_nickname LIMIT 1;

        IF p_id_jugador IS NOT NULL THEN
            SELECT COUNT(*) INTO v_contrato_activo
            FROM jugador_equipo_historial jeh
            JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
            WHERE jeh.id_jugador = p_id_jugador
              AND (he.id_split = v_id_split OR jeh.fecha_fin IS NULL);
        END IF;

        IF v_contrato_activo > 0 THEN
            SET p_mensaje = 'Error: el jugador ya tiene contrato activo en este split.';

        ELSE
            IF p_es_titular = TRUE THEN
                SELECT COUNT(*) INTO v_titular_existe
                FROM jugador_equipo_historial
                WHERE id_historial_equipo = p_id_historial
                  AND rol = p_rol
                  AND es_titular = TRUE;
            END IF;

            IF v_titular_existe > 0 THEN
                SET p_mensaje = 'Error: ya existe un titular en ese rol para este equipo.';

            ELSE
                START TRANSACTION;
                    IF p_id_jugador IS NULL THEN
                        INSERT INTO jugador (nickname, nombre_real, nacionalidad,
                                             fecha_nacimiento, rol_principal, activo)
                        VALUES (p_nickname, p_nombre_real, p_nacionalidad,
                                p_fecha_nac, p_rol, TRUE);
                        SET p_id_jugador = LAST_INSERT_ID();
                    END IF;

                    INSERT INTO jugador_equipo_historial
                        (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin)
                    VALUES
                        (p_id_historial, p_id_jugador, p_rol, p_es_titular, p_fecha_inicio, NULL);
                COMMIT;

                SET p_mensaje = CONCAT('Jugador ', p_nickname, ' fichado con ID: ', p_id_jugador);

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;