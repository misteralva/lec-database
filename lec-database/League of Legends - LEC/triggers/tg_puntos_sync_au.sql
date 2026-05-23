DELIMITER $$
CREATE TRIGGER tg_puntos_sync_au
AFTER UPDATE ON historial_equipo
FOR EACH ROW
BEGIN
 
    -- 1. Sincronizar clasificacion_anual cuando cambian los puntos
    IF OLD.puntos_campeonato <> NEW.puntos_campeonato THEN
        INSERT INTO clasificacion_anual (año, id_equipo, puntos_totales)
        VALUES (fn_get_año_split(NEW.id_split), NEW.id_equipo, NEW.puntos_campeonato)
        ON DUPLICATE KEY UPDATE
            puntos_totales = puntos_totales + (NEW.puntos_campeonato - OLD.puntos_campeonato);
    END IF;
 
    -- 2. Registrar en auditoría cuando cambia posicion_playoffs
    IF (OLD.posicion_playoffs <> NEW.posicion_playoffs)
    OR (OLD.posicion_playoffs IS NULL AND NEW.posicion_playoffs IS NOT NULL) THEN
        INSERT INTO auditoria_lec (tabla_afectada, accion, detalle, usuario)
        VALUES (
            'historial_equipo',
            'UPDATE',
            CONCAT(
                'Posición playoffs actualizada: equipo ID ', NEW.id_equipo,
                ' en split ', NEW.id_split,
                ' — posición: ', NEW.posicion_playoffs
            ),
            USER()
        );
    END IF;
 
END$$
DELIMITER ;