DELIMITER $$
CREATE TRIGGER tg_auditoria_jugador_ai
AFTER INSERT ON jugador_equipo_historial
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_lec (tabla_afectada, accion, detalle, usuario)
    VALUES (
        'jugador_equipo_historial',
        'INSERT',
        CONCAT(
            'Jugador ID ', NEW.id_jugador,
            ' fichado en historial ', NEW.id_historial_equipo,
            ' como ', IF(NEW.es_titular, 'titular', 'suplente'),
            ' en rol ', NEW.rol,
            ' con inicio ', NEW.fecha_inicio
        ),
        USER()
    );
END$$
DELIMITER ;

--  Se dispara AFTER INSERT en jugador_equipo_historial.
--  Registra automáticamente en auditoria_lec cada vez que
--  se ficha un jugador, indicando el equipo, el rol y si
--  entra como titular o suplente.