-- MySQL dump 8.23
--
-- Host: localhost    Database: test
---------------------------------------------------------
-- Server version	3.23.58

--
-- Table structure for table `test_index`
--

CREATE TABLE test_index (
  id int(11) NOT NULL auto_increment,
  uri varchar(150) NOT NULL default '',
  text varchar(150) NOT NULL default '',
  level int(11) default NULL,
  id_parent int(11) NOT NULL default '0',
  ordern varchar(100) NOT NULL default '100',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Dumping data for table `test_index`
--


INSERT INTO test_index VALUES (1,'a','a',NULL,0,'100');
INSERT INTO test_index VALUES (2,'b','b',NULL,0,'100');
INSERT INTO test_index VALUES (3,'c','c',NULL,0,'100');
INSERT INTO test_index VALUES (4,'a1','a1',NULL,1,'100');
INSERT INTO test_index VALUES (5,'wow.html','wow',NULL,4,'100');
INSERT INTO test_index VALUES (6,'bow.html','bow',NULL,2,'100');
INSERT INTO test_index VALUES (7,'row.html','row',NULL,3,'100');

