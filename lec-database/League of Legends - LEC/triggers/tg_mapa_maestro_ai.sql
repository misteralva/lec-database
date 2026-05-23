DELIMITER $$
CREATE TRIGGER tg_mapa_maestro_ai
AFTER INSERT ON mapa
FOR EACH ROW
BEGIN
    DECLARE v_m1, v_m2 INT;
    DECLARE v_tipo VARCHAR(5);
    DECLARE v_eq1 INT;

    -- Obtiene el equipo 1 y el tipo de serie del partido
    SELECT id_historial_equipo_1, tipo_serie 
    INTO v_eq1, v_tipo 
    FROM partido 
    WHERE id_partido = NEW.id_partido;

    -- Incrementa el marcador del equipo ganador del mapa
    IF NEW.ganador = v_eq1 THEN 
        UPDATE partido SET mapas_eq1 = mapas_eq1 + 1 WHERE id_partido = NEW.id_partido;
    ELSE 
        UPDATE partido SET mapas_eq2 = mapas_eq2 + 1 WHERE id_partido = NEW.id_partido;
    END IF;

    -- Comprueba si algún equipo ya alcanzó las victorias necesarias
    -- (Bo1→1, Bo3→2, Bo5→3) y cierra la serie automáticamente
    SELECT mapas_eq1, mapas_eq2 INTO v_m1, v_m2 
    FROM partido 
    WHERE id_partido = NEW.id_partido;

    IF fn_serie_terminada(v_m1, v_m2, v_tipo) THEN
        UPDATE partido SET finalizado = TRUE 
        WHERE id_partido = NEW.id_partido;
    END IF;
END$$
DELIMITER ;