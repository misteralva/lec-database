-- ============================================================
-- LEC DATABASE — SCRIPT COMPLETO ÚNICO
-- League of Legends EMEA Championship
-- ============================================================
-- CONTENIDO: 14 tablas | 7 funciones | 12 triggers | 33 SPs
--            Datos 2024-2026 | Playoffs | Usuarios | Permisos
-- ============================================================
-- Importar SOLO este archivo. Borra y recrea la BD completa.
-- Codificación: UTF-8 | Tiempo máximo: 300 segundos
-- ============================================================

DROP DATABASE IF EXISTS lec;
CREATE DATABASE lec CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lec;

-- ============================================================
-- TABLAS, FUNCIONES, TRIGGERS Y PROCEDIMIENTOS BASE
-- ============================================================

-- ============================================================
-- LEC DATABASE — SCRIPT COMPLETO
-- Ejecutar en phpMyAdmin con usuario root
-- ============================================================

-- ============================================================
-- 1. TABLAS
-- ============================================================
CREATE DATABASE IF NOT EXISTS LEC;
USE LEC;

CREATE TABLE equipo (
    id_equipo INT UNSIGNED AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL 
		COMMENT 'Nombre del equipo',
    pais VARCHAR(50) 
		COMMENT 'País de origen',
    fundacion DATE 
		COMMENT 'Fecha de fundación (día/mes/año)',
    activo BOOLEAN DEFAULT TRUE 
		COMMENT 'Si sigue compitiendo',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_equipo),
    UNIQUE KEY uk_nombre (nombre),
    
    INDEX idx_pais (pais),
    INDEX idx_activo (activo)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Equipos que han participado en la LEC';

CREATE TABLE jugador (
    id_jugador INT UNSIGNED AUTO_INCREMENT,
    nickname VARCHAR(30) NOT NULL 
		COMMENT 'Apodo jugador ',
    nombre_real VARCHAR(100) 
		COMMENT 'Nombre completo',
    nacionalidad VARCHAR(50) 
		COMMENT 'País de origen',
    fecha_nacimiento DATE 
		COMMENT 'Fecha de nacimiento',
    rol_principal ENUM('Top','Jungle','Mid','ADC','Support') NOT NULL 
		COMMENT 'Rol principal del jugador',
    activo BOOLEAN DEFAULT TRUE 
		COMMENT 'Si está actualmente compitiendo',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_jugador),
    
    INDEX idx_rol (rol_principal),
    INDEX idx_nacionalidad (nacionalidad),
    INDEX idx_activo (activo)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Jugadores profesionales que han participado en la LEC';

CREATE TABLE entrenador (
    id_entrenador INT UNSIGNED AUTO_INCREMENT,
    nickname VARCHAR(30) NOT NULL 
		COMMENT 'Apodo entrenador',
    nombre VARCHAR(100) NOT NULL 
		COMMENT 'Nombre del entrenador',
    nacionalidad VARCHAR(50) 
		COMMENT 'País de origen',
    activo BOOLEAN DEFAULT TRUE 
		COMMENT 'Si está actualmente en un equipo',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_entrenador),
    UNIQUE KEY uk_nickname (nickname),
    
    INDEX idx_nombre (nombre),
    INDEX idx_activo (activo)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Entrenadores de equipos de la LEC';

CREATE TABLE split (
    id_split INT UNSIGNED AUTO_INCREMENT,
    nombre ENUM('Spring','Summer','Winter') NOT NULL 
		COMMENT 'Nombre del split (Corregido: Winter por Versus)',
    año YEAR NOT NULL 
		COMMENT 'Año de competición',
    fecha_inicio DATE NOT NULL 
		COMMENT 'Fecha de inicio',
    fecha_fin DATE 
		COMMENT 'Fecha de finalización',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_split),
    UNIQUE KEY uk_split_año (nombre, año),
    
    INDEX idx_año (año DESC),
    
    CONSTRAINT chk_fechas_validas 
		CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Splits del año';

CREATE TABLE fase_split (
    id_fase INT UNSIGNED AUTO_INCREMENT,
    id_split INT UNSIGNED NOT NULL 
		COMMENT 'Split al que pertenece',
    tipo ENUM('FASE_REGULAR','PLAYOFFS') NOT NULL 
		COMMENT 'Tipo de fase',
    formato ENUM('Bo1','Bo3','Bo5') NOT NULL 
		COMMENT 'Formato de series',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_fase),
    
    CONSTRAINT fk_fase_split 
		FOREIGN KEY (id_split) 
        REFERENCES split(id_split) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Fases dentro de cada split';

CREATE TABLE historial_equipo (
    id_historial_equipo INT UNSIGNED AUTO_INCREMENT,
    id_equipo INT UNSIGNED NOT NULL 
		COMMENT 'Equipo participante',
    id_split INT UNSIGNED NOT NULL 
		COMMENT 'Split en que participa',
    posicion_fase_regular TINYINT UNSIGNED 
		COMMENT 'Posición en fase regular (1-10)',
    posicion_playoffs TINYINT UNSIGNED 
		COMMENT 'Posición en playoffs (1-6)',
    puntos_campeonato SMALLINT UNSIGNED DEFAULT 0 
		COMMENT 'Puntos para clasificación',
    clasificado_msi BOOLEAN DEFAULT FALSE,
    seed_worlds TINYINT UNSIGNED 
		COMMENT 'Seed para Worlds (1-4)',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_historial_equipo),
    UNIQUE KEY uk_equipo_split (id_equipo, id_split),
    
    CONSTRAINT fk_historial_equipo 
		FOREIGN KEY (id_equipo) 
        REFERENCES equipo(id_equipo) 
        ON UPDATE CASCADE,
    CONSTRAINT fk_historial_split 
		FOREIGN KEY (id_split) 
        REFERENCES split(id_split) 
        ON UPDATE CASCADE,
        
    CONSTRAINT chk_posicion_regular 
		CHECK (posicion_fase_regular BETWEEN 1 AND 10),
    CONSTRAINT chk_posicion_playoffs 
		CHECK (posicion_playoffs BETWEEN 1 AND 6)
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Participación de equipos por split';

CREATE TABLE jugador_equipo_historial (
    id_historial_equipo INT UNSIGNED NOT NULL,
    id_jugador INT UNSIGNED NOT NULL,
    rol ENUM('Top','Jungle','Mid','ADC','Support') NOT NULL
    COMMENT 'Rol jugado',
    es_titular BOOLEAN DEFAULT TRUE
    COMMENT 'Si está entre los 5 titulares',
    fecha_inicio DATE NOT NULL
    COMMENT 'Fecha de inicio',
    fecha_fin DATE
    COMMENT 'Fecha de finalización',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_historial_equipo, id_jugador),
    
    CONSTRAINT fk_jeh_equipo 
		FOREIGN KEY (id_historial_equipo) 
        REFERENCES historial_equipo(id_historial_equipo) 
        ON DELETE CASCADE,
    CONSTRAINT fk_jeh_jugador 
		FOREIGN KEY (id_jugador) 
        REFERENCES jugador(id_jugador) 
        ON UPDATE CASCADE,
        
    CONSTRAINT chk_fechas_jugador 
		CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jugadores por equipo y split';

CREATE TABLE entrenador_equipo_historial (
    id_historial_equipo INT UNSIGNED NOT NULL,
    id_entrenador INT UNSIGNED NOT NULL,
    fecha_inicio DATE NOT NULL
    COMMENT 'Fecha de inicio',
    fecha_fin DATE
    COMMENT 'Fecha de finalización',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_historial_equipo, id_entrenador),
    CONSTRAINT fk_eeh_equipo 
		FOREIGN KEY (id_historial_equipo) 
        REFERENCES historial_equipo(id_historial_equipo) 
        ON DELETE CASCADE,
    CONSTRAINT fk_eeh_entrenador 
		FOREIGN KEY (id_entrenador) 
        REFERENCES entrenador(id_entrenador) 
        ON UPDATE CASCADE
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
	COMMENT='Entrenadores por equipo y split';

CREATE TABLE partido (
    id_partido INT UNSIGNED AUTO_INCREMENT,
    id_fase INT UNSIGNED NOT NULL,
    id_historial_equipo_1 INT UNSIGNED NOT NULL
    COMMENT 'Id equipo 1',
    id_historial_equipo_2 INT UNSIGNED NOT NULL
    COMMENT 'Id equipo 2',
    fecha_hora DATETIME NOT NULL
    COMMENT 'Fecha partido',
    tipo_serie ENUM('Bo1','Bo3','Bo5') NOT NULL
    COMMENT 'Serie del partido Bo1, Bo2, Bo3',
    mapas_eq1 TINYINT UNSIGNED DEFAULT 0
    COMMENT 'Mapas Ganados equipo 1',
    mapas_eq2 TINYINT UNSIGNED DEFAULT 0
    COMMENT 'Mapas Ganados equipo 1',
    finalizado BOOLEAN DEFAULT FALSE
    COMMENT 'Si el partido está finalizado',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_partido),
    CONSTRAINT fk_partido_fase 
		FOREIGN KEY (id_fase) 
		REFERENCES fase_split(id_fase),
        
    CONSTRAINT fk_partido_eq1 
		FOREIGN KEY (id_historial_equipo_1) 
        REFERENCES historial_equipo(id_historial_equipo),
    CONSTRAINT fk_partido_eq2 
		FOREIGN KEY (id_historial_equipo_2) 
        REFERENCES historial_equipo(id_historial_equipo),
        
    CONSTRAINT chk_equipos_diff 
		CHECK (id_historial_equipo_1 != id_historial_equipo_2)
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Partidos jugados';

CREATE TABLE mapa (
    id_partido INT UNSIGNED NOT NULL,
    numero_mapa TINYINT UNSIGNED NOT NULL
    COMMENT 'Numero del mapa jugado',
    duracion_minutos SMALLINT UNSIGNED
    COMMENT 'Duración del mapa',
    ganador INT UNSIGNED NULL
    COMMENT 'Ganador del mapa',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_partido, numero_mapa),
    CONSTRAINT fk_mapa_partido 
		FOREIGN KEY (id_partido) 
        REFERENCES partido(id_partido) 
        ON DELETE CASCADE,
    CONSTRAINT fk_mapa_ganador 
		FOREIGN KEY (ganador) 
        REFERENCES historial_equipo(id_historial_equipo),
        
    CONSTRAINT chk_num_mapa 
		CHECK (numero_mapa BETWEEN 1 AND 5)
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Mapas individuales';

CREATE TABLE estadistica_jugador (
    id_estadistica INT UNSIGNED AUTO_INCREMENT,
    id_partido INT UNSIGNED NOT NULL,
    numero_mapa TINYINT UNSIGNED NOT NULL,
    id_jugador INT UNSIGNED NOT NULL,
    kills TINYINT UNSIGNED DEFAULT 0
    COMMENT 'Kills por mapa',
    deaths TINYINT UNSIGNED DEFAULT 0
    COMMENT 'Deaths por mapa',
    assists TINYINT UNSIGNED DEFAULT 0
    COMMENT 'Assists por mapa',
    cs SMALLINT UNSIGNED DEFAULT 0
    COMMENT 'Cs por mapa',
    oro INT UNSIGNED DEFAULT 0
    COMMENT 'Oro por mapa',
    campeon VARCHAR(30) NOT NULL
    COMMENT 'Campeon jugado',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_estadistica),
    CONSTRAINT fk_stats_mapa 
		FOREIGN KEY (id_partido, numero_mapa) 
        REFERENCES mapa(id_partido, numero_mapa) 
        ON DELETE CASCADE,
    CONSTRAINT fk_stats_jugador 
		FOREIGN KEY (id_jugador) 
        REFERENCES jugador(id_jugador),
        
    INDEX idx_jugador_stats (id_jugador)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Estadísticas por mapa';

CREATE TABLE clasificacion_anual (
    año YEAR NOT NULL,
    id_equipo INT UNSIGNED NOT NULL,
    puntos_totales SMALLINT UNSIGNED DEFAULT 0
    COMMENT 'Puntuación global',
    seed_worlds TINYINT UNSIGNED
    COMMENT 'Clasificación para worlds',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (año, id_equipo),
    CONSTRAINT fk_cl_anual_eq 
		FOREIGN KEY (id_equipo) 
        REFERENCES equipo(id_equipo) 
        ON DELETE CASCADE
        
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Clasificación anual para Worlds';

CREATE TABLE auditoria_lec (
    id_auditoria INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada VARCHAR(50)
    COMMENT 'Tabla en la que se han hecho cambios',
    accion ENUM('INSERT', 'UPDATE', 'DELETE')
    COMMENT 'Acción realizada en el cambio',
    detalle TEXT,
    usuario VARCHAR(100),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
COMMENT='Registro de seguridad de cambios';
-- ============================================================
-- 2. FUNCIONES
-- ============================================================

-- --- fn_get_split_de_historial.sql ---
DELIMITER $$
CREATE FUNCTION fn_get_split_de_historial(p_id_historial INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
COMMENT 'Devuelve el id_split de un registro historial_equipo'
BEGIN
    DECLARE v_id_split INT UNSIGNED;

    SELECT id_split INTO v_id_split
    FROM historial_equipo
    WHERE id_historial_equipo = p_id_historial;

    RETURN v_id_split;
END$$
DELIMITER ;
-- --- fn_get_split_de_fase.sql ---
DELIMITER $$
CREATE FUNCTION fn_get_split_de_fase(p_id_fase INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
COMMENT 'Devuelve el id_split asociado a una fase'
BEGIN
    DECLARE v_id_split INT UNSIGNED;

    SELECT id_split INTO v_id_split
    FROM fase_split
    WHERE id_fase = p_id_fase;

    RETURN v_id_split;
END$$
DELIMITER ;
-- --- fn_get_año_split.sql ---
DELIMITER $$
CREATE FUNCTION fn_get_año_split(p_id_split INT UNSIGNED)
RETURNS INT
READS SQL DATA
NOT DETERMINISTIC
COMMENT 'Devuelve el año de un split dado su id'
BEGIN
    DECLARE v_año INT;
 
    SELECT año INTO v_año
    FROM split
    WHERE id_split = p_id_split;
 
    RETURN IFNULL(v_año, 0);
END$$
DELIMITER ;
-- --- fn_split_en_curso.sql ---
DELIMITER $$
CREATE FUNCTION fn_split_en_curso(p_id_split INT UNSIGNED)
RETURNS BOOLEAN
READS SQL DATA
NOT DETERMINISTIC
COMMENT 'TRUE si el split está activo a fecha de hoy'
BEGIN
    DECLARE v_resultado BOOLEAN DEFAULT FALSE;

    SELECT TRUE INTO v_resultado
    FROM split
    WHERE id_split = p_id_split
      AND CURDATE() BETWEEN fecha_inicio AND IFNULL(fecha_fin, '9999-12-31')
    LIMIT 1;

    RETURN IFNULL(v_resultado, FALSE);
END$$
DELIMITER ;
-- --- fn_serie_terminada.sql ---
DELIMITER $$
CREATE FUNCTION fn_serie_terminada(
    p_mapas_eq1  TINYINT UNSIGNED,
    p_mapas_eq2  TINYINT UNSIGNED,
    p_tipo_serie VARCHAR(5)
)
RETURNS BOOLEAN
NO SQL
DETERMINISTIC
COMMENT 'TRUE si la serie ya tiene un ganador según Bo1/Bo3/Bo5'
BEGIN
    DECLARE v_victorias_necesarias TINYINT;

    SET v_victorias_necesarias = CASE p_tipo_serie
        WHEN 'Bo1' THEN 1
        WHEN 'Bo3' THEN 2
        WHEN 'Bo5' THEN 3
        ELSE NULL
    END;
    
    IF v_victorias_necesarias IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN (p_mapas_eq1 >= v_victorias_necesarias
         OR p_mapas_eq2 >= v_victorias_necesarias);
END$$
DELIMITER ;
-- --- fn_jugador_en_partido.sql ---
DELIMITER $$
CREATE FUNCTION fn_jugador_en_partido(
    p_id_jugador INT UNSIGNED,
    p_id_partido INT UNSIGNED
)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
COMMENT 'TRUE si el jugador pertenece a algún equipo del partido'
BEGIN
    DECLARE v_existe BOOLEAN DEFAULT FALSE;

    SELECT TRUE INTO v_existe
    FROM jugador_equipo_historial jeh
    JOIN partido p
        ON jeh.id_historial_equipo = p.id_historial_equipo_1
        OR jeh.id_historial_equipo = p.id_historial_equipo_2
    WHERE p.id_partido   = p_id_partido
      AND jeh.id_jugador = p_id_jugador
    LIMIT 1;

    RETURN IFNULL(v_existe, FALSE);
END$$
DELIMITER ;
-- --- fn_ganador_partido.sql ---
DELIMITER $$
CREATE FUNCTION fn_ganador_partido(p_id_partido INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
DETERMINISTIC
COMMENT 'Devuelve el id_historial_equipo ganador, o NULL si no ha terminado'
BEGIN
    DECLARE v_eq1   INT UNSIGNED;
    DECLARE v_eq2   INT UNSIGNED;
    DECLARE v_m1    TINYINT UNSIGNED;
    DECLARE v_m2    TINYINT UNSIGNED;
    DECLARE v_tipo  VARCHAR(5);
    DECLARE v_final BOOLEAN;

    SELECT id_historial_equipo_1,
           id_historial_equipo_2,
           mapas_eq1,
           mapas_eq2,
           tipo_serie,
           finalizado
    INTO   v_eq1, v_eq2, v_m1, v_m2, v_tipo, v_final
    FROM   partido
    WHERE  id_partido = p_id_partido;

    IF NOT v_final OR NOT fn_serie_terminada(v_m1, v_m2, v_tipo) THEN
        RETURN NULL;
    END IF;
    
    RETURN IF(v_m1 > v_m2, v_eq1, v_eq2);
END$$
DELIMITER ;
-- ============================================================
-- 3. TRIGGERS
-- ============================================================

-- --- tg_partido_maestro_bi.sql ---

-- ============================================================
-- PROCEDIMIENTO: sp_registrar_estadisticas
-- Registra o actualiza estadísticas de un jugador en un mapa
-- ============================================================
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
    DECLARE v_mapa_existe  INT     DEFAULT 0;
    DECLARE v_jugador_ok   BOOLEAN DEFAULT FALSE;
    DECLARE v_stats_existe INT     DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_mapa_existe
    FROM mapa WHERE id_partido = p_id_partido AND numero_mapa = p_numero_mapa;

    IF v_mapa_existe = 0 THEN
        SET p_mensaje = 'Error: el mapa indicado no existe en ese partido.';
    ELSE
        SET v_jugador_ok = fn_jugador_en_partido(p_id_jugador, p_id_partido);
        IF v_jugador_ok = FALSE THEN
            SET p_mensaje = 'Error: el jugador no pertenece a ningún equipo de este partido.';
        ELSE
            SELECT COUNT(*) INTO v_stats_existe
            FROM estadistica_jugador
            WHERE id_partido=p_id_partido AND numero_mapa=p_numero_mapa AND id_jugador=p_id_jugador;

            START TRANSACTION;
            IF v_stats_existe > 0 THEN
                UPDATE estadistica_jugador
                SET kills=p_kills, deaths=p_deaths, assists=p_assists,
                    cs=p_cs, oro=p_oro, campeon=p_campeon
                WHERE id_partido=p_id_partido AND numero_mapa=p_numero_mapa AND id_jugador=p_id_jugador;
                SET p_mensaje = 'Estadísticas actualizadas correctamente.';
            ELSE
                INSERT INTO estadistica_jugador
                    (id_partido,numero_mapa,id_jugador,kills,deaths,assists,cs,oro,campeon)
                VALUES (p_id_partido,p_numero_mapa,p_id_jugador,p_kills,p_deaths,p_assists,p_cs,p_oro,p_campeon);
                SET p_mensaje = 'Estadísticas registradas correctamente.';
            END IF;
            COMMIT;
        END IF;
    END IF;
END$$
DELIMITER ;
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
-- --- tg_jugador_historial_maestro_bi.sql ---
DELIMITER $$
CREATE TRIGGER tg_jugador_historial_maestro_bi
BEFORE INSERT ON jugador_equipo_historial
FOR EACH ROW
BEGIN
    -- Impide fichar a un jugador si ya tiene contrato activo
    -- (fecha_fin IS NULL) o si ya está asignado a otro equipo
    -- en el mismo split.
    IF EXISTS (
        SELECT 1 
        FROM jugador_equipo_historial jeh 
        JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo 
        WHERE jeh.id_jugador = NEW.id_jugador 
          AND (he.id_split = fn_get_split_de_historial(NEW.id_historial_equipo)
          OR jeh.fecha_fin IS NULL)
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Jugador ya tiene un contrato activo o equipo en este split.';
    END IF;

    -- Impide asignar dos titulares al mismo rol dentro del mismo
    -- historial de equipo.
    IF NEW.es_titular = TRUE AND EXISTS (
        SELECT 1 
        FROM jugador_equipo_historial 
        WHERE id_historial_equipo = NEW.id_historial_equipo 
          AND rol = NEW.rol 
          AND es_titular = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Ya existe un titular para este rol.';
    END IF;
END$$

CREATE TRIGGER tg_jugador_historial_maestro_bu
BEFORE UPDATE ON jugador_equipo_historial
FOR EACH ROW
BEGIN
    -- Bloquea traspasos (asignar fecha_fin) mientras el split
    -- del equipo sigue activo, siguiendo la regla oficial LEC.
    -- Si el bloqueo no aplica y se pone fecha_fin, automáticamente
    -- se quita la titularidad al jugador.
    IF NEW.fecha_fin IS NOT NULL AND OLD.fecha_fin IS NULL THEN
        IF fn_split_en_curso(
            fn_get_split_de_historial(OLD.id_historial_equipo)
        ) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'LEC Rule: Prohibido traspasos durante el Split.';
        END IF;
        SET NEW.es_titular = FALSE;
    END IF;
END$$
DELIMITER ;
-- --- tg_entrenador_maestro_bi.sql ---
USE LEC;

DROP TRIGGER IF EXISTS tg_entrenador_maestro_bi;

DELIMITER $$
CREATE TRIGGER tg_entrenador_maestro_bi
BEFORE INSERT ON entrenador_equipo_historial
FOR EACH ROW
BEGIN

    DECLARE v_id_split          INT UNSIGNED;
    DECLARE v_contrato_activo   INT DEFAULT 0;
    DECLARE v_entrenador_existe INT DEFAULT 0;

    -- Obtener el split al que pertenece este historial de equipo
    SET v_id_split = fn_get_split_de_historial(NEW.id_historial_equipo);

    -- 1. Comprobar que el entrenador no tiene ya contrato activo
    --    en el mismo split (no puede estar en dos equipos a la vez)
    SELECT COUNT(*) INTO v_contrato_activo
    FROM entrenador_equipo_historial eeh
    JOIN historial_equipo he ON eeh.id_historial_equipo = he.id_historial_equipo
    WHERE eeh.id_entrenador = NEW.id_entrenador
      AND he.id_split = v_id_split
      AND eeh.fecha_fin IS NULL;

    IF v_contrato_activo > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: el entrenador ya tiene un contrato activo en este split.';
    END IF;

    -- 2. Comprobar que el equipo no tiene ya un entrenador activo
    --    en este historial (un equipo solo tiene un entrenador principal)
    SELECT COUNT(*) INTO v_entrenador_existe
    FROM entrenador_equipo_historial
    WHERE id_historial_equipo = NEW.id_historial_equipo
      AND fecha_fin IS NULL;

    IF v_entrenador_existe > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: este equipo ya tiene un entrenador activo en este split.';
    END IF;

END$$
DELIMITER ;
-- --- tg_stats_maestro_bi.sql ---
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
-- --- tg_bloqueo_historico_bu.sql ---
DELIMITER $$

CREATE TRIGGER tg_bloqueo_historico_bu
BEFORE UPDATE ON partido
FOR EACH ROW
BEGIN
    -- Impide modificar cualquier campo de un partido cuyo split
    -- pertenece a una temporada anterior al año actual.
    -- Usa fn_get_año_split y fn_get_split_de_fase para obtener
    -- el año del split a partir de la fase del partido.
    
   IF fn_get_año_split(fn_get_split_de_fase(OLD.id_fase))
       < YEAR(CURDATE()) THEN
       
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Seguridad: No se pueden modificar datos de temporadas pasadas.';
    END IF;
END$$

DELIMITER ;
-- --- tg_proteccion_borrado_critico.sql ---
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
-- --- tg_mapa_maestro_ai.sql ---
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
-- --- tg_auditoria_jugador_ai.sql ---
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
-- --- tg_puntos_sync_au.sql ---
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
-- --- tg_auditoria_partido_au.sql ---
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


-- --- tg_auditoria_jugador_au.sql ---
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
-- ============================================================
-- 4. PROCEDIMIENTOS
-- ============================================================

-- --- sp_registrar_partido.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_partido;
DELIMITER $$
CREATE PROCEDURE sp_registrar_partido(
    IN  p_id_fase     INT,
    IN  p_id_hist_eq1 INT,
    IN  p_id_hist_eq2 INT,
    IN  p_fecha_hora  DATETIME,
    IN  p_tipo_serie  VARCHAR(5),
    OUT p_id_partido  INT,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_split_eq1  INT;
    DECLARE v_split_eq2  INT;
    DECLARE v_split_fase INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_partido = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    IF p_id_hist_eq1 = p_id_hist_eq2 THEN
        SET p_mensaje = 'Error: los dos equipos no pueden ser el mismo.';

    ELSEIF p_tipo_serie NOT IN ('Bo1', 'Bo3', 'Bo5') THEN
        SET p_mensaje = 'Error: el tipo de serie debe ser Bo1, Bo3 o Bo5.';

    ELSE
        SET v_split_eq1  = fn_get_split_de_historial(p_id_hist_eq1);
        SET v_split_eq2  = fn_get_split_de_historial(p_id_hist_eq2);
        SET v_split_fase = fn_get_split_de_fase(p_id_fase);

        IF v_split_eq1 IS NULL THEN
            SET p_mensaje = 'Error: el historial del equipo 1 no existe.';

        ELSEIF v_split_eq2 IS NULL THEN
            SET p_mensaje = 'Error: el historial del equipo 2 no existe.';

        ELSEIF v_split_fase IS NULL THEN
            SET p_mensaje = 'Error: la fase indicada no existe.';

        ELSEIF v_split_eq1 <> v_split_eq2 OR v_split_eq1 <> v_split_fase THEN
            SET p_mensaje = 'Error: los equipos y la fase no pertenecen al mismo split.';

        ELSE
            START TRANSACTION;
                INSERT INTO partido
                    (id_fase, id_historial_equipo_1, id_historial_equipo_2,
                     fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado)
                VALUES
                    (p_id_fase, p_id_hist_eq1, p_id_hist_eq2,
                     p_fecha_hora, p_tipo_serie, 0, 0, FALSE);
                SET p_id_partido = LAST_INSERT_ID();
            COMMIT;

            SET p_mensaje = CONCAT('Partido creado con ID: ', p_id_partido);

        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_registrar_mapa.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_mapa;
DELIMITER $$
CREATE PROCEDURE sp_registrar_mapa(
    IN  p_id_partido  INT,
    IN  p_numero_mapa INT,
    IN  p_duracion    INT,
    IN  p_ganador     INT,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_finalizado BOOLEAN;
    DECLARE v_eq1        INT;
    DECLARE v_eq2        INT;
    DECLARE v_mapa_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT finalizado, id_historial_equipo_1, id_historial_equipo_2
    INTO v_finalizado, v_eq1, v_eq2
    FROM partido WHERE id_partido = p_id_partido;

    IF v_finalizado IS NULL THEN
        SET p_mensaje = 'Error: el partido indicado no existe.';

    ELSEIF v_finalizado = TRUE THEN
        SET p_mensaje = 'Error: el partido ya está finalizado.';

    ELSEIF p_numero_mapa < 1 OR p_numero_mapa > 5 THEN
        SET p_mensaje = 'Error: el número de mapa debe estar entre 1 y 5.';

    ELSEIF p_ganador <> v_eq1 AND p_ganador <> v_eq2 THEN
        SET p_mensaje = 'Error: el equipo ganador no participa en este partido.';

    ELSE
        SELECT COUNT(*) INTO v_mapa_existe
        FROM mapa
        WHERE id_partido = p_id_partido AND numero_mapa = p_numero_mapa;

        IF v_mapa_existe > 0 THEN
            SET p_mensaje = 'Error: ya existe ese mapa en este partido.';

        ELSE
            START TRANSACTION;
                INSERT INTO mapa (id_partido, numero_mapa, duracion_minutos, ganador)
                VALUES (p_id_partido, p_numero_mapa, p_duracion, p_ganador);
            COMMIT;

            SET p_mensaje = CONCAT('Mapa ', p_numero_mapa, ' registrado correctamente.');

        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_registrar_estadisticas.sql ---
USE LEC;
-- sp_registrar_estadisticas: versión UPSERT definida arriba
-- --- sp_fichar_jugador.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_fichar_jugador;
DELIMITER $$
CREATE PROCEDURE sp_fichar_jugador(
    IN  p_nickname     VARCHAR(30),
    IN  p_nombre_real  VARCHAR(100),
    IN  p_nacionalidad VARCHAR(50),
    IN  p_fecha_nac    DATE,
    IN  p_rol          ENUM('Top','Jungle','Mid','ADC','Support'),
    IN  p_id_historial INT,
    IN  p_es_titular   BOOLEAN,
    IN  p_fecha_inicio DATE,
    OUT p_id_jugador   INT UNSIGNED,
    OUT p_mensaje      VARCHAR(200)
)
BEGIN
    DECLARE v_historial_existe INT DEFAULT 0;
    DECLARE v_id_split         INT;
    DECLARE v_contrato_activo  INT DEFAULT 0;
    DECLARE v_titular_existe   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_jugador = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_historial_existe
    FROM historial_equipo
    WHERE id_historial_equipo = p_id_historial;

    IF v_historial_existe = 0 THEN
        SET p_mensaje = 'Error: el historial de equipo indicado no existe.';

    ELSE
        SET v_id_split = fn_get_split_de_historial(p_id_historial);

        SELECT id_jugador INTO p_id_jugador
        FROM jugador
        WHERE nickname = p_nickname LIMIT 1;

        IF p_id_jugador IS NOT NULL THEN
            SELECT COUNT(*) INTO v_contrato_activo
            FROM jugador_equipo_historial jeh
            JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
            WHERE jeh.id_jugador = p_id_jugador
              AND (he.id_split = v_id_split OR jeh.fecha_fin IS NULL);
        END IF;

        IF v_contrato_activo > 0 THEN
            SET p_mensaje = 'Error: el jugador ya tiene contrato activo en este split.';

        ELSE
            IF p_es_titular = TRUE THEN
                SELECT COUNT(*) INTO v_titular_existe
                FROM jugador_equipo_historial
                WHERE id_historial_equipo = p_id_historial
                  AND rol = p_rol
                  AND es_titular = TRUE;
            END IF;

            IF v_titular_existe > 0 THEN
                SET p_mensaje = 'Error: ya existe un titular en ese rol para este equipo.';

            ELSE
                START TRANSACTION;
                    IF p_id_jugador IS NULL THEN
                        INSERT INTO jugador (nickname, nombre_real, nacionalidad,
                                             fecha_nacimiento, rol_principal, activo)
                        VALUES (p_nickname, p_nombre_real, p_nacionalidad,
                                p_fecha_nac, p_rol, TRUE);
                        SET p_id_jugador = LAST_INSERT_ID();
                    END IF;

                    INSERT INTO jugador_equipo_historial
                        (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin)
                    VALUES
                        (p_id_historial, p_id_jugador, p_rol, p_es_titular, p_fecha_inicio, NULL);
                COMMIT;

                SET p_mensaje = CONCAT('Jugador ', p_nickname, ' fichado con ID: ', p_id_jugador);

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_transferir_jugador.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_transferir_jugador;
DELIMITER $$
CREATE PROCEDURE sp_transferir_jugador(
    IN  p_id_jugador         INT,
    IN  p_id_historial_nuevo INT,
    IN  p_fecha_fin          DATE,
    IN  p_fecha_inicio_nuevo DATE,
    IN  p_rol                ENUM('Top','Jungle','Mid','ADC','Support'),
    IN  p_es_titular         BOOLEAN,
    OUT p_mensaje            VARCHAR(200)
)
BEGIN
    DECLARE v_id_historial_actual INT;
    DECLARE v_id_split_actual     INT;
    DECLARE v_split_en_curso      BOOLEAN DEFAULT FALSE;
    DECLARE v_titular_existe      INT DEFAULT 0;
    DECLARE v_destino_existe      INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT id_historial_equipo INTO v_id_historial_actual
    FROM jugador_equipo_historial
    WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL LIMIT 1;

    IF v_id_historial_actual IS NULL THEN
        SET p_mensaje = 'Error: el jugador no tiene ningún contrato activo.';

    ELSE
        SET v_id_split_actual = fn_get_split_de_historial(v_id_historial_actual);
        SET v_split_en_curso  = fn_split_en_curso(v_id_split_actual);

        IF v_split_en_curso = TRUE THEN
            SET p_mensaje = 'Error: no se pueden hacer transferencias durante el split (regla LEC).';

        ELSE
            SELECT COUNT(*) INTO v_destino_existe
            FROM historial_equipo
            WHERE id_historial_equipo = p_id_historial_nuevo;

            IF v_destino_existe = 0 THEN
                SET p_mensaje = 'Error: el equipo destino no existe en este split.';

            ELSE
                IF p_es_titular = TRUE THEN
                    SELECT COUNT(*) INTO v_titular_existe
                    FROM jugador_equipo_historial
                    WHERE id_historial_equipo = p_id_historial_nuevo
                      AND rol = p_rol
                      AND es_titular = TRUE;
                END IF;

                IF v_titular_existe > 0 THEN
                    SET p_mensaje = 'Error: ya existe un titular en ese rol en el equipo destino.';

                ELSE
                    START TRANSACTION;
                        UPDATE jugador_equipo_historial
                        SET fecha_fin = p_fecha_fin
                        WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;

                        INSERT INTO jugador_equipo_historial
                            (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin)
                        VALUES
                            (p_id_historial_nuevo, p_id_jugador, p_rol, p_es_titular, p_fecha_inicio_nuevo, NULL);
                    COMMIT;

                    SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' transferido correctamente.');

                END IF;
            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_registrar_equipo_split.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_registrar_equipo_split;
DELIMITER $$
CREATE PROCEDURE sp_registrar_equipo_split(
    IN  p_id_equipo    INT,
    IN  p_id_split     INT,
    OUT p_id_historial INT,
    OUT p_mensaje      VARCHAR(200)
)
BEGIN
    DECLARE v_equipo_activo BOOLEAN;
    DECLARE v_split_existe  INT DEFAULT 0;
    DECLARE v_ya_registrado INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_historial = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT activo INTO v_equipo_activo
    FROM equipo WHERE id_equipo = p_id_equipo;

    IF v_equipo_activo IS NULL THEN
        SET p_mensaje = 'Error: el equipo indicado no existe.';

    ELSEIF v_equipo_activo = FALSE THEN
        SET p_mensaje = 'Error: el equipo no está activo.';

    ELSE
        SELECT COUNT(*) INTO v_split_existe
        FROM split WHERE id_split = p_id_split;

        IF v_split_existe = 0 THEN
            SET p_mensaje = 'Error: el split indicado no existe.';

        ELSE
            SELECT COUNT(*) INTO v_ya_registrado
            FROM historial_equipo
            WHERE id_equipo = p_id_equipo AND id_split = p_id_split;

            IF v_ya_registrado > 0 THEN
                SET p_mensaje = 'Error: este equipo ya está registrado en ese split.';

            ELSE
                START TRANSACTION;
                    INSERT INTO historial_equipo
                        (id_equipo, id_split, puntos_campeonato, clasificado_msi)
                    VALUES
                        (p_id_equipo, p_id_split, 0, FALSE);
                    SET p_id_historial = LAST_INSERT_ID();
                COMMIT;

                SET p_mensaje = CONCAT('Equipo registrado. Historial ID: ', p_id_historial);

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_cerrar_split.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_cerrar_split;
DELIMITER $$
CREATE PROCEDURE sp_cerrar_split(
    IN  p_id_split  INT UNSIGNED,
    IN  p_fecha_fin DATE,
    OUT p_mensaje   VARCHAR(200)
)
BEGIN
    DECLARE v_ya_cerrado          DATE;
    DECLARE v_split_existe        INT DEFAULT 0;
    DECLARE v_partidos_pendientes INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*), fecha_fin INTO v_split_existe, v_ya_cerrado
    FROM split WHERE id_split = p_id_split;

    IF v_split_existe = 0 THEN
        SET p_mensaje = 'Error: el split indicado no existe.';

    ELSEIF v_ya_cerrado IS NOT NULL THEN
        SET p_mensaje = 'Error: este split ya tiene una fecha de fin asignada.';

    ELSE
        SELECT COUNT(*) INTO v_partidos_pendientes
        FROM partido p
        JOIN fase_split fs ON p.id_fase = fs.id_fase
        WHERE fs.id_split = p_id_split AND p.finalizado = FALSE;

        IF v_partidos_pendientes > 0 THEN
            SET p_mensaje = CONCAT('Error: hay ', v_partidos_pendientes, ' partido(s) sin finalizar.');

        ELSE
            START TRANSACTION;
                UPDATE split
                SET fecha_fin = p_fecha_fin
                WHERE id_split = p_id_split;

                UPDATE jugador_equipo_historial jeh
                JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
                SET jeh.fecha_fin = p_fecha_fin
                WHERE he.id_split = p_id_split AND jeh.fecha_fin IS NULL;

                UPDATE entrenador_equipo_historial eeh
                JOIN historial_equipo he ON eeh.id_historial_equipo = he.id_historial_equipo
                SET eeh.fecha_fin = p_fecha_fin
                WHERE he.id_split = p_id_split AND eeh.fecha_fin IS NULL;
            COMMIT;

            SET p_mensaje = CONCAT('Split ', p_id_split, ' cerrado. Contratos cerrados automáticamente.');

        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_asignar_puntos_split.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_asignar_puntos_split;
DELIMITER $$
CREATE PROCEDURE sp_asignar_puntos_split(
    IN  p_id_historial INT,
    IN  p_posicion     INT,
    IN  p_tipo_split   VARCHAR(10),
    OUT p_puntos       SMALLINT,
    OUT p_mensaje      VARCHAR(200)
)
BEGIN
    DECLARE v_historial_existe INT DEFAULT 0;
    DECLARE v_cp               INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_historial_existe
    FROM historial_equipo
    WHERE id_historial_equipo = p_id_historial;

    IF v_historial_existe = 0 THEN
        SET p_mensaje = 'Error: el historial indicado no existe.';

    ELSEIF p_tipo_split NOT IN ('Spring', 'Summer') THEN
        SET p_mensaje = 'Error: el tipo de split debe ser Spring o Summer.';

    ELSEIF p_posicion < 1 OR p_posicion > 10 THEN
        SET p_mensaje = 'Error: la posición debe estar entre 1 y 10.';

    ELSE
        SET v_cp = CASE p_tipo_split
            WHEN 'Spring' THEN CASE p_posicion
                WHEN 1 THEN 145 WHEN 2 THEN 120 WHEN 3 THEN 95 WHEN 4 THEN 70
                WHEN 5 THEN 55  WHEN 6 THEN 55  WHEN 7 THEN 35 WHEN 8 THEN 35 ELSE 0
            END
            WHEN 'Summer' THEN CASE p_posicion
                WHEN 1 THEN 180 WHEN 2 THEN 150 WHEN 3 THEN 120 WHEN 4 THEN 90
                WHEN 5 THEN 65  WHEN 6 THEN 65  WHEN 7 THEN 45  WHEN 8 THEN 45 ELSE 0
            END
        END;

        START TRANSACTION;
            UPDATE historial_equipo
            SET posicion_fase_regular = p_posicion,
                puntos_campeonato     = v_cp
            WHERE id_historial_equipo = p_id_historial;
        COMMIT;

        SET p_puntos  = v_cp;
        SET p_mensaje = CONCAT('Se han asignado ', v_cp, ' Championship Points.');

    END IF;

END$$
DELIMITER ;
-- --- sp_asignar_clasificacion_internacional.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_asignar_clasificacion_internacional;

DELIMITER $$
CREATE PROCEDURE sp_asignar_clasificacion_internacional(
    IN  p_año       YEAR,
    OUT p_mensaje   VARCHAR(200)
)
sp_asignar_clasificacion_internacional: BEGIN

    DECLARE v_id_spring         INT UNSIGNED;
    DECLARE v_id_summer         INT UNSIGNED;
    DECLARE v_campeon_spring    INT UNSIGNED;
    DECLARE v_subcampeon_spring INT UNSIGNED;
    DECLARE v_campeon_summer    INT UNSIGNED;
    DECLARE v_hist_verano       INT UNSIGNED;
    DECLARE v_seed2             INT UNSIGNED;
    DECLARE v_seed3             INT UNSIGNED;
    DECLARE v_registros         INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*) INTO v_registros FROM clasificacion_anual WHERE año = p_año;
    IF v_registros = 0 THEN
        SET p_mensaje = 'Error: no hay registros para ese año.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT id_split INTO v_id_spring FROM split
    WHERE nombre = 'Spring' AND año = p_año LIMIT 1;
    IF v_id_spring IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el Spring Split.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT he.id_equipo INTO v_campeon_spring FROM historial_equipo he
    WHERE he.id_split = v_id_spring AND he.posicion_playoffs = 1 LIMIT 1;
    IF v_campeon_spring IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el campeón del Spring.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT he.id_equipo INTO v_subcampeon_spring FROM historial_equipo he
    WHERE he.id_split = v_id_spring AND he.posicion_playoffs = 2 LIMIT 1;
    IF v_subcampeon_spring IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el subcampeón del Spring.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT id_split INTO v_id_summer FROM split
    WHERE nombre = 'Summer' AND año = p_año LIMIT 1;
    IF v_id_summer IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el Summer Split.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT he.id_equipo, he.id_historial_equipo
    INTO v_campeon_summer, v_hist_verano
    FROM historial_equipo he
    WHERE he.id_split = v_id_summer AND he.posicion_playoffs = 1 LIMIT 1;
    IF v_campeon_summer IS NULL THEN
        SET p_mensaje = 'Error: no se encontró el campeón del Summer.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    SELECT id_equipo INTO v_seed2 FROM clasificacion_anual
    WHERE año = p_año AND id_equipo <> v_campeon_summer
    ORDER BY puntos_totales DESC LIMIT 1;

    SELECT id_equipo INTO v_seed3 FROM clasificacion_anual
    WHERE año = p_año AND id_equipo <> v_campeon_summer AND id_equipo <> v_seed2
    ORDER BY puntos_totales DESC LIMIT 1;

    IF v_seed2 IS NULL OR v_seed3 IS NULL THEN
        SET p_mensaje = 'Error: empate sin desempate claro, requiere intervención manual.';
        LEAVE sp_asignar_clasificacion_internacional;
    END IF;

    START TRANSACTION;
        UPDATE historial_equipo SET clasificado_msi = TRUE
        WHERE id_split = v_id_spring
          AND id_equipo IN (v_campeon_spring, v_subcampeon_spring);

        UPDATE historial_equipo SET seed_worlds = 1
        WHERE id_historial_equipo = v_hist_verano;

        UPDATE clasificacion_anual SET seed_worlds = 1
        WHERE año = p_año AND id_equipo = v_campeon_summer;

        UPDATE clasificacion_anual SET seed_worlds = 2
        WHERE año = p_año AND id_equipo = v_seed2;

        UPDATE clasificacion_anual SET seed_worlds = 3
        WHERE año = p_año AND id_equipo = v_seed3;
    COMMIT;

    SET p_mensaje = CONCAT('Clasificación del año ', p_año, ' asignada correctamente.');
END$$
DELIMITER ;
-- --- sp_10_listar_clasificacion.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_clasificacion;
DELIMITER $$
CREATE PROCEDURE sp_listar_clasificacion(IN p_año YEAR)
BEGIN
    -- Calcula la clasificación directamente desde los resultados de partidos
    -- No depende de clasificacion_anual (puede estar vacía)
    SELECT
        e.id_equipo,
        e.nombre            AS equipo,
        e.pais,
        COUNT(DISTINCT p.id_partido) AS partidos,
        SUM(CASE
            WHEN he.id_historial_equipo = p.id_historial_equipo_1 AND p.mapas_eq1 > p.mapas_eq2 THEN 1
            WHEN he.id_historial_equipo = p.id_historial_equipo_2 AND p.mapas_eq2 > p.mapas_eq1 THEN 1
            ELSE 0 END) AS victorias,
        SUM(CASE
            WHEN he.id_historial_equipo = p.id_historial_equipo_1 AND p.mapas_eq1 < p.mapas_eq2 THEN 1
            WHEN he.id_historial_equipo = p.id_historial_equipo_2 AND p.mapas_eq2 < p.mapas_eq1 THEN 1
            ELSE 0 END) AS derrotas,
        ROUND(100 * SUM(CASE
            WHEN he.id_historial_equipo = p.id_historial_equipo_1 AND p.mapas_eq1 > p.mapas_eq2 THEN 1
            WHEN he.id_historial_equipo = p.id_historial_equipo_2 AND p.mapas_eq2 > p.mapas_eq1 THEN 1
            ELSE 0 END) / GREATEST(COUNT(DISTINCT p.id_partido), 1), 1) AS win_rate,
        SUM(CASE
            WHEN he.id_historial_equipo = p.id_historial_equipo_1 THEN p.mapas_eq1
            WHEN he.id_historial_equipo = p.id_historial_equipo_2 THEN p.mapas_eq2
            ELSE 0 END) AS mapas_ganados,
        SUM(CASE
            WHEN he.id_historial_equipo = p.id_historial_equipo_1 THEN p.mapas_eq2
            WHEN he.id_historial_equipo = p.id_historial_equipo_2 THEN p.mapas_eq1
            ELSE 0 END) AS mapas_perdidos,
        GROUP_CONCAT(DISTINCT s.nombre ORDER BY s.id_split SEPARATOR ', ') AS splits
    FROM equipo e
    JOIN historial_equipo he ON he.id_equipo = e.id_equipo
    JOIN split s ON he.id_split = s.id_split
    JOIN partido p ON (he.id_historial_equipo = p.id_historial_equipo_1
                    OR he.id_historial_equipo = p.id_historial_equipo_2)
    WHERE p.finalizado = TRUE
      AND s.año = p_año
      AND e.activo = TRUE
    GROUP BY e.id_equipo
    HAVING partidos > 0
    ORDER BY victorias DESC, win_rate DESC, mapas_ganados DESC;
END$$
DELIMITER ;


-- --- sp_11_listar_partidos.sql ---
DROP PROCEDURE IF EXISTS sp_listar_partidos;

DELIMITER $$
CREATE PROCEDURE sp_listar_partidos(
    IN p_id_split INT UNSIGNED,
    IN p_finalizado BOOLEAN,
    IN p_año YEAR,
    IN p_split_nombre VARCHAR(10)  
)
BEGIN
    SELECT
        p.id_partido,
        eq1.nombre AS equipo_1,
        eq2.nombre AS equipo_2,
        p.mapas_eq1,
        p.mapas_eq2,
        p.tipo_serie,
        p.fecha_hora,
        p.finalizado,
        fs.tipo AS fase,
        s.nombre AS split,
        s.año AS año,
        s.id_split AS id_split,
        he1.id_equipo AS id_equipo_1,
        he2.id_equipo AS id_equipo_2,
        CASE
            WHEN p.finalizado = TRUE AND p.mapas_eq1 > p.mapas_eq2 THEN eq1.nombre
            WHEN p.finalizado = TRUE AND p.mapas_eq2 > p.mapas_eq1 THEN eq2.nombre
            ELSE NULL
        END AS ganador

    FROM partido p
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split

    WHERE
        (p_id_split IS NULL OR s.id_split = p_id_split)
        AND (p_finalizado IS NULL OR p.finalizado = p_finalizado)
        AND (p_año IS NULL OR s.año = p_año)
        AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)

    ORDER BY p.fecha_hora DESC;
END$$
DELIMITER ;
-- --- sp_12_listar_equipos.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_equipos;

DELIMITER $$
CREATE PROCEDURE sp_listar_equipos(
    IN p_id_split       INT UNSIGNED,
    IN p_año            YEAR,
    IN p_split_nombre   VARCHAR(10)
)
BEGIN
    SELECT
        e.id_equipo,
        e.nombre,
        e.pais,
        e.fundacion,
        e.activo,
        (SELECT COUNT(*)
         FROM jugador_equipo_historial jeh
         JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo
           AND jeh.es_titular = TRUE
           AND jeh.fecha_fin IS NULL
           AND (p_id_split     IS NULL OR he.id_split = p_id_split)
           AND (p_año          IS NULL OR s.año = p_año)
           AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
        ) AS titulares,
        (SELECT he.id_historial_equipo
         FROM historial_equipo he
         JOIN split s ON he.id_split = s.id_split
         WHERE he.id_equipo = e.id_equipo
           AND (p_id_split     IS NULL OR he.id_split = p_id_split)
           AND (p_año          IS NULL OR s.año = p_año)
           AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
         ORDER BY he.id_historial_equipo DESC
         LIMIT 1
        ) AS id_historial

    FROM equipo e
    WHERE e.activo = TRUE
      AND EXISTS (
          SELECT 1 FROM historial_equipo he
          JOIN split s ON he.id_split = s.id_split
          WHERE he.id_equipo = e.id_equipo
            AND (p_id_split     IS NULL OR he.id_split = p_id_split)
            AND (p_año          IS NULL OR s.año = p_año)
            AND (p_split_nombre IS NULL OR s.nombre = p_split_nombre)
      )
    ORDER BY e.nombre ASC;
END$$
DELIMITER ;

-- --- sp_13_listar_jugadores_equipo.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_jugadores_equipo;
DELIMITER $$
CREATE PROCEDURE sp_listar_jugadores_equipo(
    IN p_id_equipo INT,
    IN p_id_split INT,
    IN p_año YEAR,
    IN p_split_nombre VARCHAR(10)
)
BEGIN
    -- Si no hay filtro, usar automáticamente el split más reciente del equipo
    DECLARE v_split_max INT DEFAULT NULL;

    IF p_id_split IS NULL AND p_año IS NULL AND p_split_nombre IS NULL THEN
        SELECT MAX(he.id_split) INTO v_split_max
        FROM historial_equipo he
        WHERE he.id_equipo = p_id_equipo;
    ELSE
        SET v_split_max = p_id_split;
    END IF;

    SELECT
        j.id_jugador,
        j.nickname,
        j.nombre_real,
        j.nacionalidad,
        j.fecha_nacimiento,
        MAX(jeh.rol)         AS rol,
        MAX(jeh.es_titular)  AS es_titular,
        MIN(jeh.fecha_inicio) AS fecha_inicio,
        MAX(jeh.fecha_fin)   AS fecha_fin,
        TIMESTAMPDIFF(YEAR, j.fecha_nacimiento, CURDATE()) AS edad

    FROM jugador j
    JOIN jugador_equipo_historial jeh ON j.id_jugador = jeh.id_jugador
    JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
    JOIN split s ON he.id_split = s.id_split

    WHERE he.id_equipo = p_id_equipo
      AND j.activo = TRUE
      AND (v_split_max IS NULL OR he.id_split = v_split_max)
      AND (p_año IS NULL OR s.año = p_año)
      AND (p_split_nombre IS NULL OR s.nombre LIKE CONCAT('%', p_split_nombre, '%'))

    GROUP BY j.id_jugador

    ORDER BY
        MAX(jeh.es_titular) DESC,
        FIELD(MAX(jeh.rol), 'Top','Jungle','Mid','ADC','Support'),
        j.nickname ASC;
END$$
DELIMITER ;

-- --- sp_14_actualizar_resultado.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_actualizar_resultado;
DELIMITER $$
CREATE PROCEDURE sp_actualizar_resultado(
    IN  p_id_partido    INT UNSIGNED,
    IN  p_mapas_eq1     TINYINT UNSIGNED,
    IN  p_mapas_eq2     TINYINT UNSIGNED,
    OUT p_mensaje       VARCHAR(200)
)
sp_actualizar_resultado: BEGIN
    DECLARE v_tipo_serie    VARCHAR(5);
    DECLARE v_id_split      INT UNSIGNED;
    DECLARE v_split_cerrado DATE;
    DECLARE v_finalizado    BOOLEAN;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT p.tipo_serie, p.finalizado, s.fecha_fin, s.id_split
    INTO v_tipo_serie, v_finalizado, v_split_cerrado, v_id_split
    FROM partido p
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split
    WHERE p.id_partido = p_id_partido;

    IF v_tipo_serie IS NULL THEN
        SET p_mensaje = 'Error: el partido indicado no existe.';
        LEAVE sp_actualizar_resultado;
    END IF;

    IF v_split_cerrado IS NOT NULL THEN
        SET p_mensaje = 'Error: no se puede modificar un partido de una temporada cerrada.';
        LEAVE sp_actualizar_resultado;
    END IF;

    -- ↓ Cambiado p_tipo_serie por v_tipo_serie en los tres IF
    IF v_tipo_serie = 'Bo1' AND (p_mapas_eq1 > 1 OR p_mapas_eq2 > 1) THEN
        SET p_mensaje = 'Error: en un Bo1 el máximo de mapas por equipo es 1.';
        LEAVE sp_actualizar_resultado;
    END IF;

    IF v_tipo_serie = 'Bo3' AND (p_mapas_eq1 > 2 OR p_mapas_eq2 > 2) THEN
        SET p_mensaje = 'Error: en un Bo3 el máximo de mapas por equipo es 2.';
        LEAVE sp_actualizar_resultado;
    END IF;

    IF v_tipo_serie = 'Bo5' AND (p_mapas_eq1 > 3 OR p_mapas_eq2 > 3) THEN
        SET p_mensaje = 'Error: en un Bo5 el máximo de mapas por equipo es 3.';
        LEAVE sp_actualizar_resultado;
    END IF;

    START TRANSACTION;
        UPDATE partido
        SET mapas_eq1  = p_mapas_eq1,
            mapas_eq2  = p_mapas_eq2,
            finalizado = fn_serie_terminada(p_mapas_eq1, p_mapas_eq2, v_tipo_serie)
        WHERE id_partido = p_id_partido;
    COMMIT;

    SET p_mensaje = CONCAT('Resultado del partido ', p_id_partido, ' actualizado correctamente.');

END$$
DELIMITER ;
-- --- sp_15_eliminar_partido.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_eliminar_partido;

DELIMITER $$
CREATE PROCEDURE sp_eliminar_partido(
    IN  p_id_partido    INT UNSIGNED,
    IN  p_forzar        BOOLEAN, 
    OUT p_mensaje       VARCHAR(200)
)
sp_eliminar_partido: BEGIN

    DECLARE v_existe        INT DEFAULT 0;
    DECLARE v_split_cerrado DATE;
    DECLARE v_num_mapas     INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    SELECT COUNT(*), s.fecha_fin
    INTO v_existe, v_split_cerrado
    FROM partido p
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split
    WHERE p.id_partido = p_id_partido;

    IF v_existe = 0 THEN
        SET p_mensaje = 'Error: el partido indicado no existe.';
        LEAVE sp_eliminar_partido;
    END IF;

    IF v_split_cerrado IS NOT NULL THEN
        SET p_mensaje = 'Error: no se puede eliminar un partido de una temporada cerrada.';
        LEAVE sp_eliminar_partido;
    END IF;


    SELECT COUNT(*) INTO v_num_mapas
    FROM mapa WHERE id_partido = p_id_partido;

    IF v_num_mapas > 0 AND p_forzar = FALSE THEN
        SET p_mensaje = CONCAT('Error: el partido tiene ', v_num_mapas, ' mapa(s) registrado(s). Usa p_forzar = TRUE para eliminar igualmente.');
        LEAVE sp_eliminar_partido;
    END IF;

    START TRANSACTION;

        DELETE FROM partido WHERE id_partido = p_id_partido;

    COMMIT;

    SET p_mensaje = CONCAT('Partido ', p_id_partido, ' eliminado correctamente.');

END$$
DELIMITER ;


-- --- sp_16_insertar_equipo.sql ---
USE LEC;
DROP PROCEDURE IF EXISTS sp_insertar_equipo;
DELIMITER $$
CREATE PROCEDURE sp_insertar_equipo(
    IN  p_nombre        VARCHAR(50),
    IN  p_pais          VARCHAR(50),
    IN  p_fundacion     DATE,
    IN  p_año           YEAR,
    IN  p_split_nombre  VARCHAR(10),
    OUT p_id_equipo     INT UNSIGNED,
    OUT p_mensaje       VARCHAR(200)
)
BEGIN
    DECLARE v_nombre_existe INT DEFAULT 0;
    DECLARE v_id_split      INT UNSIGNED;
    DECLARE v_msg_split     VARCHAR(200);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_equipo = NULL;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SET p_mensaje = 'Error: el nombre del equipo no puede estar vacío.';

    ELSE
        SELECT COUNT(*) INTO v_nombre_existe
        FROM equipo WHERE nombre = p_nombre;

        IF v_nombre_existe > 0 THEN
            SET p_mensaje = CONCAT('Error: ya existe un equipo con el nombre "', p_nombre, '".');

        ELSE
            IF p_año IS NOT NULL AND p_split_nombre IS NOT NULL THEN
                SELECT id_split INTO v_id_split
                FROM split
                WHERE año = p_año AND nombre = p_split_nombre
                LIMIT 1;
            END IF;

            IF p_año IS NOT NULL AND p_split_nombre IS NOT NULL AND v_id_split IS NULL THEN
                SET p_mensaje = CONCAT('Error: no existe el split ', p_split_nombre, ' ', p_año, '.');

            ELSE
                START TRANSACTION;
                    INSERT INTO equipo (nombre, pais, fundacion, activo)
                    VALUES (p_nombre, p_pais, p_fundacion, TRUE);
                    SET p_id_equipo = LAST_INSERT_ID();
                COMMIT;

                IF v_id_split IS NOT NULL THEN
                    CALL sp_registrar_equipo_split(p_id_equipo, v_id_split, @hist, v_msg_split);
                    SET p_mensaje = CONCAT('Equipo "', p_nombre, '" creado con ID: ', p_id_equipo, '. ', v_msg_split);
                ELSE
                    SET p_mensaje = CONCAT('Equipo "', p_nombre, '" creado con ID: ', p_id_equipo, '.');
                END IF;

            END IF;
        END IF;
    END IF;

END$$
DELIMITER ;
-- --- sp_17_gestionar_jugador.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_gestionar_jugador;

DELIMITER $$
CREATE PROCEDURE sp_gestionar_jugador(
    IN  p_id_jugador    INT UNSIGNED,
    IN  p_accion        VARCHAR(10),   
    IN  p_nuevo_rol     ENUM('Top','Jungle','Mid','ADC','Support'), 
    IN  p_fecha_fin     DATE,       
    IN  p_forzar        BOOLEAN,        
    OUT p_mensaje       VARCHAR(200)
)
sp_gestionar_jugador: BEGIN

    DECLARE v_id_historial          INT UNSIGNED;
    DECLARE v_rol_actual            VARCHAR(10);
    DECLARE v_es_titular            BOOLEAN;
    DECLARE v_id_split              INT UNSIGNED;
    DECLARE v_titular_exist         INT DEFAULT 0;
    DECLARE v_id_titular_anterior   INT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;


    IF p_accion NOT IN ('TITULAR', 'SUPLENTE', 'ROL', 'BAJA') THEN
        SET p_mensaje = 'Error: acción no válida. Usa TITULAR, SUPLENTE, ROL o BAJA.';
        LEAVE sp_gestionar_jugador;
    END IF;

 
    SELECT jeh.id_historial_equipo, jeh.rol, jeh.es_titular
    INTO v_id_historial, v_rol_actual, v_es_titular
    FROM jugador_equipo_historial jeh
    WHERE jeh.id_jugador = p_id_jugador
      AND jeh.fecha_fin IS NULL
    LIMIT 1;

    IF v_id_historial IS NULL THEN
        SET p_mensaje = 'Error: el jugador no tiene ningún contrato activo.';
        LEAVE sp_gestionar_jugador;
    END IF;


    IF p_accion = 'TITULAR' THEN


        SELECT COUNT(*), id_jugador
        INTO v_titular_exist, v_id_titular_anterior
        FROM jugador_equipo_historial
        WHERE id_historial_equipo = v_id_historial
          AND rol = v_rol_actual
          AND es_titular = TRUE
          AND id_jugador <> p_id_jugador
          AND fecha_fin IS NULL
        LIMIT 1;

        IF v_titular_exist > 0 AND p_forzar = FALSE THEN
            SET p_mensaje = CONCAT('Error: ya hay un titular en el rol ', v_rol_actual,
                                   '. Usa p_forzar = TRUE para bajarlo a suplente.');
            LEAVE sp_gestionar_jugador;
        END IF;

        START TRANSACTION;
    
            IF v_titular_exist > 0 AND p_forzar = TRUE THEN
                UPDATE jugador_equipo_historial
                SET es_titular = FALSE
                WHERE id_jugador = v_id_titular_anterior
                  AND id_historial_equipo = v_id_historial
                  AND fecha_fin IS NULL;
            END IF;
        
            UPDATE jugador_equipo_historial
            SET es_titular = TRUE
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' puesto como titular correctamente.');


    ELSEIF p_accion = 'SUPLENTE' THEN

        START TRANSACTION;
            UPDATE jugador_equipo_historial
            SET es_titular = FALSE
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' puesto como suplente correctamente.');


    ELSEIF p_accion = 'ROL' THEN

        IF p_nuevo_rol IS NULL THEN
            SET p_mensaje = 'Error: debes indicar el nuevo rol.';
            LEAVE sp_gestionar_jugador;
        END IF;


        IF v_es_titular = TRUE THEN
            SELECT COUNT(*) INTO v_titular_exist
            FROM jugador_equipo_historial
            WHERE id_historial_equipo = v_id_historial
              AND rol = p_nuevo_rol
              AND es_titular = TRUE
              AND id_jugador <> p_id_jugador
              AND fecha_fin IS NULL;

            IF v_titular_exist > 0 THEN
                SET p_mensaje = CONCAT('Error: ya hay un titular en el rol ', p_nuevo_rol, '.');
                LEAVE sp_gestionar_jugador;
            END IF;
        END IF;

        START TRANSACTION;
            UPDATE jugador_equipo_historial
            SET rol = p_nuevo_rol
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Rol del jugador ', p_id_jugador, ' cambiado a ', p_nuevo_rol, '.');


    ELSEIF p_accion = 'BAJA' THEN

        IF p_fecha_fin IS NULL THEN
            SET p_mensaje = 'Error: debes indicar la fecha de fin del contrato.';
            LEAVE sp_gestionar_jugador;
        END IF;

  
        SET v_id_split = fn_get_split_de_historial(v_id_historial);

        IF fn_split_en_curso(v_id_split) THEN
            SET p_mensaje = 'Error: no se puede dar de baja a un jugador durante el split (regla LEC).';
            LEAVE sp_gestionar_jugador;
        END IF;

        START TRANSACTION;
         
            UPDATE jugador_equipo_historial
            SET fecha_fin = p_fecha_fin
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' dado de baja correctamente.');

    END IF;

END$$
DELIMITER ;

-- --- sp_18_listar_splits.sql ---
USE LEC;

DROP PROCEDURE IF EXISTS sp_listar_splits;

DELIMITER $$
CREATE PROCEDURE sp_listar_splits(
    IN p_solo_abiertos BOOLEAN  
)
BEGIN
    SELECT
        id_split,
        nombre,
        año,
        fecha_inicio,
        fecha_fin,
        fecha_fin IS NULL AS esta_abierto,
        
        CASE nombre
            WHEN 'Winter' THEN 'LEC Versus'
            ELSE nombre
        END AS nombre_display,
        CONCAT(
            CASE nombre WHEN 'Winter' THEN 'LEC Versus' ELSE nombre END,
            ' ', año
        ) AS nombre_completo

    FROM split
    WHERE (p_solo_abiertos IS NULL OR p_solo_abiertos = FALSE
           OR fecha_fin IS NULL)
    ORDER BY año DESC, FIELD(nombre, 'Summer', 'Spring', 'Winter');
END$$
DELIMITER ;



-- --- sp_19_detalle_partido.sql ---
USE lec;
DROP PROCEDURE IF EXISTS sp_detalle_partido;
DELIMITER $$
CREATE PROCEDURE sp_detalle_partido(IN p_id_partido INT UNSIGNED)
BEGIN
    SELECT
        p.id_partido,
        eq1.nombre AS equipo_1, eq2.nombre AS equipo_2,
        he1.id_equipo AS id_equipo_1, he2.id_equipo AS id_equipo_2,
        p.mapas_eq1, p.mapas_eq2, p.tipo_serie,
        p.fecha_hora, p.finalizado,
        fs.tipo AS fase,
        CASE s.nombre WHEN 'Winter' THEN 'LEC Versus' ELSE s.nombre END AS split,
        s.año,
        CASE
            WHEN p.finalizado = TRUE AND p.mapas_eq1 > p.mapas_eq2 THEN eq1.nombre
            WHEN p.finalizado = TRUE AND p.mapas_eq2 > p.mapas_eq1 THEN eq2.nombre
            ELSE NULL
        END AS ganador
    FROM partido p
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    JOIN fase_split fs ON p.id_fase = fs.id_fase
    JOIN split s ON fs.id_split = s.id_split
    WHERE p.id_partido = p_id_partido;

    SELECT
        m.numero_mapa, m.duracion_minutos,
        CASE
            WHEN m.ganador = he1.id_historial_equipo THEN eq1.nombre
            WHEN m.ganador = he2.id_historial_equipo THEN eq2.nombre
            ELSE NULL
        END AS equipo_ganador
    FROM mapa m
    JOIN partido p ON m.id_partido = p.id_partido
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    WHERE m.id_partido = p_id_partido
    ORDER BY m.numero_mapa ASC;

    SELECT
        ej.numero_mapa, j.nickname, j.id_jugador,
        jeh.rol AS rol_jugado,
        ej.campeon, ej.kills, ej.deaths, ej.assists, ej.cs, ej.oro,
        ROUND((ej.kills + ej.assists) / GREATEST(ej.deaths, 1), 2) AS kda,
        CASE
            WHEN jeh.id_historial_equipo = p.id_historial_equipo_1 THEN eq1.nombre
            ELSE eq2.nombre
        END AS equipo
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



USE LEC;

DROP PROCEDURE IF EXISTS sp_buscar_jugador;

DELIMITER $$
CREATE PROCEDURE sp_buscar_jugador(
    IN p_nickname       VARCHAR(30),   
    IN p_nacionalidad   VARCHAR(50),    
    IN p_rol            VARCHAR(10)     
)
BEGIN
    SELECT
        j.id_jugador,
        j.nickname,
        j.nombre_real,
        j.nacionalidad,
        j.rol_principal,
        j.activo,
        TIMESTAMPDIFF(YEAR, j.fecha_nacimiento, CURDATE()) AS edad,
   
        (SELECT e.nombre FROM jugador_equipo_historial jeh
         JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
         JOIN equipo e ON he.id_equipo = e.id_equipo
         WHERE jeh.id_jugador = j.id_jugador AND jeh.fecha_fin IS NULL
         LIMIT 1)                                           AS equipo_actual,
 
        (SELECT CONCAT(CASE s.nombre WHEN 'Winter' THEN 'LEC Versus' ELSE s.nombre END, ' ', s.año)
         FROM jugador_equipo_historial jeh
         JOIN historial_equipo he ON jeh.id_historial_equipo = he.id_historial_equipo
         JOIN split s ON he.id_split = s.id_split
         WHERE jeh.id_jugador = j.id_jugador AND jeh.fecha_fin IS NULL
         LIMIT 1)                                           AS split_actual

    FROM jugador j
    WHERE (p_nickname     IS NULL OR j.nickname LIKE CONCAT('%', p_nickname, '%'))
      AND (p_nacionalidad IS NULL OR j.nacionalidad = p_nacionalidad)
      AND (p_rol          IS NULL OR j.rol_principal = p_rol)
    ORDER BY j.nickname ASC;
END$$
DELIMITER ;


USE LEC;












-- ============================================================
-- UNIFICAR COLLATION EN TODAS LAS TABLAS
-- Evita error "Illegal mix of collations"
-- ============================================================
USE lec;

ALTER TABLE equipo                   CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE jugador                  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE entrenador               CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE split                    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE fase_split               CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE historial_equipo         CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE jugador_equipo_historial CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE entrenador_equipo_historial CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE partido                  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE mapa                     CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE estadistica_jugador      CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE clasificacion_anual      CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE auditoria_lec            CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- ALTER usuarios_admin: se ejecuta al final


-- Actualizar collation por defecto de la base de datos
ALTER DATABASE lec CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- FLUSH PRIVILEGES; (no necesario — los GRANT se aplican automáticamente en MariaDB)

USE LEC;

-- usuarios_admin: definida al final del script


-- ============================================================
-- PROCEDIMIENTOS PARA ESTADÍSTICAS Y PANEL WEB
-- ============================================================

-- ── sp_top_kda ───────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_top_kda;
DELIMITER $$
CREATE PROCEDURE sp_top_kda(IN p_id_split INT, IN p_limite INT)
BEGIN
    SELECT j.nickname, j.rol_principal, e.nombre AS equipo,
           ROUND(SUM(ej.kills+ej.assists)/GREATEST(SUM(ej.deaths),1),2) AS kda,
           SUM(ej.kills) AS kills, SUM(ej.deaths) AS deaths, SUM(ej.assists) AS assists,
           COUNT(DISTINCT CONCAT(ej.id_partido,'_',ej.numero_mapa)) AS mapas
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador=j.id_jugador
    JOIN partido p ON ej.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    JOIN jugador_equipo_historial jeh ON j.id_jugador=jeh.id_jugador
        AND jeh.id_historial_equipo IN (p.id_historial_equipo_1,p.id_historial_equipo_2)
    JOIN historial_equipo he ON jeh.id_historial_equipo=he.id_historial_equipo
    JOIN equipo e ON he.id_equipo=e.id_equipo
    WHERE p.finalizado=TRUE AND (p_id_split IS NULL OR fs.id_split=p_id_split)
    GROUP BY j.id_jugador, e.nombre
    HAVING mapas >= 2
    ORDER BY kda DESC
    LIMIT p_limite;
END$$
DELIMITER ;

-- ── sp_top_cs ────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_top_cs;
DELIMITER $$
CREATE PROCEDURE sp_top_cs(IN p_id_split INT, IN p_limite INT)
BEGIN
    SELECT j.nickname, j.rol_principal, e.nombre AS equipo,
           ROUND(AVG(ej.cs),0) AS cs_promedio,
           ROUND(AVG(ej.cs*1.0/GREATEST(m.duracion_minutos,1)),1) AS cs_min,
           COUNT(*) AS mapas
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador=j.id_jugador
    JOIN partido p ON ej.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    JOIN mapa m ON ej.id_partido=m.id_partido AND ej.numero_mapa=m.numero_mapa
    JOIN jugador_equipo_historial jeh ON j.id_jugador=jeh.id_jugador
        AND jeh.id_historial_equipo IN (p.id_historial_equipo_1,p.id_historial_equipo_2)
    JOIN historial_equipo he ON jeh.id_historial_equipo=he.id_historial_equipo
    JOIN equipo e ON he.id_equipo=e.id_equipo
    WHERE p.finalizado=TRUE AND j.rol_principal IN ('ADC','Mid','Top')
      AND (p_id_split IS NULL OR fs.id_split=p_id_split)
    GROUP BY j.id_jugador, e.nombre
    HAVING mapas >= 2
    ORDER BY cs_promedio DESC
    LIMIT p_limite;
END$$
DELIMITER ;

-- ── sp_win_rate_equipos ──────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_win_rate_equipos;
DELIMITER $$
CREATE PROCEDURE sp_win_rate_equipos(IN p_id_split INT)
BEGIN
    SELECT nombre, id_equipo, partidos, victorias
    FROM (
        SELECT e.nombre, e.id_equipo,
               COUNT(DISTINCT p.id_partido) AS partidos,
               SUM(CASE
                   WHEN he.id_historial_equipo=p.id_historial_equipo_1 AND p.mapas_eq1>p.mapas_eq2 THEN 1
                   WHEN he.id_historial_equipo=p.id_historial_equipo_2 AND p.mapas_eq2>p.mapas_eq1 THEN 1
                   ELSE 0 END) AS victorias
        FROM historial_equipo he
        JOIN equipo e ON he.id_equipo=e.id_equipo
        JOIN partido p ON (he.id_historial_equipo=p.id_historial_equipo_1
                        OR he.id_historial_equipo=p.id_historial_equipo_2)
        JOIN fase_split fs ON p.id_fase=fs.id_fase
        WHERE p.finalizado=TRUE AND e.activo=TRUE
          AND (p_id_split IS NULL OR fs.id_split=p_id_split)
        GROUP BY e.id_equipo
    ) sub WHERE sub.partidos > 0
    ORDER BY sub.victorias*1.0/sub.partidos DESC;
END$$
DELIMITER ;

-- ── sp_stats_por_rol ─────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_stats_por_rol;
DELIMITER $$
CREATE PROCEDURE sp_stats_por_rol(IN p_id_split INT)
BEGIN
    SELECT j.rol_principal AS rol,
           ROUND(AVG(ej.kills),1) AS kills_prom,
           ROUND(AVG(ej.deaths),1) AS deaths_prom,
           ROUND(AVG(ej.assists),1) AS assists_prom,
           ROUND(SUM(ej.kills+ej.assists)/GREATEST(SUM(ej.deaths),1),2) AS kda
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador=j.id_jugador
    JOIN partido p ON ej.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    WHERE p.finalizado=TRUE
      AND (p_id_split IS NULL OR fs.id_split=p_id_split)
    GROUP BY j.rol_principal
    ORDER BY FIELD(j.rol_principal,'Top','Jungle','Mid','ADC','Support');
END$$
DELIMITER ;

-- ── sp_stats_jugador ─────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_stats_jugador;
DELIMITER $$
CREATE PROCEDURE sp_stats_jugador(IN p_id_jugador INT, IN p_id_split INT)
BEGIN
    SELECT j.nickname,
           ROUND(SUM(ej.kills+ej.assists)/GREATEST(SUM(ej.deaths),1),2) AS kda,
           ROUND(AVG(ej.kills),2) AS kills,
           ROUND(AVG(ej.assists),2) AS assists,
           ROUND(AVG(ej.cs),1) AS cs,
           COUNT(*) AS mapas,
           SUM(CASE
               WHEN p.id_historial_equipo_1 IN (SELECT jeh2.id_historial_equipo FROM jugador_equipo_historial jeh2 WHERE jeh2.id_jugador=j.id_jugador) AND p.mapas_eq1>p.mapas_eq2 THEN 1
               WHEN p.id_historial_equipo_2 IN (SELECT jeh2.id_historial_equipo FROM jugador_equipo_historial jeh2 WHERE jeh2.id_jugador=j.id_jugador) AND p.mapas_eq2>p.mapas_eq1 THEN 1
               ELSE 0 END) AS wins
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador=j.id_jugador
    JOIN partido p ON ej.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    WHERE j.id_jugador=p_id_jugador AND p.finalizado=TRUE
      AND (p_id_split IS NULL OR fs.id_split=p_id_split)
    GROUP BY j.id_jugador;
END$$
DELIMITER ;

-- ── sp_get_partido ───────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_get_partido;
DELIMITER $$
CREATE PROCEDURE sp_get_partido(IN p_id_partido INT)
BEGIN
    SELECT p.*,
           eq1.nombre AS equipo_1, eq2.nombre AS equipo_2,
           he1.id_historial_equipo AS hist1,
           he2.id_historial_equipo AS hist2,
           s.año AS año_split, s.nombre AS nombre_split
    FROM partido p
    JOIN historial_equipo he1 ON p.id_historial_equipo_1=he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2=he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo=eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo=eq2.id_equipo
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    JOIN split s ON fs.id_split=s.id_split
    WHERE p.id_partido=p_id_partido;
END$$
DELIMITER ;

-- ── sp_get_jugadores_historial ───────────────────────────────
DROP PROCEDURE IF EXISTS sp_get_jugadores_historial;
DELIMITER $$
CREATE PROCEDURE sp_get_jugadores_historial(IN p_id_historial INT)
BEGIN
    SELECT j.id_jugador, j.nickname, jeh.rol
    FROM jugador_equipo_historial jeh
    JOIN jugador j ON jeh.id_jugador=j.id_jugador
    WHERE jeh.id_historial_equipo=p_id_historial AND jeh.es_titular=TRUE
    ORDER BY FIELD(jeh.rol,'Top','Jungle','Mid','ADC','Support');
END$$
DELIMITER ;

-- ── sp_get_mapas_partido ─────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_get_mapas_partido;
DELIMITER $$
CREATE PROCEDURE sp_get_mapas_partido(IN p_id_partido INT)
BEGIN
    SELECT * FROM mapa WHERE id_partido=p_id_partido ORDER BY numero_mapa ASC;
END$$
DELIMITER ;

-- ── sp_get_stats_partido ─────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_get_stats_partido;
DELIMITER $$
CREATE PROCEDURE sp_get_stats_partido(IN p_id_partido INT)
BEGIN
    SELECT * FROM estadistica_jugador WHERE id_partido=p_id_partido;
END$$
DELIMITER ;

-- ── sp_guardar_marcador ──────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_guardar_marcador;
DELIMITER $$
CREATE PROCEDURE sp_guardar_marcador(
    IN  p_id_partido INT, IN p_mapas_eq1 INT,
    IN  p_mapas_eq2  INT, IN p_finalizado TINYINT(1),
    OUT p_mensaje    VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_mensaje = 'Error al guardar el marcador.'; END;
    UPDATE partido SET mapas_eq1=p_mapas_eq1, mapas_eq2=p_mapas_eq2, finalizado=p_finalizado
    WHERE id_partido=p_id_partido;
    SET p_mensaje = 'Marcador guardado correctamente.';
END$$
DELIMITER ;

-- ── sp_guardar_mapa ──────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_guardar_mapa;
DELIMITER $$
CREATE PROCEDURE sp_guardar_mapa(
    IN  p_id_partido  INT, IN p_numero_mapa INT,
    IN  p_duracion    INT, IN p_ganador     INT,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_mensaje = 'Error al guardar el mapa.'; END;
    SELECT COUNT(*) INTO v_existe FROM mapa WHERE id_partido=p_id_partido AND numero_mapa=p_numero_mapa;
    IF v_existe > 0 THEN
        UPDATE mapa SET duracion_minutos=p_duracion, ganador=p_ganador
        WHERE id_partido=p_id_partido AND numero_mapa=p_numero_mapa;
        SET p_mensaje = 'Mapa actualizado correctamente.';
    ELSE
        INSERT INTO mapa (id_partido,numero_mapa,duracion_minutos,ganador)
        VALUES (p_id_partido,p_numero_mapa,p_duracion,p_ganador);
        SET p_mensaje = 'Mapa registrado correctamente.';
    END IF;
END$$
DELIMITER ;

-- ── sp_get_jugadores_comparador ──────────────────────────────
DROP PROCEDURE IF EXISTS sp_get_jugadores_comparador;
DELIMITER $$
CREATE PROCEDURE sp_get_jugadores_comparador()
BEGIN
    SELECT DISTINCT j.id_jugador, j.nickname, j.rol_principal
    FROM jugador j
    JOIN estadistica_jugador ej ON j.id_jugador=ej.id_jugador
    ORDER BY j.rol_principal, j.nickname;
END$$
DELIMITER ;

-- ── sp_get_splits_con_stats ──────────────────────────────────
DROP PROCEDURE IF EXISTS sp_get_splits_con_stats;
DELIMITER $$
CREATE PROCEDURE sp_get_splits_con_stats()
BEGIN
    SELECT DISTINCT s.id_split, s.nombre, s.año
    FROM split s
    JOIN fase_split fs ON s.id_split=fs.id_split
    JOIN partido p ON p.id_fase=fs.id_fase
    JOIN estadistica_jugador ej ON ej.id_partido=p.id_partido
    ORDER BY s.año DESC, s.id_split DESC;
END$$
DELIMITER ;

USE lec;

-- usuarios_admin y sus datos: al final del script

-- ============================================================
-- PROCEDIMIENTOS DE ESTADÍSTICAS Y PANEL ADMIN
-- ============================================================

-- 2. PROCEDIMIENTOS DE ESTADÍSTICAS
-- ============================================================


-- sp_top_kda: ya definido arriba



-- sp_top_cs: ya definido arriba



-- sp_win_rate_equipos: ya definido arriba



-- sp_stats_por_rol: ya definido arriba



-- sp_stats_jugador: ya definido arriba



-- sp_get_jugadores_comparador: ya definido arriba


-- ============================================================
-- 3. PROCEDIMIENTOS PARA EL PANEL ADMIN
-- ============================================================


-- sp_get_partido: ya definido arriba



-- sp_get_jugadores_historial: ya definido arriba



-- sp_get_mapas_partido: ya definido arriba



-- sp_get_stats_partido: ya definido arriba



-- sp_guardar_marcador: ya definido arriba



-- sp_guardar_mapa: ya definido arriba



-- sp_get_splits_con_stats: ya definido arriba


DROP PROCEDURE IF EXISTS sp_get_entrenador_equipo;
DELIMITER $$
CREATE PROCEDURE sp_get_entrenador_equipo(IN p_id_equipo INT, IN p_id_split INT)
BEGIN
    DECLARE v_split_max INT DEFAULT NULL;

    IF p_id_split IS NULL THEN
        SELECT MAX(he.id_split) INTO v_split_max
        FROM historial_equipo he WHERE he.id_equipo = p_id_equipo;
    ELSE
        SET v_split_max = p_id_split;
    END IF;

    SELECT e.id_entrenador, e.nickname, e.nombre, 'Head Coach' AS rol
    FROM entrenador e
    JOIN entrenador_equipo_historial eeh ON e.id_entrenador = eeh.id_entrenador
    JOIN historial_equipo he ON eeh.id_historial_equipo = he.id_historial_equipo
    WHERE he.id_equipo = p_id_equipo
      AND he.id_split = v_split_max
    ORDER BY e.id_entrenador;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_listar_años;
DELIMITER $$
CREATE PROCEDURE sp_listar_años()
BEGIN
    SELECT DISTINCT año FROM split ORDER BY año DESC;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_listar_fases_split;
DELIMITER $$
CREATE PROCEDURE sp_listar_fases_split(IN p_id_split INT)
BEGIN
    SELECT id_fase, tipo, formato
    FROM fase_split
    WHERE id_split = p_id_split
    ORDER BY id_fase ASC;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_listar_historiales_split;
DELIMITER $$
CREATE PROCEDURE sp_listar_historiales_split(IN p_id_split INT)
BEGIN
    SELECT he.id_historial_equipo, e.nombre
    FROM historial_equipo he
    JOIN equipo e ON he.id_equipo = e.id_equipo
    WHERE he.id_split = p_id_split
    ORDER BY e.nombre ASC;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_obtener_partido_admin;
DELIMITER $$
CREATE PROCEDURE sp_obtener_partido_admin(IN p_id_partido INT)
BEGIN
    SELECT p.id_partido, p.mapas_eq1, p.mapas_eq2, p.tipo_serie, p.finalizado,
           eq1.nombre AS equipo_1, eq2.nombre AS equipo_2,
           COUNT(m.id_partido) AS num_mapas
    FROM partido p
    JOIN historial_equipo he1 ON p.id_historial_equipo_1 = he1.id_historial_equipo
    JOIN historial_equipo he2 ON p.id_historial_equipo_2 = he2.id_historial_equipo
    JOIN equipo eq1 ON he1.id_equipo = eq1.id_equipo
    JOIN equipo eq2 ON he2.id_equipo = eq2.id_equipo
    LEFT JOIN mapa m ON p.id_partido = m.id_partido
    WHERE p.id_partido = p_id_partido
    GROUP BY p.id_partido;
END$$
DELIMITER ;


-- ============================================================
-- SPS ESTADÍSTICAS (métricas gol.gg)
-- ============================================================

DROP PROCEDURE IF EXISTS sp_win_rate_jugadores;
DELIMITER $$
CREATE PROCEDURE sp_win_rate_jugadores(IN p_id_split INT, IN p_limite INT)
BEGIN
    SELECT j.nickname, j.rol_principal, e.nombre AS equipo,
           COUNT(*) AS partidos,
           SUM(CASE
               WHEN p.id_historial_equipo_1 IN (SELECT jeh2.id_historial_equipo FROM jugador_equipo_historial jeh2 WHERE jeh2.id_jugador=j.id_jugador) AND p.mapas_eq1>p.mapas_eq2 THEN 1
               WHEN p.id_historial_equipo_2 IN (SELECT jeh2.id_historial_equipo FROM jugador_equipo_historial jeh2 WHERE jeh2.id_jugador=j.id_jugador) AND p.mapas_eq2>p.mapas_eq1 THEN 1
               ELSE 0 END) AS victorias,
           ROUND(100 * SUM(CASE
               WHEN p.id_historial_equipo_1 IN (SELECT jeh2.id_historial_equipo FROM jugador_equipo_historial jeh2 WHERE jeh2.id_jugador=j.id_jugador) AND p.mapas_eq1>p.mapas_eq2 THEN 1
               WHEN p.id_historial_equipo_2 IN (SELECT jeh2.id_historial_equipo FROM jugador_equipo_historial jeh2 WHERE jeh2.id_jugador=j.id_jugador) AND p.mapas_eq2>p.mapas_eq1 THEN 1
               ELSE 0 END) / COUNT(*), 1) AS win_rate
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador=j.id_jugador
    JOIN partido p ON ej.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    JOIN jugador_equipo_historial jeh ON j.id_jugador=jeh.id_jugador
        AND jeh.id_historial_equipo IN (p.id_historial_equipo_1,p.id_historial_equipo_2)
    JOIN historial_equipo he ON jeh.id_historial_equipo=he.id_historial_equipo
    JOIN equipo e ON he.id_equipo=e.id_equipo
    WHERE p.finalizado=TRUE
      AND (p_id_split IS NULL OR fs.id_split=p_id_split)
    GROUP BY j.id_jugador, e.nombre HAVING partidos >= 3
    ORDER BY win_rate DESC, victorias DESC LIMIT p_limite;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_resumen_torneo;
DELIMITER $$
CREATE PROCEDURE sp_resumen_torneo(IN p_id_split INT)
BEGIN
    SELECT COUNT(DISTINCT p.id_partido) AS total_partidos,
           COUNT(*) AS total_mapas,
           ROUND(AVG(m.duracion_minutos), 1) AS duracion_media_min,
           ROUND(AVG(kpm.total_kills), 1) AS kills_media_mapa,
           MAX(m.duracion_minutos) AS mapa_mas_largo,
           MIN(m.duracion_minutos) AS mapa_mas_corto
    FROM mapa m
    JOIN partido p ON m.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    JOIN (SELECT id_partido, numero_mapa, SUM(kills) AS total_kills
          FROM estadistica_jugador GROUP BY id_partido, numero_mapa) kpm
        ON kpm.id_partido=m.id_partido AND kpm.numero_mapa=m.numero_mapa
    WHERE p.finalizado=TRUE
      AND (p_id_split IS NULL OR fs.id_split=p_id_split);
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_top_kp;
DELIMITER $$
CREATE PROCEDURE sp_top_kp(IN p_id_split INT, IN p_limite INT)
BEGIN
    SELECT j.nickname, j.rol_principal, e.nombre AS equipo,
           ROUND(100 * SUM(ej.kills+ej.assists) /
               GREATEST(SUM((SELECT SUM(ej2.kills) FROM estadistica_jugador ej2
                   JOIN jugador_equipo_historial jeh2 ON ej2.id_jugador=jeh2.id_jugador
                   WHERE ej2.id_partido=ej.id_partido AND ej2.numero_mapa=ej.numero_mapa
                   AND jeh2.id_historial_equipo IN (p.id_historial_equipo_1,p.id_historial_equipo_2))),1),1) AS kp_pct,
           COUNT(*) AS mapas
    FROM estadistica_jugador ej
    JOIN jugador j ON ej.id_jugador=j.id_jugador
    JOIN partido p ON ej.id_partido=p.id_partido
    JOIN fase_split fs ON p.id_fase=fs.id_fase
    JOIN jugador_equipo_historial jeh ON j.id_jugador=jeh.id_jugador
        AND jeh.id_historial_equipo IN (p.id_historial_equipo_1,p.id_historial_equipo_2)
    JOIN historial_equipo he ON jeh.id_historial_equipo=he.id_historial_equipo
    JOIN equipo e ON he.id_equipo=e.id_equipo
    WHERE p.finalizado=TRUE AND (p_id_split IS NULL OR fs.id_split=p_id_split)
    GROUP BY j.id_jugador, e.nombre HAVING mapas>=2
    ORDER BY kp_pct DESC LIMIT p_limite;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_editar_equipo;
DELIMITER $$
CREATE PROCEDURE sp_editar_equipo(
    IN p_id_equipo INT,
    IN p_nombre    VARCHAR(50),
    IN p_pais      VARCHAR(50),
    IN p_fundacion DATE,
    IN p_activo    BOOLEAN,
    OUT p_mensaje  VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
        SET p_mensaje = 'Error al actualizar el equipo.';
    END;
    UPDATE equipo
    SET nombre=p_nombre, pais=p_pais, fundacion=p_fundacion, activo=p_activo
    WHERE id_equipo=p_id_equipo;
    SET p_mensaje = 'Equipo actualizado correctamente.';
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_editar_jugador;
DELIMITER $$
CREATE PROCEDURE sp_editar_jugador(
    IN p_id_jugador   INT,
    IN p_nickname     VARCHAR(30),
    IN p_nombre_real  VARCHAR(100),
    IN p_nacionalidad VARCHAR(50),
    IN p_rol          VARCHAR(10),
    IN p_activo       BOOLEAN,
    OUT p_mensaje     VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
        SET p_mensaje = 'Error al actualizar el jugador.';
    END;
    UPDATE jugador
    SET nickname=p_nickname, nombre_real=p_nombre_real,
        nacionalidad=p_nacionalidad, rol_principal=p_rol, activo=p_activo
    WHERE id_jugador=p_id_jugador;
    SET p_mensaje = 'Jugador actualizado correctamente.';
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_crear_split;
DELIMITER $$
CREATE PROCEDURE sp_crear_split(
    IN  p_nombre        VARCHAR(30),
    IN  p_año           YEAR,
    IN  p_fecha_inicio  DATE,
    IN  p_fecha_fin     DATE,
    IN  p_tipo_fase     VARCHAR(30),
    IN  p_incluir_equipos BOOLEAN,
    OUT p_id_split      INT,
    OUT p_mensaje       VARCHAR(200)
)
BEGIN
    DECLARE v_id_fase INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al crear el split.';
    END;

    START TRANSACTION;

    INSERT INTO split (nombre, año, fecha_inicio, fecha_fin)
    VALUES (p_nombre, p_año, p_fecha_inicio, p_fecha_fin);
    SET p_id_split = LAST_INSERT_ID();

    INSERT INTO fase_split (id_split, tipo, formato)
    VALUES (p_id_split, p_tipo_fase, 'Bo3');
    SET v_id_fase = LAST_INSERT_ID();

    IF p_incluir_equipos THEN
        INSERT INTO historial_equipo (id_equipo, id_split)
        SELECT id_equipo, p_id_split FROM equipo WHERE activo = TRUE;
    END IF;

    COMMIT;
    SET p_mensaje = CONCAT('Split creado correctamente (ID: ', p_id_split, ').');
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_listar_splits_admin;
DELIMITER $$
CREATE PROCEDURE sp_listar_splits_admin()
BEGIN
    SELECT s.id_split, s.nombre, s.año, s.fecha_inicio, s.fecha_fin,
           COUNT(DISTINCT he.id_historial_equipo) AS num_equipos,
           COUNT(DISTINCT p.id_partido) AS num_partidos
    FROM split s
    LEFT JOIN historial_equipo he ON he.id_split = s.id_split
    LEFT JOIN fase_split fs ON fs.id_split = s.id_split
    LEFT JOIN partido p ON p.id_fase = fs.id_fase
    GROUP BY s.id_split
    ORDER BY s.año DESC, s.id_split DESC;
END$$
DELIMITER ;

-- ============================================================
-- DATOS REALES 2024-2026
-- ============================================================

-- ============================================================
-- LEC DATABASE — DATOS COMPLETOS 2024-2026
-- Ejecutar DESPUÉS de LEC_completo_final.sql
-- ============================================================
USE lec;
SET SQL_SAFE_UPDATES = 0;

-- Desactivar triggers para insertar datos históricos
DROP TRIGGER IF EXISTS tg_mapa_maestro_ai;
DROP TRIGGER IF EXISTS tg_bloqueo_historico_bu;
DROP TRIGGER IF EXISTS tg_stats_maestro_bi;
DROP TRIGGER IF EXISTS tg_jugador_historial_maestro_bi;
DROP TRIGGER IF EXISTS tg_jugador_historial_maestro_bu;
DROP TRIGGER IF EXISTS tg_proteccion_borrado_critico;
DROP TRIGGER IF EXISTS tg_partido_maestro_bi;
DROP TRIGGER IF EXISTS tg_auditoria_jugador_ai;
DROP TRIGGER IF EXISTS tg_auditoria_jugador_au;
DROP TRIGGER IF EXISTS tg_auditoria_partido_au;
DROP TRIGGER IF EXISTS tg_puntos_sync_au;

-- ============================================================
-- EQUIPOS
-- ============================================================
INSERT INTO equipo (id_equipo, nombre, pais, fundacion, activo) VALUES
(1,  'G2 Esports',    'Multinacional', '2014-01-24', TRUE),
(2,  'Fnatic',        'Reino Unido',   '2004-07-23', TRUE),
(3,  'Team Vitality', 'Francia',       '2013-05-01', TRUE),
(4,  'MAD Lions KOI', 'España',        '2022-01-01', FALSE),
(5,  'Shifters',      'Francia',       '2019-07-01', TRUE),
(6,  'GIANTX',        'España',        '2020-01-01', TRUE),
(7,  'Karmine Corp',  'Francia',       '2020-01-01', TRUE),
(8,  'SK Gaming',     'Alemania',      '1997-01-01', TRUE),
(9,  'Team Heretics', 'España',        '2016-07-01', TRUE),
(10, 'Rogue',         'Multinacional', '2017-01-01', FALSE),
(11, 'Natus Vincere', 'Ucrania',       '2009-12-18', TRUE),
(12, 'Movistar KOI',  'España',        '2024-08-01', TRUE);

-- ============================================================
-- JUGADORES
-- ============================================================
INSERT INTO jugador (id_jugador, nickname, nombre_real, nacionalidad, fecha_nacimiento, rol_principal, activo) VALUES
-- G2 Esports
(1,  'BrokenBlade', 'Sergen Celik',            'Alemania',      '2000-09-21', 'Top',     TRUE),
(2,  'Yike',        'Martin Sundelin',         'Suecia',        '2002-05-09', 'Jungle',  TRUE),
(3,  'Caps',        'Rasmus Winther',          'Dinamarca',     '1999-11-29', 'Mid',     TRUE),
(4,  'Hans sama',   'Steven Liv',              'Francia',       '2000-07-23', 'ADC',     TRUE),
(5,  'Mikyx',       'Mihael Mehle',            'Eslovenia',     '1999-09-25', 'Support', TRUE),
(6,  'SkewMond',    'Rudy Semaan',             'Francia',       '2003-04-01', 'Jungle',  TRUE),
(7,  'Labrov',      'Labros Papoutsakis',      'Grecia',        '2000-01-22', 'Support', TRUE),
-- Fnatic 2024
(8,  'Oscarinin',   'Oscar Munoz',             'España',        '2004-03-15', 'Top',     FALSE),
(9,  'Razork',      'Miguel Bueno',            'España',        '2000-06-08', 'Jungle',  TRUE),
(10, 'Humanoid',    'Marek Brazda',            'Rep. Checa',    '2001-06-17', 'Mid',     TRUE),
(11, 'Upset',       'Elias Lipp',              'Alemania',      '2001-10-09', 'ADC',     TRUE),
(12, 'Hylissang',   'Zdravets Galabov',        'Bulgaria',      '1996-09-04', 'Support', FALSE),
-- Fnatic 2026
(71, 'Empyros',     'Alexandros Triantafyllou','Grecia',        '2003-01-01', 'Top',     TRUE),
(72, 'Vladi',       'Vladislav Shashkov',      'Rusia',         '2003-01-01', 'Mid',     TRUE),
(73, 'Lospa',       'Maxime Lospa',            'Francia',       '2004-01-01', 'Support', TRUE),
-- Team Vitality 2024
(13, 'Photon',      'Chen Ze',                 'China',         '2002-05-12', 'Top',     FALSE),
(14, 'Daglas',      'Nicholas Lau',            'Dinamarca',     '2002-03-01', 'Jungle',  FALSE),
(15, 'Perkz',       'Luka Perkovic',           'Croacia',       '1999-09-22', 'Mid',     FALSE),
(16, 'Carzzy',      'Matyas Orság',            'Rep. Checa',    '2002-01-16', 'ADC',     TRUE),
(63, 'Naak Nako',   'Nathan Gauthier',         'Francia',       '2004-01-01', 'Top',     TRUE),
(77, 'Lyncas',      'Mathieu Boudon',          'Francia',       '2004-01-01', 'Jungle',  TRUE),
(78, 'Fleshy',      'Gauthier Pichon',         'Francia',       '2004-01-01', 'Support', TRUE),
-- MAD Lions KOI 2024 / Movistar KOI 2025-2026
(17, 'Myrwn',       'Nathan Renaux',           'Francia',       '2004-05-01', 'Top',     TRUE),
(18, 'Elyoya',      'Javier Prades',           'España',        '2001-02-18', 'Jungle',  TRUE),
(19, 'Fresskowy',   'Bartlomiej Przewoznik',   'Polonia',       '2004-01-01', 'Mid',     FALSE),
(20, 'Supa',        'David Garcia',            'España',        '2003-07-01', 'ADC',     TRUE),
(21, 'Alvaro',      'Alvaro Fernandez',        'España',        '2005-01-01', 'Support', TRUE),
(58, 'Jojopyun',    'Joseph Joon-pyun',        'Canada',        '2003-12-24', 'Mid',     TRUE),
-- BDS 2024 / Shifters 2026
(22, 'Adam',        'Adam Maanane',            'Francia',       '2002-05-15', 'Top',     FALSE),
(23, 'Sheo',        'Xavier Lejeune',          'Belgica',       '2003-01-01', 'Jungle',  TRUE),
(24, 'nuc',         'Amadeu Carvalho',         'Portugal',      '2004-01-01', 'Mid',     TRUE),
(25, 'Ice',         'Jakub Sterba',            'Rep. Checa',    '2003-01-01', 'ADC',     TRUE),
(26, 'Limit',       'Christophe Lafaille',     'Francia',       '1999-12-01', 'Support', FALSE),
(51, 'Trymbi',      'Adrian Trybus',           'Polonia',       '2000-05-01', 'Support', TRUE),
(84, 'Rooster',     'Robin Danjoux',           'Francia',       '2004-01-01', 'Top',     TRUE),
(69, 'Boukada',     'Mehdi Boukada',           'Francia',       '2003-01-01', 'Jungle',  TRUE),
(85, 'Paduck',      'Lamine Laouber',          'Francia',       '2004-01-01', 'ADC',     TRUE),
-- GIANTX 2024
(27, 'Odoamne',     'Andrei Pascu',            'Rumania',       '1996-08-09', 'Top',     FALSE),
(28, 'Peach',       'Yoo Bum-soo',             'Corea del Sur', '2004-01-01', 'Jungle',  FALSE),
(29, 'Jackies',     'Jakub Mrozek',            'Rep. Checa',    '2003-01-01', 'Mid',     TRUE),
(30, 'Patrik',      'Patrik Jiru',             'Rep. Checa',    '1999-04-11', 'ADC',     FALSE),
(31, 'IgNar',       'Kim Dong-geun',           'Corea del Sur', '1996-06-24', 'Support', FALSE),
(39, 'ISMA',        'Ismail Benyettou',        'Francia',       '2002-01-01', 'Jungle',  TRUE),
(62, 'Noah',        'Kim Hyeon-jun',           'Corea del Sur', '2003-01-01', 'ADC',     TRUE),
(74, 'Lot',         'Lot Kaasmann',            'Paises Bajos',  '2003-01-01', 'Top',     TRUE),
(75, 'Jun',         'Park Jun-hyeong',         'Corea del Sur', '2004-01-01', 'Support', TRUE),
-- Karmine Corp
(32, 'Cabochard',   'Gabriel Issalys',         'Francia',       '1995-02-25', 'Top',     FALSE),
(33, 'Cinkrof',     'Jakub Rokicki',           'Polonia',       '1998-07-14', 'Jungle',  FALSE),
(34, 'Saken',       'Aurelien Coullon',        'Francia',       '1999-05-01', 'Mid',     FALSE),
(35, 'Neon',        'Adrian Kurylo',           'Polonia',       '2004-11-28', 'ADC',     FALSE),
(36, 'Targamas',    'Raphael Contat',          'Francia',       '2002-01-01', 'Support', FALSE),
(59, 'Canna',       'Kim Chang-dong',          'Corea del Sur', '2000-01-13', 'Top',     TRUE),
(45, 'Jackspektra', 'Jack Secker',             'Reino Unido',   '2003-01-01', 'ADC',     FALSE),
(65, 'Busio',       'Adam Busiakiewicz',       'Polonia',       '2005-01-01', 'Support', TRUE),
(70, 'Caliste',     'Caliste Henry',           'Francia',       '2004-01-01', 'ADC',     TRUE),
(76, 'kyeahoo',     'Kim Ye-hu',               'Corea del Sur', '2004-01-01', 'Mid',     TRUE),
-- SK Gaming 2024
(37, 'LIDER',       'Lenny Nguyen',            'Alemania',      '2002-07-21', 'Mid',     TRUE),
(38, 'Markoon',     'Mark van Woensel',        'Paises Bajos',  '2003-04-01', 'Jungle',  FALSE),
(40, 'Exakick',     'Theo Feugeas',            'Francia',       '2003-07-01', 'ADC',     FALSE),
(41, 'Doss',        'Felix Braun',             'Alemania',      '2003-01-01', 'Support', FALSE),
(42, 'Wunder',      'Martin Hansen',           'Dinamarca',     '1998-09-20', 'Top',     TRUE),
(52, 'Nisqy',       'Yasin Dincer',            'Belgica',       '1998-07-22', 'Mid',     FALSE),
(86, 'Skeanz',      'Theo Dupont',             'Francia',       '2004-01-01', 'Jungle',  TRUE),
(87, 'Jopa',        'Quentin Jopa',            'Francia',       '2003-01-01', 'ADC',     TRUE),
-- Team Heretics 2024
(43, 'Jankos',      'Marcin Jankowski',        'Polonia',       '1995-05-16', 'Jungle',  FALSE),
(44, 'Vetheo',      'Vincent Berrie',          'Francia',       '2003-05-01', 'Mid',     FALSE),
(46, 'Mersa',       'Niclas Jensen',           'Dinamarca',     '2004-01-01', 'Support', FALSE),
(60, 'Tracyn',      'Tomas Szymanski',         'Polonia',       '2004-01-01', 'Top',     TRUE),
(88, 'Serin',       'Serin Mara',              'Francia',       '2004-01-01', 'Mid',     TRUE),
(89, 'Stend',       'Julien Lerat',            'Francia',       '2004-01-01', 'Support', TRUE),
-- Rogue 2024
(47, 'Finn',        'Kim Finn Wiig-Andersen',  'Noruega',       '2000-01-01', 'Top',     FALSE),
(48, 'Malrang',     'Kim Geun-seong',          'Corea del Sur', '1999-05-01', 'Jungle',  FALSE),
(49, 'Larssen',     'Emil Larsen',             'Dinamarca',     '2001-07-23', 'Mid',     FALSE),
(50, 'Comp',        'Zdravets Iliev',          'Bulgaria',      '2002-05-01', 'ADC',     FALSE),
-- Natus Vincere 2026
(79, 'Maynter',     'Manuel Martin',           'España',        '2003-01-01', 'Top',     TRUE),
(80, 'Rhilech',     'Rayan Hilech',            'Francia',       '2003-01-01', 'Jungle',  TRUE),
(81, 'Poby',        'Pablo Perez',             'España',        '2004-01-01', 'Mid',     TRUE),
(82, 'SamD',        'Samuel Dos Santos',       'Francia',       '2004-01-01', 'ADC',     TRUE),
(83, 'Parus',       'Damian Parus',            'Polonia',       '2004-01-01', 'Support', TRUE);

-- ============================================================
-- SPLITS
-- ============================================================
INSERT INTO split (id_split, nombre, año, fecha_inicio, fecha_fin) VALUES
(1, 'Winter', 2024, '2024-01-13', '2024-02-18'),
(2, 'Spring', 2024, '2024-03-09', '2024-04-14'),
(3, 'Summer', 2024, '2024-06-08', '2024-07-28'),
(4, 'Spring', 2025, '2025-03-29', '2025-06-08'),
(5, 'Winter', 2025, '2025-01-18', '2025-03-02'),
(6, 'Spring', 2026, '2026-03-28', NULL);

-- ============================================================
-- FASES
-- ============================================================
INSERT INTO fase_split (id_fase, id_split, tipo, formato) VALUES
(1, 1, 'PLAYOFFS',     'Bo5'),
(2, 2, 'FASE_REGULAR', 'Bo1'),
(3, 2, 'PLAYOFFS',     'Bo5'),
(4, 3, 'FASE_REGULAR', 'Bo1'),
(5, 3, 'PLAYOFFS',     'Bo5'),
(6, 4, 'FASE_REGULAR', 'Bo3'),
(7, 4, 'PLAYOFFS',     'Bo5'),
(8, 5, 'FASE_REGULAR', 'Bo1'),
(9, 5, 'PLAYOFFS',     'Bo5'),
(10, 6, 'FASE_REGULAR','Bo3'),
(11, 6, 'PLAYOFFS',    'Bo5');

-- ============================================================
-- HISTORIAL EQUIPO
-- ============================================================
INSERT INTO historial_equipo
(id_historial_equipo, id_equipo, id_split, posicion_fase_regular, posicion_playoffs, puntos_campeonato, clasificado_msi, seed_worlds) VALUES
-- LEC Versus 2024 (Winter) — G2 campeon
(1,  1, 1, NULL, 1, 0, FALSE, NULL),
(2,  2, 1, NULL, 2, 0, FALSE, NULL),
(3,  3, 1, NULL, 3, 0, FALSE, NULL),
(4,  4, 1, NULL, 4, 0, FALSE, NULL),
(5,  5, 1, NULL, 5, 0, FALSE, NULL),
(6,  6, 1, NULL, 6, 0, FALSE, NULL),
(7,  7, 1, NULL, NULL, 0, FALSE, NULL),
(8,  8, 1, NULL, NULL, 0, FALSE, NULL),
(9,  9, 1, NULL, NULL, 0, FALSE, NULL),
(10, 10,1, NULL, NULL, 0, FALSE, NULL),
-- Spring 2024 — G2 campeon (3-1 vs FNC)
(11, 1, 2, 2,  1, 145, TRUE,  NULL),
(12, 2, 2, 1,  2, 120, TRUE,  NULL),
(13, 3, 2, 3,  3, 95,  FALSE, NULL),
(14, 4, 2, 8,  NULL, 0, FALSE, NULL),
(15, 5, 2, 4,  4, 70,  FALSE, NULL),
(16, 6, 2, 7,  NULL, 0, FALSE, NULL),
(17, 7, 2, 9,  NULL, 0, FALSE, NULL),
(18, 8, 2, 6,  NULL, 0, FALSE, NULL),
(19, 9, 2, 5,  NULL, 0, FALSE, NULL),
(20, 10,2, 10, NULL, 0, FALSE, NULL),
-- Summer 2024 — G2 campeon (3-0 vs FNC)
(21, 1, 3, 1,  1, 180, FALSE, 1),
(22, 2, 3, 2,  2, 150, FALSE, NULL),
(23, 3, 3, 6,  NULL, 0, FALSE, NULL),
(24, 4, 3, 5,  3, 120, FALSE, NULL),
(25, 5, 3, 8,  NULL, 0, FALSE, NULL),
(26, 6, 3, 3,  4, 90,  FALSE, NULL),
(27, 7, 3, 7,  NULL, 0, FALSE, NULL),
(28, 8, 3, 9,  NULL, 0, FALSE, NULL),
(29, 9, 3, 4,  NULL, 0, FALSE, NULL),
(30, 10,3, 10, NULL, 0, FALSE, NULL),
-- Winter 2025 — Karmine Corp campeon (3-0 vs G2)
(41, 7, 5, 2,  1, 0, FALSE, NULL),
(42, 1, 5, 1,  2, 0, FALSE, NULL),
(43, 2, 5, 4,  3, 0, FALSE, NULL),
(44, 12,5, 3,  4, 0, FALSE, NULL),
(45, 3, 5, 7,  NULL, 0, FALSE, NULL),
(46, 6, 5, 5,  NULL, 0, FALSE, NULL),
(47, 8, 5, 6,  NULL, 0, FALSE, NULL),
(48, 9, 5, 8,  NULL, 0, FALSE, NULL),
(49, 5, 5, 9,  NULL, 0, FALSE, NULL),
(50, 10,5, 10, NULL, 0, FALSE, NULL),
-- Spring 2025 — Movistar KOI campeon (3-1 vs G2)
(31, 1, 4, 2,  2, 0, TRUE,  NULL),
(32, 2, 4, 5,  NULL, 0, FALSE, NULL),
(33, 3, 4, 6,  NULL, 0, FALSE, NULL),
(34, 6, 4, 4,  4, 0, FALSE, NULL),
(35, 7, 4, 1,  3, 0, FALSE, NULL),
(36, 8, 4, 7,  NULL, 0, FALSE, NULL),
(37, 9, 4, 8,  NULL, 0, FALSE, NULL),
(38, 12,4, 3,  1, 0, TRUE,  1),
(39, 5, 4, 9,  NULL, 0, FALSE, NULL),
(40, 10,4, 10, NULL, 0, FALSE, NULL),
-- Spring 2026 — en curso
(51, 1, 6, NULL, NULL, 0, FALSE, NULL),
(52, 2, 6, NULL, NULL, 0, FALSE, NULL),
(53, 3, 6, NULL, NULL, 0, FALSE, NULL),
(54, 6, 6, NULL, NULL, 0, FALSE, NULL),
(55, 7, 6, NULL, NULL, 0, FALSE, NULL),
(56, 8, 6, NULL, NULL, 0, FALSE, NULL),
(57, 9, 6, NULL, NULL, 0, FALSE, NULL),
(58, 12,6, NULL, NULL, 0, FALSE, NULL),
(59, 5, 6, NULL, NULL, 0, FALSE, NULL),
(60, 11,6, NULL, NULL, 0, FALSE, NULL);

-- ============================================================
-- CONTRATOS JUGADORES
-- ============================================================
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin) VALUES
(1,1,'Top',TRUE,'2024-01-13','2024-02-18'),
(1,2,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(1,3,'Mid',TRUE,'2024-01-13','2024-02-18'),
(1,4,'ADC',TRUE,'2024-01-13','2024-02-18'),
(1,5,'Support',TRUE,'2024-01-13','2024-02-18'),
(2,8,'Top',TRUE,'2024-01-13','2024-02-18'),
(2,9,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(2,10,'Mid',TRUE,'2024-01-13','2024-02-18'),
(2,11,'ADC',TRUE,'2024-01-13','2024-02-18'),
(2,12,'Support',TRUE,'2024-01-13','2024-02-18'),
(3,13,'Top',TRUE,'2024-01-13','2024-02-18'),
(3,14,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(3,15,'Mid',TRUE,'2024-01-13','2024-02-18'),
(3,16,'ADC',TRUE,'2024-01-13','2024-02-18'),
(3,7,'Support',TRUE,'2024-01-13','2024-02-18'),
(4,17,'Top',TRUE,'2024-01-13','2024-02-18'),
(4,18,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(4,19,'Mid',TRUE,'2024-01-13','2024-02-18'),
(4,20,'ADC',TRUE,'2024-01-13','2024-02-18'),
(4,21,'Support',TRUE,'2024-01-13','2024-02-18'),
(5,22,'Top',TRUE,'2024-01-13','2024-02-18'),
(5,23,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(5,24,'Mid',TRUE,'2024-01-13','2024-02-18'),
(5,25,'ADC',TRUE,'2024-01-13','2024-02-18'),
(5,26,'Support',TRUE,'2024-01-13','2024-02-18'),
(6,27,'Top',TRUE,'2024-01-13','2024-02-18'),
(6,28,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(6,29,'Mid',TRUE,'2024-01-13','2024-02-18'),
(6,30,'ADC',TRUE,'2024-01-13','2024-02-18'),
(6,31,'Support',TRUE,'2024-01-13','2024-02-18'),
(7,32,'Top',TRUE,'2024-01-13','2024-02-18'),
(7,33,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(7,34,'Mid',TRUE,'2024-01-13','2024-02-18'),
(7,35,'ADC',TRUE,'2024-01-13','2024-02-18'),
(7,36,'Support',TRUE,'2024-01-13','2024-02-18'),
(8,37,'Top',TRUE,'2024-01-13','2024-02-18'),
(8,38,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(8,39,'Mid',TRUE,'2024-01-13','2024-02-18'),
(8,40,'ADC',TRUE,'2024-01-13','2024-02-18'),
(8,41,'Support',TRUE,'2024-01-13','2024-02-18'),
(9,42,'Top',TRUE,'2024-01-13','2024-02-18'),
(9,43,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(9,44,'Mid',TRUE,'2024-01-13','2024-02-18'),
(9,45,'ADC',TRUE,'2024-01-13','2024-02-18'),
(9,46,'Support',TRUE,'2024-01-13','2024-02-18'),
(10,47,'Top',TRUE,'2024-01-13','2024-02-18'),
(10,48,'Jungle',TRUE,'2024-01-13','2024-02-18'),
(10,49,'Mid',TRUE,'2024-01-13','2024-02-18'),
(10,50,'ADC',TRUE,'2024-01-13','2024-02-18'),
(10,51,'Support',TRUE,'2024-01-13','2024-02-18');
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin) VALUES
(11,1,'Top',TRUE,'2024-03-09','2024-04-14'),
(11,2,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(11,3,'Mid',TRUE,'2024-03-09','2024-04-14'),
(11,4,'ADC',TRUE,'2024-03-09','2024-04-14'),
(11,5,'Support',TRUE,'2024-03-09','2024-04-14'),
(12,8,'Top',TRUE,'2024-03-09','2024-04-14'),
(12,9,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(12,10,'Mid',TRUE,'2024-03-09','2024-04-14'),
(12,11,'ADC',TRUE,'2024-03-09','2024-04-14'),
(12,12,'Support',TRUE,'2024-03-09','2024-04-14'),
(13,13,'Top',TRUE,'2024-03-09','2024-04-14'),
(13,14,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(13,15,'Mid',TRUE,'2024-03-09','2024-04-14'),
(13,16,'ADC',TRUE,'2024-03-09','2024-04-14'),
(13,7,'Support',TRUE,'2024-03-09','2024-04-14'),
(14,17,'Top',TRUE,'2024-03-09','2024-04-14'),
(14,18,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(14,19,'Mid',TRUE,'2024-03-09','2024-04-14'),
(14,20,'ADC',TRUE,'2024-03-09','2024-04-14'),
(14,21,'Support',TRUE,'2024-03-09','2024-04-14'),
(15,22,'Top',TRUE,'2024-03-09','2024-04-14'),
(15,23,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(15,24,'Mid',TRUE,'2024-03-09','2024-04-14'),
(15,25,'ADC',TRUE,'2024-03-09','2024-04-14'),
(15,26,'Support',TRUE,'2024-03-09','2024-04-14'),
(16,27,'Top',TRUE,'2024-03-09','2024-04-14'),
(16,28,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(16,29,'Mid',TRUE,'2024-03-09','2024-04-14'),
(16,30,'ADC',TRUE,'2024-03-09','2024-04-14'),
(16,31,'Support',TRUE,'2024-03-09','2024-04-14'),
(17,32,'Top',TRUE,'2024-03-09','2024-04-14'),
(17,33,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(17,34,'Mid',TRUE,'2024-03-09','2024-04-14'),
(17,35,'ADC',TRUE,'2024-03-09','2024-04-14'),
(17,36,'Support',TRUE,'2024-03-09','2024-04-14'),
(18,37,'Top',TRUE,'2024-03-09','2024-04-14'),
(18,38,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(18,39,'Mid',TRUE,'2024-03-09','2024-04-14'),
(18,40,'ADC',TRUE,'2024-03-09','2024-04-14'),
(18,41,'Support',TRUE,'2024-03-09','2024-04-14'),
(19,42,'Top',TRUE,'2024-03-09','2024-04-14'),
(19,43,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(19,44,'Mid',TRUE,'2024-03-09','2024-04-14'),
(19,45,'ADC',TRUE,'2024-03-09','2024-04-14'),
(19,46,'Support',TRUE,'2024-03-09','2024-04-14'),
(20,47,'Top',TRUE,'2024-03-09','2024-04-14'),
(20,48,'Jungle',TRUE,'2024-03-09','2024-04-14'),
(20,49,'Mid',TRUE,'2024-03-09','2024-04-14'),
(20,50,'ADC',TRUE,'2024-03-09','2024-04-14'),
(20,51,'Support',TRUE,'2024-03-09','2024-04-14');
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin) VALUES
(21,1,'Top',TRUE,'2024-06-08','2024-07-28'),
(21,2,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(21,3,'Mid',TRUE,'2024-06-08','2024-07-28'),
(21,4,'ADC',TRUE,'2024-06-08','2024-07-28'),
(21,5,'Support',TRUE,'2024-06-08','2024-07-28'),
(22,8,'Top',TRUE,'2024-06-08','2024-07-28'),
(22,9,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(22,10,'Mid',TRUE,'2024-06-08','2024-07-28'),
(22,11,'ADC',TRUE,'2024-06-08','2024-07-28'),
(22,12,'Support',TRUE,'2024-06-08','2024-07-28'),
(23,13,'Top',TRUE,'2024-06-08','2024-07-28'),
(23,14,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(23,15,'Mid',TRUE,'2024-06-08','2024-07-28'),
(23,16,'ADC',TRUE,'2024-06-08','2024-07-28'),
(23,7,'Support',TRUE,'2024-06-08','2024-07-28'),
(24,17,'Top',TRUE,'2024-06-08','2024-07-28'),
(24,18,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(24,19,'Mid',TRUE,'2024-06-08','2024-07-28'),
(24,20,'ADC',TRUE,'2024-06-08','2024-07-28'),
(24,21,'Support',TRUE,'2024-06-08','2024-07-28'),
(25,22,'Top',TRUE,'2024-06-08','2024-07-28'),
(25,23,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(25,24,'Mid',TRUE,'2024-06-08','2024-07-28'),
(25,25,'ADC',TRUE,'2024-06-08','2024-07-28'),
(25,26,'Support',TRUE,'2024-06-08','2024-07-28'),
(26,27,'Top',TRUE,'2024-06-08','2024-07-28'),
(26,28,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(26,29,'Mid',TRUE,'2024-06-08','2024-07-28'),
(26,30,'ADC',TRUE,'2024-06-08','2024-07-28'),
(26,31,'Support',TRUE,'2024-06-08','2024-07-28'),
(27,32,'Top',TRUE,'2024-06-08','2024-07-28'),
(27,33,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(27,34,'Mid',TRUE,'2024-06-08','2024-07-28'),
(27,35,'ADC',TRUE,'2024-06-08','2024-07-28'),
(27,36,'Support',TRUE,'2024-06-08','2024-07-28'),
(28,37,'Top',TRUE,'2024-06-08','2024-07-28'),
(28,38,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(28,39,'Mid',TRUE,'2024-06-08','2024-07-28'),
(28,40,'ADC',TRUE,'2024-06-08','2024-07-28'),
(28,41,'Support',TRUE,'2024-06-08','2024-07-28'),
(29,42,'Top',TRUE,'2024-06-08','2024-07-28'),
(29,43,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(29,44,'Mid',TRUE,'2024-06-08','2024-07-28'),
(29,45,'ADC',TRUE,'2024-06-08','2024-07-28'),
(29,46,'Support',TRUE,'2024-06-08','2024-07-28'),
(30,47,'Top',TRUE,'2024-06-08','2024-07-28'),
(30,48,'Jungle',TRUE,'2024-06-08','2024-07-28'),
(30,49,'Mid',TRUE,'2024-06-08','2024-07-28'),
(30,50,'ADC',TRUE,'2024-06-08','2024-07-28'),
(30,51,'Support',TRUE,'2024-06-08','2024-07-28');
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin) VALUES
(41,32,'Top',TRUE,'2025-01-18','2025-03-02'),
(41,2,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(41,34,'Mid',TRUE,'2025-01-18','2025-03-02'),
(41,45,'ADC',TRUE,'2025-01-18','2025-03-02'),
(41,36,'Support',TRUE,'2025-01-18','2025-03-02'),
(42,1,'Top',TRUE,'2025-01-18','2025-03-02'),
(42,6,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(42,3,'Mid',TRUE,'2025-01-18','2025-03-02'),
(42,4,'ADC',TRUE,'2025-01-18','2025-03-02'),
(42,7,'Support',TRUE,'2025-01-18','2025-03-02'),
(43,8,'Top',TRUE,'2025-01-18','2025-03-02'),
(43,9,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(43,10,'Mid',TRUE,'2025-01-18','2025-03-02'),
(43,11,'ADC',TRUE,'2025-01-18','2025-03-02'),
(43,12,'Support',TRUE,'2025-01-18','2025-03-02'),
(44,17,'Top',TRUE,'2025-01-18','2025-03-02'),
(44,18,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(44,58,'Mid',TRUE,'2025-01-18','2025-03-02'),
(44,20,'ADC',TRUE,'2025-01-18','2025-03-02'),
(44,21,'Support',TRUE,'2025-01-18','2025-03-02'),
(45,13,'Top',TRUE,'2025-01-18','2025-03-02'),
(45,14,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(45,15,'Mid',TRUE,'2025-01-18','2025-03-02'),
(45,16,'ADC',TRUE,'2025-01-18','2025-03-02'),
(45,52,'Support',TRUE,'2025-01-18','2025-03-02'),
(46,27,'Top',TRUE,'2025-01-18','2025-03-02'),
(46,28,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(46,29,'Mid',TRUE,'2025-01-18','2025-03-02'),
(46,30,'ADC',TRUE,'2025-01-18','2025-03-02'),
(46,46,'Support',TRUE,'2025-01-18','2025-03-02'),
(47,42,'Top',TRUE,'2025-01-18','2025-03-02'),
(47,38,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(47,37,'Mid',TRUE,'2025-01-18','2025-03-02'),
(47,40,'ADC',TRUE,'2025-01-18','2025-03-02'),
(47,41,'Support',TRUE,'2025-01-18','2025-03-02'),
(48,60,'Top',TRUE,'2025-01-18','2025-03-02'),
(48,43,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(48,44,'Mid',TRUE,'2025-01-18','2025-03-02'),
(48,30,'ADC',TRUE,'2025-01-18','2025-03-02'),
(48,33,'Support',TRUE,'2025-01-18','2025-03-02'),
(49,22,'Top',TRUE,'2025-01-18','2025-03-02'),
(49,23,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(49,24,'Mid',TRUE,'2025-01-18','2025-03-02'),
(49,25,'ADC',TRUE,'2025-01-18','2025-03-02'),
(49,26,'Support',TRUE,'2025-01-18','2025-03-02'),
(50,47,'Top',TRUE,'2025-01-18','2025-03-02'),
(50,48,'Jungle',TRUE,'2025-01-18','2025-03-02'),
(50,49,'Mid',TRUE,'2025-01-18','2025-03-02'),
(50,50,'ADC',TRUE,'2025-01-18','2025-03-02'),
(50,51,'Support',TRUE,'2025-01-18','2025-03-02');
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin) VALUES
(31,1,'Top',TRUE,'2025-03-29',NULL),
(31,6,'Jungle',TRUE,'2025-03-29',NULL),
(31,3,'Mid',TRUE,'2025-03-29',NULL),
(31,4,'ADC',TRUE,'2025-03-29',NULL),
(31,7,'Support',TRUE,'2025-03-29',NULL),
(32,8,'Top',TRUE,'2025-03-29',NULL),
(32,9,'Jungle',TRUE,'2025-03-29',NULL),
(32,10,'Mid',TRUE,'2025-03-29',NULL),
(32,11,'ADC',TRUE,'2025-03-29',NULL),
(32,12,'Support',TRUE,'2025-03-29',NULL),
(33,13,'Top',TRUE,'2025-03-29',NULL),
(33,14,'Jungle',TRUE,'2025-03-29',NULL),
(33,15,'Mid',TRUE,'2025-03-29',NULL),
(33,16,'ADC',TRUE,'2025-03-29',NULL),
(33,52,'Support',TRUE,'2025-03-29',NULL),
(34,27,'Top',TRUE,'2025-03-29',NULL),
(34,28,'Jungle',TRUE,'2025-03-29',NULL),
(34,29,'Mid',TRUE,'2025-03-29',NULL),
(34,30,'ADC',TRUE,'2025-03-29',NULL),
(34,46,'Support',TRUE,'2025-03-29',NULL),
(35,32,'Top',TRUE,'2025-03-29',NULL),
(35,2,'Jungle',TRUE,'2025-03-29',NULL),
(35,34,'Mid',TRUE,'2025-03-29',NULL),
(35,45,'ADC',TRUE,'2025-03-29',NULL),
(35,36,'Support',TRUE,'2025-03-29',NULL),
(36,42,'Top',TRUE,'2025-03-29',NULL),
(36,38,'Jungle',TRUE,'2025-03-29',NULL),
(36,37,'Mid',TRUE,'2025-03-29',NULL),
(36,40,'ADC',TRUE,'2025-03-29',NULL),
(36,41,'Support',TRUE,'2025-03-29',NULL),
(37,60,'Top',TRUE,'2025-03-29',NULL),
(37,43,'Jungle',TRUE,'2025-03-29',NULL),
(37,44,'Mid',TRUE,'2025-03-29',NULL),
(37,69,'ADC',TRUE,'2025-03-29',NULL),
(37,33,'Support',TRUE,'2025-03-29',NULL),
(38,17,'Top',TRUE,'2025-03-29',NULL),
(38,18,'Jungle',TRUE,'2025-03-29',NULL),
(38,58,'Mid',TRUE,'2025-03-29',NULL),
(38,20,'ADC',TRUE,'2025-03-29',NULL),
(38,21,'Support',TRUE,'2025-03-29',NULL),
(39,22,'Top',TRUE,'2025-03-29',NULL),
(39,23,'Jungle',TRUE,'2025-03-29',NULL),
(39,24,'Mid',TRUE,'2025-03-29',NULL),
(39,25,'ADC',TRUE,'2025-03-29',NULL),
(39,26,'Support',TRUE,'2025-03-29',NULL),
(40,47,'Top',TRUE,'2025-03-29',NULL),
(40,48,'Jungle',TRUE,'2025-03-29',NULL),
(40,49,'Mid',TRUE,'2025-03-29',NULL),
(40,50,'ADC',TRUE,'2025-03-29',NULL),
(40,51,'Support',TRUE,'2025-03-29',NULL);
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio, fecha_fin) VALUES
(51,1,'Top',TRUE,'2026-03-28',NULL),
(51,6,'Jungle',TRUE,'2026-03-28',NULL),
(51,3,'Mid',TRUE,'2026-03-28',NULL),
(51,4,'ADC',TRUE,'2026-03-28',NULL),
(51,7,'Support',TRUE,'2026-03-28',NULL),
(52,71,'Top',TRUE,'2026-03-28',NULL),
(52,9,'Jungle',TRUE,'2026-03-28',NULL),
(52,72,'Mid',TRUE,'2026-03-28',NULL),
(52,11,'ADC',TRUE,'2026-03-28',NULL),
(52,73,'Support',TRUE,'2026-03-28',NULL),
(53,63,'Top',TRUE,'2026-03-28',NULL),
(53,77,'Jungle',TRUE,'2026-03-28',NULL),
(53,10,'Mid',TRUE,'2026-03-28',NULL),
(53,16,'ADC',TRUE,'2026-03-28',NULL),
(53,78,'Support',TRUE,'2026-03-28',NULL),
(54,74,'Top',TRUE,'2026-03-28',NULL),
(54,39,'Jungle',TRUE,'2026-03-28',NULL),
(54,29,'Mid',TRUE,'2026-03-28',NULL),
(54,62,'ADC',TRUE,'2026-03-28',NULL),
(54,75,'Support',TRUE,'2026-03-28',NULL),
(55,59,'Top',TRUE,'2026-03-28',NULL),
(55,2,'Jungle',TRUE,'2026-03-28',NULL),
(55,76,'Mid',TRUE,'2026-03-28',NULL),
(55,70,'ADC',TRUE,'2026-03-28',NULL),
(55,65,'Support',TRUE,'2026-03-28',NULL),
(56,42,'Top',TRUE,'2026-03-28',NULL),
(56,86,'Jungle',TRUE,'2026-03-28',NULL),
(56,37,'Mid',TRUE,'2026-03-28',NULL),
(56,87,'ADC',TRUE,'2026-03-28',NULL),
(56,5,'Support',TRUE,'2026-03-28',NULL),
(57,60,'Top',TRUE,'2026-03-28',NULL),
(57,23,'Jungle',TRUE,'2026-03-28',NULL),
(57,88,'Mid',TRUE,'2026-03-28',NULL),
(57,25,'ADC',TRUE,'2026-03-28',NULL),
(57,89,'Support',TRUE,'2026-03-28',NULL),
(58,17,'Top',TRUE,'2026-03-28',NULL),
(58,18,'Jungle',TRUE,'2026-03-28',NULL),
(58,58,'Mid',TRUE,'2026-03-28',NULL),
(58,20,'ADC',TRUE,'2026-03-28',NULL),
(58,21,'Support',TRUE,'2026-03-28',NULL),
(59,84,'Top',TRUE,'2026-03-28',NULL),
(59,69,'Jungle',TRUE,'2026-03-28',NULL),
(59,24,'Mid',TRUE,'2026-03-28',NULL),
(59,85,'ADC',TRUE,'2026-03-28',NULL),
(59,51,'Support',TRUE,'2026-03-28',NULL),
(60,79,'Top',TRUE,'2026-03-28',NULL),
(60,80,'Jungle',TRUE,'2026-03-28',NULL),
(60,81,'Mid',TRUE,'2026-03-28',NULL),
(60,82,'ADC',TRUE,'2026-03-28',NULL),
(60,83,'Support',TRUE,'2026-03-28',NULL);

-- ============================================================
-- PARTIDOS
-- ============================================================
INSERT INTO partido
(id_partido, id_fase, id_historial_equipo_1, id_historial_equipo_2, fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado) VALUES
-- LEC Versus 2024 Final: G2 vs FNC 3-1
(1,  1, 1,  2,  '2024-02-18 17:00:00', 'Bo5', 3, 1, TRUE),
-- Spring 2024 Regular Season
(2,  2, 12, 13, '2024-03-09 17:00:00', 'Bo1', 1, 0, TRUE),
(3,  2, 11, 14, '2024-03-09 19:00:00', 'Bo1', 1, 0, TRUE),
(4,  2, 15, 16, '2024-03-09 20:00:00', 'Bo1', 0, 1, TRUE),
(5,  2, 17, 18, '2024-03-09 21:00:00', 'Bo1', 0, 1, TRUE),
(6,  2, 11, 12, '2024-03-16 17:00:00', 'Bo1', 1, 0, TRUE),
(7,  2, 13, 15, '2024-03-16 19:00:00', 'Bo1', 1, 0, TRUE),
(8,  2, 19, 18, '2024-03-16 20:00:00', 'Bo1', 1, 0, TRUE),
(9,  2, 16, 17, '2024-03-16 21:00:00', 'Bo1', 1, 0, TRUE),
(10, 2, 11, 19, '2024-03-23 17:00:00', 'Bo1', 1, 0, TRUE),
(11, 2, 12, 15, '2024-03-23 19:00:00', 'Bo1', 1, 0, TRUE),
(12, 2, 13, 14, '2024-03-23 20:00:00', 'Bo1', 1, 0, TRUE),
(13, 2, 18, 20, '2024-03-23 21:00:00', 'Bo1', 1, 0, TRUE),
-- Spring 2024 Playoffs
(14, 3, 11, 13, '2024-04-06 17:00:00', 'Bo5', 3, 1, TRUE),
(15, 3, 12, 15, '2024-04-06 20:00:00', 'Bo5', 3, 1, TRUE),
(16, 3, 11, 12, '2024-04-14 17:00:00', 'Bo5', 3, 1, TRUE),
-- Summer 2024 Regular Season
(17, 4, 29, 26, '2024-06-08 17:00:00', 'Bo1', 0, 1, TRUE),
(18, 4, 28, 30, '2024-06-08 19:00:00', 'Bo1', 1, 0, TRUE),
(19, 4, 23, 25, '2024-06-08 20:00:00', 'Bo1', 0, 1, TRUE),
(20, 4, 24, 21, '2024-06-08 21:00:00', 'Bo1', 0, 1, TRUE),
(21, 4, 21, 22, '2024-06-15 17:00:00', 'Bo1', 1, 0, TRUE),
(22, 4, 26, 27, '2024-06-15 19:00:00', 'Bo1', 1, 0, TRUE),
(23, 4, 24, 29, '2024-06-15 20:00:00', 'Bo1', 1, 0, TRUE),
(24, 4, 21, 26, '2024-06-22 17:00:00', 'Bo1', 1, 0, TRUE),
(25, 4, 22, 24, '2024-06-22 19:00:00', 'Bo1', 0, 1, TRUE),
-- Summer 2024 Playoffs
(26, 5, 21, 26, '2024-07-20 17:00:00', 'Bo5', 3, 1, TRUE),
(27, 5, 22, 24, '2024-07-20 20:00:00', 'Bo5', 3, 2, TRUE),
(28, 5, 21, 22, '2024-07-28 17:00:00', 'Bo5', 3, 0, TRUE),
-- Winter 2025 Final: KC vs G2 3-0
(55, 9, 41, 42, '2025-03-02 17:00:00', 'Bo5', 3, 0, TRUE),
-- Spring 2025 Regular Season
(29, 6, 35, 32, '2025-03-29 17:00:00', 'Bo3', 2, 0, TRUE),
(30, 6, 38, 35, '2025-03-29 20:00:00', 'Bo3', 1, 2, TRUE),
(31, 6, 31, 33, '2025-04-05 17:00:00', 'Bo3', 2, 0, TRUE),
(32, 6, 34, 36, '2025-04-05 20:00:00', 'Bo3', 2, 1, TRUE),
(33, 6, 35, 31, '2025-04-12 17:00:00', 'Bo3', 1, 2, TRUE),
(34, 6, 38, 32, '2025-04-12 20:00:00', 'Bo3', 2, 0, TRUE),
(35, 6, 38, 31, '2025-04-26 17:00:00', 'Bo3', 2, 1, TRUE),
(36, 6, 35, 34, '2025-04-26 20:00:00', 'Bo3', 2, 0, TRUE),
(37, 6, 38, 35, '2025-05-10 17:00:00', 'Bo3', 2, 1, TRUE),
(38, 6, 31, 34, '2025-05-10 20:00:00', 'Bo3', 2, 1, TRUE),
-- Spring 2025 Playoffs
(51, 7, 35, 38, '2025-05-24 17:00:00', 'Bo5', 1, 3, TRUE),
(52, 7, 31, 34, '2025-05-24 20:00:00', 'Bo5', 3, 1, TRUE),
(53, 7, 35, 31, '2025-05-31 17:00:00', 'Bo5', 3, 2, TRUE),
(54, 7, 38, 31, '2025-06-08 17:00:00', 'Bo5', 3, 1, TRUE),
-- Spring 2026 Semanas 1-6 completadas
(60, 10, 55, 57, '2026-03-29 11:00:00', 'Bo3', 2, 0, TRUE),
(61, 10, 51, 59, '2026-03-29 13:15:00', 'Bo3', 2, 0, TRUE),
(62, 10, 54, 60, '2026-03-30 11:00:00', 'Bo3', 2, 0, TRUE),
(63, 10, 52, 56, '2026-03-30 13:15:00', 'Bo3', 0, 2, TRUE),
(64, 10, 53, 58, '2026-03-31 11:00:00', 'Bo3', 2, 1, TRUE),
(65, 10, 54, 59, '2026-04-05 11:00:00', 'Bo3', 2, 0, TRUE),
(66, 10, 52, 56, '2026-04-05 13:15:00', 'Bo3', 0, 2, TRUE),
(67, 10, 55, 51, '2026-04-06 11:00:00', 'Bo3', 2, 0, TRUE),
(68, 10, 57, 60, '2026-04-06 13:15:00', 'Bo3', 0, 2, TRUE),
(69, 10, 53, 59, '2026-04-07 11:00:00', 'Bo3', 2, 1, TRUE),
(70, 10, 54, 59, '2026-04-12 11:00:00', 'Bo3', 2, 0, TRUE),
(71, 10, 57, 55, '2026-04-12 13:15:00', 'Bo3', 0, 2, TRUE),
(72, 10, 51, 53, '2026-04-13 11:00:00', 'Bo3', 1, 2, TRUE),
(73, 10, 52, 57, '2026-04-13 13:15:00', 'Bo3', 2, 0, TRUE),
(74, 10, 58, 56, '2026-04-14 11:00:00', 'Bo3', 2, 0, TRUE),
(75, 10, 58, 60, '2026-04-26 11:00:00', 'Bo3', 2, 1, TRUE),
(76, 10, 51, 53, '2026-04-26 13:15:00', 'Bo3', 2, 1, TRUE),
(77, 10, 55, 52, '2026-04-27 11:00:00', 'Bo3', 2, 0, TRUE),
(78, 10, 54, 57, '2026-04-27 13:15:00', 'Bo3', 2, 0, TRUE),
(79, 10, 53, 56, '2026-04-28 11:00:00', 'Bo3', 2, 1, TRUE),
(80, 10, 58, 56, '2026-05-02 11:00:00', 'Bo3', 2, 0, TRUE),
(81, 10, 52, 57, '2026-05-02 13:15:00', 'Bo3', 2, 0, TRUE),
(82, 10, 53, 59, '2026-05-03 11:00:00', 'Bo3', 2, 0, TRUE),
(83, 10, 51, 60, '2026-05-03 13:15:00', 'Bo3', 2, 0, TRUE),
(84, 10, 57, 59, '2026-05-04 11:00:00', 'Bo3', 0, 2, TRUE),
(85, 10, 59, 58, '2026-05-04 13:15:00', 'Bo3', 1, 2, TRUE),
(86, 10, 52, 53, '2026-05-05 11:00:00', 'Bo3', 1, 2, TRUE),
-- PROXIMOS Semana 7 (9-11 mayo)
(87, 10, 55, 60, '2026-05-09 11:00:00', 'Bo3', 0, 0, FALSE),
(88, 10, 54, 51, '2026-05-09 13:15:00', 'Bo3', 0, 0, FALSE),
(89, 10, 52, 58, '2026-05-10 11:00:00', 'Bo3', 0, 0, FALSE),
(90, 10, 53, 57, '2026-05-10 13:15:00', 'Bo3', 0, 0, FALSE),
(91, 10, 56, 59, '2026-05-11 11:00:00', 'Bo3', 0, 0, FALSE),
-- PROXIMOS Semana 8 (16-18 mayo)
(92, 10, 51, 55, '2026-05-16 11:00:00', 'Bo3', 0, 0, FALSE),
(93, 10, 60, 53, '2026-05-16 13:15:00', 'Bo3', 0, 0, FALSE),
(94, 10, 58, 54, '2026-05-17 11:00:00', 'Bo3', 0, 0, FALSE),
(95, 10, 57, 56, '2026-05-17 13:15:00', 'Bo3', 0, 0, FALSE),
(96, 10, 59, 52, '2026-05-18 11:00:00', 'Bo3', 0, 0, FALSE),
-- PROXIMOS Semana 9 - Paris Roadtrip (23-25 mayo)
(97, 10, 55, 53, '2026-05-23 11:00:00', 'Bo3', 0, 0, FALSE),
(98, 10, 51, 58, '2026-05-23 13:15:00', 'Bo3', 0, 0, FALSE),
(99, 10, 54, 56, '2026-05-24 11:00:00', 'Bo3', 0, 0, FALSE),
(100,10, 60, 52, '2026-05-24 13:15:00', 'Bo3', 0, 0, FALSE),
(101,10, 59, 57, '2026-05-25 11:00:00', 'Bo3', 0, 0, FALSE);

-- ============================================================
-- MAPAS
-- ============================================================
INSERT INTO mapa (id_partido, numero_mapa, duracion_minutos, ganador) VALUES
(1, 1,38,1),(1, 2,42,2),(1, 3,35,1),(1, 4,29,1),
(14,1,35,11),(14,2,42,13),(14,3,31,11),(14,4,28,11),
(15,1,37,12),(15,2,45,15),(15,3,33,12),(15,4,39,12),
(16,1,33,12),(16,2,40,11),(16,3,28,11),(16,4,36,11),
(26,1,33,21),(26,2,41,26),(26,3,35,21),(26,4,29,21),
(27,1,38,22),(27,2,44,24),(27,3,36,22),(27,4,42,24),(27,5,39,22),
(28,1,32,21),(28,2,27,21),(28,3,35,21),
(55,1,33,41),(55,2,29,41),(55,3,37,41),
(51,1,36,38),(51,2,42,35),(51,3,35,38),(51,4,31,38),
(52,1,38,31),(52,2,33,34),(52,3,40,31),(52,4,36,31),
(53,1,38,35),(53,2,33,31),(53,3,42,35),(53,4,36,31),(53,5,44,35),
(54,1,38,38),(54,2,35,31),(54,3,42,38),(54,4,31,38),
(62,1,31,54),(62,2,28,54),
(64,1,35,53),(64,2,38,58),(64,3,41,53),
(67,1,36,55),(67,2,40,55),
(72,1,33,51),(72,2,37,53),(72,3,44,53),
(74,1,30,58),(74,2,34,58),
(76,1,38,51),(76,2,32,53),(76,3,41,51),
(83,1,28,51),(83,2,33,51),
(85,1,36,59),(85,2,31,58),(85,3,39,58),
(86,1,34,52),(86,2,29,53),(86,3,42,53);

-- ============================================================
-- ESTADISTICAS DE JUGADORES
-- ============================================================
INSERT INTO estadistica_jugador (id_partido, numero_mapa, id_jugador, kills, deaths, assists, cs, oro, campeon) VALUES
(1,1,1,7,3,5,284,5627,'Ornn'),
(1,1,2,5,0,8,211,5313,'Wukong'),
(1,1,3,6,4,3,284,6254,'Ahri'),
(1,1,4,4,2,4,372,6098,'Lucian'),
(1,1,5,2,1,14,95,5579,'Lulu'),
(1,1,8,3,4,4,250,5652,'Camille'),
(1,1,9,2,2,6,210,5050,'Lee Sin'),
(1,1,10,4,2,5,276,5944,'Syndra'),
(1,1,11,4,3,2,340,4656,'Caitlyn'),
(1,1,12,0,5,6,43,3713,'Nautilus'),
(1,2,1,3,0,4,294,5388,'Fiora'),
(1,2,2,3,2,7,239,6323,'Viego'),
(1,2,3,5,1,4,358,4930,'Taliyah'),
(1,2,4,8,0,4,371,7612,'Kaisa'),
(1,2,5,3,1,10,42,6356,'Braum'),
(1,2,8,1,4,2,327,3792,'Ornn'),
(1,2,9,0,2,3,244,3221,'Belveth'),
(1,2,10,0,4,4,319,3565,'Akali'),
(1,2,11,2,3,0,412,4507,'Miss Fortune'),
(1,2,12,5,3,9,61,6368,'Rakan'),
(1,3,1,5,0,4,265,4953,'Garen'),
(1,3,2,8,2,8,144,7448,'Sejuani'),
(1,3,3,5,2,3,246,5481,'Orianna'),
(1,3,4,7,2,7,348,7735,'Ezreal'),
(1,3,5,4,1,10,49,5541,'Blitzcrank'),
(1,3,8,2,5,2,248,4894,'Gnar'),
(1,3,9,5,0,3,194,5689,'Sejuani'),
(1,3,10,4,3,0,268,5711,'Galio'),
(1,3,11,6,1,1,276,5319,'Kaisa'),
(1,3,12,0,2,5,48,3306,'Milio'),
(1,4,1,3,4,5,222,4239,'Camille'),
(1,4,2,4,1,12,140,5425,'Belveth'),
(1,4,3,6,4,6,236,7087,'Akali'),
(1,4,4,5,1,3,257,4657,'Ezreal'),
(1,4,5,1,1,8,61,3732,'Nautilus'),
(1,4,8,1,2,5,220,5129,'Ornn'),
(1,4,9,2,5,2,169,3808,'Vi'),
(1,4,10,3,7,0,240,4507,'Galio'),
(1,4,11,10,4,5,208,8063,'Caitlyn'),
(1,4,12,2,5,6,60,3740,'Karma'),
(14,1,1,0,5,4,286,4103,'Darius'),
(14,1,2,0,4,11,196,5513,'Graves'),
(14,1,3,7,3,9,268,7096,'Galio'),
(14,1,4,6,1,3,294,6584,'Jinx'),
(14,1,5,5,5,12,55,6628,'Blitzcrank'),
(14,1,13,2,3,5,280,4414,'Camille'),
(14,1,14,0,3,2,209,3788,'Nidalee'),
(14,1,15,4,3,3,258,4976,'Zoe'),
(14,1,16,2,1,1,336,3570,'Jhin'),
(14,1,7,0,5,7,49,3584,'Thresh'),
(14,2,1,4,5,8,273,5702,'Garen'),
(14,2,2,7,4,8,209,7370,'Graves'),
(14,2,3,3,1,2,312,4036,'Taliyah'),
(14,2,4,6,4,5,355,5837,'Jhin'),
(14,2,5,3,3,10,22,5479,'Braum'),
(14,2,13,2,7,5,310,5668,'Renekton'),
(14,2,14,4,4,8,277,5284,'Graves'),
(14,2,15,0,5,2,324,4883,'Cassiopeia'),
(14,2,16,5,1,4,344,5091,'Varus'),
(14,2,7,2,5,9,37,5786,'Nami'),
(14,3,1,6,1,5,232,6611,'Aatrox'),
(14,3,2,6,1,8,166,7236,'Kindred'),
(14,3,3,10,0,8,203,6656,'Ahri'),
(14,3,4,6,0,8,256,7281,'Jhin'),
(14,3,5,3,1,11,34,6404,'Renata'),
(14,3,13,3,3,3,202,4379,'Aatrox'),
(14,3,14,3,6,3,184,3860,'Hecarim'),
(14,3,15,2,5,1,207,3842,'Syndra'),
(14,3,16,7,5,5,317,6027,'Jinx'),
(14,3,7,3,5,6,26,5093,'Thresh'),
(14,4,1,8,4,5,206,6455,'Garen'),
(14,4,2,1,1,7,113,5085,'Lee Sin'),
(14,4,3,7,3,10,204,7284,'Taliyah'),
(14,4,4,5,0,7,231,6377,'Aphelios'),
(14,4,5,1,4,10,34,5229,'Nami'),
(14,4,13,0,1,1,190,3652,'Jax'),
(14,4,14,2,5,5,130,4269,'Lee Sin'),
(14,4,15,0,5,0,216,4397,'Galio'),
(14,4,16,3,3,0,242,4070,'Varus'),
(14,4,7,2,2,5,26,3809,'Nautilus'),
(15,1,8,6,2,1,271,4641,'Darius'),
(15,1,9,2,3,10,237,5586,'Sejuani'),
(15,1,10,6,4,9,290,7307,'Corki'),
(15,1,11,6,0,6,294,6239,'Caitlyn'),
(15,1,12,0,1,12,59,4869,'Thresh'),
(15,1,22,0,3,1,296,3648,'Ornn'),
(15,1,23,4,1,0,227,4567,'Nidalee'),
(15,1,24,3,2,3,304,5263,'Orianna'),
(15,1,25,3,1,1,312,3832,'Zeri'),
(15,1,26,1,5,5,74,3481,'Renata'),
(15,2,8,5,4,5,316,5716,'Darius'),
(15,2,9,3,1,9,273,6649,'Elise'),
(15,2,10,6,2,8,333,6642,'Lissandra'),
(15,2,11,8,1,1,420,7101,'Jinx'),
(15,2,12,0,1,13,22,4993,'Nami'),
(15,2,22,2,5,0,342,4918,'Fiora'),
(15,2,23,2,1,9,225,5493,'Jarvan IV'),
(15,2,24,5,3,3,344,5515,'Azir'),
(15,2,25,4,2,2,411,5253,'Jhin'),
(15,2,26,0,6,5,111,3835,'Alistar'),
(15,3,8,6,0,5,230,6959,'Gnar'),
(15,3,9,5,2,9,184,5281,'Elise'),
(15,3,10,6,2,7,266,6753,'Ahri'),
(15,3,11,5,1,4,256,4955,'Caitlyn'),
(15,3,12,0,0,14,70,6215,'Braum'),
(15,3,22,3,4,1,265,5542,'Gnar'),
(15,3,23,0,5,7,199,4732,'Jarvan IV'),
(15,3,24,6,5,5,235,5267,'Ahri'),
(15,3,25,3,1,1,297,4680,'Ezreal'),
(15,3,26,0,6,6,37,4941,'Milio'),
(15,4,8,2,0,4,259,5220,'Jayce'),
(15,4,9,6,2,9,196,6532,'Kindred'),
(15,4,10,3,3,6,343,6187,'Galio'),
(15,4,11,6,3,5,315,6548,'Caitlyn'),
(15,4,12,1,3,10,75,4676,'Nami'),
(15,4,22,0,6,2,264,2848,'Gnar'),
(15,4,23,3,4,4,196,5444,'Kindred'),
(15,4,24,2,2,0,306,3402,'Ahri'),
(15,4,25,4,5,1,366,5051,'Zeri'),
(15,4,26,0,3,6,36,4411,'Blitzcrank'),
(16,1,1,5,3,6,246,5136,'Renekton'),
(16,1,2,1,1,9,198,5037,'Belveth'),
(16,1,3,5,0,4,255,4815,'Syndra'),
(16,1,4,5,2,4,318,4995,'Kaisa'),
(16,1,5,3,2,10,92,5890,'Rakan'),
(16,1,8,3,4,2,259,4415,'Renekton'),
(16,1,9,4,4,5,178,4439,'Viego'),
(16,1,10,0,4,3,247,4605,'Corki'),
(16,1,11,4,2,2,314,4980,'Ezreal'),
(16,1,12,0,3,6,27,4814,'Braum'),
(16,2,1,4,4,2,298,4219,'Renekton'),
(16,2,2,6,2,9,197,6085,'Nidalee'),
(16,2,3,7,2,5,308,6302,'Taliyah'),
(16,2,4,5,0,6,353,5685,'Sivir'),
(16,2,5,3,1,11,71,6312,'Renata'),
(16,2,8,0,2,3,296,3502,'Ornn'),
(16,2,9,3,5,5,230,5733,'Wukong'),
(16,2,10,0,2,5,302,4313,'Syndra'),
(16,2,11,2,4,2,374,4544,'Varus'),
(16,2,12,0,2,6,29,3010,'Nautilus'),
(16,3,1,5,4,6,180,4802,'Camille'),
(16,3,2,6,0,9,145,6502,'Wukong'),
(16,3,3,4,2,8,218,6503,'Taliyah'),
(16,3,4,8,1,3,254,5572,'Sivir'),
(16,3,5,1,4,10,86,5638,'Lulu'),
(16,3,8,3,4,2,211,5204,'Garen'),
(16,3,9,5,2,8,157,5960,'Jarvan IV'),
(16,3,10,5,4,1,202,4959,'Corki'),
(16,3,11,4,4,4,235,5700,'Jinx'),
(16,3,12,5,7,5,30,4634,'Soraka'),
(16,4,1,2,1,10,293,6555,'Gnar'),
(16,4,2,4,2,10,182,6531,'Vi'),
(16,4,3,4,2,9,232,5513,'Syndra'),
(16,4,4,4,1,7,303,6656,'Sivir'),
(16,4,5,3,1,12,30,6673,'Lulu'),
(16,4,8,2,4,2,221,4529,'Garen'),
(16,4,9,1,4,3,198,4276,'Wukong'),
(16,4,10,0,6,7,240,4019,'Akali'),
(16,4,11,0,4,1,324,3766,'Ezreal'),
(16,4,12,3,3,9,48,5681,'Renata'),
(26,1,1,4,2,2,236,5753,'Darius'),
(26,1,2,6,1,6,182,6543,'Vi'),
(26,1,3,4,3,7,276,6786,'Orianna'),
(26,1,4,4,3,2,257,5759,'Zeri'),
(26,1,5,3,1,10,75,6105,'Milio'),
(26,1,27,3,3,5,248,6032,'Renekton'),
(26,1,28,6,4,4,189,6075,'Graves'),
(26,1,29,5,3,2,217,4328,'Cassiopeia'),
(26,1,30,3,1,2,296,4879,'Aphelios'),
(26,1,31,0,3,6,53,4789,'Nami'),
(26,2,1,4,1,6,288,5620,'Jax'),
(26,2,2,5,3,12,232,7609,'Wukong'),
(26,2,3,5,1,4,326,5955,'Syndra'),
(26,2,4,5,0,5,397,5451,'Zeri'),
(26,2,5,3,1,10,70,5145,'Nami'),
(26,2,27,1,8,1,281,4171,'Gragas'),
(26,2,28,3,0,7,213,6081,'Wukong'),
(26,2,29,3,3,3,306,4351,'Syndra'),
(26,2,30,3,5,3,328,4286,'Ezreal'),
(26,2,31,3,5,9,66,4450,'Milio'),
(26,3,1,4,2,6,241,5432,'Malphite'),
(26,3,2,6,4,10,183,6693,'Viego'),
(26,3,3,7,1,7,252,7305,'Syndra'),
(26,3,4,6,0,9,340,6118,'Zeri'),
(26,3,5,4,0,16,42,7331,'Karma'),
(26,3,27,0,6,5,253,4187,'Garen'),
(26,3,28,1,2,1,178,4731,'Elise'),
(26,3,29,4,4,7,279,5957,'Zoe'),
(26,3,30,4,2,6,320,6602,'Aphelios'),
(26,3,31,0,5,9,86,4145,'Renata'),
(26,4,1,6,3,3,203,5415,'Renekton'),
(26,4,2,8,1,6,156,7100,'Wukong'),
(26,4,3,8,0,7,202,7777,'Orianna'),
(26,4,4,8,1,0,270,6691,'Zeri'),
(26,4,5,5,3,6,25,5184,'Alistar'),
(26,4,27,1,4,5,235,4451,'Aatrox'),
(26,4,28,1,2,4,160,4831,'Vi'),
(26,4,29,3,5,2,223,5213,'Zoe'),
(26,4,30,3,3,4,240,4282,'Lucian'),
(26,4,31,5,4,6,49,5011,'Braum'),
(27,1,8,8,4,6,287,7488,'Darius'),
(27,1,9,4,2,8,224,5710,'Hecarim'),
(27,1,10,7,2,4,302,6519,'Akali'),
(27,1,11,5,1,2,311,6283,'Caitlyn'),
(27,1,12,0,2,12,51,4882,'Milio'),
(27,1,17,1,4,2,252,4945,'Jax'),
(27,1,18,2,5,6,233,5164,'Vi'),
(27,1,19,3,2,2,287,4809,'Akali'),
(27,1,20,0,3,4,351,5099,'Ezreal'),
(27,1,21,1,3,4,57,3708,'Blitzcrank'),
(27,2,8,2,3,4,332,4386,'Renekton'),
(27,2,9,8,1,8,248,6270,'Elise'),
(27,2,10,3,3,5,351,4474,'Viktor'),
(27,2,11,8,1,4,366,7521,'Ezreal'),
(27,2,12,4,1,12,58,5705,'Milio'),
(27,2,17,2,4,1,315,4367,'Malphite'),
(27,2,18,3,3,3,244,4408,'Hecarim'),
(27,2,19,3,5,0,330,4833,'Lissandra'),
(27,2,20,2,1,0,366,4752,'Ezreal'),
(27,2,21,2,4,6,16,4250,'Rakan'),
(27,3,8,5,3,4,252,6121,'Aatrox'),
(27,3,9,6,2,7,198,6175,'Wukong'),
(27,3,10,7,3,4,323,6567,'Zoe'),
(27,3,11,7,0,5,308,5633,'Caitlyn'),
(27,3,12,0,2,10,37,4015,'Rakan'),
(27,3,17,4,5,2,288,5072,'Garen'),
(27,3,18,2,3,2,219,3353,'Kindred'),
(27,3,19,3,5,4,292,4755,'Ahri'),
(27,3,20,6,2,3,332,6355,'Caitlyn'),
(27,3,21,0,4,6,43,4750,'Karma'),
(27,4,8,5,2,8,282,6443,'Gragas'),
(27,4,9,2,1,8,241,4324,'Jarvan IV'),
(27,4,10,8,5,3,335,6261,'Zoe'),
(27,4,11,5,1,3,375,4861,'Caitlyn'),
(27,4,12,4,0,12,93,5342,'Nami'),
(27,4,17,1,2,3,334,4137,'Garen'),
(27,4,18,5,3,5,243,5260,'Belveth'),
(27,4,19,4,5,3,320,6238,'Ahri'),
(27,4,20,0,2,2,345,4882,'Miss Fortune'),
(27,4,21,0,0,3,106,3309,'Braum'),
(27,5,8,3,2,2,254,4919,'Darius'),
(27,5,9,4,2,8,220,5595,'Lee Sin'),
(27,5,10,10,3,8,282,7802,'Syndra'),
(27,5,11,4,1,6,300,5621,'Xayah'),
(27,5,12,1,1,10,56,4038,'Braum'),
(27,5,17,6,6,1,306,5595,'Renekton'),
(27,5,18,3,5,2,227,4724,'Wukong'),
(27,5,19,4,5,3,324,4990,'Lissandra'),
(27,5,20,0,1,2,335,3163,'Miss Fortune'),
(27,5,21,0,3,5,26,4658,'Blitzcrank'),
(28,1,1,6,1,4,224,5564,'Malphite'),
(28,1,2,8,1,7,196,7763,'Graves'),
(28,1,3,5,3,7,214,6350,'Viktor'),
(28,1,4,8,0,4,257,6837,'Varus'),
(28,1,5,0,2,10,54,4046,'Milio'),
(28,1,8,4,3,2,240,4138,'Jayce'),
(28,1,9,3,3,5,142,5743,'Graves'),
(28,1,10,5,4,3,239,5199,'Akali'),
(28,1,11,5,5,3,243,4775,'Jhin'),
(28,1,12,0,4,5,31,3721,'Renata'),
(28,2,1,4,4,2,201,4535,'Malphite'),
(28,2,2,6,1,7,128,6008,'Sejuani'),
(28,2,3,6,0,4,210,5151,'Galio'),
(28,2,4,6,0,5,264,6868,'Kaisa'),
(28,2,5,1,2,13,5,4843,'Alistar'),
(28,2,8,2,3,3,187,4319,'Camille'),
(28,2,9,4,3,3,157,4018,'Vi'),
(28,2,10,5,4,4,275,5417,'Corki'),
(28,2,11,8,3,4,211,7042,'Kaisa'),
(28,2,12,2,5,7,10,3954,'Lulu'),
(28,3,1,2,2,5,249,4289,'Gragas'),
(28,3,2,2,1,8,195,4780,'Viego'),
(28,3,3,6,2,3,290,5766,'Ahri'),
(28,3,4,9,3,4,304,6963,'Caitlyn'),
(28,3,5,2,3,9,61,4564,'Braum'),
(28,3,8,0,5,7,279,3746,'Malphite'),
(28,3,9,0,3,4,196,4780,'Kindred'),
(28,3,10,5,4,1,297,4975,'Galio'),
(28,3,11,1,4,0,281,4367,'Caitlyn'),
(28,3,12,2,5,4,73,5046,'Alistar'),
(55,1,32,2,2,2,210,3449,'Ornn'),
(55,1,2,5,0,8,191,5490,'Belveth'),
(55,1,34,5,3,3,279,5477,'Azir'),
(55,1,45,9,2,4,327,6051,'Zeri'),
(55,1,36,2,2,8,77,5476,'Milio'),
(55,1,1,4,3,5,233,5434,'Renekton'),
(55,1,6,4,3,5,155,4421,'Elise'),
(55,1,3,0,2,1,252,2817,'Corki'),
(55,1,4,2,1,1,276,4714,'Aphelios'),
(55,1,7,1,4,7,32,4304,'Soraka'),
(55,2,32,2,0,7,218,4917,'Gnar'),
(55,2,2,1,2,9,167,5722,'Elise'),
(55,2,34,5,0,7,237,6345,'Lissandra'),
(55,2,45,3,4,6,256,5233,'Aphelios'),
(55,2,36,0,4,9,29,4223,'Alistar'),
(55,2,1,1,3,5,229,4530,'Jayce'),
(55,2,6,0,5,4,178,3869,'Kindred'),
(55,2,3,5,4,5,214,4929,'Ahri'),
(55,2,4,4,1,4,240,4459,'Jhin'),
(55,2,7,7,3,4,13,5852,'Milio'),
(55,3,32,4,3,6,292,6118,'Garen'),
(55,3,2,6,3,10,265,7452,'Wukong'),
(55,3,34,6,4,4,309,5975,'Orianna'),
(55,3,45,9,3,7,331,7880,'Lucian'),
(55,3,36,0,2,9,66,3738,'Renata'),
(55,3,1,1,3,2,249,4896,'Jayce'),
(55,3,6,1,3,6,203,5471,'Kindred'),
(55,3,3,4,2,3,300,6164,'Azir'),
(55,3,4,4,6,1,321,4153,'Varus'),
(55,3,7,3,7,5,79,5066,'Rakan'),
(51,1,32,7,3,2,244,5238,'Garen'),
(51,1,2,2,0,6,241,4066,'Wukong'),
(51,1,34,10,4,6,265,6861,'Azir'),
(51,1,45,4,2,2,315,4723,'Ezreal'),
(51,1,36,4,1,12,22,5653,'Milio'),
(51,1,17,3,4,0,267,3851,'Renekton'),
(51,1,18,1,3,4,170,5002,'Elise'),
(51,1,58,4,4,1,299,4601,'Zoe'),
(51,1,20,1,3,2,324,3842,'Kaisa'),
(51,1,21,2,3,10,40,5846,'Nami'),
(51,2,32,8,1,5,312,6828,'Jayce'),
(51,2,2,3,2,13,243,6371,'Sejuani'),
(51,2,34,7,2,6,333,6679,'Galio'),
(51,2,45,8,0,2,372,7179,'Ezreal'),
(51,2,36,0,3,11,25,4449,'Nautilus'),
(51,2,17,0,5,3,325,3250,'Aatrox'),
(51,2,18,0,4,3,295,4433,'Jarvan IV'),
(51,2,58,7,7,0,350,5494,'Lissandra'),
(51,2,20,6,1,3,390,6054,'Lucian'),
(51,2,21,2,4,5,78,4441,'Thresh'),
(51,3,32,3,1,3,275,4232,'Darius'),
(51,3,2,8,2,8,214,7724,'Jarvan IV'),
(51,3,34,3,1,5,308,5020,'Akali'),
(51,3,45,3,0,2,288,5261,'Aphelios'),
(51,3,36,0,0,11,78,5796,'Renata'),
(51,3,17,0,3,1,245,3928,'Malphite'),
(51,3,18,0,2,6,221,3406,'Belveth'),
(51,3,58,4,4,5,275,4810,'Lissandra'),
(51,3,20,2,1,3,261,5359,'Xayah'),
(51,3,21,0,1,3,46,3898,'Renata'),
(51,4,32,3,2,7,261,5173,'Renekton'),
(51,4,2,3,4,8,146,5811,'Kindred'),
(51,4,34,5,1,6,267,5394,'Syndra'),
(51,4,45,6,0,4,249,5880,'Zeri'),
(51,4,36,0,1,11,27,4878,'Alistar'),
(51,4,17,0,3,1,234,4201,'Ornn'),
(51,4,18,2,5,4,156,4417,'Viego'),
(51,4,58,3,5,4,265,5940,'Taliyah'),
(51,4,20,3,2,0,253,3902,'Lucian'),
(51,4,21,0,2,5,38,3672,'Thresh'),
(52,1,1,5,1,5,271,5919,'Jayce'),
(52,1,6,1,4,10,197,4602,'Viego'),
(52,1,3,5,4,7,292,6309,'Syndra'),
(52,1,4,3,1,9,315,5238,'Kaisa'),
(52,1,7,3,1,17,20,6303,'Nami'),
(52,1,27,4,6,3,261,4248,'Renekton'),
(52,1,28,1,6,6,205,4540,'Lee Sin'),
(52,1,29,1,3,7,282,4872,'Taliyah'),
(52,1,30,3,3,3,351,4578,'Zeri'),
(52,1,46,2,6,6,28,5106,'Renata'),
(52,2,1,6,4,8,214,6483,'Fiora'),
(52,2,6,7,3,9,195,6502,'Elise'),
(52,2,3,8,2,5,262,6349,'Ahri'),
(52,2,4,4,0,5,307,5047,'Zeri'),
(52,2,7,1,0,13,72,6284,'Thresh'),
(52,2,27,3,2,0,200,4052,'Gragas'),
(52,2,28,3,7,2,188,4816,'Nidalee'),
(52,2,29,1,5,1,262,4334,'Zoe'),
(52,2,30,3,0,0,268,4512,'Kaisa'),
(52,2,46,0,4,7,41,4829,'Soraka'),
(52,3,1,6,1,4,284,6717,'Garen'),
(52,3,6,2,3,8,202,6044,'Kindred'),
(52,3,3,5,2,7,327,6358,'Akali'),
(52,3,4,3,0,5,353,4877,'Jinx'),
(52,3,7,2,0,13,61,4802,'Thresh'),
(52,3,27,7,4,7,307,5828,'Garen'),
(52,3,28,0,5,5,169,4410,'Graves'),
(52,3,29,0,6,0,326,3425,'Corki'),
(52,3,30,8,4,3,342,7295,'Xayah'),
(52,3,46,6,7,5,62,5130,'Alistar'),
(52,4,1,5,0,2,266,5200,'Aatrox'),
(52,4,6,4,3,7,205,5046,'Kindred'),
(52,4,3,6,1,5,257,6981,'Cassiopeia'),
(52,4,4,6,2,3,302,6230,'Jinx'),
(52,4,7,3,1,13,56,6067,'Renata'),
(52,4,27,2,1,6,307,4593,'Fiora'),
(52,4,28,0,3,5,165,3565,'Belveth'),
(52,4,29,7,1,1,278,5369,'Syndra'),
(52,4,30,0,2,2,302,4294,'Jinx'),
(52,4,46,0,4,4,74,3528,'Nami'),
(53,1,32,4,3,6,288,6221,'Garen'),
(53,1,2,1,2,8,243,5636,'Kindred'),
(53,1,34,8,1,9,291,6606,'Galio'),
(53,1,45,6,2,2,296,6426,'Xayah'),
(53,1,36,5,3,12,68,6815,'Alistar'),
(53,1,1,0,2,4,304,4691,'Malphite'),
(53,1,6,0,3,6,200,5259,'Wukong'),
(53,1,3,3,5,3,263,5420,'Azir'),
(53,1,4,6,1,2,313,5216,'Sivir'),
(53,1,7,0,5,3,59,3199,'Blitzcrank'),
(53,2,32,2,4,1,244,4717,'Gnar'),
(53,2,2,5,0,9,202,5347,'Sejuani'),
(53,2,34,8,0,9,260,7466,'Lissandra'),
(53,2,45,6,0,5,302,6320,'Ezreal'),
(53,2,36,0,2,11,32,5396,'Karma'),
(53,2,1,5,3,1,237,5752,'Renekton'),
(53,2,6,4,6,0,188,4686,'Elise'),
(53,2,3,5,3,3,251,6127,'Taliyah'),
(53,2,4,3,2,4,310,4259,'Miss Fortune'),
(53,2,7,2,5,5,48,4752,'Renata'),
(53,3,32,9,0,5,298,7135,'Ornn'),
(53,3,2,4,2,8,211,5409,'Kindred'),
(53,3,34,3,2,2,348,4263,'Azir'),
(53,3,45,8,0,5,395,6456,'Caitlyn'),
(53,3,36,2,3,10,73,5403,'Alistar'),
(53,3,1,4,4,1,266,5220,'Fiora'),
(53,3,6,2,3,3,253,3670,'Wukong'),
(53,3,3,4,4,1,328,5612,'Taliyah'),
(53,3,4,0,1,4,381,3449,'Aphelios'),
(53,3,7,2,7,8,44,3983,'Karma'),
(53,4,32,4,1,2,250,4367,'Camille'),
(53,4,2,6,2,11,231,7593,'Elise'),
(53,4,34,8,1,4,271,7281,'Corki'),
(53,4,45,5,0,2,336,6090,'Xayah'),
(53,4,36,2,0,12,49,5393,'Renata'),
(53,4,1,3,3,3,209,4580,'Fiora'),
(53,4,6,4,4,7,201,5380,'Elise'),
(53,4,3,5,3,2,254,4483,'Akali'),
(53,4,4,3,3,4,322,4922,'Ezreal'),
(53,4,7,1,3,4,62,3211,'Renata'),
(53,5,32,7,1,5,306,5640,'Aatrox'),
(53,5,2,2,3,8,246,4475,'Viego'),
(53,5,34,3,1,7,304,4583,'Zoe'),
(53,5,45,3,2,4,359,4715,'Zeri'),
(53,5,36,0,2,12,75,4499,'Braum'),
(53,5,1,3,5,2,332,5466,'Renekton'),
(53,5,6,0,7,4,224,4310,'Vi'),
(53,5,3,2,4,5,344,5761,'Ahri'),
(53,5,4,0,4,0,392,4470,'Ezreal'),
(53,5,7,2,4,4,105,3821,'Milio'),
(54,1,17,3,5,6,269,5761,'Renekton'),
(54,1,18,2,2,9,233,6088,'Wukong'),
(54,1,58,3,4,8,362,5192,'Corki'),
(54,1,20,6,1,4,285,5399,'Miss Fortune'),
(54,1,21,3,0,15,69,6916,'Soraka'),
(54,1,1,2,3,2,287,3789,'Jax'),
(54,1,6,1,4,2,222,4236,'Belveth'),
(54,1,3,0,3,4,281,3237,'Corki'),
(54,1,4,2,0,0,307,3437,'Aphelios'),
(54,1,7,0,3,5,48,4167,'Karma'),
(54,2,17,2,0,3,282,3830,'Ornn'),
(54,2,18,6,2,9,171,6900,'Lee Sin'),
(54,2,58,6,3,3,280,6224,'Lissandra'),
(54,2,20,10,5,3,308,7951,'Lucian'),
(54,2,21,6,4,12,62,6656,'Nautilus'),
(54,2,1,0,4,5,269,4214,'Fiora'),
(54,2,6,3,4,4,192,4586,'Elise'),
(54,2,3,6,5,6,259,6274,'Taliyah'),
(54,2,4,1,2,0,316,4565,'Jhin'),
(54,2,7,0,3,5,32,4324,'Nami'),
(54,3,17,6,1,5,302,5593,'Malphite'),
(54,3,18,4,4,9,211,6609,'Hecarim'),
(54,3,58,7,3,4,332,7130,'Akali'),
(54,3,20,3,1,2,351,5104,'Sivir'),
(54,3,21,0,4,8,34,4713,'Nautilus'),
(54,3,1,5,3,1,286,4710,'Gnar'),
(54,3,6,4,5,6,251,5823,'Graves'),
(54,3,3,1,3,1,330,4992,'Orianna'),
(54,3,4,4,2,3,381,4795,'Miss Fortune'),
(54,3,7,2,2,9,22,4986,'Alistar'),
(54,4,17,5,3,2,211,5059,'Darius'),
(54,4,18,2,2,7,178,5163,'Wukong'),
(54,4,58,6,1,7,245,5931,'Azir'),
(54,4,20,6,0,5,248,6092,'Jhin'),
(54,4,21,1,1,5,27,4214,'Nautilus'),
(54,4,1,2,2,3,243,5043,'Aatrox'),
(54,4,6,2,3,7,174,4711,'Wukong'),
(54,4,3,0,6,3,227,4564,'Viktor'),
(54,4,4,1,2,2,243,3425,'Varus'),
(54,4,7,2,5,6,50,4318,'Braum'),
(62,1,74,4,4,3,250,4742,'Garen'),
(62,1,39,4,5,12,171,5537,'Nidalee'),
(62,1,29,9,1,11,211,8547,'Orianna'),
(62,1,62,9,3,5,302,7750,'Miss Fortune'),
(62,1,75,2,0,9,45,4590,'Karma'),
(62,1,79,0,5,0,192,2574,'Ornn'),
(62,1,80,1,4,6,166,5478,'Jarvan IV'),
(62,1,81,3,4,3,210,5266,'Galio'),
(62,1,82,1,1,4,242,4198,'Sivir'),
(62,1,83,5,3,4,44,4768,'Karma'),
(62,2,74,4,2,7,173,6427,'Jayce'),
(62,2,39,5,1,6,130,4693,'Wukong'),
(62,2,29,7,1,0,235,5446,'Viktor'),
(62,2,62,10,1,6,233,8156,'Kaisa'),
(62,2,75,4,3,14,54,6736,'Rakan'),
(62,2,79,5,4,2,168,5015,'Darius'),
(62,2,80,3,4,5,165,5195,'Wukong'),
(62,2,81,1,4,5,219,3734,'Ahri'),
(62,2,82,2,1,2,253,5056,'Xayah'),
(62,2,83,2,5,5,58,5131,'Nautilus'),
(64,1,63,3,0,7,262,5723,'Darius'),
(64,1,77,6,3,9,229,7491,'Wukong'),
(64,1,10,4,1,7,315,5166,'Corki'),
(64,1,16,4,0,6,302,4990,'Caitlyn'),
(64,1,78,2,2,9,40,5274,'Karma'),
(64,1,17,3,2,4,227,4571,'Gnar'),
(64,1,18,0,4,4,180,3071,'Hecarim'),
(64,1,58,2,4,0,273,4227,'Ahri'),
(64,1,20,8,2,5,335,6984,'Jinx'),
(64,1,21,0,5,6,0,4477,'Nami'),
(64,2,63,5,2,5,278,4929,'Camille'),
(64,2,77,2,2,7,213,5513,'Jarvan IV'),
(64,2,10,8,3,5,286,6356,'Corki'),
(64,2,16,5,1,6,309,5818,'Caitlyn'),
(64,2,78,0,0,11,46,5172,'Braum'),
(64,2,17,2,1,3,276,4491,'Jax'),
(64,2,18,0,4,3,244,4454,'Vi'),
(64,2,58,5,5,3,285,6471,'Orianna'),
(64,2,20,0,2,2,320,3199,'Aphelios'),
(64,2,21,1,3,8,30,3620,'Renata'),
(64,3,63,5,1,8,307,6494,'Jayce'),
(64,3,77,7,3,7,248,6806,'Wukong'),
(64,3,10,5,3,8,336,6852,'Orianna'),
(64,3,16,6,3,9,369,6388,'Caitlyn'),
(64,3,78,0,2,14,95,6046,'Thresh'),
(64,3,17,0,3,2,273,3505,'Aatrox'),
(64,3,18,0,5,4,238,3839,'Hecarim'),
(64,3,58,0,4,5,352,3548,'Viktor'),
(64,3,20,5,3,2,396,5262,'Xayah'),
(64,3,21,1,4,7,82,4136,'Nautilus'),
(67,1,59,3,1,3,246,5424,'Gragas'),
(67,1,2,4,0,9,191,6841,'Hecarim'),
(67,1,76,8,2,4,258,5535,'Corki'),
(67,1,70,9,1,7,288,6538,'Aphelios'),
(67,1,65,1,2,10,50,4191,'Karma'),
(67,1,1,2,4,3,297,4489,'Gragas'),
(67,1,6,4,3,4,176,5187,'Belveth'),
(67,1,3,2,3,2,277,4810,'Orianna'),
(67,1,4,3,4,1,347,5179,'Jhin'),
(67,1,7,0,5,6,98,3374,'Renata'),
(67,2,59,5,2,3,292,4781,'Malphite'),
(67,2,2,3,4,6,231,6007,'Kindred'),
(67,2,76,9,3,5,341,7367,'Viktor'),
(67,2,70,7,4,7,375,7883,'Jinx'),
(67,2,65,2,2,10,91,4638,'Alistar'),
(67,2,1,6,3,0,278,4549,'Aatrox'),
(67,2,6,5,5,5,229,6307,'Sejuani'),
(67,2,3,6,6,1,332,5934,'Ahri'),
(67,2,4,2,2,2,346,3724,'Caitlyn'),
(67,2,7,3,3,9,87,6122,'Karma'),
(72,1,1,8,4,9,251,7139,'Jayce'),
(72,1,6,4,2,8,174,5187,'Belveth'),
(72,1,3,6,3,8,280,6823,'Orianna'),
(72,1,4,5,0,6,273,5125,'Kaisa'),
(72,1,7,1,3,9,18,4196,'Rakan'),
(72,1,63,5,4,4,239,6038,'Ornn'),
(72,1,77,0,4,3,207,3522,'Elise'),
(72,1,10,3,4,3,255,5520,'Corki'),
(72,1,16,9,4,0,282,5740,'Zeri'),
(72,1,78,3,5,5,83,5694,'Lulu'),
(72,2,1,11,4,5,303,8289,'Gragas'),
(72,2,6,2,4,9,197,5557,'Jarvan IV'),
(72,2,3,7,0,6,286,7006,'Zoe'),
(72,2,4,8,0,4,318,7295,'Aphelios'),
(72,2,7,1,2,12,53,5438,'Soraka'),
(72,2,63,5,4,1,289,5879,'Fiora'),
(72,2,77,2,5,6,170,3961,'Viego'),
(72,2,10,5,6,4,296,5769,'Azir'),
(72,2,16,5,2,4,316,4938,'Aphelios'),
(72,2,78,1,5,8,92,5305,'Alistar'),
(72,3,1,8,1,7,363,7596,'Ornn'),
(72,3,6,5,1,8,240,5808,'Nidalee'),
(72,3,3,6,1,5,295,7082,'Cassiopeia'),
(72,3,4,1,4,5,383,5049,'Ezreal'),
(72,3,7,7,0,12,87,7992,'Alistar'),
(72,3,63,4,6,3,372,4737,'Renekton'),
(72,3,77,3,3,4,219,5753,'Wukong'),
(72,3,10,2,4,3,351,4277,'Zoe'),
(72,3,16,3,2,0,392,4024,'Caitlyn'),
(72,3,78,0,4,5,59,3849,'Nami'),
(74,1,17,3,0,5,222,5826,'Malphite'),
(74,1,18,4,3,9,166,5230,'Lee Sin'),
(74,1,58,6,2,11,214,6570,'Corki'),
(74,1,20,10,1,4,242,7422,'Ezreal'),
(74,1,21,0,1,13,48,6041,'Lulu'),
(74,1,42,0,5,5,204,4510,'Fiora'),
(74,1,86,2,4,2,184,4273,'Graves'),
(74,1,37,3,4,6,253,5586,'Orianna'),
(74,1,87,2,2,3,289,3795,'Ezreal'),
(74,1,5,2,3,4,56,4665,'Soraka'),
(74,2,17,7,3,6,282,6320,'Gnar'),
(74,2,18,3,2,7,194,4888,'Viego'),
(74,2,58,9,3,6,258,6820,'Lissandra'),
(74,2,20,3,2,5,304,5050,'Lucian'),
(74,2,21,0,3,13,30,5815,'Blitzcrank'),
(74,2,42,1,4,5,226,4530,'Fiora'),
(74,2,86,5,2,3,166,4528,'Nidalee'),
(74,2,37,6,8,7,259,5626,'Galio'),
(74,2,87,0,4,0,324,3932,'Jinx'),
(74,2,5,2,3,10,24,4285,'Lulu'),
(76,1,1,3,3,4,287,5012,'Camille'),
(76,1,6,5,0,7,210,5818,'Lee Sin'),
(76,1,3,8,3,6,249,7692,'Orianna'),
(76,1,4,5,1,4,356,5516,'Caitlyn'),
(76,1,7,2,4,9,43,4388,'Nami'),
(76,1,63,0,5,1,254,3468,'Gnar'),
(76,1,77,2,3,3,216,4244,'Elise'),
(76,1,10,1,6,2,332,5021,'Azir'),
(76,1,16,1,0,3,349,4971,'Varus'),
(76,1,78,1,2,5,26,3284,'Soraka'),
(76,2,1,1,3,3,242,4291,'Fiora'),
(76,2,6,6,0,10,194,6725,'Elise'),
(76,2,3,9,4,6,246,6486,'Corki'),
(76,2,4,7,0,0,292,6127,'Kaisa'),
(76,2,7,2,5,8,44,4141,'Karma'),
(76,2,63,4,4,1,223,5578,'Ornn'),
(76,2,77,1,3,7,216,5315,'Sejuani'),
(76,2,10,3,4,7,262,6071,'Cassiopeia'),
(76,2,16,5,1,2,265,5168,'Kaisa'),
(76,2,78,4,4,6,42,6050,'Blitzcrank'),
(76,3,1,3,0,6,295,6038,'Darius'),
(76,3,6,4,0,8,272,6688,'Graves'),
(76,3,3,5,2,5,343,6213,'Zoe'),
(76,3,4,6,1,10,358,7735,'Xayah'),
(76,3,7,0,1,11,87,4810,'Alistar'),
(76,3,63,1,5,2,309,4561,'Camille'),
(76,3,77,5,3,5,252,5246,'Belveth'),
(76,3,10,4,1,1,303,5350,'Azir'),
(76,3,16,2,0,4,358,4773,'Jhin'),
(76,3,78,0,4,5,32,3202,'Nami'),
(83,1,1,4,1,1,193,5592,'Jayce'),
(83,1,6,4,3,10,183,6209,'Wukong'),
(83,1,3,5,3,6,186,5916,'Orianna'),
(83,1,4,10,0,4,233,6523,'Jhin'),
(83,1,7,4,1,13,26,6401,'Renata'),
(83,1,79,1,4,5,210,4658,'Gnar'),
(83,1,80,6,5,0,157,4895,'Nidalee'),
(83,1,81,3,4,4,210,4330,'Akali'),
(83,1,82,1,3,4,232,4011,'Aphelios'),
(83,1,83,1,4,3,90,3571,'Renata'),
(83,2,1,7,2,6,270,6720,'Ornn'),
(83,2,6,1,2,11,200,5647,'Viego'),
(83,2,3,2,4,6,261,4430,'Corki'),
(83,2,4,6,1,3,322,5284,'Varus'),
(83,2,7,1,0,11,77,4809,'Thresh'),
(83,2,79,4,5,1,230,5497,'Gnar'),
(83,2,80,2,5,4,158,4207,'Lee Sin'),
(83,2,81,8,1,1,293,5871,'Corki'),
(83,2,82,5,5,2,285,4829,'Kaisa'),
(83,2,83,2,4,8,49,4150,'Renata'),
(85,1,84,4,0,3,278,5785,'Jayce'),
(85,1,69,3,0,10,205,6522,'Kindred'),
(85,1,24,7,2,5,284,5935,'Azir'),
(85,1,85,6,0,5,312,6035,'Sivir'),
(85,1,51,4,3,9,28,5463,'Milio'),
(85,1,17,0,4,2,293,3905,'Camille'),
(85,1,18,0,2,7,155,4093,'Hecarim'),
(85,1,58,2,4,0,268,4545,'Cassiopeia'),
(85,1,20,3,2,0,276,5162,'Sivir'),
(85,1,21,0,3,8,63,4807,'Braum'),
(85,2,84,6,2,5,282,5720,'Gragas'),
(85,2,69,4,2,9,179,5503,'Graves'),
(85,2,24,7,1,6,233,7018,'Zoe'),
(85,2,85,7,1,4,256,7043,'Jinx'),
(85,2,51,4,1,11,24,5599,'Soraka'),
(85,2,17,4,5,0,233,5078,'Darius'),
(85,2,18,3,2,5,165,5405,'Sejuani'),
(85,2,58,7,5,4,259,6427,'Cassiopeia'),
(85,2,20,4,0,3,289,4962,'Sivir'),
(85,2,21,4,4,9,0,4817,'Braum'),
(85,3,84,6,1,4,283,5501,'Renekton'),
(85,3,69,3,4,7,188,5506,'Wukong'),
(85,3,24,1,0,5,288,4697,'Cassiopeia'),
(85,3,85,6,0,4,328,5764,'Varus'),
(85,3,51,1,0,13,33,5571,'Milio'),
(85,3,17,7,4,0,279,5673,'Aatrox'),
(85,3,18,4,5,5,272,4597,'Viego'),
(85,3,58,3,6,2,313,4766,'Akali'),
(85,3,20,4,1,4,324,4691,'Sivir'),
(85,3,21,1,4,5,57,4288,'Soraka'),
(86,1,71,6,0,7,237,7146,'Aatrox'),
(86,1,9,2,1,7,196,5732,'Kindred'),
(86,1,72,8,0,4,295,6818,'Azir'),
(86,1,11,6,0,4,300,6349,'Sivir'),
(86,1,73,4,2,9,21,5713,'Karma'),
(86,1,63,2,4,4,230,5343,'Garen'),
(86,1,77,2,2,4,204,3855,'Belveth'),
(86,1,10,4,7,4,282,5914,'Corki'),
(86,1,16,6,3,2,288,6502,'Xayah'),
(86,1,78,0,4,1,46,2250,'Soraka'),
(86,2,71,4,0,2,219,5831,'Garen'),
(86,2,9,6,0,8,151,6971,'Kindred'),
(86,2,72,8,3,5,215,7385,'Orianna'),
(86,2,11,4,2,4,239,5092,'Xayah'),
(86,2,73,4,2,13,56,6695,'Alistar'),
(86,2,63,0,4,1,203,4065,'Gragas'),
(86,2,77,1,3,3,151,3759,'Kindred'),
(86,2,10,5,6,4,224,5659,'Taliyah'),
(86,2,16,1,1,2,228,4249,'Varus'),
(86,2,78,4,3,4,3,4899,'Braum'),
(86,3,71,6,1,6,302,6084,'Gnar'),
(86,3,9,5,2,8,271,5828,'Viego'),
(86,3,72,6,5,5,312,6717,'Taliyah'),
(86,3,11,10,2,8,391,8496,'Lucian'),
(86,3,73,4,0,10,53,6412,'Blitzcrank'),
(86,3,63,2,6,4,293,5745,'Gragas'),
(86,3,77,1,6,6,237,4944,'Wukong'),
(86,3,10,5,1,2,300,5946,'Galio'),
(86,3,16,0,2,3,316,3684,'Ezreal'),
(86,3,78,2,6,6,70,4692,'Soraka');

-- ============================================================
-- CLASIFICACION ANUAL
-- ============================================================
INSERT INTO clasificacion_anual (año, id_equipo, puntos_totales, seed_worlds) VALUES
(2024, 1, 325, 1),(2024, 2, 270, 2),(2024, 4, 120, 3),
(2024, 6, 90,  NULL),(2024, 3, 95, NULL),(2024, 5, 70, NULL),
(2024, 9, 0, NULL),(2024, 7, 0, NULL),(2024, 8, 0, NULL),(2024, 10, 0, NULL),
(2025, 12, 0, 1),(2025, 1, 0, 2),(2025, 7, 0, NULL),(2025, 6, 0, NULL),
(2025, 2, 0, NULL),(2025, 3, 0, NULL),(2025, 8, 0, NULL),
(2025, 9, 0, NULL),(2025, 5, 0, NULL),(2025, 10, 0, NULL);

-- ============================================================
-- TABLA ADMIN
-- ============================================================
-- usuarios_admin: definida al final del script


-- ============================================================

-- ============================================================
-- PARTIDOS DE PLAYOFFS
-- ============================================================
USE lec;
SET FOREIGN_KEY_CHECKS = 0;
SET @admin_bypass = 1;
-- Ejecutar DESPUÉS de lec_datos.sql

-- WINTER 2024 (split 1, fase 1)
-- h1=G2, h2=FNC, h3=VIT, h4=MAD Lions, h5=KC, h6=GX
-- Ya existe: partido 1 → G2 vs FNC 3-1 (Grand Final 2024-02-18)
-- Añadimos el resto del bracket
INSERT INTO partido (id_partido, id_fase, id_historial_equipo_1, id_historial_equipo_2, fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado) VALUES
-- UB Semis
(200, 1, 1, 4, '2024-02-10 17:00:00', 'Bo5', 3, 1, TRUE),  -- G2 vs MAD → G2 wins
(201, 1, 2, 3, '2024-02-10 20:00:00', 'Bo5', 3, 2, TRUE),  -- FNC vs VIT → FNC wins
-- LB Round 1 (seeds 5,6 + UB losers)
(202, 1, 4, 6, '2024-02-11 17:00:00', 'Bo5', 3, 0, TRUE),  -- MAD vs GX → MAD wins
(203, 1, 3, 5, '2024-02-11 20:00:00', 'Bo5', 3, 1, TRUE),  -- VIT vs KC → VIT wins
-- UB Final
(204, 1, 1, 2, '2024-02-14 18:00:00', 'Bo5', 3, 1, TRUE),  -- G2 vs FNC → G2 wins, FNC drops
-- LB Semi
(205, 1, 4, 3, '2024-02-15 18:00:00', 'Bo5', 3, 2, TRUE),  -- MAD vs VIT → MAD wins
-- LB Final
(206, 1, 2, 4, '2024-02-17 18:00:00', 'Bo5', 3, 1, TRUE);  -- FNC vs MAD → FNC wins
-- Grand Final ya existe: partido 1 (G2 vs FNC 3-1, 2024-02-18) ✓

-- SPRING 2024 (split 2, fase 3)
-- h11=G2, h12=FNC, h13=VIT, h15=KC
-- Ya existen: 14(G2-VIT 3-1), 15(FNC-KC 3-1), 16(G2-FNC 3-1)
-- Añadimos LB matches
INSERT INTO partido (id_partido, id_fase, id_historial_equipo_1, id_historial_equipo_2, fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado) VALUES
(207, 3, 13, 15, '2024-04-07 17:00:00', 'Bo5', 3, 1, TRUE),  -- VIT vs KC → VIT
(208, 3, 12, 13, '2024-04-13 17:00:00', 'Bo5', 3, 2, TRUE);  -- FNC vs VIT → FNC (LB Final)
-- Grand Final ya existe: partido 16 (G2-FNC 3-1, 2024-04-14) ✓

-- SUMMER 2024 (split 3, fase 5)
-- h21=G2, h22=FNC, h24=MAD Lions, h26=GX
-- Ya existen: 26(G2-GX 3-1), 27(FNC-MAD 3-2), 28(G2-FNC 3-0)
-- Añadimos LB matches
INSERT INTO partido (id_partido, id_fase, id_historial_equipo_1, id_historial_equipo_2, fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado) VALUES
(209, 5, 26, 24, '2024-07-22 17:00:00', 'Bo5', 3, 1, TRUE),  -- GX vs MAD → GX (LB R1)
(210, 5, 22, 26, '2024-07-27 17:00:00', 'Bo5', 3, 2, TRUE);  -- FNC vs GX → FNC (LB Final)
-- Grand Final ya existe: partido 28 (G2-FNC 3-0, 2024-07-28) ✓

-- SPRING 2025 (split 4, fase 7)
-- h31=G2, h34=GX, h35=KC, h38=MKOI
-- Ya existen: 51(KC-MKOI 1-3), 52(G2-GX 3-1), 53(KC-G2 3-2), 54(MKOI-G2 3-1)
-- Añadimos UB Final y LB Semi que faltaban
INSERT INTO partido (id_partido, id_fase, id_historial_equipo_1, id_historial_equipo_2, fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado) VALUES
(211, 7, 38, 31, '2025-05-28 17:00:00', 'Bo5', 1, 3, TRUE),  -- MKOI vs G2 → G2 wins UB Final, MKOI drops LB
(212, 7, 34, 35, '2025-05-28 20:00:00', 'Bo5', 0, 3, TRUE);  -- GX vs KC → KC wins LB R1
-- LB Final ya existe: partido 53 (KC-G2 3-2, 2025-05-31) → KC beats G2 en LB
-- Grand Final: partido 54 (MKOI-G2 3-1, 2025-06-08) → MKOI vuelve y gana

-- WINTER 2025 (split 5, fase 9)
-- h41=SK, h42=G2, h43=FNC, h44=MKOI
-- Ya existe: partido 55 (SK-G2 3-0, 2025-03-02) → Grand Final
-- Añadimos el bracket completo
INSERT INTO partido (id_partido, id_fase, id_historial_equipo_1, id_historial_equipo_2, fecha_hora, tipo_serie, mapas_eq1, mapas_eq2, finalizado) VALUES
-- UB Semis
(213, 9, 41, 44, '2025-02-22 17:00:00', 'Bo5', 3, 1, TRUE),  -- SK vs MKOI → SK wins
(214, 9, 42, 43, '2025-02-22 20:00:00', 'Bo5', 3, 2, TRUE),  -- G2 vs FNC → G2 wins
-- UB Final
(215, 9, 41, 42, '2025-02-27 18:00:00', 'Bo5', 3, 1, TRUE),  -- SK vs G2 → SK wins, G2 drops LB
-- LB Match (UB Semi losers)
(216, 9, 44, 43, '2025-02-24 17:00:00', 'Bo5', 3, 2, TRUE),  -- MKOI vs FNC → MKOI wins
-- LB Final
(217, 9, 42, 44, '2025-03-01 18:00:00', 'Bo5', 3, 1, TRUE);  -- G2 vs MKOI → G2 wins, goes to Grand Final
-- Grand Final ya existe: partido 55 (SK-G2 3-0, 2025-03-02) ✓
SET FOREIGN_KEY_CHECKS = 1;
SET @admin_bypass = NULL;

-- ============================================================
-- ROSTER SPRING 2026 — Jugadores, nombres correctos y entrenadores
-- ============================================================
-- ============================================================
-- 1. CORREGIR NOMBRES Y DATOS DE JUGADORES
-- ============================================================
UPDATE jugador SET nickname='Hans Sama', nombre_real='Steven Liv',          nacionalidad='Francia'        WHERE id_jugador=4;
UPDATE jugador SET nombre_real='Lampros Papoutsakis',  nacionalidad='Grecia'         WHERE id_jugador=7;
UPDATE jugador SET nombre_real='Iván Martín Díaz',    nacionalidad='España'         WHERE id_jugador=9;
UPDATE jugador SET nombre_real='Marek Brázda',         nacionalidad='Rep. Checa'     WHERE id_jugador=10;
UPDATE jugador SET nombre_real='Alex Pastor Villarejo',nacionalidad='España'         WHERE id_jugador=17;
UPDATE jugador SET nombre_real='Ilias Bizriken',       nacionalidad='Francia'        WHERE id_jugador=24;
UPDATE jugador SET nombre_real='Yoon Sang-hoon',       nacionalidad='Corea del Sur'  WHERE id_jugador=25;
UPDATE jugador SET nombre_real='Panagiotis Tantis',    nacionalidad='Grecia'         WHERE id_jugador=71;
UPDATE jugador SET nombre_real='Vladimiros Kourtidis', nacionalidad='Grecia'         WHERE id_jugador=72;
UPDATE jugador SET nombre_real='Park Joon-hyeong',     nacionalidad='Corea del Sur'  WHERE id_jugador=73;
UPDATE jugador SET nombre_real='Linas Nauncikas',      nacionalidad='Lituania'       WHERE id_jugador=77;
UPDATE jugador SET nombre_real='Kadir Kemiksiz',       nacionalidad='Turquía'        WHERE id_jugador=78;
UPDATE jugador SET nombre_real='Volodymyr Sorokin',    nacionalidad='Ucrania'        WHERE id_jugador=79;
UPDATE jugador SET nombre_real='Enes Uçan',            nacionalidad='Turquía'        WHERE id_jugador=80;
UPDATE jugador SET nombre_real='Yoon Sung-won',        nacionalidad='Corea del Sur'  WHERE id_jugador=81;
UPDATE jugador SET nombre_real='Lee Jae-hoon',         nacionalidad='Corea del Sur'  WHERE id_jugador=82;
UPDATE jugador SET nombre_real='Shin Yun-hwan',        nacionalidad='Corea del Sur'  WHERE id_jugador=84;
UPDATE jugador SET nombre_real='Park Seok-hyeon',      nacionalidad='Corea del Sur'  WHERE id_jugador=85;
UPDATE jugador SET nombre_real='Josip Čančar',         nacionalidad='Croacia'        WHERE id_jugador=87;
UPDATE jugador SET nombre_real='Tolga Ölmez',          nacionalidad='Turquía'        WHERE id_jugador=88;
UPDATE jugador SET nombre_real='Paul Lardin',          nacionalidad='Francia'        WHERE id_jugador=89;
UPDATE jugador SET nombre_real='Théo Borile',          nacionalidad='Francia'        WHERE id_jugador=23;
UPDATE jugador SET nombre_real='Sebastian Wojtoń',     nacionalidad='Polonia'        WHERE id_jugador=60;
UPDATE jugador SET nombre_real='Kaan Okan',            nacionalidad='Turquía'        WHERE id_jugador=63;

-- ============================================================
-- 2. LIMPIAR Y RECONSTRUIR JUGADOR_EQUIPO_HISTORIAL SPRING 2026
-- ============================================================
DELETE FROM jugador_equipo_historial
WHERE id_historial_equipo IN (51,52,53,54,55,56,57,58,59,60);

SET @admin_bypass = 1;
SET FOREIGN_KEY_CHECKS = 0;

-- hist=51: G2 Esports
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(51, 1,  'Top',     TRUE, '2026-01-10'),  -- BrokenBlade
(51, 6,  'Jungle',  TRUE, '2026-01-10'),  -- SkewMond
(51, 3,  'Mid',     TRUE, '2026-01-10'),  -- Caps
(51, 4,  'ADC',     TRUE, '2026-01-10'),  -- Hans Sama
(51, 7,  'Support', TRUE, '2026-01-10');  -- Labrov

-- hist=52: Fnatic
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(52, 71, 'Top',     TRUE, '2026-01-10'),  -- Empyros
(52, 9,  'Jungle',  TRUE, '2026-01-10'),  -- Razork
(52, 72, 'Mid',     TRUE, '2026-01-10'),  -- Vladi
(52, 11, 'ADC',     TRUE, '2026-01-10'),  -- Upset
(52, 73, 'Support', TRUE, '2026-01-10');  -- Lospa

-- hist=53: Team Vitality
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(53, 63, 'Top',     TRUE, '2026-01-10'),  -- Naak Nako
(53, 77, 'Jungle',  TRUE, '2026-01-10'),  -- Lyncas
(53, 10, 'Mid',     TRUE, '2026-01-10'),  -- Humanoid
(53, 16, 'ADC',     TRUE, '2026-01-10'),  -- Carzzy
(53, 78, 'Support', TRUE, '2026-01-10');  -- Fleshy

-- hist=54: GIANTX
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(54, 74, 'Top',     TRUE, '2026-01-10'),  -- Lot
(54, 39, 'Jungle',  TRUE, '2026-01-10'),  -- ISMA
(54, 29, 'Mid',     TRUE, '2026-01-10'),  -- Jackies
(54, 62, 'ADC',     TRUE, '2026-01-10'),  -- Noah
(54, 75, 'Support', TRUE, '2026-01-10');  -- Jun

-- hist=55: Karmine Corp
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(55, 59, 'Top',     TRUE, '2026-01-10'),  -- Canna
(55, 2,  'Jungle',  TRUE, '2026-01-10'),  -- Yike
(55, 76, 'Mid',     TRUE, '2026-01-10'),  -- kyeahoo
(55, 70, 'ADC',     TRUE, '2026-01-10'),  -- Caliste
(55, 65, 'Support', TRUE, '2026-01-10');  -- Busio

-- hist=56: SK Gaming
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(56, 42, 'Top',     TRUE, '2026-01-10'),  -- Wunder
(56, 86, 'Jungle',  TRUE, '2026-01-10'),  -- Skeanz
(56, 37, 'Mid',     TRUE, '2026-01-10'),  -- LIDER
(56, 87, 'ADC',     TRUE, '2026-01-10'),  -- Jopa
(56, 5,  'Support', TRUE, '2026-01-10');  -- Mikyx

-- hist=57: Team Heretics
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(57, 60, 'Top',     TRUE, '2026-01-10'),  -- Tracyn
(57, 23, 'Jungle',  TRUE, '2026-01-10'),  -- Sheo
(57, 88, 'Mid',     TRUE, '2026-01-10'),  -- Serin
(57, 25, 'ADC',     TRUE, '2026-01-10'),  -- Ice
(57, 89, 'Support', TRUE, '2026-01-10');  -- Stend

-- hist=58: Movistar KOI
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(58, 17, 'Top',     TRUE, '2026-01-10'),  -- Myrwn
(58, 18, 'Jungle',  TRUE, '2026-01-10'),  -- Elyoya
(58, 58, 'Mid',     TRUE, '2026-01-10'),  -- Jojopyun
(58, 20, 'ADC',     TRUE, '2026-01-10'),  -- Supa
(58, 21, 'Support', TRUE, '2026-01-10');  -- Alvaro

-- hist=59: Shifters
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(59, 84, 'Top',     TRUE, '2026-01-10'),  -- Rooster
(59, 69, 'Jungle',  TRUE, '2026-01-10'),  -- Boukada
(59, 24, 'Mid',     TRUE, '2026-01-10'),  -- nuc
(59, 85, 'ADC',     TRUE, '2026-01-10'),  -- Paduck
(59, 51, 'Support', TRUE, '2026-01-10');  -- Trymbi

-- hist=60: Natus Vincere
INSERT INTO jugador_equipo_historial (id_historial_equipo, id_jugador, rol, es_titular, fecha_inicio) VALUES
(60, 79, 'Top',     TRUE, '2026-01-10'),  -- Maynter
(60, 80, 'Jungle',  TRUE, '2026-01-10'),  -- Rhilech
(60, 81, 'Mid',     TRUE, '2026-01-10'),  -- Poby
(60, 82, 'ADC',     TRUE, '2026-01-10'),  -- SamD
(60, 83, 'Support', TRUE, '2026-01-10');  -- Parus

SET FOREIGN_KEY_CHECKS = 1;
SET @admin_bypass = NULL;

-- ============================================================
-- 3. ENTRENADORES SPRING 2026
-- ============================================================
INSERT IGNORE INTO entrenador
    (id_entrenador, nickname, nombre, nacionalidad, activo) VALUES
(1,  'GrabbZ',       'Fabian Lohmann',       'Alemania',      TRUE),  -- Fnatic
(2,  'Dylan Falco',  'Dylan Falco',           'Francia',       TRUE),  -- G2
(3,  'Guilhoto',     'André Guilhoto',        'Brasil',        TRUE),  -- GIANTX
(4,  'Reapered',     'Bok Han-gyu',           'Corea del Sur', TRUE),  -- Karmine Corp
(5,  'Melzhet',      'Tomás Campelos',        'España',        TRUE),  -- Movistar KOI
(6,  'TheRock',      'Vasilis Voltis',        'Grecia',        TRUE),  -- Natus Vincere
(7,  'Striker',      'Yanis Kella',           'Francia',       TRUE),  -- Shifters
(8,  'OWN3R',        'David Rodriguez',       'España',        TRUE),  -- SK Gaming
(9,  'Hidon',        'Jonas Vraa',            'Dinamarca',     TRUE),  -- Team Heretics
(10, 'Pad',          'Patrick Suckow-Breum',  'Dinamarca',     TRUE);  -- Team Vitality

-- ============================================================
-- 4. LIGAR ENTRENADORES A EQUIPOS SPRING 2026
-- ============================================================
INSERT IGNORE INTO entrenador_equipo_historial
    (id_entrenador, id_historial_equipo, fecha_inicio) VALUES
(1,  52, '2026-01-10'),  -- GrabbZ → Fnatic
(2,  51, '2026-01-10'),  -- Dylan Falco → G2
(3,  54, '2026-01-10'),  -- Guilhoto → GIANTX
(4,  55, '2026-01-10'),  -- Reapered → Karmine Corp
(5,  58, '2026-01-10'),  -- Melzhet → Movistar KOI
(6,  60, '2026-01-10'),  -- TheRock → Natus Vincere
(7,  59, '2026-01-10'),  -- Striker → Shifters
(8,  56, '2026-01-10'),  -- OWN3R → SK Gaming
(9,  57, '2026-01-10'),  -- Hidon → Team Heretics
(10, 53, '2026-01-10');  -- Pad → Team Vitality

SELECT 'Roster Spring 2026 actualizado correctamente' AS resultado;


-- ============================================================
-- TABLA DE USUARIOS WEB
-- ============================================================
USE lec;
DROP TABLE IF EXISTS usuarios_admin;
CREATE TABLE usuarios_admin (
    id_usuario     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(80)  NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    rol            ENUM('superadmin','editor','auditor') NOT NULL DEFAULT 'editor',
    activo         BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso  DATETIME NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Contraseña de los tres: "password" — cambiar desde gestionar_usuarios.php
INSERT INTO usuarios_admin (nombre, email, password_hash, rol) VALUES
('Administrador', 'admin@lec.es',
 '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'superadmin'),
('Editor LEC', 'editor@lec.es',
 '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'editor'),
('Auditor LEC', 'auditor@lec.es',
 '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'auditor');

-- ============================================================
-- Con DB_USE_ROLES=false en .env estos usuarios no se usan
-- ============================================================
USE lec;

DROP USER IF EXISTS 'lec_admin'@'localhost';
DROP USER IF EXISTS 'lec_backend'@'localhost';
DROP USER IF EXISTS 'lec_readonly'@'localhost';
DROP USER IF EXISTS 'lec_auditor'@'localhost';

-- lec_admin: acceso total
CREATE USER 'lec_admin'@'localhost' IDENTIFIED BY 'Admin_LEC@2026!';
GRANT ALL PRIVILEGES ON lec.* TO 'lec_admin'@'localhost' WITH GRANT OPTION;

-- lec_backend: lectura + escritura + ejecución de SPs
CREATE USER 'lec_backend'@'localhost' IDENTIFIED BY 'Backend_LEC@2026!';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON lec.* TO 'lec_backend'@'localhost';

-- lec_readonly: solo lectura + ejecución de SPs (sin auditoria)
CREATE USER 'lec_readonly'@'localhost' IDENTIFIED BY 'Readonly_LEC@2026!';
GRANT SELECT, EXECUTE ON lec.* TO 'lec_readonly'@'localhost';

-- lec_auditor: solo tabla de auditoría
CREATE USER 'lec_auditor'@'localhost' IDENTIFIED BY 'Auditor_LEC@2026!';
GRANT SELECT ON lec.auditoria_lec TO 'lec_auditor'@'localhost';