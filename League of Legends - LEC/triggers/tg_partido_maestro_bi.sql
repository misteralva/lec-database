DELIMITER $$
CREATE TRIGGER tg_partido_maestro_bi
BEFORE INSERT ON partido
FOR EACH ROW
BEGIN
    -- Valida que el partido sea consistente en tres aspectos:
    -- 1. Ambos equipos pertenecen al mismo split.
    -- 2. La fase del partido pertenece al mismo split que los equipos.
    -- 3. Los dos equipos son distintos (no puede jugar un equipo contra sí mismo).
    IF  fn_get_split_de_historial(NEW.id_historial_equipo_1)
     <> fn_get_split_de_historial(NEW.id_historial_equipo_2)
    OR  fn_get_split_de_historial(NEW.id_historial_equipo_1)
     <> fn_get_split_de_fase(NEW.id_fase)
    OR  NEW.id_historial_equipo_1 = NEW.id_historial_equipo_2
    THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Inconsistencia en equipos, split o fase.';
    END IF;
END$$
DELIMITER ;