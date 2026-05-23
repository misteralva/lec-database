USE LEC;
DROP PROCEDURE IF EXISTS sp_transferir_jugador;
DELIMITER $$
CREATE PROCEDURE sp_transferir_jugador(
    IN  p_id_jugador         INT,
    IN  p_id_historial_nuevo INT,
    IN  p_fecha_fin          DATE,
    IN  p_fecha_inicio_nuevo DATE,
    IN  p_rol                ENUM('Top','Jungle','Mid','ADC','Support'),
    IN  p_es_titular         BOOLEAN,
    OUT p_mensaje            VARCHAR(200)
)
BEGIN
    DECLARE v_id_historial_actual INT;
    DECLARE v_id_split_actual     INT;
    DECLARE v_split_en_curso      BOOLEAN DEFAULT FALSE;
    DECLARE v_titular_existe      INT DEFAULT 0;
    DECLARE v_destino_existe      INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT id_historial_equipo INTO v_id_historial_actual
    FROM jugador_equipo_historial
    WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL LIMIT 1;

    IF v_id_historial_actual IS NULL THEN
        SET p_mensaje = 'Error: el jugador no tiene ningún contrato activo.';

    ELSE
        SET v_id_split_actual = fn_get_split_de_historial(v_id_historial_actual);
        SET v_split_en_curso  = fn_split_en_curso(v_id_split_actual);

        IF v_split_en_curso = TRUE THEN
            SET p_mensaje = 'Error: no se pueden hacer transferencias durante el split (regla LEC).';

        ELSE
            SELECT COUNT(*) INTO v_destino_existe
            FROM historial_equipo
            WHERE id_historial_equipo = p_id_historial_nuevo;

            IF v_destino_existe = 0 THEN
                SET p_mensaje = 'Error: el equipo destino no existe en este split.';

            ELSE
                IF p_es_titular = TRUE THEN
                    SELECT COUNT(*) INTO v_titular_existe
                    FROM jugador_equipo_historial
                    WHERE id_historial_equipo = p_id_historial_nuevo
                      AND rol = p_rol
                      AND es_titular = TRUE;
                END IF;

                IF v_titular_existe > 0 THEN
                    SET p_mensaje = 'Error: ya existe un titular en ese rol en el equipo destino.';

                ELSE
                    START TRANSACTION;
                        UPDATE jugador_equipo_historial
                        SET fecha_fin = p_fecha_fin
                        WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;

                        INSERT INTO jugador_equipo_historial
                            (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin)
                        VALUES
                            (p_id_historial_nuevo, p_id_jugador, p_rol, p_es_titular, p_fecha_inicio_nuevo, NULL);
                    COMMIT;

                    SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' transferido correctamente.');

                END IF;
            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;