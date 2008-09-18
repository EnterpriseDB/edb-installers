CREATE TABLE wiki (
        pagename VARCHAR(100) NOT NULL,
        version INT NOT NULL DEFAULT 1,
        flags INT NOT NULL DEFAULT 0,
        author VARCHAR(100),
        lastmodified INT NOT NULL,
        created INT NOT NULL,           
        content TEXT NOT NULL,
        refs TEXT,                      
        PRIMARY KEY (pagename)
        );

CREATE TABLE archive (
        pagename VARCHAR(100) NOT NULL,
        version INT NOT NULL DEFAULT 1,
        flags INT NOT NULL DEFAULT 0,
        author VARCHAR(100),
        lastmodified INT NOT NULL,
        created INT NOT NULL,           
        content TEXT NOT NULL,
        refs TEXT,                      
        PRIMARY KEY (pagename)
        );

CREATE TABLE wikilinks (
        frompage VARCHAR(100) NOT NULL,
        topage VARCHAR(100) NOT NULL,
        PRIMARY KEY (frompage, topage)
        );

CREATE TABLE hottopics (                
        pagename VARCHAR(100) NOT NULL,
        lastmodified INT NOT NULL,
        PRIMARY KEY (pagename, lastmodified)
        );

CREATE TABLE hitcount (                 
        pagename VARCHAR(100) NOT NULL, 
        hits INT NOT NULL DEFAULT 0,    
        PRIMARY KEY (pagename)          
        );

CREATE TABLE wikiscore (
        pagename VARCHAR(100) NOT NULL,
        score INT NOT NULL DEFAULT 0,
        PRIMARY KEY (pagename)
        );
