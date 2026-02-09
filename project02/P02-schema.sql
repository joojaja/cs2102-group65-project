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
CREATE TABLE IF NOT EXISTS country ( -- ERD "Countries"
    country_code CHAR(3) PRIMARY KEY,
    country_name VARCHAR(64) NOT NULL UNIQUE, --candidate key
    country_region VARCHAR(64) NOT NULL
);

-- Cannot enforce A team must have 1-8 riders current constraints
-- If Team is Updated, propagate to Rider
-- If Team is Deleted, blocked if referenced
CREATE TABLE IF NOT EXISTS team ( -- ERD "Teams" + "Represent" 
    country_code CHAR(3) NOT NULL,
    FOREIGN KEY (country_code) REFERENCES country(country_code)
        ON UPDATE CASCADE
);

-- If Rider is Updated, propagate to Result, Exit
-- If Rider is Deleted, propagate to Result, Exit
CREATE TABLE IF NOT EXISTS rider ( -- ERD "Riders" + "Consist"
    rider_bib INT PRIMARY KEY,
    rider_name VARCHAR(64) NOT NULL,
    rider_dob DATE NOT NULL,
    team_name VARCHAR(64) NOT NULL,
    FOREIGN KEY (country_code) REFERENCES country(country_code)
        ON UPDATE CASCADE,
    FOREIGN KEY (team_name) REFERENCES team(team_name)
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS from ( -- ERD "From"
	rider_bib INT PRIMARY KEY,
	country_code CHAR(3) NOT NULL,
	FOREIGN KEY (rider_bib) REFERENCES  rider(rider_bib)
		ON UPDATE CASCADE,
	FOREIGN KEY (country_code) REFERENCES country(country_code)
		ON UPDATE CASCADE
);

-- If Location is Updated, propagate to Stage
-- If Location is Deleted, blocked if referenced
CREATE TABLE IF NOT EXISTS location ( -- ERD "Location" + "Has"
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
    stage_day DATE NOT NULL UNIQUE, -- candidate key
    start_location VARCHAR(64) NOT NULL,
    end_location VARCHAR(64) NOT NULL,
    FOREIGN KEY (start_location) REFERENCES location(location_name)
        ON UPDATE CASCADE,
    FOREIGN KEY (end_location) REFERENCES location(location_name)
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS exit (
    reason VARCHAR(64) NOT NULL
        CHECK (reason IN ( -- to add more reasons once added
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
    PRIMARY KEY (rider_bib) --pkey is only from rider (exception #1)
);

-- Cannot enforce gaps in result_rank
-- Cannot enforce Only 2 non-consecutive rest days
-- Cannot enforce Rider cannot have results for stages after exit
-- Enforce 1 Result per rider per stage
-- Enforce No two different riders with the same rank for the same stage
CREATE TABLE IF NOT EXISTS result ( -- ERD "Compete" 
-- 
-- TODO change ERD name or table name
-- TODO change ERD "AGGREGATE TIME" to "ADJUSTED TIME"
	-- bonus is derived, dont need to store.
	-- rank 1: bonus 10, rank 2: bonus 6, rank 3: bonus 4
	--
	-- adjusted time = time - bonus + penalty
    time INT NOT NULL CHECK(result_time > 0),
    penalty INT NOT NULL CHECK(result_penalty >= 0),
    rank INT NOT NULL CHECK(result_rank > 0),
    rider_bib INT NOT NULL,
    stage_number INT NOT NULL,
    FOREIGN KEY (rider_bib) REFERENCES rider(rider_bib)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (stage_number) REFERENCES stage(stage_number)
        ON UPDATE CASCADE,
    PRIMARY KEY (rider_bib, stage_number), -- pkey is pkey from parti. entities
    UNIQUE (rank, stage_number) -- enforce rank, stage_number constraint
);

