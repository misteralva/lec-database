DELIMITER $$
CREATE TRIGGER tg_auditoria_jugador_au
AFTER UPDATE ON jugador_equipo_historial
FOR EACH ROW
BEGIN
    IF NEW.fecha_fin IS NOT NULL AND OLD.fecha_fin IS NULL THEN
        INSERT INTO auditoria_lec (tabla_afectada, accion, detalle, usuario)
        VALUES (
            'jugador_equipo_historial',
            'UPDATE',
            CONCAT(
                'Contrato cerrado: jugador ID ', OLD.id_jugador,
                ' en historial ', OLD.id_historial_equipo,
                ' — fecha fin: ', NEW.fecha_fin
            ),
            USER()
        );
    END IF;
END$$
DELIMITER ;

--  Se dispara AFTER UPDATE en jugador_equipo_historial.
--  Solo actúa cuando se cierra un contrato, es decir cuando
--  se pone fecha_fin donde antes había NULL. Eso indica que
--  el jugador ha sido traspasado o que se ha cerrado el split.
--  Registra el evento en auditoria_lec.