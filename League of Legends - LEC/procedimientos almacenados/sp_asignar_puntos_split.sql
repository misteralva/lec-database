USE LEC;
DROP PROCEDURE IF EXISTS sp_asignar_puntos_split;
DELIMITER $$
CREATE PROCEDURE sp_asignar_puntos_split(
    IN  p_id_historial INT,
    IN  p_posicion     INT,
    IN  p_tipo_split   VARCHAR(10),
    OUT p_puntos       SMALLINT,
    OUT p_mensaje      VARCHAR(200)
)
BEGIN
    DECLARE v_historial_existe INT DEFAULT 0;
    DECLARE v_cp               INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_historial_existe
    FROM historial_equipo
    WHERE id_historial_equipo = p_id_historial;

    IF v_historial_existe = 0 THEN
        SET p_mensaje = 'Error: el historial indicado no existe.';

    ELSEIF p_tipo_split NOT IN ('Spring', 'Summer') THEN
        SET p_mensaje = 'Error: el tipo de split debe ser Spring o Summer.';

    ELSEIF p_posicion < 1 OR p_posicion > 10 THEN
        SET p_mensaje = 'Error: la posición debe estar entre 1 y 10.';

    ELSE
        SET v_cp = CASE p_tipo_split
            WHEN 'Spring' THEN CASE p_posicion
                WHEN 1 THEN 145 WHEN 2 THEN 120 WHEN 3 THEN 95 WHEN 4 THEN 70
                WHEN 5 THEN 55  WHEN 6 THEN 55  WHEN 7 THEN 35 WHEN 8 THEN 35 ELSE 0
            END
            WHEN 'Summer' THEN CASE p_posicion
                WHEN 1 THEN 180 WHEN 2 THEN 150 WHEN 3 THEN 120 WHEN 4 THEN 90
                WHEN 5 THEN 65  WHEN 6 THEN 65  WHEN 7 THEN 45  WHEN 8 THEN 45 ELSE 0
            END
        END;

        START TRANSACTION;
            UPDATE historial_equipo
            SET posicion_fase_regular = p_posicion,
                puntos_campeonato     = v_cp
            WHERE id_historial_equipo = p_id_historial;
        COMMIT;

        SET p_puntos  = v_cp;
        SET p_mensaje = CONCAT('Se han asignado ', v_cp, ' Championship Points.');

    END IF;

END$$
DELIMITER ;