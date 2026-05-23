USE lec;

DROP PROCEDURE IF EXISTS sp_detalle_partido;

DELIMITER $$
CREATE PROCEDURE sp_detalle_partido(IN p_id_partido INT UNSIGNED)
BEGIN
    -- Result set 1: datos del partido
    SELECT
        p.id_partido,
        eq1.nombre                          AS equipo_1,
        eq2.nombre                          AS equipo_2,
        he1.id_equipo                       AS id_equipo_1,
        he2.id_equipo                       AS id_equipo_2,
        p.mapas_eq1,
        p.mapas_eq2,
        p.tipo_serie,
        p.fecha_hora,
        p.finalizado,
        fs.tipo                             AS fase,
        CASE s.nombre WHEN 'Winter' THEN 'LEC Versus' ELSE s.nombre END AS split,
        s.año,
        CASE
            WHEN p.finalizado = TRUE AND p.mapas_eq1 > p.mapas_eq2 THEN eq1.nombre
            WHEN p.finalizado = TRUE AND p.mapas_eq2 > p.mapas_eq1 THEN eq2.nombre
            ELSE NULL
        END                                 AS ganador
    FROM partido p
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split
    WHERE p.id_partido = p_id_partido;

    -- Result set 2: mapas del partido
    SELECT
        m.numero_mapa,
        m.duracion_minutos,
        CASE
            WHEN m.ganador = he1.id_historial_equipo THEN eq1.nombre
            WHEN m.ganador = he2.id_historial_equipo THEN eq2.nombre
            ELSE NULL
        END                                 AS equipo_ganador
    FROM mapa m
    JOIN partido p ON m.id_partido = p.id_partido
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    WHERE m.id_partido = p_id_partido
    ORDER BY m.numero_mapa ASC;

    -- Result set 3: estadísticas por jugador y mapa
    -- CORRECCIÓN: el rol se lee de jugador_equipo_historial (jeh.rol)
    -- porque la tabla estadistica_jugador NO tiene columna rol
    SELECT
        ej.numero_mapa,
        j.nickname,
        j.id_jugador,
        jeh.rol                             AS rol_jugado,
        ej.campeon,
        ej.kills,
        ej.deaths,
        ej.assists,
        ej.cs,
        ej.oro,
        ROUND((ej.kills + ej.assists) / GREATEST(ej.deaths, 1), 2) AS kda,
        CASE
            WHEN jeh.id_historial_equipo = p.id_historial_equipo_1 THEN eq1.nombre
            ELSE eq2.nombre
        END                                 AS equipo
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador = j.id_jugador
    JOIN partido p ON ej.id_partido = p.id_partido
    JOIN jugador_equipo_historial jeh
        ON j.id_jugador = jeh.id_jugador
        AND jeh.id_historial_equipo IN (p.id_historial_equipo_1, p.id_historial_equipo_2)
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    WHERE ej.id_partido = p_id_partido
    ORDER BY ej.numero_mapa ASC,
             FIELD(jeh.id_historial_equipo, p.id_historial_equipo_1, p.id_historial_equipo_2),
             FIELD(jeh.rol, 'Top','Jungle','Mid','ADC','Support');
END$$
DELIMITER ;