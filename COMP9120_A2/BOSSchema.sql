DROP TABLE IF EXISTS EVENT;
DROP TABLE IF EXISTS OFFICIAL;
DROP TABLE IF EXISTS SPORT;

CREATE TABLE SPORT
(
	SPORTID SERIAL PRIMARY KEY,
	SPORTNAME VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO SPORT (SPORTNAME) VALUES ('Archery');		-- 1
INSERT INTO SPORT (SPORTNAME) VALUES ('Athletics');		-- 2
INSERT INTO SPORT (SPORTNAME) VALUES ('Badminton');		-- 3
INSERT INTO SPORT (SPORTNAME) VALUES ('Basketball');	-- 4
INSERT INTO SPORT (SPORTNAME) VALUES ('Boxing');		-- 5
INSERT INTO SPORT (SPORTNAME) VALUES ('Diving');		-- 6
INSERT INTO SPORT (SPORTNAME) VALUES ('Fencing');		-- 7
INSERT INTO SPORT (SPORTNAME) VALUES ('Golf');			-- 8
INSERT INTO SPORT (SPORTNAME) VALUES ('Handball');		-- 9
INSERT INTO SPORT (SPORTNAME) VALUES ('Hockey');		-- 10
INSERT INTO SPORT (SPORTNAME) VALUES ('Ice Hockey');	-- 11
INSERT INTO SPORT (SPORTNAME) VALUES ('Judo');			-- 12
INSERT INTO SPORT (SPORTNAME) VALUES ('Karate');		-- 13
INSERT INTO SPORT (SPORTNAME) VALUES ('Luge');			-- 14
INSERT INTO SPORT (SPORTNAME) VALUES ('Rowing');		-- 15
INSERT INTO SPORT (SPORTNAME) VALUES ('Rugby');			-- 16
INSERT INTO SPORT (SPORTNAME) VALUES ('Sailing');		-- 17
INSERT INTO SPORT (SPORTNAME) VALUES ('Shooting');		-- 18
INSERT INTO SPORT (SPORTNAME) VALUES ('Snowboard');		-- 19
INSERT INTO SPORT (SPORTNAME) VALUES ('Weightlifting');	-- 20

CREATE TABLE OFFICIAL
(
	OFFICIALID SERIAL PRIMARY KEY,
	USERNAME VARCHAR(20) NOT NULL UNIQUE,
	FIRSTNAME VARCHAR(50) NOT NULL,
	LASTNAME VARCHAR(50) NOT NULL,
	PASSWORD VARCHAR(20) NOT NULL
);

INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('-','Not','Assigned','000');			-- 1
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('JohnW','John','Waith','999');			-- 2
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('ChrisP','Christopher','Putin','888');	-- 3
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('GuoZ','Guo','Zhang','777');			-- 4
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('JulieA','Julie','Ahlering','666');		-- 5
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('MaksimS','Maksim','Sulejmani','555');	-- 6
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('KrisN','Kristina','Ness','444');		-- 7
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('ZvonkoO','Zvonko','Ocic','333');		-- 8
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('SusanF','Susan','Fischer','222');		-- 9
INSERT INTO OFFICIAL (USERNAME,FIRSTNAME,LASTNAME,PASSWORD) VALUES ('KevinB','Kevin','Boyd','111');			-- 10

CREATE TABLE EVENT
(
	EVENTID SERIAL PRIMARY KEY,
	EVENTNAME VARCHAR(50) NOT NULL,
	SPORTID INTEGER REFERENCES SPORT,
	REFEREE INTEGER REFERENCES OFFICIAL,
	JUDGE INTEGER REFERENCES OFFICIAL,
	MEDALGIVER INTEGER REFERENCES OFFICIAL

);

INSERT INTO EVENT (EVENTNAME,SPORTID,REFEREE,JUDGE,MEDALGIVER) VALUES ('Men''s Singles Semifinal',3,2,3,4);		-- 1
INSERT INTO EVENT (EVENTNAME,SPORTID,REFEREE,JUDGE,MEDALGIVER) VALUES ('Women''s Long Jump Final',2,1,5,6);		-- 2
INSERT INTO EVENT (EVENTNAME,SPORTID,REFEREE,JUDGE,MEDALGIVER) VALUES ('Men''s Team Semifinal',1,3,4,5);		-- 3
INSERT INTO EVENT (EVENTNAME,SPORTID,REFEREE,JUDGE,MEDALGIVER) VALUES ('Men''s Tournament Semifinal',4,1,2,6);	-- 4
INSERT INTO EVENT (EVENTNAME,SPORTID,REFEREE,JUDGE,MEDALGIVER) VALUES ('Women''s Lightweight Final',5,4,6,1);	-- 5

-- add event
DROP FUNCTION IF EXISTS addNewEvent;
CREATE FUNCTION addNewEvent(eventName VARCHAR, sportID INTEGER, referee INTEGER, judge INTEGER, medalGiver INTEGER) RETURNS INTEGER AS $$
BEGIN
   INSERT INTO EVENT (EVENTNAME,SPORTID,REFEREE,JUDGE,MEDALGIVER) VALUES (eventName,sportID,referee,judge,medalGiver);
   RETURN 1;
END;$$LANGUAGE plpgsql;

-- update events
CREATE OR REPLACE FUNCTION UPDATE_EVENT (event_id INTEGER, event_name VARCHAR, sport VARCHAR,
																				 r_official VARCHAR, j_official VARCHAR, m_official VARCHAR) RETURNS INTEGER AS $$
																				 BEGIN
																				 	UPDATE EVENT SET EVENTNAME = event_name,
																													 SPORTID = (SELECT s.SPORTID FROM SPORT AS s WHERE s.SPORTNAME = sport),
																													 REFEREE = (SELECT o.OFFICIALID FROM OFFICIAL AS o WHERE o.USERNAME = r_official),
																													 JUDGE = (SELECT o.OFFICIALID FROM OFFICIAL AS o WHERE o.USERNAME = j_official),
																													 MEDALGIVER = (SELECT o.OFFICIALID FROM OFFICIAL AS o WHERE o.USERNAME = m_official)
																											 WHERE EVENTID = event_id;
																											 RETURN 1;
																				 END; $$ LANGUAGE plpgsql;
COMMIT;
