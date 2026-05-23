DELIMITER $$

CREATE TRIGGER tg_auditoria_partido_au
AFTER UPDATE ON partido
FOR EACH ROW
BEGIN
    -- Registra en auditoria_lec cualquier cambio en el marcador
    -- (mapas_eq1, mapas_eq2) o en el estado de finalización de un partido.
    -- Guarda el marcador anterior y el nuevo en el campo detalle. 
    
    IF OLD.finalizado <> NEW.finalizado 
       OR OLD.mapas_eq1 <> NEW.mapas_eq1
       OR OLD.mapas_eq2 <> NEW.mapas_eq2 THEN
       
        INSERT INTO auditoria_lec (tabla_afectada, accion, detalle, usuario)
        VALUES (
            'partido',
            'UPDATE',
            CONCAT(
                'Partido ', NEW.id_partido,
                ' marcador cambiado de ',
                OLD.mapas_eq1, '-', OLD.mapas_eq2,
                ' a ',
                NEW.mapas_eq1, '-', NEW.mapas_eq2
            ),
            USER()
        );
    END IF;
END$$

DELIMITER ;

