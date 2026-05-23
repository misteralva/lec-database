USE LEC;

DROP TRIGGER IF EXISTS tg_entrenador_maestro_bi;

DELIMITER $$
CREATE TRIGGER tg_entrenador_maestro_bi
BEFORE INSERT ON entrenador_equipo_historial
FOR EACH ROW
BEGIN

    DECLARE v_id_split          INT UNSIGNED;
    DECLARE v_contrato_activo   INT DEFAULT 0;
    DECLARE v_entrenador_existe INT DEFAULT 0;

    -- Obtener el split al que pertenece este historial de equipo
    SET v_id_split = fn_get_split_de_historial(NEW.id_historial_equipo);

    -- 1. Comprobar que el entrenador no tiene ya contrato activo
    --    en el mismo split (no puede estar en dos equipos a la vez)
    SELECT COUNT(*) INTO v_contrato_activo
    FROM entrenador_equipo_historial eeh
    JOIN historial_equipo he ON eeh.id_historial_equipo = he.id_historial_equipo
    WHERE eeh.id_entrenador = NEW.id_entrenador
      AND he.id_split = v_id_split
      AND eeh.fecha_fin IS NULL;

    IF v_contrato_activo > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: el entrenador ya tiene un contrato activo en este split.';
    END IF;

    -- 2. Comprobar que el equipo no tiene ya un entrenador activo
    --    en este historial (un equipo solo tiene un entrenador principal)
    SELECT COUNT(*) INTO v_entrenador_existe
    FROM entrenador_equipo_historial
    WHERE id_historial_equipo = NEW.id_historial_equipo
      AND fecha_fin IS NULL;

    IF v_entrenador_existe > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: este equipo ya tiene un entrenador activo en este split.';
    END IF;

END$$
DELIMITER ;