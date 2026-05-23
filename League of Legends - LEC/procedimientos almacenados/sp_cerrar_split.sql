USE LEC;
DROP PROCEDURE IF EXISTS sp_cerrar_split;
DELIMITER $$
CREATE PROCEDURE sp_cerrar_split(
    IN  p_id_split  INT UNSIGNED,
    IN  p_fecha_fin DATE,
    OUT p_mensaje   VARCHAR(200)
)
BEGIN
    DECLARE v_ya_cerrado          DATE;
    DECLARE v_split_existe        INT DEFAULT 0;
    DECLARE v_partidos_pendientes INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*), fecha_fin INTO v_split_existe, v_ya_cerrado
    FROM split WHERE id_split = p_id_split;

    IF v_split_existe = 0 THEN
        SET p_mensaje = 'Error: el split indicado no existe.';

    ELSEIF v_ya_cerrado IS NOT NULL THEN
        SET p_mensaje = 'Error: este split ya tiene una fecha de fin asignada.';

    ELSE
        SELECT COUNT(*) INTO v_partidos_pendientes
        FROM partido p
        JOIN fase_split fs ON p.id_fase = fs.id_fase
        WHERE fs.id_split = p_id_split AND p.finalizado = FALSE;

        IF v_partidos_pendientes > 0 THEN
            SET p_mensaje = CONCAT('Error: hay ', v_partidos_pendientes, ' partido(s) sin finalizar.');

        ELSE
            START TRANSACTION;
                UPDATE split
                SET fecha_fin = p_fecha_fin
                WHERE id_split = p_id_split;

                UPDATE jugador_equipo_historial jeh
                JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
                SET jeh.fecha_fin = p_fecha_fin
                WHERE he.id_split = p_id_split AND jeh.fecha_fin IS NULL;

                UPDATE entrenador_equipo_historial eeh
                JOIN historial_equipo he ON eeh.id_historial_equipo = he.id_historial_equipo
                SET eeh.fecha_fin = p_fecha_fin
                WHERE he.id_split = p_id_split AND eeh.fecha_fin IS NULL;
            COMMIT;

            SET p_mensaje = CONCAT('Split ', p_id_split, ' cerrado. Contratos cerrados automáticamente.');

        END IF;
    END IF;

END$$
DELIMITER ;