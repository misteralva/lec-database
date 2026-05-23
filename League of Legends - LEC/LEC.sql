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