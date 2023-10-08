DROP TABLE IF EXISTS Locations CASCADE;
DROP TABLE IF EXISTS Accommodation CASCADE;
DROP TABLE IF EXISTS Venue CASCADE;
DROP TABLE IF EXISTS Stay CASCADE;
DROP TABLE IF EXISTS Person CASCADE;
DROP TABLE IF EXISTS Official CASCADE;
DROP TABLE IF EXISTS Athlete CASCADE;
DROP TABLE IF EXISTS SportEvent CASCADE;
DROP TABLE IF EXISTS TakePlace CASCADE;
DROP TABLE IF EXISTS Run CASCADE;
DROP TABLE IF EXISTS Participate CASCADE;
DROP TABLE IF EXISTS Vehicle CASCADE;
DROP TABLE IF EXISTS Journey CASCADE;
DROP TABLE IF EXISTS Book CASCADE;

DROP TYPE IF EXISTS sex;
DROP TYPE IF EXISTS responsibilities;
DROP TYPE IF EXISTS result_type;
DROP TYPE IF EXISTS vehicle_type;

CREATE TYPE sex AS ENUM ('Male', 'Female');
CREATE TYPE responsibilities AS ENUM ('referee game', 'judge performance', 'award medal');
CREATE TYPE result_type AS ENUM ('time-based', 'score-based');
CREATE TYPE vehicle_type AS ENUM ('Van', 'Minibus', 'Bus');

CREATE TABLE Locations (
	uniqueName			VARCHAR(20),
	longitude			DECIMAL NOT NULL,
	latitude			DECIMAL NOT NULL,
	buildDate			DATE NOT NULL,
	buildCost			FLOAT NOT NULL,
	suburb				VARCHAR(20) NOT NULL,
	address				VARCHAR(100) UNIQUE NOT NULL,
	PRIMARY KEY (uniqueName),
	-- 	each location has uniue GPS
	Constraint unique_GPS UNIQUE (longitude, latitude),
	-- 	locations must be completed before 2024
	Constraint build_date_before_2024 CHECK (buildDate < '2024-01-01'),
	-- 	build cost should always larger than nil
	Constraint build_cost_larger_than_0 CHECK (buildcost > 0)
);

CREATE TABLE Accommodation (
	accommodationName	VARCHAR(20),
	PRIMARY KEY (accommodationName),
	FOREIGN KEY (accommodationName) REFERENCES Locations (uniqueName) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Venue (
	venueName			VARCHAR(20),
	PRIMARY KEY (venueName),
	FOREIGN KEY (venueName) REFERENCES Locations (uniqueName) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 	each contingent from each country will be allocated an accommodation village for the entire duration of this event
CREATE TABLE Stay (
	homecountry			VARCHAR(50),
	accommodationName	VARCHAR(20),
	PRIMARY KEY (homecountry),
	FOREIGN KEY (accommodationName) REFERENCES Accommodation ON UPDATE CASCADE
);

CREATE TABLE Person (
 	personID			VARCHAR(20),
	p_name				VARCHAR(100) NOT NUll,
	gender				sex NOT NULL,
 	dateOfBirth			DATE NOT NULL,
	age					INTEGER NOT NULL, 	
 	emailAddress		VARCHAR(50) UNIQUE NOT NULL,
 	homeCountry			VARCHAR(50) NOT NULL,
 	PRIMARY KEY (personID),
	-- 	each person should be between age 0 to age 100
	Constraint age_range CHECK (age > 0 and age <= 100),
 	Constraint birthdate_range CHECK (dateOfBirth between '1924-01-01' and '2024-01-01'),
 	FOREIGN KEY (homecountry) REFERENCES Stay ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE Table Official (
 	officialID			VARCHAR(20),
 	PRIMARY KEY (officialID),
	-- 	one person cannnot be official and athlete at smame time
-- 	Constraint not_athlete CHECK (
-- 		(select count(*) from Athlete where athleteID = officialID) = 0
-- 	),
	FOREIGN KEY (officialID) REFERENCES Person (personID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE Table Athlete (
 	athleteID			VARCHAR(20),
 	birthCountry		VARCHAR(50),
 	PRIMARY KEY (athleteID),
	-- 	one person cannnot be official and athlete at smame time
-- 	Constraint not_athlete CHECK (
-- 		(select count(*) from Official where officialID = athleteID) = 0
-- 	),
	FOREIGN KEY (athleteID) REFERENCES Person (personID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE SportEvent (
	sportEventID		VARCHAR(20),
	s_name				VARCHAR(50) NOT NULL,
	resultType			result_type NOT NULL,
	PRIMARY KEY (sportEventID)
);

CREATE TABLE TakePlace (
	sportEventID		VARCHAR(20),
	venueName			VARCHAR(20),
	scheduledDate		DATE NOT NULL,
	scheduledTime		TIME NOT NULL,
	PRIMARY KEY (sportEventID,venueName, scheduledDate, scheduledTime),
	-- 	events must be held in year 2024
	Constraint event_must_hold_in_2024 CHECK (scheduledDate between '2024-01-01' and '2024-12-31'),
	FOREIGN KEY (sportEventID) REFERENCES SportEvent ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (venueName) REFERENCES Venue ON UPDATE CASCADE
);

CREATE TABLE Run (
 	officialID			VARCHAR(20),
 	sportEventID		VARCHAR(20),
 	venueName			VARCHAR(20),
 	scheduledDate		DATE NOT NULL,
 	scheduledTime		TIME NOT NULL,
 	-- 	each official would have only one respinsibility per event according to our assumption
 	responsibility		responsibilities NOT NULL,
 	PRIMARY KEY (officialID, sportEventID, venueName, scheduledDate, scheduledTime),
 	-- 	each ooficial can only work in one event per day
  	Constraint each_official_in_one_event_per_day UNIQUE (officialID, scheduledDate),
 	FOREIGN KEY (officialID) REFERENCES Official ON UPDATE CASCADE,
 	FOREIGN KEY (sportEventID, venueName, scheduledDate, scheduledTime) REFERENCES TakePlace ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Participate (
 	athleteID			VARCHAR(20),
 	sportEventID		VARCHAR(20),
 	venueName			VARCHAR(20),
 	scheduledDate		DATE NOT NULL,
 	scheduledTime		TIME NOT NULL,
 	p_results			VARCHAR(100),
 	PRIMARY KEY (athleteID, sportEventID, venueName, scheduledDate, scheduledTime),
 	-- 	each athlete can only participate one event par day
 	Constraint each_athlete_attend_one_event_per_day UNIQUE (athleteID, scheduledDate),
 	FOREIGN KEY (athleteID) REFERENCES Athlete ON DELETE CASCADE ON UPDATE CASCADE,
 	FOREIGN KEY (sportEventID, venueName, scheduledDate, scheduledTime) REFERENCES TakePlace ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Vehicle (
	vehicleID			VARCHAR(20),
	vehicleType			vehicle_type NOT NULL,
	capacity			INTEGER NOT NULL,
	PRIMARY KEY (vehicleID),
	-- 	capacity cannot be zero and should not exceed 23 
	Constraint capacity_range CHECK (capacity > 0 and capacity <= 23)
);

CREATE TABLE Journey (
	journeyID			VARCHAR(20),
	vehicleID			VARCHAR(20),
	origin				VARCHAR(20) NOT NULL,
	destination			VARCHAR(20) NOT NULL,
	originTime			TIME NOT NULL,
	destinationTime		TIME NOT NULL,
	PRIMARY KEY (journeyID),
	-- 	arrival and destination cannot be the same location
	Constraint arrival_destination_notEqual CHECK (origin != destination),
	FOREIGN KEY (vehicleID) REFERENCES Vehicle ON UPDATE CASCADE,
	FOREIGN KEY (origin) REFERENCES Locations (uniqueName) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (destination) REFERENCES Locations (uniqueName) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE BOOK (
	journeyID			VARCHAR(20),
	bookDate			DATE NOT NULL,
	journeyDate			DATE NOT NULL,
	passengerID			VARCHAR(20) NOT NULL,
	PRIMARY KEY (journeyID, bookDate, journeyDate, passengerID),
	-- 	person cannot book if the capacity if full
-- 	Constraint book_num_no_exceed_capacity CHECK (
-- 		(select count(*)
-- 		 from Book
-- 		 group by journeyID, journeyDate) <=(select capacity
-- 		 from Book natural join Journey natural join Vehicle)
-- 		),
	-- 	for each journey, each person can only book or be booked once per day
	Constraint book_once_per_journey_per_day UNIQUE (journeyID, journeyDate, passengerID),
	-- 	bookdate and journey date must be in 2024
	Constraint book_date_in_2024 CHECK (bookDate between '2024-01-01' and '2024-12-31'),
	Constraint journey_date_in_2024 CHECK (journeyDate between '2024-01-01' and '2024-12-31'),
	-- passengers cannot book journeys that are already past
	Constraint bookDate_no_bigger_than_journeyDate CHECK (bookDate <= journeyDate),
	FOREIGN KEY (journeyID) REFERENCES Journey ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (passengerID) REFERENCES Person (personID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Inserting data
-- Table Locations
INSERT INTO Locations VALUES ('Sunset', 33.859972, 151.211111, '2018-09-30', 15000000, 'Camperdown','5 Miles street');
INSERT INTO Locations VALUES ('Rainbow', 37.816667, 144.966667, '2020-01-26', 16000000,	'Darlington', '100 East road');
INSERT INTO Locations VALUES ('Starry sky',	27.466667, 153.033333, '2021-05-20', 17000000,	'Forest Lodge',	'26 Glaisher street');
INSERT INTO Locations VALUES ('Milky Way',	34.300000, 149.133333,	'2019-12-22', 18000000,	'Chatswood',	'20 Cunningham road');
INSERT INTO Locations VALUES ('Sunrise',	34.933333, 138.600000, '2017-11-11', 19000000,	'Burwood',	'1 Victoria road');
INSERT INTO Locations VALUES ('Suncorp Stadium',	113.0, 28.22, '2018-09-30', 10000000,	'Brisbane River',	'96 parramatte road');
INSERT INTO Locations VALUES ('Arena',	118.10, 24.47, '2020-01-26', 11000000, 'Sunnybank',	'6 central park ave');
INSERT INTO Locations VALUES ('Dome',	119.300, 26.08, '2020-05-20', 12000000,	'Runcorn',	'159 Ross street');
INSERT INTO Locations VALUES ('Aurora',	106.72, 26.57,	'2019-12-22', 13000000, 'Carindale',	'103 Camley street');
INSERT INTO Locations VALUES ('Bird Nest', 110.97, 35.03, '2017-11-11',	14000000,	'Chermside',	'203 Westminster Bridge road');

-- Table Accommodation
INSERT INTO Accommodation VALUES ('Sunset');
INSERT INTO Accommodation VALUES ('Rainbow');
INSERT INTO Accommodation VALUES ('Starry sky');
INSERT INTO Accommodation VALUES ('Milky Way');
INSERT INTO Accommodation VALUES ('Sunrise');

-- Table Venue
INSERT INTO Venue VALUES ('Suncorp Stadium');
INSERT INTO Venue VALUES ('Arena');
INSERT INTO Venue VALUES ('Dome');
INSERT INTO Venue VALUES ('Aurora');
INSERT INTO Venue VALUES ('Bird Nest');

-- Table Stay
INSERT INTO Stay VALUES ('China',	'Sunset');
INSERT INTO Stay VALUES ('Japan',	'Rainbow');
INSERT INTO Stay VALUES ('Jamaica',	'Milky Way');
INSERT INTO Stay VALUES ('the United Kingdom', 'Rainbow');
INSERT INTO Stay VALUES ('Australia',	'Sunrise');
INSERT INTO Stay VALUES ('New zetland',	'Starry sky');

-- Table Person
INSERT INTO Person VALUES ('P0001',	'Jingjing GUO',	'Female', '1981-10-15', 40,	'guojingjing@email.com', 'China');
INSERT INTO Person VALUES ('P0002',	'Yuzuru Hanyu',	'Male', '1994-12-07', 27,	'yuzuruhanyu@email.com', 'Japan');
INSERT INTO Person VALUES ('P0003',	'Dan LIN',	'Male', '1983-10-14',	38,	'lindan@email.com', 'China');
INSERT INTO Person VALUES ('P0004',	'Yuanhui FU',	'Female', '1996-01-07', 25, 'fuyuanhui@email.com',	'China');
INSERT INTO Person VALUES ('P0005',	'Usain Bolt',	'Male', '1986-08-21', 35, 'usainbolt@email.com', 'Jamaica');
INSERT INTO Person VALUES ('P0006',	'Liping HUANG',	'Male', '1981-11-11',	40,	'huangliping@email.com', 'China');
INSERT INTO Person VALUES ('P0007',	'Jing LI',	'Male', '1985-07-14', 36, 'lijing@email.com', 'China');
INSERT INTO Person VALUES ('P0008',	'Mark CLATTENBURG',	'Male', '1980-05-17', 41, 'markclat@email.com',	'the United Kingdom');
INSERT INTO Person VALUES ('P0009',	'Christopher James',	'Male', '1978-10-22', 43, 'chrisjame@email.com', 'Australia');
INSERT INTO Person VALUES ('P0010',	'Matthew Conger',	'Male', '1974-01-21', 47, 'matconger@email.com',	'New zetland');

-- Table Official
INSERT INTO Official VALUES ('P0006');
INSERT INTO Official VALUES ('P0007');
INSERT INTO Official VALUES ('P0008');
INSERT INTO Official VALUES ('P0009');
INSERT INTO Official VALUES ('P0010');

-- Table Athlete
INSERT INTO Athlete VALUES ('P0001');
INSERT INTO Athlete VALUES ('P0002');
INSERT INTO Athlete VALUES ('P0003');
INSERT INTO Athlete VALUES ('P0004');
INSERT INTO Athlete VALUES ('P0005');

-- Table SportEvent
INSERT INTO SportEvent VALUES ('S0001',	'swimming', 'time-based');
INSERT INTO SportEvent VALUES ('S0002',	'diving', 'score-based');
INSERT INTO SportEvent VALUES ('S0003',	'figure skating', 'score-based');
INSERT INTO SportEvent VALUES ('S0004',	'sprint', 'time-based');
INSERT INTO SportEvent VALUES ('S0005',	'badmintoon', 'score-based');

-- Table TakePlace
INSERT INTO TakePlace VALUES ('S0001', 'Suncorp Stadium', '2024-07-20',	'20:00');
INSERT INTO TakePlace VALUES ('S0001', 'Suncorp Stadium', '2024-07-22',	'14:00');
INSERT INTO TakePlace VALUES ('S0002', 'Arena', '2024-07-21', '10:00');
INSERT INTO TakePlace VALUES ('S0002', 'Suncorp Stadium', '2024-07-22', '14:00');
INSERT INTO TakePlace VALUES ('S0003', 'Dome', '2024-07-25', '16:00');
INSERT INTO TakePlace VALUES ('S0004', 'Bird Nest', '2024-07-26', '13:00');
INSERT INTO TakePlace VALUES ('S0005', 'Aurora', '2024-07-26', '16:00');
INSERT INTO TakePlace VALUES ('S0005', 'Bird Nest', '2024-07-28', '12:00');

-- Table Run
INSERT INTO Run VALUES ('P0006', 'S0001', 'Suncorp Stadium', '2024-07-20',	'20:00', 'referee game');
INSERT INTO Run VALUES ('P0006', 'S0001', 'Suncorp Stadium', '2024-07-22',	'14:00', 'judge performance');
INSERT INTO Run VALUES ('P0007', 'S0001', 'Suncorp Stadium', '2024-07-20',	'20:00', 'award medal');
INSERT INTO Run VALUES ('P0008', 'S0003', 'Dome', '2024-07-25', '16:00', 'award medal');
INSERT INTO Run VALUES ('P0009', 'S0004', 'Bird Nest', '2024-07-26', '13:00', 'referee game');
INSERT INTO Run VALUES ('P0010', 'S0005', 'Aurora', '2024-07-26', '16:00', 'award medal');

-- Table Participate
INSERT INTO Participate VALUES ('P0001', 'S0001', 'Suncorp Stadium', '2024-07-20',	'20:00', '50.09 seconds');
INSERT INTO Participate VALUES ('P0001', 'S0001', 'Suncorp Stadium', '2024-07-22',	'14:00', '48.88 seconds');
INSERT INTO Participate VALUES ('P0002', 'S0001', 'Suncorp Stadium', '2024-07-20',	'20:00', '50.79 seconds');
INSERT INTO Participate VALUES ('P0003', 'S0003', 'Dome', '2024-07-25', '16:00', '213 scores');
INSERT INTO Participate VALUES ('P0004', 'S0004', 'Bird Nest', '2024-07-26', '13:00', '12.78 seconds');
INSERT INTO Participate VALUES ('P0005', 'S0005', 'Aurora', '2024-07-26', '16:00', '24 scores');

-- Table Vehicle
INSERT INTO Vehicle VALUES ('V0001', 'Bus', 20);
INSERT INTO Vehicle VALUES ('V0002', 'Minibus', 8);
INSERT INTO Vehicle VALUES ('V0003', 'Van', 12);
INSERT INTO Vehicle VALUES ('V0004', 'Minibus', 8);
INSERT INTO Vehicle VALUES ('V0005', 'Bus', 20);

-- Table Journey
INSERT INTO Journey VALUES ('J0001', 'V0001', 'Sunset', 'Suncorp Stadium', '12:00', '12:30');
INSERT INTO Journey VALUES ('J0002', 'V0004', 'Sunset', 'Milky Way', '10:45', '11:00');
INSERT INTO Journey VALUES ('J0003', 'V0005',	'Rainbow', 'Aurora', '14:00', '14:10');
INSERT INTO Journey VALUES ('J0004', 'V0003', 'Bird Nest', 'Starry sky', '15:00', '15:30');
INSERT INTO Journey VALUES ('J0005', 'V0002', 'Dome', 'Suncorp Stadium', '12:00',	'12:30');

-- Table Book
INSERT INTO Book VALUES ('J0001', '2024-07-21', '2024-07-22', 'P0003');
INSERT INTO Book VALUES ('J0002', '2024-07-22', '2024-07-22', 'P0001');
INSERT INTO Book VALUES ('J0002', '2024-07-24', '2024-07-30', 'P0008');
INSERT INTO Book VALUES ('J0004', '2024-07-25', '2024-07-26', 'P0005');
INSERT INTO Book VALUES ('J0005', '2024-07-26', '2024-07-28', 'P0010');

