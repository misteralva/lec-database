USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_equipo_split;
DELIMITER $$
CREATE PROCEDURE sp_registrar_equipo_split(
    IN  p_id_equipo    INT,
    IN  p_id_split     INT,
    OUT p_id_historial INT,
    OUT p_mensaje      VARCHAR(200)
)
BEGIN
    DECLARE v_equipo_activo BOOLEAN;
    DECLARE v_split_existe  INT DEFAULT 0;
    DECLARE v_ya_registrado INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_historial = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT activo INTO v_equipo_activo
    FROM equipo WHERE id_equipo = p_id_equipo;

    IF v_equipo_activo IS NULL THEN
        SET p_mensaje = 'Error: el equipo indicado no existe.';

    ELSEIF v_equipo_activo = FALSE THEN
        SET p_mensaje = 'Error: el equipo no está activo.';

    ELSE
        SELECT COUNT(*) INTO v_split_existe
        FROM split WHERE id_split = p_id_split;

        IF v_split_existe = 0 THEN
            SET p_mensaje = 'Error: el split indicado no existe.';

        ELSE
            SELECT COUNT(*) INTO v_ya_registrado
            FROM historial_equipo
            WHERE id_equipo = p_id_equipo AND id_split = p_id_split;

            IF v_ya_registrado > 0 THEN
                SET p_mensaje = 'Error: este equipo ya está registrado en ese split.';

            ELSE
                START TRANSACTION;
                    INSERT INTO historial_equipo
                        (id_equipo, id_split, puntos_campeonato, clasificado_msi)
                    VALUES
                        (p_id_equipo, p_id_split, 0, FALSE);
                    SET p_id_historial = LAST_INSERT_ID();
                COMMIT;

                SET p_mensaje = CONCAT('Equipo registrado. Historial ID: ', p_id_historial);

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;