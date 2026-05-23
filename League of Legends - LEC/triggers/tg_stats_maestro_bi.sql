DELIMITER $$
CREATE TRIGGER tg_stats_maestro_bi
BEFORE INSERT ON estadistica_jugador
FOR EACH ROW
BEGIN
    -- Impide insertar estadísticas de un jugador que no pertenece
    -- a ninguno de los dos equipos que disputan el partido.
    IF NOT fn_jugador_en_partido(NEW.id_jugador, NEW.id_partido)
    THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El jugador no pertenece a este partido.';
    END IF;
END$$
DELIMITER ;