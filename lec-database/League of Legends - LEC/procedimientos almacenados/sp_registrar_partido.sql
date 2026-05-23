USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_partido;
DELIMITER $$
CREATE PROCEDURE sp_registrar_partido(
    IN  p_id_fase     INT,
    IN  p_id_hist_eq1 INT,
    IN  p_id_hist_eq2 INT,
    IN  p_fecha_hora  DATETIME,
    IN  p_tipo_serie  VARCHAR(5),
    OUT p_id_partido  INT,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_split_eq1  INT;
    DECLARE v_split_eq2  INT;
    DECLARE v_split_fase INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_partido = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    IF p_id_hist_eq1 = p_id_hist_eq2 THEN
        SET p_mensaje = 'Error: los dos equipos no pueden ser el mismo.';

    ELSEIF p_tipo_serie NOT IN ('Bo1', 'Bo3', 'Bo5') THEN
        SET p_mensaje = 'Error: el tipo de serie debe ser Bo1, Bo3 o Bo5.';

    ELSE
        SET v_split_eq1  = fn_get_split_de_historial(p_id_hist_eq1);
        SET v_split_eq2  = fn_get_split_de_historial(p_id_hist_eq2);
        SET v_split_fase = fn_get_split_de_fase(p_id_fase);

        IF v_split_eq1 IS NULL THEN
            SET p_mensaje = 'Error: el historial del equipo 1 no existe.';

        ELSEIF v_split_eq2 IS NULL THEN
            SET p_mensaje = 'Error: el historial del equipo 2 no existe.';

        ELSEIF v_split_fase IS NULL THEN
            SET p_mensaje = 'Error: la fase indicada no existe.';

        ELSEIF v_split_eq1 <> v_split_eq2 OR v_split_eq1 <> v_split_fase THEN
            SET p_mensaje = 'Error: los equipos y la fase no pertenecen al mismo split.';

        ELSE
            START TRANSACTION;
                INSERT INTO partido
                    (id_fase, id_historial_equipo_1, id_historial_equipo_2,
                     fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado)
                VALUES
                    (p_id_fase, p_id_hist_eq1, p_id_hist_eq2,
                     p_fecha_hora, p_tipo_serie, 0, 0, FALSE);
                SET p_id_partido = LAST_INSERT_ID();
            COMMIT;

            SET p_mensaje = CONCAT('Partido creado con ID: ', p_id_partido);

        END IF;
    END IF;

END$$
DELIMITER ;