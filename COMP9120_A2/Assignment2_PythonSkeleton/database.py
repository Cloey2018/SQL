#!/usr/bin/env python3
import psycopg2

#####################################################
##  Database Connection
#####################################################

'''
Connect to the database using the connection string
'''
def openConnection():
    # connection parameters - ENTER YOUR LOGIN AND PASSWORD HERE
    userid = "postgres"
    passwd = "940522"
    myHost = "localhost"

    # Create a connection to the database
    conn = None
    try:
        # Parses the config file and connects using the connect string
        conn = psycopg2.connect(database="Assignment2",
                                    user=userid,
                                    password=passwd,
                                    host=myHost)
    except psycopg2.Error as sqle:
        print("psycopg2.Error : " + sqle.pgerror)

    # return the connection to use
    return conn

'''
Validate user login request based on username and password
'''
def checkUserCredentials(username, password):
    conn = openConnection()
    user_sql = """SELECT * FROM OFFICIAL
                  WHERE username = %s and password = %s"""
    cursor = conn.cursor()
    cursor.execute(user_sql, (username, password))
    userInfo = cursor.fetchone()
    # check if user is '-'
    if username == '-':
        userInfo = None
    cursor.close()
    #userInfo = ['3', 'ChrisP', 'Christopher', 'Putin', '888']
    conn.close()

    return userInfo


'''
List all the associated events in the database for a given official
'''
def findEventsByOfficial(official_id):
    conn = openConnection()
    sql = """SELECT eventid, eventname, sportname, o1.username AS refereename, o2.username AS judgename, o3.username AS medalgivername
                    FROM EVENT JOIN SPORT USING (SPORTID)
                    INNER JOIN  OFFICIAL AS o1 ON (o1.OFFICIALID = REFEREE)
                    INNER JOIN OFFICIAL AS o2 ON (o2.OFFICIALID = JUDGE)
                    INNER JOIN OFFICIAL AS o3 ON (o3.OFFICIALID = MEDALGIVER)
                    WHERE referee= %s or judge = %s or medalgiver = %s
                    ORDER BY sportname"""
    cursor = conn.cursor()
    cursor.execute(sql, (official_id, official_id, official_id))
    event_db = cursor.fetchall()

    # event_db = [
    #     ['3', 'Men''\'s Team Semifinal', 'Archery', 'ChrisP', 'GuoZ', 'JulieA'],
    #     ['1', 'Men''\'s Singles Semifinal', 'Badminton', 'JohnW', 'ChrisP', 'GuoZ']
    # ]

    event_list = [{
        'event_id': str(row[0]),
        'event_name': row[1],
        'sport': row[2],
        'referee': row[3],
        'judge': row[4],
        'medal_giver': row[5]
    } for row in event_db]
    cursor.close()
    conn.close()

    return event_list


'''
Find a list of events based on the searchString provided as parameter
See assignment description for search specification
'''
def findEventsByCriteria(searchString):
    conn = openConnection()
    searchString = '%' + searchString + '%'
    searchString = searchString.lower()
    sql = """SELECT eventid, eventname, sportname, o1.username AS refereename, o2.username AS judgename, o3.username AS medalgivername
                    FROM EVENT JOIN SPORT USING (SPORTID)
                    INNER JOIN  OFFICIAL AS o1 ON (o1.OFFICIALID = REFEREE)
                    INNER JOIN OFFICIAL AS o2 ON (o2.OFFICIALID = JUDGE)
                    INNER JOIN OFFICIAL AS o3 ON (o3.OFFICIALID = MEDALGIVER)
                    WHERE LOWER(sportname) LIKE %s OR LOWER(eventname) LIKE %s OR LOWER(o1.username) LIKE %s OR LOWER(o2.username) LIKE %s OR LOWER(o3.username) LIKE %s
                    ORDER BY sportname"""
    cursor = conn.cursor()
    cursor.execute(sql, (searchString, searchString, searchString, searchString, searchString))
    event_db = cursor.fetchall()

    # event_db = [
    #     ['3', 'Men''\'s Team Semifinal', 'Archery', 'ChrisP', 'GuoZ', 'JulieA'],
    #     ['1', 'Men''\'s Singles Semifinal', 'Badminton', 'JohnW', 'ChrisP', 'GuoZ'],
    #     ['4', 'Men''\'s Tournament Semifinal', 'Basketball', '-', 'JohnW', 'MaksimS']
    # ]

    event_list = [{
        'event_id': row[0],
        'event_name': row[1],
        'sport': row[2],
        'referee': row[3],
        'judge': row[4],
        'medal_giver': row[5]
    } for row in event_db]

    cursor.close()
    conn.close()
    return event_list


'''
Add a new event
'''
def addEvent(event_name, sport, referee, judge, medal_giver):
    conn = openConnection()
    cursor = conn.cursor()
    cursor.execute("BEGIN;")
    cursor.callproc('addNewEvent', [int(event_id), event_name, sport, referee, judge, medal_giver])
    conn.commit()
    cursor.close()
    conn.close()
    return True


'''
Update an existing event
'''
def updateEvent(event_id, event_name, sport, referee, judge, medal_giver):
    conn = openConnection()
    cursor = conn.cursor()
    sql_sport = """select sportid from sport where sportname = %s"""
    sql_official = """select officialid from official where username = %s"""
    # if len(event_name) > 50:
    #     return False

    cursor.execute(sql_sport, (sport,))
    if cursor.fetchone() == None:
        return False

    cursor.execute(sql_official, (referee,))
    if cursor.fetchone() == None:
        return False

    cursor.execute(sql_official, (judge,))
    if cursor.fetchone() == None:
        return False

    cursor.execute(sql_official, (medal_giver,))
    if cursor.fetchone() == None:
        return False

    cursor.execute("BEGIN;")
    cursor.callproc('UPDATE_EVENT', [int(event_id), event_name, sport, referee, judge, medal_giver])
    conn.commit()
    cursor.close()
    conn.close()
    return True
