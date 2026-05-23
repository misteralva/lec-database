USE LEC;
DROP PROCEDURE IF EXISTS sp_insertar_equipo;
DELIMITER $$
CREATE PROCEDURE sp_insertar_equipo(
    IN  p_nombre        VARCHAR(50),
    IN  p_pais          VARCHAR(50),
    IN  p_fundacion     DATE,
    IN  p_año           YEAR,
    IN  p_split_nombre  VARCHAR(10),
    OUT p_id_equipo     INT UNSIGNED,
    OUT p_mensaje       VARCHAR(200)
)
BEGIN
    DECLARE v_nombre_existe INT DEFAULT 0;
    DECLARE v_id_split      INT UNSIGNED;
    DECLARE v_msg_split     VARCHAR(200);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_equipo = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_mensaje = 'Error: el nombre del equipo no puede estar vacío.';

    ELSE
        SELECT COUNT(*) INTO v_nombre_existe
        FROM equipo WHERE nombre = p_nombre;

        IF v_nombre_existe > 0 THEN
            SET p_mensaje = CONCAT('Error: ya existe un equipo con el nombre "', p_nombre, '".');

        ELSE
            IF p_año IS NOT NULL AND p_split_nombre IS NOT NULL THEN
                SELECT id_split INTO v_id_split
                FROM split
                WHERE año = p_año AND nombre = p_split_nombre
                LIMIT 1;
            END IF;

            IF p_año IS NOT NULL AND p_split_nombre IS NOT NULL AND v_id_split IS NULL THEN
                SET p_mensaje = CONCAT('Error: no existe el split ', p_split_nombre, ' ', p_año, '.');

            ELSE
                START TRANSACTION;
                    INSERT INTO equipo (nombre, pais, fundacion, activo)
                    VALUES (p_nombre, p_pais, p_fundacion, TRUE);
                    SET p_id_equipo = LAST_INSERT_ID();
                COMMIT;

                IF v_id_split IS NOT NULL THEN
                    CALL sp_registrar_equipo_split(p_id_equipo, v_id_split, @hist, v_msg_split);
                    SET p_mensaje = CONCAT('Equipo "', p_nombre, '" creado con ID: ', p_id_equipo, '. ', v_msg_split);
                ELSE
                    SET p_mensaje = CONCAT('Equipo "', p_nombre, '" creado con ID: ', p_id_equipo, '.');
                END IF;

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;