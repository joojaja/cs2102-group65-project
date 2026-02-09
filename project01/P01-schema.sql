--
-- Group Number: 65
-- Group Members:
--   1. Brian Hu
--   2. Lee Jun Heng
--   3. Lip Pink Ray
--   4. Toh Keng Hian
--

-- If Country is Updated, propagate to Team, Rider, Location
-- If Country is Deleted, blocked if referenced
CREATE TABLE IF NOT EXISTS country (
    country_code CHAR(3) PRIMARY KEY,
    country_name VARCHAR(64) NOT NULL UNIQUE,
    country_region VARCHAR(64) NOT NULL
);

-- Cannot enforce A team must have at least one rider with current constraints
-- If Team is Updated, propagate to Rider
-- If Team is Deleted, blocked if referenced
CREATE TABLE IF NOT EXISTS team (
    team_name VARCHAR(64) PRIMARY KEY,
    country_code CHAR(3) NOT NULL,
    FOREIGN KEY (country_code) REFERENCES country(country_code)
        ON UPDATE CASCADE
);

-- If Rider is Updated, propagate to Result, Exit
-- If Rider is Deleted, propagate to Result, Exit
CREATE TABLE IF NOT EXISTS rider (
    rider_bib INT PRIMARY KEY,
    rider_name VARCHAR(64) NOT NULL,
    rider_dob DATE NOT NULL,
    country_code CHAR(3), -- possible for rider with no country data
    team_name VARCHAR(64) NOT NULL,
    FOREIGN KEY (country_code) REFERENCES country(country_code)
        ON UPDATE CASCADE,
    FOREIGN KEY (team_name) REFERENCES team(team_name)
        ON UPDATE CASCADE
);

-- If Location is Updated, propagate to Stage
-- If Location is Deleted, blocked if referenced
CREATE TABLE IF NOT EXISTS location (
    location_name VARCHAR(64) PRIMARY KEY,
    country_code CHAR(3) NOT NULL,
    FOREIGN KEY (country_code) REFERENCES country(country_code)
        ON UPDATE CASCADE
);

-- If Stage is Updated, propagate to Result, Exit
-- If Stage is Deleted, blocked if referenced
CREATE TABLE IF NOT EXISTS stage (
    stage_number INT PRIMARY KEY CHECK(stage_number > 0),
    stage_type VARCHAR(64) NOT NULL
        CHECK (stage_type IN (
            'team time-trial',
            'hilly',
            'mountain',
            'flat',
            'individual time-trial'
        )),
    stage_length INT NOT NULL,
    stage_day DATE NOT NULL UNIQUE,
    start_location VARCHAR(64) NOT NULL,
    end_location VARCHAR(64) NOT NULL,
    FOREIGN KEY (start_location) REFERENCES location(location_name)
        ON UPDATE CASCADE,
    FOREIGN KEY (end_location) REFERENCES location(location_name)
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS exit (
    exit_reason VARCHAR(64) NOT NULL
        CHECK (exit_reason IN ( -- to add more reasons once added
            'withdrawal',
            'DNS'
        )),
    rider_bib INT NOT NULL,
    stage_number INT NOT NULL,
    FOREIGN KEY (rider_bib) REFERENCES rider(rider_bib)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (stage_number) REFERENCES stage(stage_number)
        ON UPDATE CASCADE,
    PRIMARY KEY (rider_bib)
);

-- Cannot enforce gaps in result_rank
-- Cannot enforce Only 2 non-consecutive rest days
-- Cannot enforce Rider cannot have results for stages after exit
-- Enforce 1 Result per rider per stage
-- Enforce No two different riders with the same rank for the same stage
CREATE TABLE IF NOT EXISTS result (
    result_time INT NOT NULL CHECK(result_time > 0),
    result_bonus INT NOT NULL CHECK(result_bonus >= 0),
    result_penalty INT NOT NULL CHECK(result_penalty >= 0),
    result_rank INT NOT NULL CHECK(result_rank > 0),
    rider_bib INT NOT NULL,
    stage_number INT NOT NULL,
    FOREIGN KEY (rider_bib) REFERENCES rider(rider_bib)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (stage_number) REFERENCES stage(stage_number)
        ON UPDATE CASCADE,
    PRIMARY KEY (rider_bib, stage_number),
    UNIQUE (result_rank, stage_number)
);

CREATE TABLE IF NOT EXISTS rest_day (
    rest_day DATE PRIMARY KEY
);


