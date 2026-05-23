DELIMITER $$
CREATE TRIGGER tg_proteccion_borrado_critico
BEFORE DELETE ON historial_equipo
FOR EACH ROW
BEGIN
    -- Impide borrar un registro de historial_equipo si el equipo
    -- ya ha disputado algún partido, ya sea como equipo 1 o equipo 2.
    IF EXISTS (
        SELECT 1 
        FROM partido 
        WHERE id_historial_equipo_1 = OLD.id_historial_equipo 
           OR id_historial_equipo_2 = OLD.id_historial_equipo
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede borrar un equipo que ya ha disputado partidos.';
    END IF;
END$$
DELIMITER ;