USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_estadisticas;
DELIMITER $$
CREATE PROCEDURE sp_registrar_estadisticas(
    IN  p_id_partido  INT,
    IN  p_numero_mapa INT,
    IN  p_id_jugador  INT,
    IN  p_kills       INT,
    IN  p_deaths      INT,
    IN  p_assists     INT,
    IN  p_cs          INT,
    IN  p_oro         INT,
    IN  p_campeon     VARCHAR(30),
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_mapa_existe  INT DEFAULT 0;
    DECLARE v_jugador_ok   BOOLEAN DEFAULT FALSE;
    DECLARE v_stats_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_mapa_existe
    FROM mapa
    WHERE id_partido = p_id_partido AND numero_mapa = p_numero_mapa;

    IF v_mapa_existe = 0 THEN
        SET p_mensaje = 'Error: el mapa indicado no existe en ese partido.';

    ELSE
        SET v_jugador_ok = fn_jugador_en_partido(p_id_jugador, p_id_partido);

        IF v_jugador_ok = FALSE THEN
            SET p_mensaje = 'Error: el jugador no pertenece a ningún equipo de este partido.';

        ELSE
            SELECT COUNT(*) INTO v_stats_existe
            FROM estadistica_jugador
            WHERE id_partido   = p_id_partido
              AND numero_mapa  = p_numero_mapa
              AND id_jugador   = p_id_jugador;

            IF v_stats_existe > 0 THEN
                SET p_mensaje = 'Error: ya existen estadísticas de este jugador en ese mapa.';

            ELSE
                START TRANSACTION;
                    INSERT INTO estadistica_jugador
                        (id_partido, numero_mapa, id_jugador,
                         kills, deaths, assists, cs, oro, campeon)
                    VALUES
                        (p_id_partido, p_numero_mapa, p_id_jugador,
                         p_kills, p_deaths, p_assists, p_cs, p_oro, p_campeon);
                COMMIT;

                SET p_mensaje = 'Estadísticas registradas correctamente.';

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;