\r mysql
GRANT USAGE ON *.* TO 'eve-ng'@'%';
DROP USER  'eve-ng';
CREATE USER 'eve-ng'@'%'  IDENTIFIED BY 'eve-ng';
drop database IF EXISTS eve_ng_db ;
create database eve_ng_db ;
GRANT SELECT,INSERT,UPDATE,DELETE ON eve_ng_db.* TO 'eve-ng'@'%';
-- FLUSH PRIVILEGES;
\r eve_ng_db 

-- MySQL dump 10.13  Distrib 5.5.49, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: unetlab_db
-- ------------------------------------------------------
-- Server version	5.5.49-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `html5`
--

DROP TABLE IF EXISTS `html5`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `html5` (
  `username` text,
  `pod` int(11) DEFAULT NULL,
  `token` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `html5`
--

LOCK TABLES `html5` WRITE;
/*!40000 ALTER TABLE `html5` DISABLE KEYS */;
/*!40000 ALTER TABLE `html5` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pods`
--

DROP TABLE IF EXISTS `pods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pods` (
  `id` int(11) NOT NULL,
  `expiration` int(11) DEFAULT '-1',
  `username` text,
  `lab_id` text,
  PRIMARY KEY (`id`),
  KEY `username_pods` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pods`
--

LOCK TABLES `pods` WRITE;
/*!40000 ALTER TABLE `pods` DISABLE KEYS */;
/*!40000 ALTER TABLE `pods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `username` text NOT NULL,
  `cookie` text,
  `email` text,
  `expiration` int(11) DEFAULT '-1',
  `name` text,
  `password` text,
  `session` int(11) DEFAULT NULL,
  `ip` text,
  `role` text,
  `folder` text,
  `html5` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
/*INSERT INTO `users` VALUES ('admin',NULL,'root@localhost',-1,'UNetLab Administrator','dddc487d503fdb607bc113821a7416cfd67a3abf77f4ec87ee5797449bdca796',NULL,'217.136.253.84','admin','/SEC',1);*/
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-05-08 17:16:25
