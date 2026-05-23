DELIMITER $$
CREATE TRIGGER tg_jugador_historial_maestro_bi
BEFORE INSERT ON jugador_equipo_historial
FOR EACH ROW
BEGIN
    -- Impide fichar a un jugador si ya tiene contrato activo
    -- (fecha_fin IS NULL) o si ya está asignado a otro equipo
    -- en el mismo split.
    IF EXISTS (
        SELECT 1 
        FROM jugador_equipo_historial jeh 
        JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo 
        WHERE jeh.id_jugador = NEW.id_jugador 
          AND (he.id_split = fn_get_split_de_historial(NEW.id_historial_equipo)
          OR jeh.fecha_fin IS NULL)
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Jugador ya tiene un contrato activo o equipo en este split.';
    END IF;

    -- Impide asignar dos titulares al mismo rol dentro del mismo
    -- historial de equipo.
    IF NEW.es_titular = TRUE AND EXISTS (
        SELECT 1 
        FROM jugador_equipo_historial 
        WHERE id_historial_equipo = NEW.id_historial_equipo 
          AND rol = NEW.rol 
          AND es_titular = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Ya existe un titular para este rol.';
    END IF;
END$$

CREATE TRIGGER tg_jugador_historial_maestro_bu
BEFORE UPDATE ON jugador_equipo_historial
FOR EACH ROW
BEGIN
    -- Bloquea traspasos (asignar fecha_fin) mientras el split
    -- del equipo sigue activo, siguiendo la regla oficial LEC.
    -- Si el bloqueo no aplica y se pone fecha_fin, automáticamente
    -- se quita la titularidad al jugador.
    IF NEW.fecha_fin IS NOT NULL AND OLD.fecha_fin IS NULL THEN
        IF fn_split_en_curso(
            fn_get_split_de_historial(OLD.id_historial_equipo)
        ) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'LEC Rule: Prohibido traspasos durante el Split.';
        END IF;
        SET NEW.es_titular = FALSE;
    END IF;
END$$
DELIMITER ;