-- 1. Tabla de Competiciones
CREATE TABLE competiciones (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    city VARCHAR,
    course VARCHAR(10),
    timing VARCHAR(50),
    nation VARCHAR(10),
    pool_min_lane INTEGER,
    pool_max_lane INTEGER,
    start_date DATE,
    end_date DATE,
    -- Añadimos esto para que no se dupliquen competiciones al subir el mismo JSON
    UNIQUE(name, city, start_date) 
);

-- 2. Tabla de Clubes
CREATE TABLE clubes (
    club_code VARCHAR PRIMARY KEY,
    club_nation VARCHAR(10),
    club_region VARCHAR(50),
    club_name VARCHAR NOT NULL,
    club_shortname VARCHAR,
    es_federacion BOOLEAN DEFAULT FALSE
);

-- 3. Tabla de Nadadores
CREATE TABLE nadadores (
    athleteid VARCHAR PRIMARY KEY,
    firstname VARCHAR NOT NULL,
    lastname VARCHAR NOT NULL,
    birthdate DATE,
    birthyear INTEGER,
    gender VARCHAR(5),
    nation VARCHAR(10)
);

-- 4. Tabla intermedia: Nadadores_Clubes
CREATE TABLE nadadores_clubes (
    athleteid VARCHAR REFERENCES nadadores(athleteid) ON DELETE CASCADE,
    club_code VARCHAR REFERENCES clubes(club_code) ON DELETE CASCADE,
    PRIMARY KEY (athleteid, club_code)
);

-- 5. Resultados Individuales
CREATE TABLE resultados_individuales (
    id SERIAL PRIMARY KEY,
    competicion_id INTEGER REFERENCES competiciones(id) ON DELETE CASCADE,
    athleteid VARCHAR REFERENCES nadadores(athleteid) ON DELETE CASCADE,
    club_code VARCHAR REFERENCES clubes(club_code) ON DELETE SET NULL,
    place INTEGER,
    orden INTEGER,
    daytime VARCHAR(20),
    num_prueba INTEGER,
    round VARCHAR(20),
    style VARCHAR(20),
    distance INTEGER,
    event_date DATE, 
    heat INTEGER,
    lane INTEGER,
    points INTEGER,
    reactiontime NUMERIC,
    swimtime NUMERIC,
    entry_swimtime NUMERIC,
    entry_course VARCHAR(10),
    estado VARCHAR(20),
    UNIQUE(competicion_id, athleteid, num_prueba, round) 
);

-- 6. Resultados Relevos (Equipos)
CREATE TABLE resultados_relevos (
    id SERIAL PRIMARY KEY,
    competicion_id INTEGER REFERENCES competiciones(id) ON DELETE CASCADE,
    club_code VARCHAR REFERENCES clubes(club_code) ON DELETE CASCADE,
    place INTEGER,
    orden INTEGER,
    daytime VARCHAR(20),
    num_prueba INTEGER,
    round VARCHAR(20),
    style VARCHAR(20),
    distance INTEGER,
    gender VARCHAR(5),
    event_date DATE, 
    heat INTEGER,
    lane INTEGER,
    points INTEGER,
    swimtime NUMERIC,
    entry_swimtime NUMERIC,
    entry_course VARCHAR(10),
    estado VARCHAR(20),
    UNIQUE(competicion_id, club_code, num_prueba, round)
);

-- 7. Relevistas
CREATE TABLE relevistas (
    id SERIAL PRIMARY KEY,
    relevo_id INTEGER REFERENCES resultados_relevos(id) ON DELETE CASCADE,
    athleteid VARCHAR REFERENCES nadadores(athleteid) ON DELETE SET NULL,
    num_relevista INTEGER,
    reactiontime NUMERIC,
    leg_time NUMERIC,
    UNIQUE(relevo_id, num_relevista)
);

-- 8. Parciales (Splits)
CREATE TABLE parciales (
    id SERIAL PRIMARY KEY,
    resultado_indiv_id INTEGER REFERENCES resultados_individuales(id) ON DELETE CASCADE,
    relevista_id INTEGER REFERENCES relevistas(id) ON DELETE CASCADE,
    distance INTEGER, 
    cumswimtime NUMERIC, 
    parcial_swimtime NUMERIC, 
    parcial_distance INTEGER, 
    leg_time NUMERIC,
    CHECK (
        (resultado_indiv_id IS NOT NULL AND relevista_id IS NULL) OR 
        (resultado_indiv_id IS NULL AND relevista_id IS NOT NULL)
    )
);