USE LEC;

DROP PROCEDURE IF EXISTS sp_eliminar_partido;

DELIMITER $$
CREATE PROCEDURE sp_eliminar_partido(
    IN  p_id_partido    INT UNSIGNED,
    IN  p_forzar        BOOLEAN, 
    OUT p_mensaje       VARCHAR(200)
)
sp_eliminar_partido: BEGIN

    DECLARE v_existe        INT DEFAULT 0;
    DECLARE v_split_cerrado DATE;
    DECLARE v_num_mapas     INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*), s.fecha_fin
    INTO v_existe, v_split_cerrado
    FROM partido p
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split
    WHERE p.id_partido = p_id_partido;

    IF v_existe = 0 THEN
        SET p_mensaje = 'Error: el partido indicado no existe.';
        LEAVE sp_eliminar_partido;
    END IF;

    IF v_split_cerrado IS NOT NULL THEN
        SET p_mensaje = 'Error: no se puede eliminar un partido de una temporada cerrada.';
        LEAVE sp_eliminar_partido;
    END IF;


    SELECT COUNT(*) INTO v_num_mapas
    FROM mapa WHERE id_partido = p_id_partido;

    IF v_num_mapas > 0 AND p_forzar = FALSE THEN
        SET p_mensaje = CONCAT('Error: el partido tiene ', v_num_mapas, ' mapa(s) registrado(s). Usa p_forzar = TRUE para eliminar igualmente.');
        LEAVE sp_eliminar_partido;
    END IF;

    START TRANSACTION;

        DELETE FROM partido WHERE id_partido = p_id_partido;

    COMMIT;

    SET p_mensaje = CONCAT('Partido ', p_id_partido, ' eliminado correctamente.');

END$$
DELIMITER ;

