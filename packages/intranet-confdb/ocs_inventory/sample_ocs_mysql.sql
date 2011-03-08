-- MySQL dump 10.9
--
-- Host: localhost    Database: ocsweb
-- ------------------------------------------------------
-- Server version	4.1.10a

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

--
-- Table structure for table `accesslog`
--

DROP TABLE IF EXISTS `accesslog`;
CREATE TABLE `accesslog` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `USERID` varchar(255) default NULL,
  `LOGDATE` datetime default NULL,
  `PROCESSES` text,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `accesslog`
--


/*!40000 ALTER TABLE `accesslog` DISABLE KEYS */;
LOCK TABLES `accesslog` WRITE;
INSERT INTO `accesslog` VALUES (1,1,'N/A','2007-08-11 18:32:05',NULL),(6,2,NULL,NULL,NULL),(4,3,'N/A','2007-08-11 19:09:38',NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `accesslog` ENABLE KEYS */;

--
-- Table structure for table `accountinfo`
--

DROP TABLE IF EXISTS `accountinfo`;
CREATE TABLE `accountinfo` (
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `TAG` varchar(255) default 'NA',
  PRIMARY KEY  (`HARDWARE_ID`),
  KEY `TAG` (`TAG`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `accountinfo`
--


/*!40000 ALTER TABLE `accountinfo` DISABLE KEYS */;
LOCK TABLES `accountinfo` WRITE;
INSERT INTO `accountinfo` VALUES (1,NULL),(3,NULL),(2,'NA');
UNLOCK TABLES;
/*!40000 ALTER TABLE `accountinfo` ENABLE KEYS */;

--
-- Table structure for table `bios`
--

DROP TABLE IF EXISTS `bios`;
CREATE TABLE `bios` (
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `SMANUFACTURER` varchar(255) default NULL,
  `SMODEL` varchar(255) default NULL,
  `SSN` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `BMANUFACTURER` varchar(255) default NULL,
  `BVERSION` varchar(255) default NULL,
  `BDATE` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`),
  KEY `SSN` (`SSN`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `bios`
--


/*!40000 ALTER TABLE `bios` DISABLE KEYS */;
LOCK TABLES `bios` WRITE;
INSERT INTO `bios` VALUES (1,'IBM','eserver xSeries 445 -[887022X]-','KKMML7T',NULL,'IBM','-[REE145AUS-1.11]-','08/25/2004'),(2,'VIA Technologies, Inc.','KM266-8235',NULL,'Desktop','Phoenix Technologies, LTD','6.00 PG','10/18/2002'),(3,'Shuttle Inc','SN41UV10',NULL,NULL,'Phoenix Technologies, LTD','6.00 PG','08/26/2004');
UNLOCK TABLES;
/*!40000 ALTER TABLE `bios` ENABLE KEYS */;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
CREATE TABLE `config` (
  `NAME` varchar(50) NOT NULL default '',
  `IVALUE` int(11) default NULL,
  `TVALUE` varchar(255) default NULL,
  `COMMENTS` text,
  PRIMARY KEY  (`NAME`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `config`
--


/*!40000 ALTER TABLE `config` DISABLE KEYS */;
LOCK TABLES `config` WRITE;
INSERT INTO `config` VALUES ('FREQUENCY',0,'','Specify the frequency (days) of inventories. (0: inventory at each login. -1: no inventory)'),('PROLOG_FREQ',24,'','Specify the frequency (hours) of prolog, on agents'),('IPDISCOVER',2,'','Max number of computers per gateway retrieving IP on the network'),('INVENTORY_DIFF',1,'','Activate/Deactivate inventory incremental writing'),('IPDISCOVER_LATENCY',100,'','Default latency between two arp requests'),('INVENTORY_TRANSACTION',1,'','Enable/disable db commit at each inventory section'),('REGISTRY',0,'','Activates or not the registry query function'),('IPDISCOVER_MAX_ALIVE',7,'','Max number of days before an Ip Discover computer is replaced'),('DEPLOY',1,'','Activates or not the automatic deployment option'),('UPDATE',0,'','Activates or not the update feature'),('GUI_VERSION',0,'4100','Version of the installed GUI and database'),('TRACE_DELETED',0,'','Trace deleted/duplicated computers (Activated by GLPI)'),('LOGLEVEL',0,'','ocs engine loglevel'),('AUTO_DUPLICATE_LVL',7,'','Duplicates bitmap'),('DOWNLOAD',0,'','Activate softwares auto deployment feature'),('DOWNLOAD_CYCLE_LATENCY',60,'','Time between two cycles (seconds)'),('DOWNLOAD_PERIOD_LENGTH',10,'','Number of cycles in a period'),('DOWNLOAD_FRAG_LATENCY',10,'','Time between two downloads (seconds)'),('DOWNLOAD_PERIOD_LATENCY',0,'','Time between two periods (seconds)'),('DOWNLOAD_TIMEOUT',30,'','Validity of a package (in days)'),('LOCAL_SERVER',0,'localhost','Server address used for local import'),('LOCAL_PORT',80,'','Server port used for local import');
UNLOCK TABLES;
/*!40000 ALTER TABLE `config` ENABLE KEYS */;

--
-- Table structure for table `conntrack`
--

DROP TABLE IF EXISTS `conntrack`;
CREATE TABLE `conntrack` (
  `IP` varchar(255) NOT NULL default '',
  `TIMESTAMP` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`IP`)
) ENGINE=HEAP DEFAULT CHARSET=latin1;

--
-- Dumping data for table `conntrack`
--


/*!40000 ALTER TABLE `conntrack` DISABLE KEYS */;
LOCK TABLES `conntrack` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `conntrack` ENABLE KEYS */;

--
-- Table structure for table `controllers`
--

DROP TABLE IF EXISTS `controllers`;
CREATE TABLE `controllers` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `MANUFACTURER` varchar(255) default NULL,
  `NAME` varchar(255) default NULL,
  `CAPTION` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `VERSION` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `controllers`
--


/*!40000 ALTER TABLE `controllers` DISABLE KEYS */;
LOCK TABLES `controllers` WRITE;
INSERT INTO `controllers` VALUES (1,1,'IBM Winnipeg PCI-X Host Bridge','Host bridge',NULL,NULL,NULL,'rev 05'),(2,1,'ATI Technologies Inc Radeon RV100 QY [Radeon 7000/VE]','VGA compatible controller',NULL,NULL,NULL,NULL),(3,1,'VIA Technologies, Inc. VT82C686 [Apollo Super South]','ISA bridge',NULL,NULL,NULL,'rev 40'),(4,1,'VIA Technologies, Inc. VT82C586A/B/VT82C686/A/B/VT823x/A/C PIPC Bus Master IDE','IDE interface',NULL,NULL,NULL,'rev 06'),(5,1,'VIA Technologies, Inc. VT82xxxxx UHCI USB 1.1 Controller','USB Controller',NULL,NULL,NULL,'rev 1a'),(6,1,'VIA Technologies, Inc. VT82xxxxx UHCI USB 1.1 Controller','USB Controller',NULL,NULL,NULL,'rev 1a'),(7,1,'VIA Technologies, Inc. VT82C686 [Apollo Super ACPI]','SMBus',NULL,NULL,NULL,'rev 40'),(8,1,'IBM Winnipeg PCI-X Host Bridge','Host bridge',NULL,NULL,NULL,'rev 05'),(9,1,'Broadcom Corporation NetXtreme BCM5704 Gigabit Ethernet','Ethernet controller',NULL,NULL,NULL,'rev 02'),(10,1,'Broadcom Corporation NetXtreme BCM5704 Gigabit Ethernet','Ethernet controller',NULL,NULL,NULL,'rev 02'),(11,1,'IBM Winnipeg PCI-X Host Bridge','Host bridge',NULL,NULL,NULL,'rev 05'),(12,1,'IBM Winnipeg PCI-X Host Bridge','Host bridge',NULL,NULL,NULL,'rev 05'),(13,1,'IBM PCI-X to PCI-X Bridge','PCI bridge',NULL,NULL,NULL,'rev 02'),(14,1,'Adaptec ServeRAID Controller','RAID bus controller',NULL,NULL,NULL,'rev 02'),(15,1,'IBM Winnipeg PCI-X Host Bridge','Host bridge',NULL,NULL,NULL,'rev 05'),(16,1,'Silicon Image, Inc. (formerly CMD Technology Inc) SiI 3124 PCI-X Serial ATA Controller','RAID bus controller',NULL,NULL,NULL,'rev 02'),(17,1,'IBM Winnipeg PCI-X Host Bridge','Host bridge',NULL,NULL,NULL,'rev 05'),(18,2,'(Standard floppy disk controllers)','Standard floppy disk controller','Standard floppy disk controller','Standard floppy disk controller','N/A','Floppy Controller'),(19,2,'VIA Technologies, Inc.','VIA Bus Master IDE Controller','VIA Bus Master IDE Controller','VIA Bus Master IDE Controller','N/A','IDE Controller'),(20,2,'(Standard IDE ATA/ATAPI controllers)','Primary IDE Channel','Primary IDE Channel','Primary IDE Channel','N/A','IDE Controller'),(21,2,'(Standard IDE ATA/ATAPI controllers)','Secondary IDE Channel','Secondary IDE Channel','Secondary IDE Channel','N/A','IDE Controller'),(22,2,'(Standard mass storage controllers)','D347PRT SCSI Controller','D347PRT SCSI Controller','D347PRT SCSI Controller',NULL,'SCSI Controller'),(23,2,'VIA Technologies','VIA USB Universal Host Controller','VIA USB Universal Host Controller','VIA USB Universal Host Controller','N/A','USB Controller'),(24,2,'VIA Technologies','VIA USB Universal Host Controller','VIA USB Universal Host Controller','VIA USB Universal Host Controller','N/A','USB Controller'),(25,2,'VIA Technologies','VIA USB Universal Host Controller','VIA USB Universal Host Controller','VIA USB Universal Host Controller','N/A','USB Controller'),(26,2,'VIA','VIA PCI to USB Enhanced Host Controller','VIA PCI to USB Enhanced Host Controller','VIA PCI to USB Enhanced Host Controller','N/A','USB Controller'),(27,2,'VIA','VIA OHCI Compliant IEEE 1394 Host Controller','VIA OHCI Compliant IEEE 1394 Host Controller','VIA OHCI Compliant IEEE 1394 Host Controller','N/A','IEEE1394 Controller'),(28,3,'nVidia Corporation nForce2 AGP (different version?)','Host bridge',NULL,NULL,NULL,'rev a2'),(29,3,'nVidia Corporation nForce2 Memory Controller 1','RAM memory',NULL,NULL,NULL,'rev a2'),(30,3,'nVidia Corporation nForce2 Memory Controller 4','RAM memory',NULL,NULL,NULL,'rev a2'),(31,3,'nVidia Corporation nForce2 Memory Controller 3','RAM memory',NULL,NULL,NULL,'rev a2'),(32,3,'nVidia Corporation nForce2 Memory Controller 2','RAM memory',NULL,NULL,NULL,'rev a2'),(33,3,'nVidia Corporation nForce2 Memory Controller 5','RAM memory',NULL,NULL,NULL,'rev a2'),(34,3,'nVidia Corporation: Unknown device 0080','ISA bridge',NULL,NULL,NULL,'rev a3'),(35,3,'nVidia Corporation: Unknown device 0084','SMBus',NULL,NULL,NULL,'rev a1'),(36,3,'nVidia Corporation: Unknown device 0087','USB Controller',NULL,NULL,NULL,'rev a1'),(37,3,'nVidia Corporation: Unknown device 0087','USB Controller',NULL,NULL,NULL,'rev a1'),(38,3,'nVidia Corporation: Unknown device 0088','USB Controller',NULL,NULL,NULL,'rev a2'),(39,3,'nVidia Corporation: Unknown device 008c','Bridge',NULL,NULL,NULL,'rev a3'),(40,3,'nVidia Corporation: Unknown device 008a','Multimedia audio controller',NULL,NULL,NULL,'rev a1'),(41,3,'nVidia Corporation: Unknown device 008b','PCI bridge',NULL,NULL,NULL,'rev a3'),(42,3,'nVidia Corporation: Unknown device 0085','IDE interface',NULL,NULL,NULL,'rev a3'),(43,3,'nVidia Corporation: Unknown device 008e','IDE interface',NULL,NULL,NULL,'rev a3'),(44,3,'nVidia Corporation nForce2 AGP','PCI bridge',NULL,NULL,NULL,'rev a2'),(45,3,'VIA Technologies, Inc. IEEE 1394 Host Controller','FireWire (IEEE 1394)',NULL,NULL,NULL,'rev 80'),(46,3,'nVidia Corporation NV18 [GeForce4 MX - nForce GPU]','VGA compatible controller',NULL,NULL,NULL,'rev a3');
UNLOCK TABLES;
/*!40000 ALTER TABLE `controllers` ENABLE KEYS */;

--
-- Table structure for table `deleted_equiv`
--

DROP TABLE IF EXISTS `deleted_equiv`;
CREATE TABLE `deleted_equiv` (
  `DATE` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `DELETED` varchar(255) NOT NULL default '',
  `EQUIVALENT` varchar(255) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `deleted_equiv`
--


/*!40000 ALTER TABLE `deleted_equiv` DISABLE KEYS */;
LOCK TABLES `deleted_equiv` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `deleted_equiv` ENABLE KEYS */;

--
-- Table structure for table `deploy`
--

DROP TABLE IF EXISTS `deploy`;
CREATE TABLE `deploy` (
  `NAME` varchar(255) NOT NULL default '',
  `CONTENT` longblob NOT NULL,
  PRIMARY KEY  (`NAME`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `deploy`
--


/*!40000 ALTER TABLE `deploy` DISABLE KEYS */;
LOCK TABLES `deploy` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `deploy` ENABLE KEYS */;

--
-- Table structure for table `devices`
--

DROP TABLE IF EXISTS `devices`;
CREATE TABLE `devices` (
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `NAME` varchar(50) NOT NULL default '',
  `IVALUE` int(11) default NULL,
  `TVALUE` varchar(255) default NULL,
  `COMMENTS` text,
  KEY `HARDWARE_ID` (`HARDWARE_ID`),
  KEY `TVALUE` (`TVALUE`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `devices`
--


/*!40000 ALTER TABLE `devices` DISABLE KEYS */;
LOCK TABLES `devices` WRITE;
INSERT INTO `devices` VALUES (2,'IPDISCOVER',1,'192.168.198.0','');
UNLOCK TABLES;
/*!40000 ALTER TABLE `devices` ENABLE KEYS */;

--
-- Table structure for table `devicetype`
--

DROP TABLE IF EXISTS `devicetype`;
CREATE TABLE `devicetype` (
  `ID` int(11) NOT NULL auto_increment,
  `NAME` varchar(255) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `devicetype`
--


/*!40000 ALTER TABLE `devicetype` DISABLE KEYS */;
LOCK TABLES `devicetype` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `devicetype` ENABLE KEYS */;

--
-- Table structure for table `dico_cat`
--

DROP TABLE IF EXISTS `dico_cat`;
CREATE TABLE `dico_cat` (
  `NAME` varchar(255) NOT NULL default '',
  `PERMANENT` tinyint(4) default '0',
  PRIMARY KEY  (`NAME`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `dico_cat`
--


/*!40000 ALTER TABLE `dico_cat` DISABLE KEYS */;
LOCK TABLES `dico_cat` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `dico_cat` ENABLE KEYS */;

--
-- Table structure for table `dico_ignored`
--

DROP TABLE IF EXISTS `dico_ignored`;
CREATE TABLE `dico_ignored` (
  `EXTRACTED` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`EXTRACTED`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `dico_ignored`
--


/*!40000 ALTER TABLE `dico_ignored` DISABLE KEYS */;
LOCK TABLES `dico_ignored` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `dico_ignored` ENABLE KEYS */;

--
-- Table structure for table `dico_soft`
--

DROP TABLE IF EXISTS `dico_soft`;
CREATE TABLE `dico_soft` (
  `EXTRACTED` varchar(255) NOT NULL default '',
  `FORMATTED` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`EXTRACTED`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `dico_soft`
--


/*!40000 ALTER TABLE `dico_soft` DISABLE KEYS */;
LOCK TABLES `dico_soft` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `dico_soft` ENABLE KEYS */;

--
-- Table structure for table `download_available`
--

DROP TABLE IF EXISTS `download_available`;
CREATE TABLE `download_available` (
  `FILEID` varchar(255) NOT NULL default '',
  `NAME` varchar(255) NOT NULL default '',
  `PRIORITY` int(11) NOT NULL default '0',
  `FRAGMENTS` int(11) NOT NULL default '0',
  `SIZE` int(11) NOT NULL default '0',
  `OSNAME` varchar(255) NOT NULL default '',
  `COMMENT` text,
  PRIMARY KEY  (`FILEID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `download_available`
--


/*!40000 ALTER TABLE `download_available` DISABLE KEYS */;
LOCK TABLES `download_available` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `download_available` ENABLE KEYS */;

--
-- Table structure for table `download_enable`
--

DROP TABLE IF EXISTS `download_enable`;
CREATE TABLE `download_enable` (
  `ID` int(11) NOT NULL auto_increment,
  `FILEID` varchar(255) NOT NULL default '',
  `INFO_LOC` varchar(255) NOT NULL default '',
  `PACK_LOC` varchar(255) NOT NULL default '',
  `CERT_PATH` varchar(255) default NULL,
  `CERT_FILE` varchar(255) default NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `download_enable`
--


/*!40000 ALTER TABLE `download_enable` DISABLE KEYS */;
LOCK TABLES `download_enable` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `download_enable` ENABLE KEYS */;

--
-- Table structure for table `download_history`
--

DROP TABLE IF EXISTS `download_history`;
CREATE TABLE `download_history` (
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `PKG_ID` int(11) NOT NULL default '0',
  `PKG_NAME` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`PKG_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `download_history`
--


/*!40000 ALTER TABLE `download_history` DISABLE KEYS */;
LOCK TABLES `download_history` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `download_history` ENABLE KEYS */;

--
-- Table structure for table `drives`
--

DROP TABLE IF EXISTS `drives`;
CREATE TABLE `drives` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `LETTER` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `FILESYSTEM` varchar(255) default NULL,
  `TOTAL` int(11) default NULL,
  `FREE` int(11) default NULL,
  `NUMFILES` int(11) default NULL,
  `VOLUMN` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `drives`
--


/*!40000 ALTER TABLE `drives` DISABLE KEYS */;
LOCK TABLES `drives` WRITE;
INSERT INTO `drives` VALUES (1,1,NULL,'/dev/sda2','reiserfs',33682,5281,NULL,'/'),(2,1,NULL,'//172.26.2.5/projop','smbfs',111650,11672,NULL,'/mnt/berlin_projop'),(3,1,NULL,'//172.26.2.5/public','smbfs',111650,11672,NULL,'/mnt/berlin_public'),(4,1,NULL,'//172.26.2.5/web','smbfs',40961,20768,NULL,'/mnt/berlin_web'),(25,2,'A:/','Removable Drive','N/A',0,0,0,'N/A'),(26,2,'C:/','Hard Drive','NTFS',38154,3016,0,'Local Disk'),(27,2,'D:/','CD-Rom Drive','N/A',0,0,0,'N/A'),(28,2,'E:/','CD-Rom Drive','N/A',0,0,0,'N/A'),(29,2,'H:/','Network Drive','NTFS',0,0,0,'//172.26.2.5/fbergmann'),(30,2,'P:/','Network Drive','NTFS',0,0,0,'//172.26.2.5/projop'),(17,3,NULL,'/dev/md0','reiserfs',40961,20761,NULL,'/'),(18,3,NULL,'/dev/md1','reiserfs',111651,11670,NULL,'/home');
UNLOCK TABLES;
/*!40000 ALTER TABLE `drives` ENABLE KEYS */;

--
-- Table structure for table `files`
--

DROP TABLE IF EXISTS `files`;
CREATE TABLE `files` (
  `NAME` varchar(255) NOT NULL default '',
  `VERSION` varchar(255) NOT NULL default '',
  `OS` varchar(255) NOT NULL default '',
  `CONTENT` longblob NOT NULL,
  PRIMARY KEY  (`NAME`,`OS`,`VERSION`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `files`
--


/*!40000 ALTER TABLE `files` DISABLE KEYS */;
LOCK TABLES `files` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `files` ENABLE KEYS */;

--
-- Table structure for table `hardware`
--

DROP TABLE IF EXISTS `hardware`;
CREATE TABLE `hardware` (
  `ID` int(11) NOT NULL auto_increment,
  `DEVICEID` varchar(255) NOT NULL default '',
  `NAME` varchar(255) default NULL,
  `WORKGROUP` varchar(255) default NULL,
  `USERDOMAIN` varchar(255) default NULL,
  `OSNAME` varchar(255) default NULL,
  `OSVERSION` varchar(255) default NULL,
  `OSCOMMENTS` varchar(255) default NULL,
  `PROCESSORT` varchar(255) default NULL,
  `PROCESSORS` int(11) default '0',
  `PROCESSORN` smallint(6) default NULL,
  `MEMORY` int(11) default NULL,
  `SWAP` int(11) default NULL,
  `IPADDR` varchar(255) default NULL,
  `ETIME` datetime default NULL,
  `LASTDATE` datetime default NULL,
  `LASTCOME` datetime default NULL,
  `QUALITY` decimal(4,3) default '0.000',
  `FIDELITY` bigint(20) default '1',
  `USERID` varchar(255) default NULL,
  `TYPE` int(11) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `WINCOMPANY` varchar(255) default NULL,
  `WINOWNER` varchar(255) default NULL,
  `WINPRODID` varchar(255) default NULL,
  `WINPRODKEY` varchar(255) default NULL,
  `USERAGENT` varchar(50) default NULL,
  `CHECKSUM` int(11) default '131071',
  PRIMARY KEY  (`DEVICEID`,`ID`),
  KEY `NAME` (`NAME`),
  KEY `CHECKSUM` (`CHECKSUM`),
  KEY `DEVICEID` (`DEVICEID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `hardware`
--


/*!40000 ALTER TABLE `hardware` DISABLE KEYS */;
LOCK TABLES `hardware` WRITE;
INSERT INTO `hardware` VALUES (3,'berlin-2007-08-11-19-09-25','berlin','projop.com',NULL,'Linux','2.6.8-24.14-default','SuSe / SuSE Linux 9.2 (i586) / VERSION = 9.2 / #1 Tue Mar 29 09:27:43 UTC 2005','AMD Athlon(tm) XP 1800+',1500,1,1995,999,'172.26.2.5','0000-00-00 00:00:00','2007-08-11 19:17:28','2007-08-11 19:17:28','0.000',1,'root',8,'i686/00-00-18 18:26:08',NULL,NULL,NULL,NULL,'OCS-NG_linux_client_v15',131071),(1,'berlin2-2007-08-11-18-31-26','berlin2','site',NULL,'Linux','2.6.11.4-21.15-bigsmp','SuSe / SuSE Linux 9.3 (i586) / VERSION = 9.3 / #1 SMP Tue Nov 28 13:39:58 UTC 2006','Intel(R) Xeon(TM) MP CPU 2.70GHz',2695,4,16242,1027,'172.26.2.4','0000-00-00 00:00:00','2007-08-11 18:32:17','2007-08-11 18:32:17','0.000',1,'root',8,'i686/00-00-18 08:51:56',NULL,NULL,NULL,NULL,'OCS-NG_linux_client_v15',131071),(2,'BRASILIA-2007-08-11-18-49-48','BRASILIA','WORKGROUP','BRASILIA','Microsoft Windows 2000 Server','5.0.2195','Service Pack 4','AMD Athlon(tm)',1250,1,992,1620,'172.26.0.29','0000-00-00 00:00:00','2007-08-11 19:38:09','2007-08-11 19:38:09','0.006',4,'fbergmann',1,NULL,'SLS International','BRASILIA','51876-006-5671351-05668','K28TH-R7GGW-CD723-8RK9V-BGK7J','OCS-NG_windows_client_v4032',131071);
UNLOCK TABLES;
/*!40000 ALTER TABLE `hardware` ENABLE KEYS */;

--
-- Table structure for table `inputs`
--

DROP TABLE IF EXISTS `inputs`;
CREATE TABLE `inputs` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `TYPE` varchar(255) default NULL,
  `MANUFACTURER` varchar(255) default NULL,
  `CAPTION` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `INTERFACE` varchar(255) default NULL,
  `POINTTYPE` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `inputs`
--


/*!40000 ALTER TABLE `inputs` DISABLE KEYS */;
LOCK TABLES `inputs` WRITE;
INSERT INTO `inputs` VALUES (1,2,'Keyboard',NULL,'Enhanced (101- or 102-key)','Standard 101/102-Key or Microsoft Natural PS/2 Keyboard','N/A','N/A'),(2,2,'Pointing','Microsoft','PS/2 Compatible Mouse','PS/2 Compatible Mouse','PS/2','N/A'),(3,3,'kbd',NULL,'Keyboard[0]',NULL,'Standard',NULL),(4,3,'mouse',NULL,'Mouse[1]',NULL,'Auto',NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `inputs` ENABLE KEYS */;

--
-- Table structure for table `locks`
--

DROP TABLE IF EXISTS `locks`;
CREATE TABLE `locks` (
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `ID` int(11) default NULL,
  `SINCE` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`HARDWARE_ID`),
  KEY `SINCE` (`SINCE`)
) ENGINE=HEAP DEFAULT CHARSET=latin1;

--
-- Dumping data for table `locks`
--


/*!40000 ALTER TABLE `locks` DISABLE KEYS */;
LOCK TABLES `locks` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `locks` ENABLE KEYS */;

--
-- Table structure for table `memories`
--

DROP TABLE IF EXISTS `memories`;
CREATE TABLE `memories` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `CAPTION` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `CAPACITY` varchar(255) default NULL,
  `PURPOSE` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `SPEED` varchar(255) default NULL,
  `NUMSLOTS` smallint(6) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `memories`
--


/*!40000 ALTER TABLE `memories` DISABLE KEYS */;
LOCK TABLES `memories` WRITE;
INSERT INTO `memories` VALUES (1,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(2,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(3,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(4,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(5,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(6,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(7,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(8,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(9,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(10,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(11,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(12,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(13,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(14,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(15,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(16,1,NULL,'DIMM','1024',NULL,'DDR',NULL,0),(17,2,'Physical Memory','A0 (No ECC)','512','System Memory','Unknown','N/A',1),(18,2,'Physical Memory','A1 (No ECC)','512','System Memory','Unknown','N/A',2),(19,3,NULL,'DIMM','1024',NULL,'Unknown',NULL,0),(20,3,NULL,'DIMM','1024',NULL,'Unknown',NULL,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `memories` ENABLE KEYS */;

--
-- Table structure for table `modems`
--

DROP TABLE IF EXISTS `modems`;
CREATE TABLE `modems` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `NAME` varchar(255) default NULL,
  `MODEL` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `modems`
--


/*!40000 ALTER TABLE `modems` DISABLE KEYS */;
LOCK TABLES `modems` WRITE;
INSERT INTO `modems` VALUES (1,2,'Standard Modem over IR link','Standard Modem over IR link','Standard Modem over IR link','External Modem'),(2,2,'Motorola USB Modem','Motorola USB Modem','Motorola USB Modem','Internal Modem'),(3,2,'Motorola USB Modem #2','Motorola USB Modem','Motorola USB Modem','Internal Modem');
UNLOCK TABLES;
/*!40000 ALTER TABLE `modems` ENABLE KEYS */;

--
-- Table structure for table `monitors`
--

DROP TABLE IF EXISTS `monitors`;
CREATE TABLE `monitors` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `MANUFACTURER` varchar(255) default NULL,
  `CAPTION` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `SERIAL` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `monitors`
--


/*!40000 ALTER TABLE `monitors` DISABLE KEYS */;
LOCK TABLES `monitors` WRITE;
INSERT INTO `monitors` VALUES (1,2,'Samsung','SyncMaster','42/2006','RGB color','HMCLA23099'),(2,3,'--> VESA','Monitor[0]','800X600@60HZ',NULL,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `monitors` ENABLE KEYS */;

--
-- Table structure for table `netmap`
--

DROP TABLE IF EXISTS `netmap`;
CREATE TABLE `netmap` (
  `IP` varchar(15) NOT NULL default '',
  `MAC` varchar(17) NOT NULL default '',
  `MASK` varchar(15) NOT NULL default '',
  `NETID` varchar(15) NOT NULL default '',
  `DATE` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `NAME` varchar(255) default NULL,
  PRIMARY KEY  (`MAC`),
  KEY `IP` (`IP`),
  KEY `NETID` (`NETID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `netmap`
--


/*!40000 ALTER TABLE `netmap` DISABLE KEYS */;
LOCK TABLES `netmap` WRITE;
INSERT INTO `netmap` VALUES ('192.168.198.1','00:50:56:C0:00:08','255.255.255.0','192.168.198.0','2007-08-11 19:38:09','brasilia'),('192.168.198.254','00:50:56:E7:D2:9B','255.255.255.0','192.168.198.0','2007-08-11 19:38:09','192.168.198.254');
UNLOCK TABLES;
/*!40000 ALTER TABLE `netmap` ENABLE KEYS */;

--
-- Table structure for table `network_devices`
--

DROP TABLE IF EXISTS `network_devices`;
CREATE TABLE `network_devices` (
  `ID` int(11) NOT NULL auto_increment,
  `DESCRIPTION` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `MACADDR` varchar(255) default NULL,
  `USER` varchar(255) default NULL,
  PRIMARY KEY  (`ID`),
  KEY `MACADDR` (`MACADDR`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `network_devices`
--


/*!40000 ALTER TABLE `network_devices` DISABLE KEYS */;
LOCK TABLES `network_devices` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `network_devices` ENABLE KEYS */;

--
-- Table structure for table `networks`
--

DROP TABLE IF EXISTS `networks`;
CREATE TABLE `networks` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `DESCRIPTION` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `TYPEMIB` varchar(255) default NULL,
  `SPEED` varchar(255) default NULL,
  `MACADDR` varchar(255) default NULL,
  `STATUS` varchar(255) default NULL,
  `IPADDRESS` varchar(255) default NULL,
  `IPMASK` varchar(255) default NULL,
  `IPGATEWAY` varchar(255) default NULL,
  `IPSUBNET` varchar(255) default NULL,
  `IPDHCP` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `MACADDR` (`MACADDR`),
  KEY `IPSUBNET` (`IPSUBNET`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `networks`
--


/*!40000 ALTER TABLE `networks` DISABLE KEYS */;
LOCK TABLES `networks` WRITE;
INSERT INTO `networks` VALUES (1,1,'eth0','Ethernet',NULL,NULL,'00:09:6B:E6:44:80','Up','172.26.2.4','255.255.255.0','leconte.opus5.n','172.26.2.0',NULL),(2,2,'VMware Virtual Ethernet Adapter','Ethernet','ethernetCsmacd','100 Mb/s','00:50:56:C0:00:08','Up','192.168.198.1','255.255.255.0',NULL,'192.168.198.0','255.255.255.255'),(3,2,'VMware Virtual Ethernet Adapter','Ethernet','ethernetCsmacd','100 Mb/s','00:50:56:C0:00:01','Up','192.168.220.1','255.255.255.0',NULL,'192.168.220.0','255.255.255.255'),(4,2,'NDIS 5.0 driver','Ethernet','ethernetCsmacd','100 Mb/s','00:30:1B:AE:75:5F','Up','172.26.0.29','255.255.255.0','172.26.0.1','172.26.0.0','172.26.0.1'),(5,3,'eth0','Ethernet',NULL,NULL,'00:30:1B:B6:06:15','Up','172.26.2.5','255.255.255.0','leconte.opus5.n','172.26.2.0',NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `networks` ENABLE KEYS */;

--
-- Table structure for table `operators`
--

DROP TABLE IF EXISTS `operators`;
CREATE TABLE `operators` (
  `ID` varchar(255) NOT NULL default '',
  `FIRSTNAME` varchar(255) default NULL,
  `LASTNAME` varchar(255) default NULL,
  `PASSWD` varchar(50) default NULL,
  `ACCESSLVL` int(11) default NULL,
  `COMMENTS` text,
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `operators`
--


/*!40000 ALTER TABLE `operators` DISABLE KEYS */;
LOCK TABLES `operators` WRITE;
INSERT INTO `operators` VALUES ('admin','admin','admin','admin',1,'Default administrator account');
UNLOCK TABLES;
/*!40000 ALTER TABLE `operators` ENABLE KEYS */;

--
-- Table structure for table `ports`
--

DROP TABLE IF EXISTS `ports`;
CREATE TABLE `ports` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `TYPE` varchar(255) default NULL,
  `NAME` varchar(255) default NULL,
  `CAPTION` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `ports`
--


/*!40000 ALTER TABLE `ports` DISABLE KEYS */;
LOCK TABLES `ports` WRITE;
INSERT INTO `ports` VALUES (1,1,'Other','Not Specified','Proprietary','None'),(2,1,'Other','Not Specified','Proprietary','None'),(3,1,'Other','Not Specified','Proprietary','None'),(4,1,'Other','Not Specified','Proprietary','None'),(5,1,'Mouse Port','Not Specified','Mini DIN','None'),(6,1,'Keyboard Port','Not Specified','Mini DIN','None'),(7,1,'Other','Not Specified','RJ-45','None'),(8,1,'USB','Not Specified','Access Bus (USB)','None'),(9,1,'USB','Not Specified','Access Bus (USB)','None'),(10,1,'USB','Not Specified','Access Bus (USB)','None'),(11,1,'Video Port','Not Specified','DB-15 female','None'),(12,1,'Other','Not Specified','Proprietary','None'),(13,1,'Other','Diskette/CDROM','None','Other'),(14,1,'SCSI Wide','Not Specified','68 Pin Dual Inline','None'),(15,1,'SCSI Wide','Internal SCSI (channel B)','None','68 Pin Dual Inline'),(16,1,'Network Port','Not Specified','RJ-45','None'),(17,1,'Network Port','Not Specified','RJ-45','None'),(18,1,'Serial Port 16550A Compatible','Not Specified','DB-9 male','None'),(19,1,'Network Port','Not Specified','RJ-45','None'),(20,1,'Other','Not Specified','RJ-45','None'),(21,2,'Serial','Communications Port (COM1)','Communications Port (COM1)','Communications Port'),(22,2,'Serial','Communications Port (COM2)','Communications Port (COM2)','Communications Port'),(23,2,'Parallel','LPT1','LPT1','LPT1'),(24,3,'Other','PRIMARY IDE','None','On Board IDE'),(25,3,'Other','SECONDARY IDE','None','On Board IDE'),(26,3,'8251 FIFO Compatible','FDD','None','On Board Floppy'),(27,3,'Serial Port 16450 Compatible','COM1','DB-9 male','9 Pin Dual Inline (pin 10 cut)'),(28,3,'Serial Port 16450 Compatible','COM2','DB-9 male','9 Pin Dual Inline (pin 10 cut)'),(29,3,'Parallel Port ECP/EPP','LPT1','DB-25 female','DB-25 female'),(30,3,'Keyboard Port','Keyboard','PS/2','PS/2'),(31,3,'Mouse Port','PS/2 Mouse','PS/2','PS/2'),(32,3,'USB','Not Specified','Other','None');
UNLOCK TABLES;
/*!40000 ALTER TABLE `ports` ENABLE KEYS */;

--
-- Table structure for table `printers`
--

DROP TABLE IF EXISTS `printers`;
CREATE TABLE `printers` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `NAME` varchar(255) default NULL,
  `DRIVER` varchar(255) default NULL,
  `PORT` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `printers`
--


/*!40000 ALTER TABLE `printers` DISABLE KEYS */;
LOCK TABLES `printers` WRITE;
INSERT INTO `printers` VALUES (1,2,'Microsoft Office Live Meeting Document Writer','Microsoft Office Live Meeting Document Writer Driver','Microsoft Office Live Meeting Document Writer Port:'),(2,2,'hp color LaserJet 2550 series','HP 2500C Series PS3','IP_opus5.local.9100'),(3,2,'Fax','Windows NT Fax Driver','MSFAX:'),(4,2,'Acrobat Distiller','AdobePS Acrobat Distiller','C:/Documents and Settings/All Users/Desktop/*.pdf');
UNLOCK TABLES;
/*!40000 ALTER TABLE `printers` ENABLE KEYS */;

--
-- Table structure for table `regconfig`
--

DROP TABLE IF EXISTS `regconfig`;
CREATE TABLE `regconfig` (
  `ID` int(11) NOT NULL auto_increment,
  `NAME` varchar(255) default NULL,
  `REGTREE` int(11) default NULL,
  `REGKEY` text,
  `REGVALUE` varchar(255) default NULL,
  PRIMARY KEY  (`ID`),
  KEY `NAME` (`NAME`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `regconfig`
--


/*!40000 ALTER TABLE `regconfig` DISABLE KEYS */;
LOCK TABLES `regconfig` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `regconfig` ENABLE KEYS */;

--
-- Table structure for table `registry`
--

DROP TABLE IF EXISTS `registry`;
CREATE TABLE `registry` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `NAME` varchar(255) default NULL,
  `REGVALUE` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `NAME` (`NAME`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `registry`
--


/*!40000 ALTER TABLE `registry` DISABLE KEYS */;
LOCK TABLES `registry` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `registry` ENABLE KEYS */;

--
-- Table structure for table `slots`
--

DROP TABLE IF EXISTS `slots`;
CREATE TABLE `slots` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `NAME` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `DESIGNATION` varchar(255) default NULL,
  `PURPOSE` varchar(255) default NULL,
  `STATUS` varchar(255) default NULL,
  `PSHARE` tinyint(4) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `slots`
--


/*!40000 ALTER TABLE `slots` DISABLE KEYS */;
LOCK TABLES `slots` WRITE;
INSERT INTO `slots` VALUES (1,1,'Node 1 133MHz PCI-X ActivePCI Card Slot 6','64-bit PCI-X','6',NULL,'In Use',NULL),(2,1,'Node 1 133MHz PCI-X ActivePCI Card Slot 5','64-bit PCI-X','5',NULL,'In Use',NULL),(3,1,'Node 1 100MHz PCI-X ActivePCI Card Slot 4','64-bit PCI-X','4',NULL,'Available',NULL),(4,1,'Node 1 100MHz PCI-X ActivePCI Card Slot 3','64-bit PCI-X','3',NULL,'Available',NULL),(5,1,'Node 1 66MHz PCI-X ActivePCI Card Slot 2','64-bit PCI-X','2',NULL,'Available',NULL),(6,1,'Node 1 66MHz PCI-X ActivePCI Card Slot 1','64-bit PCI-X','1',NULL,'Available',NULL),(7,2,'System Slot','System Slot','PCI0',NULL,'OK',0),(8,2,'System Slot','System Slot','PCI1',NULL,'OK',0),(9,2,'System Slot','System Slot','PCI2',NULL,'OK',0),(10,2,'System Slot','System Slot','PCI3',NULL,'OK',0),(11,2,'System Slot','System Slot','AGP',NULL,'OK',0),(12,3,'PCI0','32-bit PCI','1',NULL,'Available',NULL),(13,3,'AGP','32-bit AGP','240',NULL,'In Use',NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `slots` ENABLE KEYS */;

--
-- Table structure for table `softwares`
--

DROP TABLE IF EXISTS `softwares`;
CREATE TABLE `softwares` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `PUBLISHER` varchar(255) default NULL,
  `NAME` varchar(255) default NULL,
  `VERSION` varchar(255) default NULL,
  `FOLDER` text,
  `COMMENTS` text,
  `FILENAME` varchar(255) default NULL,
  `FILESIZE` int(11) default '0',
  `SOURCE` int(11) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `NAME` (`NAME`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `softwares`
--


/*!40000 ALTER TABLE `softwares` DISABLE KEYS */;
LOCK TABLES `softwares` WRITE;
INSERT INTO `softwares` VALUES (1,1,NULL,'yast2-schema','2.10.1-3',NULL,'AutoYaST Schema',NULL,NULL,NULL),(2,1,NULL,'filesystem','9.3-2',NULL,'Basic Directory Layout',NULL,NULL,NULL),(3,1,NULL,'terminfo','5.4-68',NULL,'A terminal descriptions database',NULL,NULL,NULL),(4,1,NULL,'expat','1.95.8-4',NULL,'XML Parser Toolkit',NULL,NULL,NULL),(5,1,NULL,'cabextract','1.1-4',NULL,'A Program to Extract Microsoft Cabinet files',NULL,NULL,NULL),(6,1,NULL,'utempter','0.5.5-3',NULL,'A privileged helper for utmp and wtmp updates',NULL,NULL,NULL),(7,1,NULL,'ethtool','3-3',NULL,'Examine and Tune Ethernet-Based Network Interfaces',NULL,NULL,NULL),(8,1,NULL,'popt','1.7-207',NULL,'A C library for parsing command line parameters',NULL,NULL,NULL),(9,1,NULL,'ash','1.6.1-2',NULL,'The Ash shell',NULL,NULL,NULL),(10,1,NULL,'lukemftp','1.5-581',NULL,'enhanced ftp client',NULL,NULL,NULL),(11,1,NULL,'glib2','2.6.3-4',NULL,'A Library with Convenient Functions Written in C',NULL,NULL,NULL),(12,1,NULL,'tcpd','7.6-715',NULL,'A security wrapper for TCP daemons',NULL,NULL,NULL),(13,1,NULL,'libacl','2.2.30-3',NULL,'A dynamic library for accessing POSIX Access Control Lists',NULL,NULL,NULL),(14,1,NULL,'libgcj','3.3.5-5',NULL,'Java Runtime Library for gcc',NULL,NULL,NULL),(15,1,NULL,'pciutils','2.1.11-201',NULL,'PCI-utilities for Kernel version 2.2 and newer',NULL,NULL,NULL),(16,1,NULL,'cpp','3.3.5-5',NULL,'The GCC Preprocessor',NULL,NULL,NULL),(17,1,NULL,'pam','0.78-8',NULL,'A security tool that provides authentication for applications',NULL,NULL,NULL),(18,1,NULL,'grep','2.5.1a-4',NULL,'GNU grep',NULL,NULL,NULL),(19,1,NULL,'libgcrypt','1.2.1-3',NULL,'The GNU Crypto Library',NULL,NULL,NULL),(20,1,NULL,'libxml2','2.6.17-4',NULL,'A library to manipulate XML files',NULL,NULL,NULL),(21,1,NULL,'tcsh','6.12.00-455',NULL,'The C SHell',NULL,NULL,NULL),(22,1,NULL,'devs','9.3-2',NULL,'Device files',NULL,NULL,NULL),(23,1,NULL,'isapnp','1.26-492',NULL,'An ISA plug and play configuration utility',NULL,NULL,NULL),(24,1,NULL,'procinfo','18-43',NULL,'Display System Status Gathered from /proc',NULL,NULL,NULL),(25,1,NULL,'acpid','1.0.3-8',NULL,'Executes Actions at ACPI Events',NULL,NULL,NULL),(26,1,NULL,'scsi','1.7_2.35_1.12_0.14-4',NULL,'SCSI Tools (Text Mode)',NULL,NULL,NULL),(27,1,NULL,'yast2-mail-aliases','2.11.4-3',NULL,'YaST2 - Mail Configuration (Aliases)',NULL,NULL,NULL),(28,1,NULL,'sitar','0.9.0-5',NULL,'System InformaTion at Runtime',NULL,NULL,NULL),(29,1,NULL,'scpm','1.1-6',NULL,'System Configuration Profile Management',NULL,NULL,NULL),(30,1,NULL,'convmv','1.08-3',NULL,'Converts File Names from one Encoding to Another',NULL,NULL,NULL),(31,1,NULL,'perl-Digest-SHA1','2.10-3',NULL,'A Perl Interface to the SHA-1 Algorithm',NULL,NULL,NULL),(32,1,NULL,'openslp','1.2.0-3',NULL,'An OpenSLP Implementation of Service Location Protocol V2',NULL,NULL,NULL),(33,1,NULL,'hotplug','0.50-19',NULL,'Automatic configuration of hotplugged devices',NULL,NULL,NULL),(34,1,NULL,'pam-modules','9.3-4',NULL,'Additional PAM Modules',NULL,NULL,NULL),(35,1,NULL,'dmraid','0.99_1.0.0rc5CDH1-4',NULL,'A Device-Mapper Software RAID Support Tool',NULL,NULL,NULL),(36,1,NULL,'eject','2.0.13-190',NULL,'A program to eject media under software control',NULL,NULL,NULL),(37,1,NULL,'finger','1.2-42',NULL,'Show user information (client)',NULL,NULL,NULL),(38,1,NULL,'powersave','0.9.25-3',NULL,'General Powermanagement daemon supporting APM and ACPI and CPU frequency scaling',NULL,NULL,NULL),(39,1,NULL,'postfix','2.2.1-3',NULL,'A fast, secure, and flexible mailer',NULL,NULL,NULL),(40,1,NULL,'mailx','11.4-3',NULL,'A MIME-capable Implementation of the mailx Command',NULL,NULL,NULL),(41,1,NULL,'yast2-ncurses','2.11.5-3',NULL,'YaST2 - Character Based User Interface',NULL,NULL,NULL),(42,1,NULL,'yast2-nfs-client','2.11.7-3',NULL,'YaST2 - NFS Configuration',NULL,NULL,NULL),(43,1,NULL,'yast2-tune','2.11.6-3',NULL,'YaST2 - Hardware Tuning',NULL,NULL,NULL),(44,1,NULL,'yast2-support','2.11.1-3',NULL,'YaST2 - Support Inquiries',NULL,NULL,NULL),(45,1,NULL,'yast2-mouse','2.11.5-5',NULL,'YaST2 - Mouse Configuration',NULL,NULL,NULL),(46,1,NULL,'yast2-nis-client','2.11.10-3',NULL,'YaST2 - Network Information Services (NIS, YP) Configuration',NULL,NULL,NULL),(47,1,NULL,'yast2-ldap-client','2.11.11-3',NULL,'YaST2 - LDAP Client Configuration',NULL,NULL,NULL),(48,1,NULL,'yast2-profile-manager','2.11.2-3',NULL,'YaST2 - Profiles Configuration',NULL,NULL,NULL),(49,1,NULL,'yast2-dns-server','2.11.8-3',NULL,'YaST2 - DNS Server Configuration',NULL,NULL,NULL),(50,1,NULL,'yast2-restore','2.11.1-3',NULL,'YaST2 - System Restore',NULL,NULL,NULL),(51,1,NULL,'yast2-tv','2.11.3-3',NULL,'YaST2 - TV Configuration',NULL,NULL,NULL),(52,1,NULL,'xaw3d','1.5E-224',NULL,'3D Athena Widgets',NULL,NULL,NULL),(53,1,NULL,'emacs','21.3-202',NULL,'GNU Emacs Base Package',NULL,NULL,NULL),(54,1,NULL,'gcc-info','3.3.5-5',NULL,'GNU Info-Pages for GCC',NULL,NULL,NULL),(55,1,NULL,'ccache','2.4-3',NULL,'Compiler Cache',NULL,NULL,NULL),(56,1,NULL,'mysql-client','4.1.10a-3',NULL,'MySQL Client',NULL,NULL,NULL),(57,1,NULL,'ziptool','1.4.0-111',NULL,'Tool for the Iomega ZIP and JAZ drives',NULL,NULL,NULL),(58,1,NULL,'yast2-network','2.11.33-0.1',NULL,'YaST2 - Network Configuration',NULL,NULL,NULL),(59,1,NULL,'readline','5.0-7.2',NULL,'The Readline Library',NULL,NULL,NULL),(60,1,NULL,'yast2-firewall','2.11.12-0.1',NULL,'YaST2 - Firewall Configuration',NULL,NULL,NULL),(61,1,NULL,'yast2-packager','2.11.41-0.1',NULL,'YaST2 - Package Library',NULL,NULL,NULL),(62,1,NULL,'glibc-devel','2.3.4-23.4',NULL,'Include Files and Libraries Mandatory for Development.',NULL,NULL,NULL),(63,1,NULL,'xorg-x11-libs','6.8.2-30.3',NULL,'X Window System shared libraries',NULL,NULL,NULL),(64,1,NULL,'zlib','1.2.2-5.4',NULL,'Data Compression Library',NULL,NULL,NULL),(65,1,NULL,'util-linux','2.12q-7.4',NULL,'A collection of basic system utilities',NULL,NULL,NULL),(66,1,NULL,'giflib','4.1.3-5.2',NULL,'A Library for Working with GIF Images',NULL,NULL,NULL),(67,1,NULL,'coreutils','5.3.0-10.2',NULL,'GNU Core Utilities',NULL,NULL,NULL),(68,1,NULL,'cpio','2.5-328.3',NULL,'A Backup and Archiving Utility',NULL,NULL,NULL),(69,1,NULL,'libsmbclient','3.0.13-1.3',NULL,'Samba Client Library',NULL,NULL,NULL),(70,1,NULL,'libtiff','3.7.1-7.8',NULL,'The Tiff Library (with JPEG and compression support)',NULL,NULL,NULL),(71,1,NULL,'python','2.4-14.2',NULL,'Python Interpreter',NULL,NULL,NULL),(72,1,NULL,'postgresql-libs','8.0.8-0.4',NULL,'Shared Libraries Required for PostgreSQL Clients',NULL,NULL,NULL),(73,1,NULL,'timezone','2.3.4-23.7',NULL,'Timezone descriptions',NULL,NULL,NULL),(74,1,NULL,'kernel-source-debuginfo','2.6.11.4-20a',NULL,'Debug information for package kernel-source',NULL,NULL,NULL),(75,1,NULL,'syslog-ng','1.6.5-10.3',NULL,'new-generation syslog-daemon',NULL,NULL,NULL),(76,1,NULL,'cvsps','1.99-155',NULL,'A Program for Generating Patch Set Information from a CVS Repository',NULL,NULL,NULL),(77,1,NULL,'gpg-pubkey','c66b6eae-4491871e',NULL,'gpg(NVIDIA Corporation <linux-bugs@nvidia.com>)',NULL,NULL,NULL),(78,1,NULL,'perl-Net-SNMP','5.0.1-3',NULL,'Net::SNMP Perl Module',NULL,NULL,NULL),(79,1,NULL,'perl-TermReadKey','2.21-295',NULL,'A Perl Module for Simple Terminal Control',NULL,NULL,NULL),(80,1,NULL,'dante','1.1.14-126',NULL,'A Free Socks v4 and v5 Client Implementation',NULL,NULL,NULL),(81,1,NULL,'fetchmail','6.2.5-59.2',NULL,'Full-featured POP and IMAP mail retrieval daemon',NULL,NULL,NULL),(82,1,NULL,'libapr0','2.0.53-9',NULL,'Apache Portable Runtime (APR) Library',NULL,NULL,NULL),(83,1,NULL,'perl-DBI','1.47-3',NULL,'The Perl Database Interface',NULL,NULL,NULL),(84,1,NULL,'perl-IO-stringy','2.109-30',NULL,'I/O on in-core objects like strings and arrays',NULL,NULL,NULL),(85,1,NULL,'perl-Net-IP','1.20-118',NULL,'allow easy manipulation of IPv4 and IPv6 addresses',NULL,NULL,NULL),(86,1,NULL,'perl-URI','1.35-3',NULL,'Perl Interface for URI Objects',NULL,NULL,NULL),(87,1,NULL,'perl-XML-Parser','2.34-31',NULL,'XML Parser (Perl Module)',NULL,NULL,NULL),(88,1,NULL,'perl-HTML-Parser','3.45-3',NULL,'Perl HTML Interface',NULL,NULL,NULL),(89,1,NULL,'gtkmm2','2.2.12-6',NULL,'C++ Interface for GTK2 (a GUI library for X)',NULL,NULL,NULL),(90,1,NULL,'apache2-mod_perl','2.0.0-4',NULL,'Embedded Perl for Apache',NULL,NULL,NULL),(91,1,NULL,'perl-Apache-Filter','1.022-250',NULL,'Alter the output of previous handlers',NULL,NULL,NULL),(92,1,NULL,'perl-SOAP-Lite','0.60a-25',NULL,'SOAP::Lite for Perl',NULL,NULL,NULL),(93,1,NULL,'perl-XML-NamespaceSupport','1.08-3',NULL,'XML::NamespaceSupport Perl Module',NULL,NULL,NULL),(94,1,NULL,'perl-XML-SAX','0.12-4',NULL,'XML::SAX Perl Module',NULL,NULL,NULL),(95,1,NULL,'php4-gd','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(96,1,NULL,'gmp','4.1.4-3',NULL,'The GNU MP Library',NULL,NULL,NULL),(97,1,NULL,'libmcrypt','2.5.7-124',NULL,'Data Encryption Library',NULL,NULL,NULL),(98,1,NULL,'php4-bz2','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(99,1,NULL,'php4-dbase','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(100,1,NULL,'php4-filepro','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(101,1,NULL,'php4-ldap','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(102,1,NULL,'php4-pgsql','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(103,1,NULL,'php4-sockets','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(104,1,NULL,'php4-unixODBC','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(105,1,NULL,'php4-zlib','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(106,1,NULL,'php4-imap','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(107,1,NULL,'php4-pear','4.3.10-14',NULL,'PHP Extension and Application Repository',NULL,NULL,NULL),(108,1,NULL,'mod_php4-core','4.3.10-14',NULL,'Metapackage for Old PHP4 Layout.',NULL,NULL,NULL),(109,1,NULL,'gpg-pubkey','0dfb3188-41ed929b',NULL,'gpg(Open Enterprise Server <support@novell.com>)',NULL,NULL,NULL),(110,1,NULL,'aaa_skel','2005.2.1-3',NULL,'Skeleton for default users',NULL,NULL,NULL),(111,1,NULL,'yast2-bootfloppy','2.11.22-3',NULL,'YaST2 - Boot Floppy Creation',NULL,NULL,NULL),(112,1,NULL,'libcap','1.92-483',NULL,'library and binaries for capabilities (linux-privs) support',NULL,NULL,NULL),(113,1,NULL,'ncurses','5.4-68',NULL,'New curses libraries',NULL,NULL,NULL),(114,1,NULL,'gdbm','1.8.3-230',NULL,'GNU database routines',NULL,NULL,NULL),(115,1,NULL,'iptables','1.3.1-3',NULL,'IP Packet Filter Administration',NULL,NULL,NULL),(116,1,NULL,'libxcrypt','2.2-3',NULL,'Crypt library for DES, MD5, and blowfish',NULL,NULL,NULL),(117,1,NULL,'insserv','1.00.8-4',NULL,'A program to arrange init-scripts',NULL,NULL,NULL),(118,1,NULL,'less','382-41',NULL,'Text File Browser and Pager Similar to More',NULL,NULL,NULL),(119,1,NULL,'libgpg-error','1.0-3',NULL,'library that defines common error values for all GnuPG components',NULL,NULL,NULL),(120,1,NULL,'klogd','1.4.1-537',NULL,'The kernel log daemon',NULL,NULL,NULL),(121,1,NULL,'glib','1.2.10-593',NULL,'The utility functions for Gtk',NULL,NULL,NULL),(122,1,NULL,'iproute2','2.6.10-4',NULL,'Advanced routing',NULL,NULL,NULL),(123,1,NULL,'info','4.8-7',NULL,'A Stand-Alone Terminal-Based Info Browser',NULL,NULL,NULL),(124,1,NULL,'make','3.80-187',NULL,'GNU make',NULL,NULL,NULL),(125,1,NULL,'diffutils','2.8.7-4',NULL,'GNU diff utilities',NULL,NULL,NULL),(126,1,NULL,'sed','4.1.4-3',NULL,'A stream-oriented non-interactive text editor',NULL,NULL,NULL),(127,1,NULL,'findutils','4.2.19-3',NULL,'GNU find - Finding Files',NULL,NULL,NULL),(128,1,NULL,'grub','0.95-16',NULL,'GRand Unified Bootloader',NULL,NULL,NULL),(129,1,NULL,'ksymoops','2.4.11-3',NULL,'Kernel oops and error message decoder',NULL,NULL,NULL),(130,1,NULL,'reiserfs','3.6.18-3',NULL,'Reiser File System utilities',NULL,NULL,NULL),(131,1,NULL,'lilo','22.3.4-521',NULL,'The LInux LOader, a boot menu',NULL,NULL,NULL),(132,1,NULL,'raidtools','1.00.3-231',NULL,'Software-raid utilities',NULL,NULL,NULL),(133,1,NULL,'pmtools','20031210-5',NULL,'ACPI Debugging Tools',NULL,NULL,NULL),(134,1,NULL,'nscd','2.3.4-23',NULL,'Name Service Caching Daemon',NULL,NULL,NULL),(135,1,NULL,'SuSEfirewall2','3.3-18',NULL,'Stateful packetfilter using iptables and netfilter',NULL,NULL,NULL),(136,1,NULL,'kbd','1.12-37',NULL,'Keyboard and font utilities',NULL,NULL,NULL),(137,1,NULL,'netcfg','9.3-2',NULL,'Network configuration files in /etc',NULL,NULL,NULL),(138,1,NULL,'siga','9.301-3',NULL,'System Information GAthering',NULL,NULL,NULL),(139,1,NULL,'usbutils','0.70-8',NULL,'Tools and libraries for USB devices',NULL,NULL,NULL),(140,1,NULL,'portmap','5beta-733',NULL,'A program that manages RPC connections',NULL,NULL,NULL),(141,1,NULL,'rsh','0.17-556',NULL,'Clients for remote access commands (rsh, rlogin, and rcp)',NULL,NULL,NULL),(142,1,NULL,'yast2-transfer','2.9.3-3',NULL,'YaST2 - Agent for Various Transfer Protocols',NULL,NULL,NULL),(143,1,NULL,'mkinitrd','1.2-26',NULL,'Creates an initial ramdisk image for preloading modules',NULL,NULL,NULL),(144,1,NULL,'dbus-1-glib','0.23.4-7',NULL,'GLib-based library for using D-BUS',NULL,NULL,NULL),(145,1,NULL,'deltarpm','2.2-3',NULL,'Tools to Create and Apply deltarpms',NULL,NULL,NULL),(146,1,NULL,'yast2-irda','2.11.3-3',NULL,'YaST2 - Infra-Red (IrDA) Access Configuration',NULL,NULL,NULL),(147,1,NULL,'yast2-tftp-server','2.11.3-3',NULL,'YaST2 - TFTP Server Configuration',NULL,NULL,NULL),(148,1,NULL,'yast2-runlevel','2.11.8-4',NULL,'YaST2 - Runlevel Editor',NULL,NULL,NULL),(149,1,NULL,'yast2-pam','2.11.1-3',NULL,'YaST2 - PAM Agent',NULL,NULL,NULL),(150,1,NULL,'yast2-ldap','2.11.0-3',NULL,'YaST2 - LDAP Agent',NULL,NULL,NULL),(151,1,NULL,'yast2-update','2.11.16-3',NULL,'YaST2 - Update',NULL,NULL,NULL),(152,1,NULL,'autoyast2-installation','2.11.13-3',NULL,'YaST2 - Auto Installation Modules',NULL,NULL,NULL),(153,1,NULL,'autoyast2','2.11.13-3',NULL,'YaST2 -Automated Installation',NULL,NULL,NULL),(154,1,NULL,'yast2-nfs-server','2.11.5-3',NULL,'YaST2 - NFS Server Configuration',NULL,NULL,NULL),(155,1,NULL,'yast2-nis-server','2.11.5-3',NULL,'YaST2 - Network Information Services (NIS) Server Configuration',NULL,NULL,NULL),(156,1,NULL,'fontconfig','2.2.99.20050218-8',NULL,'Library for Font Configuration',NULL,NULL,NULL),(157,1,NULL,'ctags','2004.11.15-3',NULL,'A Program to Generate Tag files for use with Vi and other Editors',NULL,NULL,NULL),(158,1,NULL,'graphviz','2.2-3',NULL,'Graph Visualization Tools',NULL,NULL,NULL),(159,1,NULL,'gcc','3.3.5-5',NULL,'The GNU C Compiler and Support Files',NULL,NULL,NULL),(160,1,NULL,'libstdc++-devel','3.3.5-5',NULL,'Include Files and Libraries mandatory for Development',NULL,NULL,NULL),(161,1,NULL,'flex','2.5.4a-296',NULL,'Fast Lexical Analyser Generator',NULL,NULL,NULL),(162,1,NULL,'sysbench','0.3.2-5',NULL,'A MySQL benchmarking tool',NULL,NULL,NULL),(163,1,NULL,'chkfontpath','1.10.0-4',NULL,'Simple interface for editing the font path for the X font server.',NULL,NULL,NULL),(164,1,NULL,'yast2-storage','2.11.31-1.1',NULL,'YaST2 - Storage Configuration',NULL,NULL,NULL),(165,1,NULL,'gnome-filesystem','0.1-211.4',NULL,'GNOME Directory Layout',NULL,NULL,NULL),(166,1,NULL,'hal','0.4.7-26.3',NULL,'Daemon for Collecting Hardware Information',NULL,NULL,NULL),(167,1,NULL,'yast2-x11','2.11.4-8.2',NULL,'YaST2 - X Window System Configuration',NULL,NULL,NULL),(168,1,NULL,'alsa','1.0.9-9.1',NULL,'Advanced Linux Sound Architecture',NULL,NULL,NULL),(169,1,NULL,'glibc-locale','2.3.4-23.4',NULL,'Locale Data for Localized Programs',NULL,NULL,NULL),(170,1,NULL,'logrotate','3.7-35.2',NULL,'A program to rotate, compress, remove, and mail system log files',NULL,NULL,NULL),(171,1,NULL,'zlib-devel','1.2.2-5.4',NULL,'Include Files and Libraries mandatory for Development.',NULL,NULL,NULL),(172,1,NULL,'permissions','2005.10.20-0.1',NULL,'SUSE Linux Default Permissions',NULL,NULL,NULL),(173,1,NULL,'perl','5.8.6-5.3',NULL,'The Perl interpreter',NULL,NULL,NULL),(174,1,NULL,'resmgr','0.9.8-65.4',NULL,'A program to allow arbitrary access to device files',NULL,NULL,NULL),(175,1,NULL,'cron','4.1-20.2',NULL,'cron daemon',NULL,NULL,NULL),(176,1,NULL,'samba','3.0.13-1.3',NULL,'A SMB/ CIFS File Server',NULL,NULL,NULL),(177,1,NULL,'freetype2','2.1.9-4.4',NULL,'A TrueType font library',NULL,NULL,NULL),(178,1,NULL,'binutils','2.15.94.0.2.2-3.5',NULL,'GNU Binutils',NULL,NULL,NULL),(179,1,NULL,'postgresql','8.0.8-0.4',NULL,'Basic Clients and Utilities for PostgreSQL',NULL,NULL,NULL),(180,1,NULL,'postgresql-pl','8.0.8-0.4',NULL,'The PL/Tcl, PL/Perl, and PL/Python Procedural Languages for PostgreSQL',NULL,NULL,NULL),(181,1,NULL,'libpng','1.2.8-3.3',NULL,'Library for the Portable Network Graphics Format',NULL,NULL,NULL),(182,1,NULL,'kernel-bigsmp','2.6.11.4-21.15',NULL,'Kernel with multiprocessor support and PAE',NULL,NULL,NULL),(183,1,NULL,'xinetd','2.3.13-45.2',NULL,'An \'inetd\' with Expanded Functionality',NULL,NULL,NULL),(184,1,NULL,'cups-libs','1.1.23-7.6',NULL,'libraries for CUPS',NULL,NULL,NULL),(185,1,NULL,'patch','2.5.9-145',NULL,'GNU patch',NULL,NULL,NULL),(186,1,NULL,'readline-devel','5.0-7.2',NULL,'Include Files and Libraries mandatory for Development.',NULL,NULL,NULL),(187,1,NULL,'nagios-plugins','1.4-3',NULL,'The Nagios Plug-Ins',NULL,NULL,NULL),(188,1,NULL,'radiusclient','0.3.2-144',NULL,'Radius Client Software',NULL,NULL,NULL),(189,1,NULL,'rsaref','2.0-508',NULL,'RSA Reference Implementation',NULL,NULL,NULL),(190,1,NULL,'python-tk','2.4-14',NULL,'TkInter - Python Tk Interface',NULL,NULL,NULL),(191,1,NULL,'libsigc++12','1.2.5-4',NULL,'Typesafe Signal Framework for C++',NULL,NULL,NULL),(192,1,NULL,'perl-Data-ShowTable','3.3-572',NULL,'A Perl Module that allows Pretty-Printing of Data Arrays',NULL,NULL,NULL),(193,1,NULL,'perl-MIME-Lite','3.01-142',NULL,'Module for Generating MIME messages',NULL,NULL,NULL),(194,1,NULL,'perl-NetAddr-IP','3.21-3',NULL,'NetAddr::IP - Manages IP addresses and subnets',NULL,NULL,NULL),(195,1,NULL,'perl-Unicode-String','2.07-131',NULL,'String of Unicode characters (UCS2/UTF16)',NULL,NULL,NULL),(196,1,NULL,'apache2-prefork','2.0.53-9',NULL,'Apache 2 \"prefork\" MPM (Multi-Processing Module)',NULL,NULL,NULL),(197,1,NULL,'perl-MIME-tools','5.415-4',NULL,'modules for parsing (and creating!) MIME entities',NULL,NULL,NULL),(198,1,NULL,'libglade2','2.5.1-6',NULL,'Glade Library Compatible with the GNOME 2.x Desktop Platform',NULL,NULL,NULL),(199,1,NULL,'mysql-administrator','1.0.19-3',NULL,'A MySQL server management, configuration and monitoring tool.',NULL,NULL,NULL),(200,1,NULL,'perl-HTTPS-Daemon','1.02-3',NULL,'a simple http server class with SSL support',NULL,NULL,NULL),(201,1,NULL,'perl-Archive-Zip','1.09-30',NULL,'perl-Archive-Zip',NULL,NULL,NULL),(202,1,NULL,'perl-XML-RegExp','0.03-478',NULL,'Regular Expressions for XML Tokens',NULL,NULL,NULL),(203,1,NULL,'gd','2.0.32-6',NULL,'A Drawing Library for programs that use PNG and JPEG Output',NULL,NULL,NULL),(204,1,NULL,'php5','5.0.3-14.4',NULL,'PHP5 Core Files',NULL,NULL,NULL),(205,1,NULL,'imap-lib','2004c-3',NULL,'IMAP4rev1/c-client Development Environment',NULL,NULL,NULL),(206,1,NULL,'libtool','1.5.14-3',NULL,'A tool to build shared libraries',NULL,NULL,NULL),(207,1,NULL,'php4-calendar','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(208,1,NULL,'php4-dbx','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(209,1,NULL,'php4-ftp','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(210,1,NULL,'php4-mbstring','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(211,1,NULL,'php4-session','4.3.10-14.4',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(212,1,NULL,'php4-swf','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(213,1,NULL,'php4-yp','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(214,1,NULL,'php4-gmp','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(215,1,NULL,'php4-mhash','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(216,1,NULL,'php4-qtdom','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(217,1,NULL,'gpg-pubkey','3d25d3d9-36e12d04',NULL,'gpg(SuSE Security Team <security@suse.de>)',NULL,NULL,NULL),(218,1,NULL,'release-notes','9.3.10-3',NULL,'A Short Description of the Most Important Changes for This SUSE Linux Release',NULL,NULL,NULL),(219,1,NULL,'yast2-trans-stats','2.11.0-5',NULL,'YaST Translation Statistics',NULL,NULL,NULL),(220,1,NULL,'yast2-trans-en_US','2.11.3-3',NULL,'YaST2 - American English Translations',NULL,NULL,NULL),(221,1,NULL,'netcat','1.10-869',NULL,'A simple but powerful network tool',NULL,NULL,NULL),(222,1,NULL,'libattr','2.4.22-3',NULL,'A dynamic library for filesystem extended attribute support',NULL,NULL,NULL),(223,1,NULL,'libnscd','1.1-4',NULL,'Library to Allow Applications to Communicate with nscd',NULL,NULL,NULL),(224,1,NULL,'mingetty','0.9.6s-76',NULL,'Minimal Getty for Virtual Consoles Only',NULL,NULL,NULL),(225,1,NULL,'lsof','4.74-3',NULL,'A program that lists information about files opened by processes',NULL,NULL,NULL),(226,1,NULL,'boehm-gc','3.3.5-5',NULL,'Boehm Garbage Collector Library',NULL,NULL,NULL),(227,1,NULL,'libstdc++','3.3.5-5',NULL,'The standard C++ shared library',NULL,NULL,NULL),(228,1,NULL,'attr','2.4.22-3',NULL,'A command to manipulate filesystem extended attributes',NULL,NULL,NULL),(229,1,NULL,'db','4.3.27-3',NULL,'Berkeley DB Database Library',NULL,NULL,NULL),(230,1,NULL,'libzio','0.1-5',NULL,'A library for accessing compressed text files',NULL,NULL,NULL),(231,1,NULL,'ntfsprogs','1.9.4-3',NULL,'NTFS Utilities',NULL,NULL,NULL),(232,1,NULL,'iputils','ss021109-151',NULL,'IPv4and IPv6 networking utilities',NULL,NULL,NULL),(233,1,NULL,'src_vipa','2.0.0-63',NULL,'Virtual Source IP address support for HA solutions',NULL,NULL,NULL),(234,1,NULL,'busybox','1.00-3',NULL,'The Swiss Army Knife of Embedded Linux',NULL,NULL,NULL),(235,1,NULL,'libselinux','1.21.7-3',NULL,'SELinux Library and Utilities',NULL,NULL,NULL),(236,1,NULL,'gettext','0.14.1-39',NULL,'Tools for Native Language Support (NLS)',NULL,NULL,NULL),(237,1,NULL,'fillup','1.42-101',NULL,'Tool for merging config files',NULL,NULL,NULL),(238,1,NULL,'gawk','3.1.4-7',NULL,'GNU awk',NULL,NULL,NULL),(239,1,NULL,'ed','0.2-869',NULL,'Standard UNIX line editor',NULL,NULL,NULL),(240,1,NULL,'yast2-theme-SuSELinux','2.11.2-3',NULL,'YaST2 - Theme (SuSE Linux)',NULL,NULL,NULL),(241,1,NULL,'cyrus-sasl','2.1.20-7',NULL,'Implementation of Cyrus SASL API',NULL,NULL,NULL),(242,1,NULL,'perl-gettext','1.01-579',NULL,'gettext for perl',NULL,NULL,NULL),(243,1,NULL,'groff','1.18.1.1-7',NULL,'GNU troff document formatting system',NULL,NULL,NULL),(244,1,NULL,'gpm','1.20.1-305',NULL,'Console Mouse Support',NULL,NULL,NULL),(245,1,NULL,'perl-Config-Crontab','1.03-49',NULL,'Read/Write Vixie compatible crontab files',NULL,NULL,NULL),(246,1,NULL,'device-mapper','1.01.00-3',NULL,'Device Mapper Tools',NULL,NULL,NULL),(247,1,NULL,'procps','3.2.5-3',NULL,'ps utilities for /proc',NULL,NULL,NULL),(248,1,NULL,'perl-Parse-RecDescent','1.80-247',NULL,'Perl RecDescent Module',NULL,NULL,NULL),(249,1,NULL,'perl-Bootloader','0.2-17',NULL,'Library for Configuring Boot Loaders',NULL,NULL,NULL),(250,1,NULL,'evms','2.3.3-5',NULL,'EVMS - Enterprise Volume Management System',NULL,NULL,NULL),(251,1,NULL,'openct','0.6.2-4',NULL,'OpenCT Library for Smart Card Readers',NULL,NULL,NULL),(252,1,NULL,'yast2-core','2.11.26-3',NULL,'YaST2 - Core Libraries',NULL,NULL,NULL),(253,1,NULL,'cyrus-sasl-saslauthd','2.1.20-7',NULL,'The SASL Authentication Server',NULL,NULL,NULL),(254,1,NULL,'suse-build-key','1.0-665',NULL,'The public gpg key for rpm package signature verification',NULL,NULL,NULL),(255,1,NULL,'at','3.1.8-902',NULL,'A job manager',NULL,NULL,NULL),(256,1,NULL,'yast2-slp','2.10.0-3',NULL,'SLP Agent and Browser for  YaST',NULL,NULL,NULL),(257,1,NULL,'yast2-pkg-bindings','2.11.6-3',NULL,'YaST2 Package Manager Access',NULL,NULL,NULL),(258,1,NULL,'yast2-scanner','2.11.6-3',NULL,'YaST2 - Scanner Configuration',NULL,NULL,NULL),(259,1,NULL,'yast2-mail','2.11.4-3',NULL,'YaST2 - Mail Configuration',NULL,NULL,NULL),(260,1,NULL,'yast2-xml','2.11.2-3',NULL,'YaST2 - XML Agent',NULL,NULL,NULL),(261,1,NULL,'yast2-phone-services','2.11.1-3',NULL,'YaST2 - Phone Services Configuration',NULL,NULL,NULL),(262,1,NULL,'yast2-sound','2.11.10-3',NULL,'YaST2 - Sound Configuration',NULL,NULL,NULL),(263,1,NULL,'yast2-power-management','2.11.6-2',NULL,'YaST2 - Power Management Configuration',NULL,NULL,NULL),(264,1,NULL,'yast2-bootloader','2.11.22-3',NULL,'YaST2 - Bootloader Configuration',NULL,NULL,NULL),(265,1,NULL,'yast2-kerberos-client','2.11.7-3',NULL,'YaST2 - Kerberos Client Configuration',NULL,NULL,NULL),(266,1,NULL,'yast2-repair','2.11.9-3',NULL,'YaST2 - System Repair Tool',NULL,NULL,NULL),(267,1,NULL,'yast2-sysconfig','2.11.3-3',NULL,'YaST2 - Sysconfig Editor',NULL,NULL,NULL),(268,1,NULL,'yast2-inetd','2.11.11-3',NULL,'YaST2 - Network Services Configuration',NULL,NULL,NULL),(269,1,NULL,'yast2-backup','2.11.6-3',NULL,'YaST2 - System Backup',NULL,NULL,NULL),(270,1,NULL,'emacs-info','21.3-202',NULL,'Info files for GNU Emacs',NULL,NULL,NULL),(271,1,NULL,'graphviz-devel','2.2-3',NULL,'Graphiviz development package',NULL,NULL,NULL),(272,1,NULL,'m4','1.4.2-4',NULL,'GNU m4',NULL,NULL,NULL),(273,1,NULL,'gcc-c++','3.3.5-5',NULL,'The GNU C++ Compiler',NULL,NULL,NULL),(274,1,NULL,'swig','1.3.21-110',NULL,'Simplified Wrapper and Interface Generator',NULL,NULL,NULL),(275,1,NULL,'smartmontools','5.33-6',NULL,'Monitor for S.M.A.R.T. Disks and Devices',NULL,NULL,NULL),(276,1,NULL,'unzip','5.51-3',NULL,'A program to unpack compressed files',NULL,NULL,NULL),(277,1,NULL,'webfonts','1-3',NULL,'TrueType web fonts: Times, Courier, Arial, Comic, Impact',NULL,NULL,NULL),(278,1,NULL,'sysconfig','0.32.0-18.2',NULL,'The sysconfig scheme',NULL,NULL,NULL),(279,1,NULL,'sysvinit','2.85-38.4',NULL,'SysV-Style init',NULL,NULL,NULL),(280,1,NULL,'bzip2','1.0.2-348.3',NULL,'A program for compressing files',NULL,NULL,NULL),(281,1,NULL,'telnet','1.1-44.4',NULL,'A client program for the telnet remote login protocol',NULL,NULL,NULL),(282,1,NULL,'dhcpcd','1.3.22pl4-202.2',NULL,'A DHCP client daemon',NULL,NULL,NULL),(283,1,NULL,'cvs','1.12.12-2.1',NULL,'Concurrent Versions System',NULL,NULL,NULL),(284,1,NULL,'lynx','2.8.5-34.3',NULL,'A text-based WWW browser',NULL,NULL,NULL),(285,1,NULL,'curl','7.13.0-5.4',NULL,'A tool for transfering data from URLs',NULL,NULL,NULL),(286,1,NULL,'net-tools','1.60-556.3',NULL,'Important programs for networking',NULL,NULL,NULL),(287,1,NULL,'wget','1.10-1.5',NULL,'A Tool for Mirroring FTP and HTTP Servers',NULL,NULL,NULL),(288,1,NULL,'samba-client','3.0.13-1.3',NULL,'Samba Client Utilities',NULL,NULL,NULL),(289,1,NULL,'gzip','1.3.5-140.2',NULL,'GNU Zip Compression Utilities',NULL,NULL,NULL),(290,1,NULL,'openssh','3.9p1-12.10',NULL,'Secure shell client and server (remote login program)',NULL,NULL,NULL),(291,1,NULL,'postgresql-contrib','8.0.8-0.4',NULL,'Contributed Extensions and Additions to PostgreSQL',NULL,NULL,NULL),(292,1,NULL,'postgresql-server','8.0.8-0.4',NULL,'The Programs Needed to Create and Run a PostgreSQL Server',NULL,NULL,NULL),(293,1,NULL,'tar','1.15.1-5.4',NULL,'GNU implementation of tar ( (t)ape (ar)chiver )',NULL,NULL,NULL),(294,1,NULL,'VMware-server','1.0.1-29996',NULL,'VMware Server',NULL,NULL,NULL),(295,1,NULL,'kernel-bigsmp-nongpl','2.6.11.4-21.15',NULL,'Non-GPL kernel modules',NULL,NULL,NULL),(296,1,NULL,'krb5','1.4-16.7',NULL,'MIT Kerberos5 Implementation--Libraries',NULL,NULL,NULL),(297,1,NULL,'bind-libs','9.3.2-56.1',NULL,'Shared libraries of BIND',NULL,NULL,NULL),(298,1,NULL,'patchutils','0.2.30-3',NULL,'A Collection of Tools for Manipulating Patch Files',NULL,NULL,NULL),(299,1,NULL,'perl-Digest-HMAC','1.01-495',NULL,'Keyed Hashing for Message Authentication',NULL,NULL,NULL),(300,1,NULL,'fping','2.4b2-3',NULL,'A Program to Ping Multiple Hosts',NULL,NULL,NULL),(301,1,NULL,'net-snmp','5.2.1-5',NULL,'SNMP Daemon',NULL,NULL,NULL),(302,1,NULL,'tk','8.4.9-9',NULL,'TK Toolkit for TCL',NULL,NULL,NULL),(303,1,NULL,'fetchmailconf','6.2.5-59',NULL,'Fetchmail Configuration Utility',NULL,NULL,NULL),(304,1,NULL,'pango','1.8.1-4',NULL,'System for Layout and Rendering of Internationalised Text',NULL,NULL,NULL),(305,1,NULL,'perl-HTML-Tagset','3.04-3',NULL,'Data Tables Useful for Dealing with HTML',NULL,NULL,NULL),(306,1,NULL,'perl-MailTools','1.60-32',NULL,'a set of perl modules related to mail applications',NULL,NULL,NULL),(307,1,NULL,'perl-Net_SSLeay','1.25-31',NULL,'Net::SSLeay Perl Module',NULL,NULL,NULL),(308,1,NULL,'perl-XML-LibXML','1.58-3',NULL,'XML::LibXML Perl Module',NULL,NULL,NULL),(309,1,NULL,'gtk2','2.6.4-6',NULL,'Library for Creation of Graphical User Interfaces',NULL,NULL,NULL),(310,1,NULL,'perl-libxml-perl','0.07-481',NULL,'Collection of Perl modules for working with XML',NULL,NULL,NULL),(311,1,NULL,'mysql','4.1.10a-3.2',NULL,'A true Multi-User, Multi-Threaded SQL Database Server',NULL,NULL,NULL),(312,1,NULL,'perl-IO-Socket-SSL','0.96-4',NULL,'IO::Socket::SSL Perl Module',NULL,NULL,NULL),(313,1,NULL,'perl-XML-Stream','1.17-31',NULL,'Creates and XML Stream connection and parses return data',NULL,NULL,NULL),(314,1,NULL,'php4','4.3.10-14.4',NULL,'PHP4 Core Files',NULL,NULL,NULL),(315,1,NULL,'perl-XML-Simple','2.12-3',NULL,'Easy API to read/write XML (Perl module)',NULL,NULL,NULL),(316,1,NULL,'mm','1.3.0-124',NULL,'Shared Memory Library',NULL,NULL,NULL),(317,1,NULL,'php5-gd','5.0.3-14',NULL,'PHP5 Extension Module',NULL,NULL,NULL),(318,1,NULL,'liblcms','1.14-3',NULL,'Libraries for the little CMS engine',NULL,NULL,NULL),(319,1,NULL,'mhash','0.9.2-3',NULL,'A library for working with strong hashes, such as MD5',NULL,NULL,NULL),(320,1,NULL,'php4-ctype','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(321,1,NULL,'php4-domxml','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(322,1,NULL,'php4-gettext','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(323,1,NULL,'php4-mime_magic','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(324,1,NULL,'php4-shmop','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(325,1,NULL,'php4-sysvsem','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(326,1,NULL,'php4-wddx','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(327,1,NULL,'libmng','1.0.9-4',NULL,'Library for Support of MNG and JNG Formats',NULL,NULL,NULL),(328,1,NULL,'php4-mcrypt','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(329,1,NULL,'qt3','3.3.4-11.3',NULL,'A library for developing applications with graphical user interfaces',NULL,NULL,NULL),(330,1,NULL,'apache2-mod_php4','4.3.10-14.4',NULL,'PHP4 Module for Apache 2.0',NULL,NULL,NULL),(331,1,NULL,'gpg-pubkey','9c800aca-40d8063e',NULL,'gpg(SuSE Package Signing Key <build@suse.de>)',NULL,NULL,NULL),(332,1,NULL,'suse-release','9.3-4',NULL,'SuSE release version files',NULL,NULL,NULL),(333,1,NULL,'sash','3.7-32',NULL,'A stand-alone shell with built-in commands',NULL,NULL,NULL),(334,1,NULL,'providers','2004.10.25-3',NULL,'A list of internet service providers',NULL,NULL,NULL),(335,1,NULL,'hdparm','5.9-4',NULL,'A program to get and set hard disk parameters',NULL,NULL,NULL),(336,1,NULL,'libgcc','3.3.5-5',NULL,'C compiler runtime library',NULL,NULL,NULL),(337,1,NULL,'mktemp','1.5-732',NULL,'A utility for tempfiles',NULL,NULL,NULL),(338,1,NULL,'gpart','0.1h-478',NULL,'Tool that can Guess a Lost Partition Table',NULL,NULL,NULL),(339,1,NULL,'file','4.13-5',NULL,'A tool to determine file types',NULL,NULL,NULL),(340,1,NULL,'dialog','0.9b-192',NULL,'Menus and Input Boxes for Shell Scripts',NULL,NULL,NULL),(341,1,NULL,'bash','3.0-15',NULL,'The GNU Bourne-Again Shell',NULL,NULL,NULL),(342,1,NULL,'module-init-tools','3.2_pre1-7',NULL,'Utilities to load modules into the kernel',NULL,NULL,NULL),(343,1,NULL,'initviocons','0.4-301',NULL,'Terminal initialization for the iSeries virtual console',NULL,NULL,NULL),(344,1,NULL,'cracklib','2.7-1010',NULL,'A Password-Checking Library',NULL,NULL,NULL),(345,1,NULL,'acl','2.2.30-3',NULL,'Commands for Manipulating POSIX Access Control Lists',NULL,NULL,NULL),(346,1,NULL,'recode','3.6-491',NULL,'A character set converter',NULL,NULL,NULL),(347,1,NULL,'bc','1.06-749',NULL,'GNU command line calculator',NULL,NULL,NULL),(348,1,NULL,'e2fsprogs','1.36-5',NULL,'Utilities for the second extended file system',NULL,NULL,NULL),(349,1,NULL,'parted','1.6.21-4',NULL,'GNU partitioner',NULL,NULL,NULL),(350,1,NULL,'jfsutils','1.1.7-5',NULL,'IBM JFS utility programs',NULL,NULL,NULL),(351,1,NULL,'xfsprogs','2.6.25-3',NULL,'Utilities for managing the XFS file system',NULL,NULL,NULL),(352,1,NULL,'hwinfo','10.16-3',NULL,'Hardware library',NULL,NULL,NULL),(353,1,NULL,'libxslt','1.1.12-5',NULL,'XSL Transformation Library',NULL,NULL,NULL),(354,1,NULL,'vim','6.3.58-3',NULL,'Vi IMproved',NULL,NULL,NULL),(355,1,NULL,'checkmedia','1.0-5',NULL,'Check Installation Media',NULL,NULL,NULL),(356,1,NULL,'fbset','2.1-782',NULL,'Frame Buffer Configuration Tool',NULL,NULL,NULL),(357,1,NULL,'psmisc','21.5-3',NULL,'Utilities for managing processes on your system',NULL,NULL,NULL),(358,1,NULL,'xdelta','1.1.3-6',NULL,'Binary delta generator and RCS replacement library',NULL,NULL,NULL),(359,1,NULL,'libusb','0.1.8-36',NULL,'USB libraries',NULL,NULL,NULL),(360,1,NULL,'man','2.4.1-221',NULL,'A program for displaying man pages',NULL,NULL,NULL),(361,1,NULL,'perl-X500-DN','0.28-120',NULL,'provides an interface for RFC 2253 style DN strings',NULL,NULL,NULL),(362,1,NULL,'openslp-server','1.2.0-3',NULL,'The OpenSLP Implementation of the  Service Location Protocol V2',NULL,NULL,NULL),(363,1,NULL,'ldapcpplib','0.0.3-30',NULL,'C++ API for LDAPv3',NULL,NULL,NULL),(364,1,NULL,'pcsc-lite','1.2.9-6',NULL,'The MUSCLE project SmartCards library',NULL,NULL,NULL),(365,1,NULL,'dbus-1','0.23.4-7',NULL,'D-BUS message bus system',NULL,NULL,NULL),(366,1,NULL,'opensc','0.9.4-4',NULL,'OpenSC smart card library',NULL,NULL,NULL),(367,1,NULL,'yast2-perl-bindings','2.11.3-3',NULL,'YaST2 - Perl Bindings',NULL,NULL,NULL),(368,1,NULL,'yast2','2.11.48-3',NULL,'YaST2 - Main Package',NULL,NULL,NULL),(369,1,NULL,'yast2-bluetooth','2.11.4-3',NULL,'YaST2 Bluetooth Configuration',NULL,NULL,NULL),(370,1,NULL,'yast2-ntp-client','2.11.3-3',NULL,'YaST2 - NTP Client Configuration',NULL,NULL,NULL),(371,1,NULL,'yast2-online-update','2.11.9-3',NULL,'YaST2 - Online Update (YOU)',NULL,NULL,NULL),(372,1,NULL,'yast2-country','2.11.21-3',NULL,'YaST2 - Country Settings (Language, Keyboard, and Timezone)',NULL,NULL,NULL),(373,1,NULL,'yast2-dhcp-server','2.11.6-3',NULL,'YaST2 - DHCP Server Configuration',NULL,NULL,NULL),(374,1,NULL,'yast2-security','2.11.4-3',NULL,'YaST2 - Security Configuration',NULL,NULL,NULL),(375,1,NULL,'yast2-users','2.11.16-3',NULL,'YaST2 - User and Group Configuration',NULL,NULL,NULL),(376,1,NULL,'yast2-installation','2.11.22-6',NULL,'YaST2 - Installation Parts',NULL,NULL,NULL),(377,1,NULL,'yast2-powertweak','2.11.3-3',NULL,'YaST2 - Powertweak Configuration',NULL,NULL,NULL),(378,1,NULL,'libjpeg','6.2.0-738',NULL,'JPEG libraries',NULL,NULL,NULL),(379,1,NULL,'emacs-x11','21.3-202',NULL,'GNU Emacs: Emacs binary with X Window System Support',NULL,NULL,NULL),(380,1,NULL,'yast2-samba-client','2.11.5-3',NULL,'YaST2 - Samba Client Configuration',NULL,NULL,NULL),(381,1,NULL,'tcl','8.4.9-7',NULL,'The Tcl scripting language',NULL,NULL,NULL),(382,1,NULL,'cvs-doc','1.12.11-4',NULL,'Open Source Development with CVS, 2nd Edition Book',NULL,NULL,NULL),(383,1,NULL,'guile','1.6.7-3',NULL,'GNU\'s Ubiquitous Intelligent Language for Extension',NULL,NULL,NULL),(384,1,NULL,'bison','1.875-55',NULL,'The GNU Parser Generator',NULL,NULL,NULL),(385,1,NULL,'indent','2.2.9-195',NULL,'Indent Formats C Source Code',NULL,NULL,NULL),(386,1,NULL,'findutils-locate','4.2.19-3',NULL,'Tool for Locating Files (GNU Findutils Subpackage)',NULL,NULL,NULL),(387,1,NULL,'dbench','1.3-340',NULL,'File System Benchmark similar to Netbench',NULL,NULL,NULL),(388,1,NULL,'zip','2.3-741',NULL,'File compression program',NULL,NULL,NULL),(389,1,NULL,'aaa_base','9.3-9.2',NULL,'SuSE Linux base package',NULL,NULL,NULL),(390,1,NULL,'mdadm','1.9.0-3.2',NULL,'Utility for configuring MD setup',NULL,NULL,NULL),(391,1,NULL,'wireless-tools','28pre4-16.2',NULL,'Tools for a wireless LAN',NULL,NULL,NULL),(392,1,NULL,'submount','0.9-61.2',NULL,'Auto Mounting of Removable Media',NULL,NULL,NULL),(393,1,NULL,'yast2-packagemanager','2.11.29-0.1',NULL,'YaST2 - Package Manager',NULL,NULL,NULL),(394,1,NULL,'glibc','2.3.4-23.4',NULL,'Standard Shared Libraries (from the GNU C Library)',NULL,NULL,NULL),(395,1,NULL,'rpm','4.1.1-208.2',NULL,'The RPM Package Manager',NULL,NULL,NULL),(396,1,NULL,'udev','053-15.4',NULL,'A Userspace Implementation of DevFS',NULL,NULL,NULL),(397,1,NULL,'pcre','5.0-3.2',NULL,'A library for Perl-compatible regular expressions',NULL,NULL,NULL),(398,1,NULL,'pwdutils','2.6.96-4.2',NULL,'Utilities to Manage User and Group Accounts',NULL,NULL,NULL),(399,1,NULL,'procmail','3.22-41.4',NULL,'A program for local e-mail delivery',NULL,NULL,NULL),(400,1,NULL,'liby2util','2.11.7-0.3',NULL,'YaST2 - Utilities Library',NULL,NULL,NULL),(401,1,NULL,'cifs-mount','3.0.13-1.3',NULL,'mount using the Common Internet File System (CIFS)',NULL,NULL,NULL),(402,1,NULL,'samba-doc','3.0.13-1.3',NULL,'Samba Documentation',NULL,NULL,NULL),(403,1,NULL,'openssl','0.9.7e-3.8',NULL,'Secure Sockets and Transport Layer Security',NULL,NULL,NULL),(404,1,NULL,'postgresql-docs','8.0.8-0.4',NULL,'HTML Documentation for PostgreSQL',NULL,NULL,NULL),(405,1,NULL,'openldap2-client','2.2.23-6.6',NULL,'OpenLDAP2 client utilities',NULL,NULL,NULL),(406,1,NULL,'gpg','1.4.0-4.11',NULL,'The GNU Privacy Guard. Encrypts, decrypts, and signs data',NULL,NULL,NULL),(407,1,NULL,'kernel-source','2.6.11.4-21.15',NULL,'The Linux kernel sources',NULL,NULL,NULL),(408,1,NULL,'w3m','0.5.1-4.2',NULL,'A text-based WWW browser',NULL,NULL,NULL),(409,1,NULL,'bind-utils','9.3.2-56.1',NULL,'Utilities to query and test DNS',NULL,NULL,NULL),(410,1,NULL,'rsync','2.6.3-7',NULL,'Replacement for RCP/mirror that has Many More Features',NULL,NULL,NULL),(411,1,NULL,'perl-Crypt-DES','2.03-362',NULL,'Crypt::DES Perl Module',NULL,NULL,NULL),(412,1,NULL,'mysql-shared','4.1.10a-3',NULL,'MySQL Shared Libraries',NULL,NULL,NULL),(413,1,NULL,'nagios-plugins-extras','1.4-3',NULL,'Nagios Plug-Ins which Depend on Additional Packages',NULL,NULL,NULL),(414,1,NULL,'blt','2.4z-205',NULL,'Tcl/Tk Extension',NULL,NULL,NULL),(415,1,NULL,'atk','1.9.1-4',NULL,'An Accessibility ToolKit',NULL,NULL,NULL),(416,1,NULL,'perl-Compress-Zlib','1.34-4',NULL,'Perl interface to part of the info-zip zlib compression library',NULL,NULL,NULL),(417,1,NULL,'perl-IO-Zlib','1.01-31',NULL,'IO:: style interface to the Compress::Zlib',NULL,NULL,NULL),(418,1,NULL,'perl-Net-DNS','0.48-3',NULL,'Perl interface to the DNS resolver',NULL,NULL,NULL),(419,1,NULL,'perl-Tie-IxHash','1.21-587',NULL,'TieIxHash Perl Module',NULL,NULL,NULL),(420,1,NULL,'perl-XML-LibXML-Common','0.13-4',NULL,'XML::LibXML::Common Perl Module',NULL,NULL,NULL),(421,1,NULL,'perl-DBD-mysql','2.9004-3',NULL,'Interface to the MySQL database',NULL,NULL,NULL),(422,1,NULL,'apache2','2.0.53-9',NULL,'The Apache web server (version 2.0)',NULL,NULL,NULL),(423,1,NULL,'perl-libwww-perl','5.803-3',NULL,'Modules Providing a World Wide Web API',NULL,NULL,NULL),(424,1,NULL,'perl-Apache-DBI','0.94-46',NULL,'Apache authentication via perl DBI',NULL,NULL,NULL),(425,1,NULL,'perl-Net-Jabber','1.29-30',NULL,'Jabber Perl Library',NULL,NULL,NULL),(426,1,NULL,'php4-devel','4.3.10-14.4',NULL,'Include files of PHP4',NULL,NULL,NULL),(427,1,NULL,'perl-XML-DOM','1.43-33',NULL,'Perl Extension to XML::Parser',NULL,NULL,NULL),(428,1,NULL,'t1lib','1.3.1-572',NULL,'Adobe Type 1 Font Rasterizing Library',NULL,NULL,NULL),(429,1,NULL,'libmcal','0.7-121',NULL,'Modular Calendar Access Library',NULL,NULL,NULL),(430,1,NULL,'php4-bcmath','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(431,1,NULL,'php4-curl','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(432,1,NULL,'php4-exif','4.3.10-14.4',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(433,1,NULL,'php4-iconv','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(434,1,NULL,'php4-mysql','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(435,1,NULL,'php4-snmp','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(436,1,NULL,'php4-sysvshm','4.3.10-14.4',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(437,1,NULL,'sablot','1.0.1-44',NULL,'XSL Processor',NULL,NULL,NULL),(438,1,NULL,'php4-mcal','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(439,1,NULL,'php4-xslt','4.3.10-14',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(440,1,NULL,'mod_php4-apache2','4.3.10-14',NULL,'Metapackage for Old PHP4 Layout.',NULL,NULL,NULL),(570,2,'N/A','7-Zip 4.42','N/A','N/A','N/A','N/A',0,1),(571,2,'ActiveState Corporation','ActiveState ActiveTcl 8.4.7.0','8.4.7.0','N/A','N/A','N/A',0,1),(572,2,'N/A','WebEx','N/A','N/A','N/A','N/A',0,1),(573,2,'Adobe Systems, Inc.','Adobe Acrobat 5.0','5.0','C:/Program Files/Adobe/Acrobat 5.0','N/A','N/A',0,1),(574,2,'Adobe Systems Incorporated','Adobe Flash Player Plugin','9.0.47.0','N/A','N/A','N/A',0,1),(575,2,'Adobe Systems, Inc.','Adobe FrameMaker v7.0','7.0','C:/Program Files/Adobe/FrameMaker7.0','N/A','N/A',0,1),(576,2,'Adobe Systems, Inc.','Adobe Photoshop 6.0','6.0','C:/Program Files/Adobe/Photoshop 6.0','N/A','N/A',0,1),(577,2,'N/A','Audacity 1.2.4','N/A','C:/Program Files/Audacity/','N/A','N/A',0,1),(578,2,'N/A','AVG Free Edition','N/A','N/A','N/A','N/A',0,1),(579,2,'N/A','FreeMind','0.8.0','C:/Program Files/FreeMind/','N/A','N/A',0,1),(580,2,'N/A','CamStudio','N/A','N/A','N/A','N/A',0,1),(581,2,'DBTools Software','DBManagerPro 3.4.4','3.4.4','C:/Program Files/DBTools Software/DBManagerPro/','N/A','N/A',0,1),(582,2,'DNKA Software','DNKA 0.45','0.45','C:/Program Files/DNKA/','N/A','N/A',0,1),(583,2,'N/A','eMule','N/A','N/A','N/A','N/A',0,1),(584,2,'N/A','EPSON Scan','N/A','N/A','N/A','N/A',0,1),(585,2,'Aquino Developments S.L.','freebudget 4.1','freebudget 4.1','c:/Aquino/freebudget4/','N/A','N/A',0,1),(586,2,'N/A','GanttProject','N/A','N/A','N/A','N/A',0,1),(587,2,'N/A','GSview 4.7','N/A','N/A','N/A','N/A',0,1),(588,2,'Martijn Laan','Inno Setup QuickStart Pack 4.2.7','4.2.7','C:/Program Files/Inno Setup 4/','N/A','N/A',0,1),(589,2,'Apple Computer, Inc.','Bonjour','1.0.66','C:/Program Files/Bonjour/',NULL,'N/A',0,1),(590,2,'Apple Computer, Inc.','iTunes','6.0.4.2','C:/Program Files/iTunes/',NULL,'N/A',0,1),(591,2,'Aladdin Systems, Inc.','StuffIt Standard','8.5.0.137','C:/Program Files/Aladdin Systems/StuffIt/',NULL,'N/A',0,1),(592,2,'Apple Computer, Inc.','QuickTime','7.1','C:/Program Files/QuickTime/',NULL,'N/A',0,1),(593,2,'N/A','IrfanView (remove only)','N/A','N/A','N/A','N/A',0,1),(594,2,'Microsoft Corporation','DirectX 9 Hotfix - KB839643','N/A','N/A','N/A','N/A',0,1),(595,2,'Microsoft Corporation','Windows 2000 Hotfix - KB842773',NULL,'N/A','N/A','N/A',0,1),(596,2,'Microsoft Corporation','Windows 2000 Hotfix - KB890046','20050517.235025','N/A','N/A','N/A',0,1),(597,2,'Microsoft Corporation','Windows 2000 Hotfix - KB893756','20050702.42421','N/A','N/A','N/A',0,1),(598,2,'Microsoft Corporation','Windows Installer 3.1 (KB893803)','3.1','N/A','N/A','N/A',0,1),(599,2,'Microsoft Corporation','Windows 2000 Hotfix - KB896358','20050421.70926','N/A','N/A','N/A',0,1),(600,2,'Microsoft Corporation','Windows 2000 Hotfix - KB896422','20050503.23608','N/A','N/A','N/A',0,1),(601,2,'Microsoft Corporation','Windows 2000 Hotfix - KB896423','20050713.01536','N/A','N/A','N/A',0,1),(602,2,'Microsoft Corporation','Windows 2000 Hotfix - KB896424','20051007.114600','N/A','N/A','N/A',0,1),(603,2,'Microsoft Corporation','Windows 2000 Hotfix - KB899587','20050614.212757','N/A','N/A','N/A',0,1),(604,2,'Microsoft Corporation','Windows 2000 Hotfix - KB899589','20050822.21016','N/A','N/A','N/A',0,1),(605,2,'Microsoft Corporation','Windows 2000 Hotfix - KB899591','20050629.14549','N/A','N/A','N/A',0,1),(606,2,'Microsoft Corporation','Windows 2000 Hotfix - KB900725','20050923.34708','N/A','N/A','N/A',0,1),(607,2,'Microsoft Corporation','Windows 2000 Hotfix - KB901017','20050830.22150','N/A','N/A','N/A',0,1),(608,2,'Microsoft Corporation','Windows 2000 Hotfix - KB901214','20050629.02152','N/A','N/A','N/A',0,1),(609,2,'Microsoft Corporation','Security Update for Windows 2000 (KB904706)','N/A','N/A','N/A','N/A',0,1),(610,2,'Microsoft Corporation','Windows 2000 Hotfix - KB905414','20050816.13004','N/A','N/A','N/A',0,1),(611,2,'Microsoft Corporation','Windows 2000 Hotfix - KB905495','20050805.184113','N/A','N/A','N/A',0,1),(612,2,'Microsoft Corporation','Windows 2000 Hotfix - KB905749','20050902.21643','N/A','N/A','N/A',0,1),(613,2,'Microsoft Corporation','Windows 2000 Hotfix - KB908519','20051124.165020','N/A','N/A','N/A',0,1),(614,2,'Microsoft Corporation','Windows 2000 Hotfix - KB908523','20051021.131026','N/A','N/A','N/A',0,1),(615,2,'Microsoft Corporation','Windows 2000 Hotfix - KB908531','20060421.150136','N/A','N/A','N/A',0,1),(616,2,'Microsoft Corporation','Security Update for Windows Media Player (KB911564)','N/A','N/A','N/A','N/A',0,1),(617,2,'Microsoft Corporation','Windows 2000 Hotfix - KB911567','20060316.165634','N/A','N/A','N/A',0,1),(618,2,'Microsoft Corporation','Windows 2000 Hotfix - KB912812','20060322.182418','N/A','N/A','N/A',0,1),(619,2,'Microsoft Corporation','Windows 2000 Hotfix - KB912919','20060103.111025','N/A','N/A','N/A',0,1),(620,2,'Microsoft Corporation','Windows 2000 Hotfix - KB913580','20060423.131341','N/A','N/A','N/A',0,1),(621,2,'N/A','Python 2.4 linkchecker-3.2','N/A','N/A','N/A','N/A',0,1),(622,2,'Macromedia, Inc.','Macromedia Shockwave Player','10.1.0.11','N/A','N/A','N/A',0,1),(623,2,'N/A','Microsoft .NET Framework 1.1','N/A','N/A','N/A','N/A',0,1),(624,2,'N/A','Microsoft SDK Update February 2003 (5.2.3790.0)','5.2.3790.0','N/A','To add or remove SDK Update components from your system if you do not have a live Internet connection, choose Change or Remove and follow the SDK Update or Uninstall links.','N/A',0,1),(625,2,'Microsoft','Microsoft SQL Server 2000','8.00.194','C:/Program Files/Microsoft SQL Server/MSSQL','N/A','N/A',0,1),(626,2,'Microsoft Corporation','Microsoft SQL Server 2000 Analysis Services','8.0.1.94','C:/Program Files/Microsoft Analysis Services','N/A','N/A',0,1),(627,2,'N/A','Mirage Driver 1.1','1.1','N/A','N/A','N/A',0,1),(628,2,'Mozilla','Mozilla Firefox (2.0.0.6)','2.0.0.6 (en-US)','C:/Program Files/Mozilla Firefox','Mozilla Firefox','N/A',0,1),(629,2,'Mozilla','Mozilla Thunderbird (1.0.6)','1.0.6 (en)','C:/Program Files/Mozilla Thunderbird','N/A','N/A',0,1),(630,2,'N/A','Nero 6 Ultra Edition','N/A','N/A','N/A','N/A',0,1),(631,2,'OCS Inventory Team','OCS Inventory Agent 4.0.3.2','4.0.3.2','N/A','N/A','N/A',0,1),(632,2,'Syn-Tactic','Ophelia TE 3.0 Client','N/A','C:/Program Files/Ophelia/','N/A','N/A',0,1),(633,2,'N/A','ProSavageDDR and Utilities','N/A','N/A','N/A','N/A',0,1),(634,2,'N/A','Lexware buchhalter','N/A','N/A','N/A','N/A',0,1),(635,2,'Python Software Foundation','Python 2.3.4','2.3.4','N/A','N/A','N/A',0,1),(636,2,'Microsoft Corporation','Windows Media Player Hotfix [See Q828026 for more information]','N/A','N/A','N/A','N/A',0,1),(637,2,'N/A','Quest Software Toad  for Oracle , Version 8.0.0','N/A','N/A','N/A','N/A',0,1),(638,2,'N/A','RealPlayer','N/A','N/A','N/A','N/A',0,1),(639,2,'RealVNC Ltd.','VNC Free Edition 4.1.1','4.1.1','C:/Program Files/RealVNC/VNC4/','N/A','N/A',0,1),(640,2,'N/A','S3Display','N/A','N/A','N/A','N/A',0,1),(641,2,'N/A','S3Gamma2','N/A','N/A','N/A','N/A',0,1),(642,2,'N/A','S3Info2','N/A','N/A','N/A','N/A',0,1),(643,2,'N/A','S3Overlay','N/A','N/A','N/A','N/A',0,1),(644,2,'Adobe Systems','Adobe Flash Player 9 ActiveX','9','N/A','N/A','N/A',0,1),(645,2,'Skype Technologies S.A.','Skype 2.5','2.5','C:/Program Files/Skype/Phone/','N/A','N/A',0,1),(646,2,'N/A','SpamBayes 1.0.4','1.0.4','C:/Program Files/SpamBayes/','N/A','N/A',0,1),(647,2,'Syntap Software','Time Stamp 3.12','3.12','N/A','N/A','N/A',0,1),(648,2,'Pink Software','TurboCASH 3.73M','N/A','C:/TCash3/','N/A','N/A',0,1),(649,2,'N/A','UltraISO 8.0 Premium Edition','N/A','C:/Program Files/UltraISO/','N/A','N/A',0,1),(650,2,'Microsoft Corporation','Update Rollup 1 for Windows 2000 SP4','20050809.32623','N/A','N/A','N/A',0,1),(651,2,'N/A','Microsoft VGX Q833989','N/A','N/A','N/A','N/A',0,1),(652,2,'MeGALiTH Software','Visual IRC 2.0','N/A','N/A','N/A','N/A',0,1),(653,2,'N/A','WebBudget XT (Build 3.9.0.3)','N/A','N/A','N/A','N/A',0,1),(654,2,'N/A','Winamp (remove only)','N/A','N/A','N/A','N/A',0,1),(655,2,'N/A','Windows 2000 Service Pack 4','N/A','N/A','N/A','N/A',0,1),(656,2,'N/A','Compresor WinRAR','N/A','N/A','N/A','N/A',0,1),(657,2,'WinZip Computing, Inc.','WinZip','9.0  (6028)','C:/PROGRA~1/WINZIP/','N/A','N/A',0,1),(658,2,'N/A','Yahoo! Messenger','N/A','N/A','N/A','N/A',0,1),(659,2,'Yahoo! Inc.','Yahoo! Widgets','4.0.2.0','N/A','N/A','N/A',0,1),(660,2,']project-open[',']project-open[ V3.1.2.0.0','3.1.2.0.0','C:/ProjectOpen/','N/A','N/A',0,1),(661,2,'Microsoft Corporation','Microsoft Office 2000 Professional','9.00.2720',NULL,NULL,'N/A',0,1),(662,2,'Aquino Developments S.L.','freebudget 5','freebudget 5','C:/Program Files/Aquino/freebudget5/','N/A','N/A',0,1),(663,2,'Macromedia','Macromedia Dreamweaver MX 2004','7.0','C:/Program Files/Macromedia/Dreamweaver MX 2004','N/A','N/A',0,1),(664,2,'N/A','Google Toolbar for Internet Explorer','N/A','N/A','N/A','N/A',0,1),(665,2,'Microsoft Corporation','Microsoft Project 2000','9.00.3821',NULL,NULL,'N/A',0,1),(666,2,'Sun Microsystems, Inc.','Java 2 SDK, SE v1.4.2_08','1.4.2_08',NULL,'http://java.sun.com','N/A',0,1),(667,2,'Microsoft','Microsoft Visual C++ Toolkit 2003','1.01.0000','C:/Program Files/Microsoft Visual C++ Toolkit 2003/',NULL,'N/A',0,1),(668,2,'N/A','Mobile User VPN','N/A','N/A','N/A','N/A',0,1),(669,2,'Macromedia','Macromedia Flash MX','6','C:/Program Files/Macromedia/Flash MX','N/A','N/A',0,1),(670,2,'DAEMON\'\'S HOME','DAEMON Tools','3.47.0',NULL,NULL,'N/A',0,1),(671,2,'Microsoft','Remote Desktop Connection','5.1.2600.2180',NULL,NULL,'N/A',0,1),(672,2,'ActiveState Corporation','ActiveState ActivePython 2.4.1','2.4.247',NULL,'ActiveState\'\'s quality-assured binary build of Python','N/A',0,1),(673,2,'N/A','Motorola Handset USB Driver','N/A','N/A','N/A','N/A',0,1),(674,2,'PostgreSQL Global Development Group','PostgreSQL 8.0','8.0',NULL,NULL,'N/A',0,1),(675,2,'Sun Microsystems, Inc.','Java 2 Runtime Environment, SE v1.4.2_08','1.4.2_08',NULL,'http://www.java.com','N/A',0,1),(676,2,'N/A','SSH Secure Shell','N/A','N/A','N/A','N/A',0,1),(677,2,'OpenOffice.org','OpenOffice.org 2.0','2.0.9073',NULL,'OpenOffice.org 2.0 (en-US) (OOD680m5(Build:9073))','N/A',0,1),(678,2,'BVRP Software','LiveUpdate BVRP Software','1.00.005','C:/Program Files/LiveUpdate','N/A','N/A',0,1),(679,2,'Opera Software ASA','Opera 9.22','9.22','C:/Program Files/Opera/',NULL,'N/A',0,1),(680,2,'Microsoft Corporation','Microsoft Office Live Meeting 2005','7.6.2525.10','C:/Program Files/Microsoft Office/Live Meeting 7/Console/7.6.2525.10/',NULL,'N/A',0,1),(681,2,'Macromedia','MacromediaDreamweaver MX','6.0','C:/Program Files/Macromedia/Dreamweaver MX','N/A','N/A',0,1),(682,2,'Apple Inc.','Safari','3.522.11.3','C:/Program Files/Safari/',NULL,'N/A',0,1),(683,2,'EMS-HiTech','EMS PostgreSQL Manager','2.7.0.1',NULL,NULL,'N/A',0,1),(684,2,'Macromedia','Macromedia Extension Manager','1.5','C:/Program Files/Macromedia/Extension Manager','N/A','N/A',0,1),(685,2,'Ultra@VNC','Ultr@VNC Release 1.0.0 RC 18 - Win32','1.0018','N/A','N/A','N/A',0,1),(686,2,'Bjxrnar Henden','ISTool 4.2.7.0','4.2.7.0','C:/Program Files/ISTool 4/','N/A','N/A',0,1),(687,2,'Microsoft Corporation','MSN Messenger 6.2','6.2.0133',NULL,NULL,'N/A',0,1),(688,2,'Helios','TextPad 4.7','4.7.2',NULL,'Your Comments','N/A',0,1),(689,2,'DMSoft Technologies','Access2PostgreSQL Pro','1.7.1',NULL,NULL,'N/A',0,1),(690,2,'The pgAdmin Development Team','pgAdmin III 1.6','1.6',NULL,NULL,'N/A',0,1),(691,2,'Microsoft','Microsoft .NET Framework 1.1','1.1.4322',NULL,NULL,'N/A',0,1),(692,2,'CvsGui','WinCvs 1.3','N/A','N/A','N/A','N/A',0,1),(693,2,'Microsoft Corporation','Windows Resource Kit Tools - SubInAcl.exe','5.2.3790.1164',NULL,NULL,'N/A',0,1),(694,2,'ActiveState','ActivePerl 5.8.4 Build 810','5.8.810','C:/Perl/',NULL,'N/A',0,1),(695,2,'BVRP Software','mobile PhoneTools','3.11h 08/27/2004','C:/Program Files/mobile PhoneTools','N/A','N/A',0,1),(696,2,'WebEx Communication Inc.','Meeting Manager for Internet Explorer','1.00.0000',NULL,'Meeting Manager for Internet Explorer','N/A',0,1),(697,2,'N/A','Avance AC\'\'97 Audio','N/A','N/A','N/A','N/A',0,1),(698,2,'VMware, Inc.','VMware Server','1.0.1.29996',NULL,NULL,'N/A',0,1),(699,2,'Microsoft Corporation','Microsoft Windows 2000 Server','5.0.2195','N/A','Service Pack 4','N/A',0,1),(700,3,NULL,'yast2-bootfloppy','2.10.17-2',NULL,'YaST2 - Boot Floppy Creation',NULL,NULL,NULL),(701,3,NULL,'aaa_skel','2004.6.6-2',NULL,'Skeleton for default users',NULL,NULL,NULL),(702,3,NULL,'glibc','2.3.3-118',NULL,'Standard Shared Libraries (from the GNU C Library)',NULL,NULL,NULL),(703,3,NULL,'gdbm','1.8.3-229',NULL,'GNU database routines',NULL,NULL,NULL),(704,3,NULL,'gpart','0.1h-477',NULL,'Tool that can Guess a Lost Partition Table',NULL,NULL,NULL),(705,3,NULL,'libgcc','3.3.4-11',NULL,'C compiler runtime library',NULL,NULL,NULL),(706,3,NULL,'eject','2.0.13-187',NULL,'A program to eject media under software control',NULL,NULL,NULL),(707,3,NULL,'libstdc++','3.3.4-11',NULL,'The standard C++ shared library',NULL,NULL,NULL),(708,3,NULL,'db','4.2.52-90',NULL,'Berkeley DB Database Library',NULL,NULL,NULL),(709,3,NULL,'cracklib','2.7-1008',NULL,'A Password-Checking Library',NULL,NULL,NULL),(710,3,NULL,'iputils','ss021109-150',NULL,'IPv4and IPv6 networking utilities',NULL,NULL,NULL),(711,3,NULL,'cpp','3.3.4-11',NULL,'The GCC Preprocessor',NULL,NULL,NULL),(712,3,NULL,'less','382-40',NULL,'Text File Browser and Pager Similar to More',NULL,NULL,NULL),(713,3,NULL,'pam','0.77-227',NULL,'A security tool that provides authentication for applications',NULL,NULL,NULL),(714,3,NULL,'diffutils','2.8.7-3',NULL,'GNU diff utilities',NULL,NULL,NULL),(715,3,NULL,'grep','2.5.1-431',NULL,'GNU Grep',NULL,NULL,NULL),(716,3,NULL,'sed','4.1.2-3',NULL,'A stream-oriented non-interactive text editor',NULL,NULL,NULL),(717,3,NULL,'xfsprogs','2.6.13-2',NULL,'Utilities for managing the XFS file system',NULL,NULL,NULL),(718,3,NULL,'logrotate','3.7-34',NULL,'A program to rotate, compress, remove, and mail system log files',NULL,NULL,NULL),(719,3,NULL,'reiserfs','3.6.18-2',NULL,'Reiser File System utilities',NULL,NULL,NULL),(720,3,NULL,'gpm','1.20.1-303',NULL,'Console Mouse Support',NULL,NULL,NULL),(721,3,NULL,'pcsc-lite','1.1.1-248',NULL,'The MUSCLE project SmartCards library',NULL,NULL,NULL),(722,3,NULL,'pmtools','20010730-175',NULL,'ACPI Debugging Tools',NULL,NULL,NULL),(723,3,NULL,'perl-gettext','1.01-578',NULL,'gettext for perl',NULL,NULL,NULL),(724,3,NULL,'procinfo','18-38',NULL,'display system status gathered from /proc',NULL,NULL,NULL),(725,3,NULL,'kbd','1.12-31',NULL,'Keyboard and font utilities',NULL,NULL,NULL),(726,3,NULL,'psmisc','21.5-2',NULL,'Utilities for managing processes on your system',NULL,NULL,NULL),(727,3,NULL,'netcfg','9.2-1',NULL,'Network configuration files in /etc',NULL,NULL,NULL),(728,3,NULL,'w3m','0.5.1-3',NULL,'A text-based WWW browser',NULL,NULL,NULL),(729,3,NULL,'perl-X500-DN','0.28-119',NULL,'provides an interface for RFC 2253 style DN strings',NULL,NULL,NULL),(730,3,NULL,'mkinitrd','1.1-7',NULL,'Creates an initial ramdisk image for preloading modules',NULL,NULL,NULL),(731,3,NULL,'cyrus-sasl-saslauthd','2.1.19-5',NULL,'The SASL Authentication Server',NULL,NULL,NULL),(732,3,NULL,'finger','1.2-41',NULL,'Show user information (client)',NULL,NULL,NULL),(733,3,NULL,'portmap','5beta-731',NULL,'A program that manages RPC connections',NULL,NULL,NULL),(734,3,NULL,'suse-build-key','1.0-663',NULL,'The public gpg key for rpm package signature verification',NULL,NULL,NULL),(735,3,NULL,'yast2-packagemanager','2.10.18-2',NULL,'YaST2 - Package Manager',NULL,NULL,NULL),(736,3,NULL,'yast2-slp','2.10.0-2',NULL,'SLP Agent and Browser for  YaST',NULL,NULL,NULL),(737,3,NULL,'yast2-pam','2.10.3-2',NULL,'YaST2 - PAM Agent',NULL,NULL,NULL),(738,3,NULL,'yast2-mouse','2.10.5-2',NULL,'YaST2 - Mouse Configuration',NULL,NULL,NULL),(739,3,NULL,'yast2-firewall','2.10.13-2',NULL,'YaST2 - Firewall Configuration',NULL,NULL,NULL),(740,3,NULL,'yast2-scanner','2.10.5-2',NULL,'YaST2 - Scanner Configuration',NULL,NULL,NULL),(741,3,NULL,'yast2-profile-manager','2.10.5-2',NULL,'YaST2 - Profiles Configuration',NULL,NULL,NULL),(742,3,NULL,'yast2-nfs-client','2.10.5-2',NULL,'YaST2 - NFS Configuration',NULL,NULL,NULL),(743,3,NULL,'yast2-users','2.10.11-2',NULL,'YaST2 - User and Group Configuration',NULL,NULL,NULL),(744,3,NULL,'yast2-restore','2.10.1-2',NULL,'YaST2 - System Restore',NULL,NULL,NULL),(745,3,NULL,'yast2-powertweak','2.10.5-2',NULL,'YaST2 - Powertweak Configuration',NULL,NULL,NULL),(746,3,NULL,'yast2-backup','2.10.3-2',NULL,'YaST2 - System Backup',NULL,NULL,NULL),(747,3,NULL,'yast2-ntp-client','2.10.8-2',NULL,'YaST2 - NTP Client Configuration',NULL,NULL,NULL),(748,3,NULL,'hdparm','5.7-2.2',NULL,'A program to get and set hard disk parameters',NULL,NULL,NULL),(749,3,NULL,'yast2-storage','2.10.23-0.1',NULL,'YaST2 - Storage Configuration',NULL,NULL,NULL),(750,3,NULL,'yast2-tv','2.10.8-0.1',NULL,'YaST2 - TV Configuration',NULL,NULL,NULL),(751,3,NULL,'PgTcl','1.4-316',NULL,'Tcl Client Library for PostgreSQL',NULL,NULL,NULL),(752,3,NULL,'libpgeasy','3.0.4-2',NULL,'Simplified C Client Interface for PostgreSQL',NULL,NULL,NULL),(753,3,NULL,'perl-DBD-Pg','1.22-198',NULL,'DBD::Pg - DBI driver for PostgreSQL',NULL,NULL,NULL),(754,3,NULL,'libgda-postgres','1.0.3-58',NULL,'PostgreSQL provider for GNU Data Access (GDA)',NULL,NULL,NULL),(755,3,NULL,'emacs-x11','21.3-193',NULL,'GNU Emacs: Emacs binary with X Window System Support',NULL,NULL,NULL),(756,3,NULL,'atk','1.6.0-4',NULL,'An Accessibility ToolKit',NULL,NULL,NULL),(757,3,NULL,'ghostscript-fonts-std','7.07.1rc1-207',NULL,'Standard Fonts for Ghostscript',NULL,NULL,NULL),(758,3,NULL,'gtk','1.2.10-882',NULL,'A library for the creation of graphical user interfaces',NULL,NULL,NULL),(759,3,NULL,'iptraf','2.7.0-186',NULL,'TCP/IP Network Monitor',NULL,NULL,NULL),(760,3,NULL,'libpcap','0.8.3-3',NULL,'A library for network sniffers',NULL,NULL,NULL),(761,3,NULL,'marsnwe','0.99.pl20-583',NULL,'Novell Server Emulation',NULL,NULL,NULL),(762,3,NULL,'perl-Digest-HMAC','1.01-494',NULL,'Keyed Hashing for Message Authentication',NULL,NULL,NULL),(763,3,NULL,'perl-XML-Parser','2.34-30',NULL,'XML Parser (Perl Module)',NULL,NULL,NULL),(764,3,NULL,'quota','3.11-26',NULL,'Disk Quota System',NULL,NULL,NULL),(765,3,NULL,'sax2-ident','1.2-36',NULL,'SaX2 identity and profile information',NULL,NULL,NULL),(766,3,NULL,'termcap','2.0.8-878',NULL,'The Termcap Library',NULL,NULL,NULL),(767,3,NULL,'xdmbgrd','0.5-30',NULL,'SuSE Linux background',NULL,NULL,NULL),(768,3,NULL,'xtermset','0.5.2-120',NULL,'A program to change the settings of an xterm',NULL,NULL,NULL),(769,3,NULL,'fonts-config','20041001-2',NULL,'Configures Installed X Window System Fonts',NULL,NULL,NULL),(770,3,NULL,'perl-HTML-Parser','3.36-2',NULL,'Perl HTML Interface',NULL,NULL,NULL),(771,3,NULL,'kdebase3-ksysguardd','3.3.0-29',NULL,'KDE base package: ksysguard daemon',NULL,NULL,NULL),(772,3,NULL,'pptpd','1.1.2-587',NULL,'PoPToP - PPTP Daemon, Linux as Microsoft VPN Server',NULL,NULL,NULL),(773,3,NULL,'sax2','4.8-142',NULL,'SuSE advanced X Window System-configuration',NULL,NULL,NULL),(774,3,NULL,'WindowMaker','0.80.2.20030506-200',NULL,'A colorful and flexible window manager',NULL,NULL,NULL),(775,3,NULL,'xbanner','1.31-858',NULL,'X Window System background writings and images',NULL,NULL,NULL),(776,3,NULL,'WindowMaker-themes','0.1-239',NULL,'Themes for WindowMaker',NULL,NULL,NULL),(777,3,NULL,'libgimpprint','4.2.7-7',NULL,'Gimp-Print libraries',NULL,NULL,NULL),(778,3,NULL,'ghostscript-x11','7.07.1rc1-207',NULL,'Ghostscript for the X Window System',NULL,NULL,NULL),(779,3,NULL,'howtoenh','2004.10.4-1',NULL,'A collection of HOWTOs from the Linux Documentation Project.  Formatted in HTML',NULL,NULL,NULL),(780,3,NULL,'libksba','0.9.8-3',NULL,'A X.509 Library',NULL,NULL,NULL),(781,3,NULL,'findutils-locate','4.1.20-2',NULL,'Tool for Locating Files (GNU Findutils Subpackage)',NULL,NULL,NULL),(782,3,NULL,'libnetpbm','1.0.0-623',NULL,'Libraries for the NetPBM (NetPortableBitmap) Graphic Formats',NULL,NULL,NULL),(783,3,NULL,'libjasper','1.701.0-2',NULL,'JPEG-2000 library',NULL,NULL,NULL),(784,3,NULL,'html2ps','1.0b3-970',NULL,'HTML to PostScript Converter',NULL,NULL,NULL),(785,3,NULL,'tftp','0.38-2.2',NULL,'Trivial File Transfer Protocol (TFTP)',NULL,NULL,NULL),(786,3,NULL,'tcpd','7.6-713.2',NULL,'A security wrapper for TCP daemons',NULL,NULL,NULL),(787,3,NULL,'release-notes','9.2-21.6',NULL,'A Short Description of the Most Important Changes for this SUSE Linux Release',NULL,NULL,NULL),(788,3,NULL,'iproute2','2.4.7-870.4',NULL,'Advanced routing',NULL,NULL,NULL),(789,3,NULL,'sysconfig','0.31.3-17.4',NULL,'The sysconfig scheme',NULL,NULL,NULL),(790,3,NULL,'blt','2.4z-204',NULL,'Tcl/Tk Extension',NULL,NULL,NULL),(791,3,NULL,'slang','1.4.9-123',NULL,'A Library for Display Control',NULL,NULL,NULL),(792,3,NULL,'python-doc','2.3.4-3',NULL,'Additional Package Documentation.',NULL,NULL,NULL),(793,3,NULL,'python-ldap','2.0.2-2',NULL,'Python LDAP interface',NULL,NULL,NULL),(794,3,NULL,'python-doc-pdf','2.3.4-3',NULL,'Python PDF Documentation',NULL,NULL,NULL),(795,3,NULL,'gammu','0.97.7-2',NULL,'Mobile phones tools',NULL,NULL,NULL),(796,3,NULL,'wxGTK','2.5.2.8-3',NULL,'C++ Framework for Cross-Platform Development',NULL,NULL,NULL),(797,3,NULL,'wxGTK-compat','2.5.2.8-3',NULL,'wxWidgets Compatibility Package',NULL,NULL,NULL),(798,3,NULL,'python-wxGTK','2.5.2.8-3',NULL,'Cross Platform GUI Toolkit for Python Using wxGTK',NULL,NULL,NULL),(799,3,NULL,'graphviz-graphs','1.12-3',NULL,'Demo graphs for graphviz',NULL,NULL,NULL),(800,3,NULL,'bzip2','1.0.2-347.3',NULL,'A program for compressing files',NULL,NULL,NULL),(801,3,NULL,'sharutils','4.2c-721.2',NULL,'GNU shar utilities',NULL,NULL,NULL),(802,3,NULL,'permissions','2005.10.20-0.1',NULL,'SUSE Linux Default Permissions',NULL,NULL,NULL),(803,3,NULL,'libgda','1.0.3-58.2',NULL,'GNU Data Access (GDA) Library',NULL,NULL,NULL),(804,3,NULL,'fam','2.6.10-122.2',NULL,'File Alteration Monitoring Daemon',NULL,NULL,NULL),(805,3,NULL,'curl','7.12.0-2.6',NULL,'A tool for transfering data from URLs',NULL,NULL,NULL),(806,3,NULL,'liblcms-devel','1.12-57',NULL,'Include Files and Libraries Mandatory for Development',NULL,NULL,NULL),(807,3,NULL,'freetype','1.3.1-1157',NULL,'TrueType Font Engine',NULL,NULL,NULL),(808,3,NULL,'te_web','2.0.2-198',NULL,'The WEB tools for programming in WEB',NULL,NULL,NULL),(809,3,NULL,'te_etex','2.0.2-198',NULL,'The Extended TeX/LaTeX from the NTS Project',NULL,NULL,NULL),(810,3,NULL,'weblint','1.9.3-474',NULL,'A syntax and minimal style checker for HTML',NULL,NULL,NULL),(811,3,NULL,'perl-GDTextUtil','0.85-126',NULL,'text utilities for use with the GD drawing package',NULL,NULL,NULL),(812,3,NULL,'fltk','1.1.4-82',NULL,'Free C++ GUI toolkit for the X Window System, OpenGL, and WIN32 (Windows 95,98,NT)',NULL,NULL,NULL),(813,3,NULL,'xntp-doc','4.2.0a-27',NULL,'Additional Package Documentation.',NULL,NULL,NULL),(814,3,NULL,'htdig','3.2.0b6-6',NULL,'WWW index and search system',NULL,NULL,NULL),(815,3,NULL,'wv','1.0.3-3',NULL,'Word 8 Converter for Unix',NULL,NULL,NULL),(816,3,NULL,'xpdf','3.00-87',NULL,'A PDF File Viewer for the X Window System',NULL,NULL,NULL),(817,3,NULL,'pdftohtml','0.36-129',NULL,'PDF to HTML Converter',NULL,NULL,NULL),(818,3,NULL,'xntp','4.2.0a-27.2',NULL,'Network Time Protocol daemon (version 4)',NULL,NULL,NULL),(819,3,NULL,'cups-libs','1.1.21-5.8',NULL,'libraries for CUPS',NULL,NULL,NULL),(820,3,NULL,'gd-devel','2.0.28-2.5',NULL,'Drawing Library for Programs with PNG and JPEG Output',NULL,NULL,NULL),(821,3,NULL,'freeradius','1.0.0-5.8',NULL,'Very highly Configurable Radius-Server',NULL,NULL,NULL),(822,3,NULL,'java-1_4_2-sun-plugin','1.4.2.11-1.1',NULL,'Browser plugin files for java-1.4.2-sun',NULL,NULL,NULL),(823,3,NULL,'cron','4.1-14.2',NULL,'cron daemon',NULL,NULL,NULL),(824,3,NULL,'postgresql-devel','7.4.13-0.2',NULL,'PostgreSQL development header files and libraries',NULL,NULL,NULL),(825,3,NULL,'postgresql-server','7.4.13-0.2',NULL,'The Programs Needed to Create and Run a PostgreSQL Server',NULL,NULL,NULL),(826,3,NULL,'samba','3.0.9-2.5',NULL,'A SMB/ CIFS File Server',NULL,NULL,NULL),(827,3,NULL,'libtiff','3.6.1-47.12',NULL,'The Tiff Library (with JPEG and compression support)',NULL,NULL,NULL),(828,3,NULL,'libwmf','0.2.8.2-91.2',NULL,'library and utilities for displaying and converting metafile images',NULL,NULL,NULL),(829,3,NULL,'ethereal','0.10.13-2.12',NULL,'A Network Traffic Analyser',NULL,NULL,NULL),(830,3,NULL,'ImageMagick','6.0.7-4.10',NULL,'Viewer and converter for images',NULL,NULL,NULL),(831,3,NULL,'apache2-prefork','2.0.50-7.17',NULL,'Apache 2 \"prefork\" MPM (Multi-Processing Module)',NULL,NULL,NULL),(832,3,NULL,'xorg-x11-server','6.8.1-15.12',NULL,'X Window System modularized server',NULL,NULL,NULL),(833,3,NULL,'apache2-mod_php4','4.3.8-8.33',NULL,'PHP4 Module for Apache 2.0',NULL,NULL,NULL),(834,3,NULL,'openssh','3.9p1-3.10',NULL,'Secure shell client and server (remote login program)',NULL,NULL,NULL),(835,3,NULL,'python','2.3.4-3.4',NULL,'Python Interpreter',NULL,NULL,NULL),(836,3,NULL,'nagios-plugins-extras','1.3.1-271.1',NULL,'Nagios Plug-Ins which Depend on Additional Packages',NULL,NULL,NULL),(837,3,NULL,'latex-ucs','20040703-2',NULL,'Unicode support for LaTeX',NULL,NULL,NULL),(838,3,NULL,'filesystem','9.2-2',NULL,'Basic Directory Layout',NULL,NULL,NULL),(839,3,NULL,'providers','2004.9.23-2',NULL,'A list of internet service providers',NULL,NULL,NULL),(840,3,NULL,'yast2-trans-en_US','2.10.4-2',NULL,'YaST2 - American English Translations',NULL,NULL,NULL),(841,3,NULL,'utempter','0.5.5-2',NULL,'A privileged helper for utmp and wtmp updates',NULL,NULL,NULL),(842,3,NULL,'boehm-gc','3.3.4-11',NULL,'Boehm Garbage Collector Library',NULL,NULL,NULL),(843,3,NULL,'ethtool','2-2',NULL,'Examine and Tune Ethernet-Based Network Interfaces',NULL,NULL,NULL),(844,3,NULL,'glibc-locale','2.3.3-118',NULL,'Locale Data for Localized Programs',NULL,NULL,NULL),(845,3,NULL,'libxcrypt','2.2-2',NULL,'Crypt library for DES, MD5, and blowfish',NULL,NULL,NULL),(846,3,NULL,'dialog','0.9b-191',NULL,'Menus and Input Boxes for Shell Scripts',NULL,NULL,NULL),(847,3,NULL,'timezone','2.3.3-118',NULL,'Timezone descriptions',NULL,NULL,NULL),(848,3,NULL,'pciutils','2.1.11-197',NULL,'PCI-utilities for Kernel version 2.2 and newer',NULL,NULL,NULL),(849,3,NULL,'libacl','2.2.25-2',NULL,'A dynamic library for accessing POSIX Access Control Lists',NULL,NULL,NULL),(850,3,NULL,'info','4.7-6',NULL,'A Stand-Alone Terminal-Based Info Browser',NULL,NULL,NULL),(851,3,NULL,'fillup','1.42-100',NULL,'Tool for merging config files',NULL,NULL,NULL),(852,3,NULL,'make','3.80-186',NULL,'The GNU make Command',NULL,NULL,NULL),(853,3,NULL,'mdadm','1.6.0-2',NULL,'Utility for configuring MD setup',NULL,NULL,NULL),(854,3,NULL,'parted','1.6.15-4',NULL,'GNU partitioner',NULL,NULL,NULL),(855,3,NULL,'devs','9.2-1',NULL,'Device files',NULL,NULL,NULL),(856,3,NULL,'ksymoops','2.4.9-138',NULL,'Kernel oops and error message decoder',NULL,NULL,NULL),(857,3,NULL,'convmv','1.08-2',NULL,'Converts File Names from one Encoding to Another',NULL,NULL,NULL),(858,3,NULL,'sitar','0.8.12-2',NULL,'System InformaTion at Runtime',NULL,NULL,NULL),(859,3,NULL,'groff','1.18.1.1-5',NULL,'GNU troff document formatting system',NULL,NULL,NULL),(860,3,NULL,'lilo','22.3.4-516',NULL,'The LInux LOader, a boot menu',NULL,NULL,NULL),(861,3,NULL,'pam-modules','9.2-2',NULL,'Additional PAM Modules',NULL,NULL,NULL),(862,3,NULL,'siga','9.203-2',NULL,'System Information GAthering',NULL,NULL,NULL),(863,3,NULL,'usbutils','0.12-3',NULL,'Tools and libraries for USB devices',NULL,NULL,NULL),(864,3,NULL,'openct','0.5.0-3',NULL,'OpenCT Library for Smart Card Readers',NULL,NULL,NULL),(865,3,NULL,'opensc','0.8.1-3',NULL,'OpenSC smart card library',NULL,NULL,NULL),(866,3,NULL,'rpm','4.1.1-191',NULL,'The RPM Package Manager',NULL,NULL,NULL),(867,3,NULL,'yast2-perl-bindings','2.10.3-2',NULL,'YaST2 - Perl Bindings',NULL,NULL,NULL),(868,3,NULL,'yast2','2.10.27-2',NULL,'YaST2 - Main Package',NULL,NULL,NULL),(869,3,NULL,'yast2-power-management','2.10.9-2',NULL,'YaST2 - Power Management Configuration',NULL,NULL,NULL),(870,3,NULL,'yast2-ldap','2.10.4-2',NULL,'YaST2 - LDAP Agent',NULL,NULL,NULL),(871,3,NULL,'yast2-bluetooth','2.10.8-2',NULL,'YaST2 - Bluetooth Configuration',NULL,NULL,NULL),(872,3,NULL,'yast2-runlevel','2.10.1-2',NULL,'YaST2 - Runlevel Editor',NULL,NULL,NULL),(873,3,NULL,'yast2-update','2.10.18-2',NULL,'YaST2 - Update',NULL,NULL,NULL),(874,3,NULL,'yast2-ldap-client','2.10.7-2',NULL,'YaST2 - LDAP Client Configuration',NULL,NULL,NULL),(875,3,NULL,'autoyast2','2.10.13-2',NULL,'YaST2 - DTD for AutoYaST Profile',NULL,NULL,NULL),(876,3,NULL,'yast2-packager','2.10.24-2',NULL,'YaST2 - Package Library',NULL,NULL,NULL),(877,3,NULL,'yast2-nfs-server','2.10.5-2',NULL,'YaST2 - NFS Server Configuration',NULL,NULL,NULL),(878,3,NULL,'yast2-nis-client','2.10.8-2',NULL,'YaST2 - Network Information Services (NIS, YP) Configuration',NULL,NULL,NULL),(879,3,NULL,'yast2-mail','2.10.8-2',NULL,'YaST2 - Mail Configuration',NULL,NULL,NULL),(880,3,NULL,'cyrus-sasl','2.1.19-7.2',NULL,'Implementation of Cyrus SASL API',NULL,NULL,NULL),(881,3,NULL,'iptables','1.2.11-4.2',NULL,'IP Packet Filter Administration',NULL,NULL,NULL),(882,3,NULL,'hwinfo','9.31-1.1',NULL,'Hardware library',NULL,NULL,NULL),(883,3,NULL,'aaa_base','9.2-5.4',NULL,'SuSE Linux base package',NULL,NULL,NULL),(884,3,NULL,'ctags','2004.5.4-2',NULL,'A Program to Generate Tag files for use with Vi and other Editors',NULL,NULL,NULL),(885,3,NULL,'glib2','2.4.6-5',NULL,'A Library with Convenient Functions Written in C',NULL,NULL,NULL),(886,3,NULL,'tcl','8.4.7-3',NULL,'The Tcl scripting language',NULL,NULL,NULL),(887,3,NULL,'PyGreSQL','3.4-34',NULL,'Python Client Library for PostgreSQL',NULL,NULL,NULL),(888,3,NULL,'libpq++','4.0-302',NULL,'C++ Client Library for PostgreSQL',NULL,NULL,NULL),(889,3,NULL,'pgperl','2.1.1-2',NULL,'Perl Client Library for PostgreSQL',NULL,NULL,NULL),(890,3,NULL,'libpqxx-devel','2.2.7-2',NULL,'C++ Client Library for PostgreSQL',NULL,NULL,NULL),(891,3,NULL,'bing','1.0.4-864',NULL,'A Point-to-Point Bandwidth Measurement tool',NULL,NULL,NULL),(892,3,NULL,'db-utils','4.2.52-90',NULL,'Command Line tools for Managing Berkeley DB Databases',NULL,NULL,NULL),(893,3,NULL,'fping','2.4b2-2',NULL,'A Program to Ping Multiple Hosts',NULL,NULL,NULL),(894,3,NULL,'gkermit','1.0-704',NULL,'A Mini-Kermit Program that is Distributed under the GPL',NULL,NULL,NULL),(895,3,NULL,'libstroke','0.4-737',NULL,'a stroke translation library',NULL,NULL,NULL),(896,3,NULL,'mirror','2.9-752',NULL,'Perl Scripts for Mirroring FTP Servers',NULL,NULL,NULL),(897,3,NULL,'netacct','0.71-498',NULL,'Network Accounting',NULL,NULL,NULL),(898,3,NULL,'pango','1.4.1-3',NULL,'System for Layout and Rendering of Internationalised Text',NULL,NULL,NULL),(899,3,NULL,'perl-HTML-Tagset','3.03-552',NULL,'Data Tables Useful for Dealing with HTML',NULL,NULL,NULL),(900,3,NULL,'privoxy','3.0.3-24',NULL,'The Internet Junkbuster - HTTP Proxy Server',NULL,NULL,NULL),(901,3,NULL,'radiusclient','0.3.2-142',NULL,'Radius Client Software',NULL,NULL,NULL),(902,3,NULL,'rzsz','0.12.20-838',NULL,'X-, Y-, and Z-Modem Data Transfer Protocols',NULL,NULL,NULL),(903,3,NULL,'rinetd','0.61-806',NULL,'TCP Redirection Server',NULL,NULL,NULL),(904,3,NULL,'tk','8.4.7-3',NULL,'TK Toolkit for TCL',NULL,NULL,NULL),(905,3,NULL,'whoson','2.03-2',NULL,'Protocol for Keeping Track of Dynamically Allocated IP Addresses',NULL,NULL,NULL),(906,3,NULL,'ypserv','2.14-2',NULL,'YP - (NIS)-Server',NULL,NULL,NULL),(907,3,NULL,'ifnteuro','1.2.1-192',NULL,'European fonts for the X Window System',NULL,NULL,NULL),(908,3,NULL,'ckermit','8.0.211-2',NULL,'A combined Serial and Network Communication Software Package',NULL,NULL,NULL),(909,3,NULL,'gup','0.3-853',NULL,'Group Update Program for INN and C-News',NULL,NULL,NULL),(910,3,NULL,'libmng','1.0.8-3',NULL,'Library for Support of MNG and JNG Formats',NULL,NULL,NULL),(911,3,NULL,'netatalk','1.6.4-54',NULL,'AppleTalk for Linux',NULL,NULL,NULL),(912,3,NULL,'perl-Net-SNMP','5.0.0-2',NULL,'Net::SNMP Perl Module',NULL,NULL,NULL),(913,3,NULL,'sax2-tools','2.3-36',NULL,'X Window System tools for SaX2',NULL,NULL,NULL),(914,3,NULL,'tightvnc','1.2.9-181',NULL,'A virtual X-Window System server',NULL,NULL,NULL),(915,3,NULL,'desktop-data-SuSE','9.2-3',NULL,'SuSE Theme Files for KDE and GNOME',NULL,NULL,NULL),(916,3,NULL,'nagios-plugins','1.3.1-271',NULL,'The Nagios Plug-Ins',NULL,NULL,NULL),(917,3,NULL,'xdg-menu','0.2-48',NULL,'XDG Menus for WindowMaker and other Window Managers',NULL,NULL,NULL),(918,3,NULL,'fvwm2','2.5.10-2',NULL,'Improved Version of FVWM Window Manager',NULL,NULL,NULL),(919,3,NULL,'yast2-control-center','2.10.1-2',NULL,'YaST2 - Control Center',NULL,NULL,NULL),(920,3,NULL,'a2ps','4.13-1051',NULL,'Converts ASCII Text into PostScript',NULL,NULL,NULL),(921,3,NULL,'foomatic-filters','3.0.1-44',NULL,'Filter Scripts Used by Printer Spoolers',NULL,NULL,NULL),(922,3,NULL,'pinentry','0.7.1-2',NULL,'Collection of Simple PIN or Passphrase Entry Dialogs',NULL,NULL,NULL),(923,3,NULL,'pgp','2.6.3in001006-393',NULL,'PGP encryption software',NULL,NULL,NULL),(924,3,NULL,'nmap','3.70-2',NULL,'Portscanner',NULL,NULL,NULL),(925,3,NULL,'cvs-doc','1.12.9-2',NULL,'Open Source Development with CVS, 2nd Edition Book',NULL,NULL,NULL),(926,3,NULL,'html2txt','1.3.2a-44',NULL,'HTML to ASCII Converter',NULL,NULL,NULL),(927,3,NULL,'dos2unix','3.1-302',NULL,'A DOS to UNIX Text Converter',NULL,NULL,NULL),(928,3,NULL,'courier-imap','3.0.7-3.2',NULL,'An IMAP and POP3 Server for Maildir MTAs',NULL,NULL,NULL),(929,3,NULL,'perl-DBI','1.43-2.2',NULL,'The Perl Database Interface',NULL,NULL,NULL),(930,3,NULL,'emacs','21.3-193.4',NULL,'GNU Emacs Base Package',NULL,NULL,NULL),(931,3,NULL,'rsync','2.6.3pre1-2.4',NULL,'Replacement for RCP/mirror that has Many More Features',NULL,NULL,NULL),(932,3,NULL,'apache2-mod_fastcgi','2.4.2-2',NULL,'A FastCGI Module for Apache 2',NULL,NULL,NULL),(933,3,NULL,'apache2-example-pages','2.0.50-7.2',NULL,'Example Pages for the Apache 2 Web Server',NULL,NULL,NULL),(934,3,NULL,'openslp-server','1.1.5-80.4',NULL,'The OpenSLP Implementation of the  Service Location Protocol V2',NULL,NULL,NULL),(935,3,NULL,'xorg-x11-libs','6.8.1-15.7',NULL,'X Window System shared libraries',NULL,NULL,NULL),(936,3,NULL,'gnome-filesystem','0.1-189.2',NULL,'GNOME Directory Layout',NULL,NULL,NULL),(937,3,NULL,'python-xml','2.3.4-3',NULL,'A Python XML Interface',NULL,NULL,NULL),(938,3,NULL,'gcc-c++','3.3.4-11',NULL,'The GNU C++ Compiler',NULL,NULL,NULL),(939,3,NULL,'pine','4.61-8',NULL,'The Pine e-mail program',NULL,NULL,NULL),(940,3,NULL,'libogg','1.1-59',NULL,'Ogg Bitstream Library',NULL,NULL,NULL),(941,3,NULL,'pyweblib','1.3.3-2',NULL,'PyWebLib - web programming framework for Python',NULL,NULL,NULL),(942,3,NULL,'python-demo','2.3.4-3',NULL,'Python Demonstration Scripts',NULL,NULL,NULL),(943,3,NULL,'python-openssl','0.6-2',NULL,'Python wrapper module around the OpenSSL library',NULL,NULL,NULL),(944,3,NULL,'python-curses','2.3.4-3',NULL,'Python Interface to the (N)Curses Library',NULL,NULL,NULL),(945,3,NULL,'aalib','1.4.0-281',NULL,'An ascii art library',NULL,NULL,NULL),(946,3,NULL,'smpeg','0.4.5-227',NULL,'SDL MPEG Player Library',NULL,NULL,NULL),(947,3,NULL,'SDL_mixer','1.2.5-208',NULL,'Sample Mixer Library for SDL',NULL,NULL,NULL),(948,3,NULL,'python-pygame-doc','1.6.2-2',NULL,'pygame documentation and example programs',NULL,NULL,NULL),(949,3,NULL,'graphviz-tcl','1.12-3',NULL,'Tcl extension tools for graphviz',NULL,NULL,NULL),(950,3,NULL,'esound','0.2.35-4.2',NULL,'A sound daemon for Enlightenment and GNOME',NULL,NULL,NULL),(951,3,NULL,'SuSEfirewall2','3.2-14.4',NULL,'Stateful packetfilter using iptables and netfilter',NULL,NULL,NULL),(952,3,NULL,'pcre','4.5-2.2',NULL,'A library for Perl-compatible regular expressions',NULL,NULL,NULL),(953,3,NULL,'uudeview','0.5.20-26',NULL,'The Nice and Friendly Decoder',NULL,NULL,NULL),(954,3,NULL,'util-linux','2.12c-4.2',NULL,'A collection of basic system utilities',NULL,NULL,NULL),(955,3,NULL,'net-snmp','5.1.2-3.2',NULL,'SNMP Daemon',NULL,NULL,NULL),(956,3,NULL,'squid','2.5.STABLE6-6.17',NULL,'Squid WWW proxy server',NULL,NULL,NULL),(957,3,NULL,'netpbm','10.18.15-4.6',NULL,'A Powerful Graphics Conversion Package',NULL,NULL,NULL),(958,3,NULL,'t1lib','1.3.1-569',NULL,'Adobe Type 1 Font Rasterizing Library',NULL,NULL,NULL),(959,3,NULL,'te_kpath','2.0.2-198',NULL,'The headers and library of the kpathsea tools',NULL,NULL,NULL),(960,3,NULL,'TeX-Guy','1.2.4-409',NULL,'DVI interpreter library, DVI utilities (for displaying and printing)',NULL,NULL,NULL),(961,3,NULL,'pdflib','4.0.3-9',NULL,'Portable C library for dynamically generating PDF files',NULL,NULL,NULL),(962,3,NULL,'php4-ctype','4.3.8-8',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(963,3,NULL,'stunnel','4.05-23',NULL,'Universal SSL Tunnel',NULL,NULL,NULL),(964,3,NULL,'pkgconfig','0.15.0-201',NULL,'A library management system',NULL,NULL,NULL),(965,3,NULL,'xlhtml-cole','0.5-111',NULL,'free C OLE library',NULL,NULL,NULL),(966,3,NULL,'tetex','2.0.2-198.7',NULL,'The base system of teTeX',NULL,NULL,NULL),(967,3,NULL,'procmail','3.22-40.4',NULL,'A program for local e-mail delivery',NULL,NULL,NULL),(968,3,NULL,'resmgr','0.9.8-53.6',NULL,'A program to allow arbitrary access to device files',NULL,NULL,NULL),(969,3,NULL,'java-1_4_2-sun','1.4.2.11-1.1',NULL,'Java(TM) 2 Runtime Environment',NULL,NULL,NULL),(970,3,NULL,'java-1_4_2-sun-src','1.4.2.11-1.1',NULL,'Source files for java-1.4.2-sun',NULL,NULL,NULL),(971,3,NULL,'whois','4.6.20u-2.2',NULL,'whois Client Program',NULL,NULL,NULL),(972,3,NULL,'postgresql-docs','7.4.13-0.2',NULL,'HTML Documentation for PostgreSQL',NULL,NULL,NULL),(973,3,NULL,'awstats','6.6-0.1',NULL,'Advanced Web Statistics',NULL,NULL,NULL),(974,3,NULL,'samba-client','3.0.9-2.5',NULL,'Samba Client Utilities',NULL,NULL,NULL),(975,3,NULL,'libtiff-devel','3.6.1-47.12',NULL,'Development Tools for Programs which will use the libtiff Library',NULL,NULL,NULL),(976,3,NULL,'gpg','1.2.5-3.10',NULL,'The GNU Privacy Guard. Encrypts, decrypts, and signs data',NULL,NULL,NULL),(977,3,NULL,'heimdal','0.6.2-8.8',NULL,'Free Kerberos5 implementation - server',NULL,NULL,NULL),(978,3,NULL,'ImageMagick-devel','6.0.7-4.10',NULL,'Include Files and Libraries Mandatory for Development.',NULL,NULL,NULL),(979,3,NULL,'kernel-default','2.6.8-24.25',NULL,'The standard kernel',NULL,NULL,NULL),(980,3,NULL,'gzip','1.3.5-139.2',NULL,'GNU Zip Compression Utilities',NULL,NULL,NULL),(981,3,NULL,'php4','4.3.8-8.33',NULL,'PHP4 Core Files',NULL,NULL,NULL),(982,3,NULL,'openssh-askpass','3.9p1-3.10',NULL,'A passphrase dialog for OpenSSH and the X Window System',NULL,NULL,NULL),(983,3,NULL,'python-devel','2.3.4-3.4',NULL,'Include Files and Libraries Mandatory for Building Python Modules.',NULL,NULL,NULL),(984,3,NULL,'te_latex','2.0.2-198.4',NULL,'All About LaTeX',NULL,NULL,NULL),(985,3,NULL,'gpg-pubkey','9c800aca-40d8063e',NULL,'gpg(SuSE Package Signing Key <build@suse.de>)',NULL,NULL,NULL),(986,3,NULL,'terminfo','5.4-65',NULL,'A terminal descriptions database',NULL,NULL,NULL),(987,3,NULL,'yast2-schema','2.10.1-2',NULL,'AutoYaST Schema',NULL,NULL,NULL),(988,3,NULL,'libnscd','1.0-2',NULL,'Library to Allow Applications to Communicate with nscd',NULL,NULL,NULL),(989,3,NULL,'ncurses','5.4-65',NULL,'New curses libraries',NULL,NULL,NULL),(990,3,NULL,'popt','1.7-190',NULL,'A C library for parsing command line parameters',NULL,NULL,NULL),(991,3,NULL,'libattr','2.4.16-2',NULL,'A dynamic library for filesystem extended attribute support',NULL,NULL,NULL),(992,3,NULL,'ash','1.6.1-1',NULL,'The Ash shell',NULL,NULL,NULL),(993,3,NULL,'attr','2.4.16-2',NULL,'A command to manipulate filesystem extended attributes',NULL,NULL,NULL),(994,3,NULL,'busybox','1.00.rc3-2',NULL,'The Swiss Army Knife of Embedded Linux',NULL,NULL,NULL),(995,3,NULL,'glib','1.2.10-589',NULL,'The utility functions for Gtk',NULL,NULL,NULL),(996,3,NULL,'libzio','0.1-4',NULL,'A library for accessing compressed text files',NULL,NULL,NULL),(997,3,NULL,'ntfsprogs','1.9.2-2',NULL,'NTFS Utilities',NULL,NULL,NULL),(998,3,NULL,'bc','1.06-748',NULL,'GNU command line calculator',NULL,NULL,NULL),(999,3,NULL,'gawk','3.1.4-4',NULL,'GNU awk',NULL,NULL,NULL),(1000,3,NULL,'findutils','4.1.20-2',NULL,'GNU find - Finding Files',NULL,NULL,NULL),(1001,3,NULL,'sysvinit','2.85-31',NULL,'SysV-Style init',NULL,NULL,NULL),(1002,3,NULL,'tcsh','6.12.00-453',NULL,'The C SHell',NULL,NULL,NULL),(1003,3,NULL,'jfsutils','1.1.7-2',NULL,'IBM JFS utility programs',NULL,NULL,NULL),(1004,3,NULL,'grub','0.95-10',NULL,'GRand Unified Bootloader',NULL,NULL,NULL),(1005,3,NULL,'vim','6.3-7',NULL,'Vi IMproved',NULL,NULL,NULL),(1006,3,NULL,'xdelta','1.1.3-3',NULL,'Binary delta generator and RCS replacement library',NULL,NULL,NULL),(1007,3,NULL,'alsa','1.0.6-8',NULL,'Advanced Linux Sound Architecture',NULL,NULL,NULL),(1008,3,NULL,'scsi','1.7_2.34_1.07_0.13-4',NULL,'SCSI Tools (Text Mode)',NULL,NULL,NULL),(1009,3,NULL,'isapnp','1.26-491',NULL,'An ISA plug and play configuration utility',NULL,NULL,NULL),(1010,3,NULL,'perl-Parse-RecDescent','1.80-246',NULL,'Perl RecDescent Module',NULL,NULL,NULL),(1011,3,NULL,'libxslt','1.1.9-2',NULL,'XSL Transformation Library',NULL,NULL,NULL),(1012,3,NULL,'fbset','2.1-780',NULL,'Frame Buffer Configuration Tool',NULL,NULL,NULL),(1013,3,NULL,'dmraid','0.99_1.0.0rc5CDH1-3',NULL,'dmraid, a Device-Mapper Software RAID support tool',NULL,NULL,NULL),(1014,3,NULL,'man','2.4.1-217',NULL,'A program for displaying man pages',NULL,NULL,NULL),(1015,3,NULL,'hotplug','0.45-21',NULL,'Automatic configuration of hotplugged devices',NULL,NULL,NULL),(1016,3,NULL,'yast2-core','2.10.16-2',NULL,'YaST2 - Core Libraries',NULL,NULL,NULL),(1017,3,NULL,'yast2-ncurses','2.10.5-3',NULL,'YaST2 - Character Based User Interface',NULL,NULL,NULL),(1018,3,NULL,'yast2-x11','2.10.8-2',NULL,'YaST2 - X Window System Configuration',NULL,NULL,NULL),(1019,3,NULL,'yast2-country','2.10.15-2',NULL,'YaST2 - Country Settings (Language, Keyboard, and Timezone)',NULL,NULL,NULL),(1020,3,NULL,'yast2-tune','2.10.1-2',NULL,'YaST2 - Hardware Tuning',NULL,NULL,NULL),(1021,3,NULL,'yast2-phone-services','2.10.0-2',NULL,'YaST2 - Phone Services Configuration',NULL,NULL,NULL),(1022,3,NULL,'yast2-bootloader','2.10.17-2',NULL,'YaST2 - Bootloader Configuration',NULL,NULL,NULL),(1023,3,NULL,'yast2-kerberos-client','2.10.5-2',NULL,'YaST2 - Kerberos Client Configuration',NULL,NULL,NULL),(1024,3,NULL,'yast2-tftp-server','2.10.6-2',NULL,'YaST2 - TFTP Server Configuration',NULL,NULL,NULL),(1025,3,NULL,'yast2-installation','2.10.30-2',NULL,'YaST2 - Installation Parts',NULL,NULL,NULL),(1026,3,NULL,'yast2-inetd','2.10.6-2',NULL,'YaST2 - Network Services Configuration',NULL,NULL,NULL),(1027,3,NULL,'yast2-network','2.10.33-2',NULL,'YaST2 - Network Configuration',NULL,NULL,NULL),(1028,3,NULL,'yast2-dns-server','2.10.12-2',NULL,'YaST2 - DNS Server Configuration',NULL,NULL,NULL),(1029,3,NULL,'yast2-dhcp-server','2.10.8-0.1',NULL,'YaST2 - DHCP Server Configuration',NULL,NULL,NULL),(1030,3,NULL,'acpid','1.0.3-4.4',NULL,'Executes Actions at ACPI Events',NULL,NULL,NULL),(1031,3,NULL,'readline','5.0-1.2',NULL,'The Readline Library',NULL,NULL,NULL),(1032,3,NULL,'powersave','0.8.19.13-0.1',NULL,'General Powermanagement daemon supporting APM and ACPI and CPU frequency scaling',NULL,NULL,NULL),(1033,3,NULL,'libxml2','2.6.12-3.4',NULL,'A library to manipulate XML files',NULL,NULL,NULL),(1034,3,NULL,'expat','1.95.8-2',NULL,'XML Parser Toolkit',NULL,NULL,NULL),(1035,3,NULL,'libjpeg','6.2.0-736',NULL,'JPEG libraries',NULL,NULL,NULL),(1036,3,NULL,'fontconfig','2.2.96.20040728-9',NULL,'Library for Font Configuration',NULL,NULL,NULL),(1037,3,NULL,'libpqxx','2.2.7-2',NULL,'C++ Client Library for PostgreSQL',NULL,NULL,NULL),(1038,3,NULL,'3ddiag','0.722-2',NULL,'A Tool to Verify the 3D Configuration',NULL,NULL,NULL),(1039,3,NULL,'calamaris','2.59-2',NULL,'A Report Generator',NULL,NULL,NULL),(1040,3,NULL,'dhcp','3.0.1-3',NULL,'Common files used by ISC DHCP software',NULL,NULL,NULL),(1041,3,NULL,'fribidi','0.10.4-485',NULL,'Free Implementation of BiDi Algorithm',NULL,NULL,NULL),(1042,3,NULL,'hermes','1.3.2-444',NULL,'A graphics conversion library',NULL,NULL,NULL),(1043,3,NULL,'imwheel','0.9.5-1031',NULL,'A program to enable the wheel on a Microsoft Intellimouse',NULL,NULL,NULL),(1044,3,NULL,'ircd','2.10.3p7-2',NULL,'Internet Relay Chat Server',NULL,NULL,NULL),(1045,3,NULL,'libtool','1.5.8-3',NULL,'A tool to build shared libraries',NULL,NULL,NULL),(1046,3,NULL,'mrtg','2.10.15-2',NULL,'The Multi Router Traffic Grapher',NULL,NULL,NULL),(1047,3,NULL,'netdiag','20010114-387',NULL,'Hardware Level Diagnostic Tool',NULL,NULL,NULL),(1048,3,NULL,'patch','2.5.9-143',NULL,'GNU Patch program',NULL,NULL,NULL),(1049,3,NULL,'perl-TermReadKey','2.21-294',NULL,'A Perl Module for Simple Terminal Control',NULL,NULL,NULL),(1050,3,NULL,'python-japanese','1.4.10-68',NULL,'Japanese Codecs for Python',NULL,NULL,NULL),(1051,3,NULL,'radvd','0.7.2-183',NULL,'Router ADVertisement Daemon for IPv6',NULL,NULL,NULL),(1052,3,NULL,'unclutter','8-836',NULL,'Remove the idle cursor image from the screen',NULL,NULL,NULL),(1053,3,NULL,'wwwoffle','2.8c-2',NULL,'World Wide Web Offline Proxy',NULL,NULL,NULL),(1054,3,NULL,'xlockmore','5.13-3',NULL,'Screen Saver and Locker for the X Window System',NULL,NULL,NULL),(1055,3,NULL,'xorg-x11-fonts-scalable','6.8.1-15',NULL,'Scalable fonts for the X Window System',NULL,NULL,NULL),(1056,3,NULL,'zsh','4.2.1-2',NULL,'Shell with comprehensive completion',NULL,NULL,NULL),(1057,3,NULL,'intlfnts','1.2.1-192',NULL,'Documentation for the international fonts',NULL,NULL,NULL),(1058,3,NULL,'dhcp-server','3.0.1-3',NULL,'ISC DHCP Server',NULL,NULL,NULL),(1059,3,NULL,'heimdal-x11','0.6.2-8',NULL,'Free Kerberos5 implementation - x11 tools',NULL,NULL,NULL),(1060,3,NULL,'ntop','3.0.053-3',NULL,'Web-Based Network Traffic Monitor',NULL,NULL,NULL),(1061,3,NULL,'ppp','2.4.2-49',NULL,'The Point to Point Protocol for Linux',NULL,NULL,NULL),(1062,3,NULL,'sensors','2.8.7-2',NULL,'Hardware health monitoring for Linux',NULL,NULL,NULL),(1063,3,NULL,'traffic-vis','0.35-138',NULL,'Network Traffic Analysis Suite',NULL,NULL,NULL),(1064,3,NULL,'perl-SNMP','5.1.2-3',NULL,'Perl-SNMP',NULL,NULL,NULL),(1065,3,NULL,'xorg-x11','6.8.1-15',NULL,'The basic X Window System package',NULL,NULL,NULL),(1066,3,NULL,'nagios-nrpe','2.0-110',NULL,'Nagios Remote Plug-In Executor',NULL,NULL,NULL),(1067,3,NULL,'yast2-qt','2.10.12-2',NULL,'YaST2 - Graphical User Interface',NULL,NULL,NULL),(1068,3,NULL,'apcupsd','3.10.15-3',NULL,'APC UPS Daemon (powerful daemon for APC UPS\'es)',NULL,NULL,NULL),(1069,3,NULL,'ghostscript-library','7.07.1rc1-207',NULL,'Necessary files for running Ghostscript',NULL,NULL,NULL),(1070,3,NULL,'cups-SUSE-ppds-dat','1.1.20-104',NULL,'Pre-generated ppds.dat for cupsd',NULL,NULL,NULL),(1071,3,NULL,'bonnie','1.4-338',NULL,'File System Benchmark',NULL,NULL,NULL),(1072,3,NULL,'libgcrypt','1.2.0-3',NULL,'The GNU Crypto Library',NULL,NULL,NULL),(1073,3,NULL,'hp2xx','3.4.2-354',NULL,'Converts HP-GL Plotter Language into a Variety of Formats',NULL,NULL,NULL),(1074,3,NULL,'courier-imap-ldap','3.0.7-3.2',NULL,'Courier-IMAP LDAP authentication driver',NULL,NULL,NULL),(1075,3,NULL,'imlib','1.9.14-188.2',NULL,'A shared library for loading and rendering 3D images',NULL,NULL,NULL),(1076,3,NULL,'ncpfs','2.2.4-29.4',NULL,'Tools for Accessing Novell File Systems',NULL,NULL,NULL),(1077,3,NULL,'xorg-x11-fonts-75dpi','6.8.1-15.5',NULL,'75dpi Bitmap Fonts',NULL,NULL,NULL),(1078,3,NULL,'apache2-mod_perl','1.99_12_20040302-38',NULL,'Embedded Perl for Apache',NULL,NULL,NULL),(1079,3,NULL,'apache2-mod_macro','1.1.6-2',NULL,'Define and Use Macros within the Apache Configuration',NULL,NULL,NULL),(1080,3,NULL,'apache2-doc','2.0.50-7.2',NULL,'Additional Package Documentation.',NULL,NULL,NULL),(1081,3,NULL,'openslp','1.1.5-80.4',NULL,'An OpenSLP Implementation of Service Location Protocol V2',NULL,NULL,NULL),(1082,3,NULL,'deltarpm','1.0-4.2',NULL,'Tools to create and apply deltarpms',NULL,NULL,NULL),(1083,3,NULL,'glibc-devel','2.3.3-118',NULL,'Include Files and Libraries Mandatory for Development.',NULL,NULL,NULL),(1084,3,NULL,'gcc','3.3.4-11',NULL,'The GNU C Compiler and Support Files',NULL,NULL,NULL),(1085,3,NULL,'linkchecker','2.2-1',NULL,'check HTML documents for broken links',NULL,NULL,NULL),(1086,3,NULL,'fetchmailconf','6.2.5-54',NULL,'Fetchmail Configuration Utility',NULL,NULL,NULL),(1087,3,NULL,'python-fcgi','2000.09.21-145',NULL,'Python FastCGI Module',NULL,NULL,NULL),(1088,3,NULL,'python-dialog','2.06-2',NULL,'A Python interface to the Unix dialog utility',NULL,NULL,NULL),(1089,3,NULL,'python-gdbm','2.3.4-3',NULL,'Python Interface to the GDBM Library',NULL,NULL,NULL),(1090,3,NULL,'bluez-libs','2.10-2',NULL,'Bluetooth Libraries',NULL,NULL,NULL),(1091,3,NULL,'SDL','1.2.7-41',NULL,'Simple DirectMedia Layer Library',NULL,NULL,NULL),(1092,3,NULL,'SDL_ttf','2.0.6-220',NULL,'Simple DirectMedia Layer - Truetype Library',NULL,NULL,NULL),(1093,3,NULL,'wxGTK-gl','2.5.2.8-3',NULL,'OpenGl add-on for wxGTK',NULL,NULL,NULL),(1094,3,NULL,'graphviz','1.12-3',NULL,'Graphs visualization tools',NULL,NULL,NULL),(1095,3,NULL,'unzip','5.51-2',NULL,'A program to unpack compressed files',NULL,NULL,NULL),(1096,3,NULL,'postfix','2.1.5-3.4',NULL,'A fast, secure, and flexible mailer',NULL,NULL,NULL),(1097,3,NULL,'fetchmail','6.2.5-54.4',NULL,'Full-featured POP and IMAP mail retrieval daemon',NULL,NULL,NULL),(1098,3,NULL,'pam_krb5','1.3-202.4',NULL,'PAM Module for Kerberos Authentication',NULL,NULL,NULL),(1099,3,NULL,'xinetd','2.3.13-42.2',NULL,'An \'inetd\' with Expanded Functionality',NULL,NULL,NULL),(1100,3,NULL,'lynx','2.8.5-32.3',NULL,'A text-based WWW browser',NULL,NULL,NULL),(1101,3,NULL,'perl','5.8.5-3.5',NULL,'The Perl interpreter',NULL,NULL,NULL),(1102,3,NULL,'libjpeg-devel','6.2.0-2',NULL,'Development Tools for Programs which will use the Libjpeg Library',NULL,NULL,NULL),(1103,3,NULL,'detex','2.7-636',NULL,'TeX to ASCII Converter',NULL,NULL,NULL),(1104,3,NULL,'TeX-Guy-devel','1.2.4-409',NULL,'DVI interpreter library, DVI utilities (for displaying and printing)',NULL,NULL,NULL),(1105,3,NULL,'perl-GD','2.16-3',NULL,'Interface to Thomas Boutell\'s gd library',NULL,NULL,NULL),(1106,3,NULL,'perl-GD-Graph3d','0.63-3',NULL,'3d extension for perl-GDGraph',NULL,NULL,NULL),(1107,3,NULL,'htmldoc','1.8.23-270',NULL,'HTML processor that generates HTML, PostScript, and PDF files',NULL,NULL,NULL),(1108,3,NULL,'openmotif-libs','2.2.3-11',NULL,'Open Motif Runtime Libraries',NULL,NULL,NULL),(1109,3,NULL,'xlhtml','0.5-111',NULL,'Excel 95 and later file converter',NULL,NULL,NULL),(1110,3,NULL,'mysql-client','4.1.10a-3',NULL,'MySQL Client',NULL,NULL,NULL),(1111,3,NULL,'cups','1.1.21-5.8',NULL,'The Common UNIX Printing System',NULL,NULL,NULL),(1112,3,NULL,'coreutils','5.2.1-32.4',NULL,'GNU Core Utilities',NULL,NULL,NULL),(1113,3,NULL,'net-tools','1.60-551.3',NULL,'Important programs for networking',NULL,NULL,NULL),(1114,3,NULL,'java-1_4_2-sun-demo','1.4.2.11-1.1',NULL,'Demonstration files for java-1.4.2-sun',NULL,NULL,NULL),(1115,3,NULL,'cpio','2.5-326.3',NULL,'A backup and archiving utility',NULL,NULL,NULL),(1116,3,NULL,'postgresql','7.4.13-0.2',NULL,'Basic Clients and Utilities for PostgreSQL',NULL,NULL,NULL),(1117,3,NULL,'postgresql-libs','7.4.13-0.2',NULL,'Shared Libraries Required for PostgreSQL Clients',NULL,NULL,NULL),(1118,3,NULL,'snort','2.3.2-0.6',NULL,'A Packet Sniffer and Logger',NULL,NULL,NULL),(1119,3,NULL,'pwdutils','2.6.90-6.5',NULL,'Utilities to Manage User and Group Accounts',NULL,NULL,NULL),(1120,3,NULL,'freetype2','2.1.9-3.4',NULL,'A TrueType font library',NULL,NULL,NULL),(1121,3,NULL,'gpg2','1.9.10-3.10',NULL,'GnuPG 2',NULL,NULL,NULL),(1122,3,NULL,'heimdal-lib','0.6.2-8.8',NULL,'Free Kerberos5 implementation - libraries',NULL,NULL,NULL),(1123,3,NULL,'perl-PerlMagick','6.0.7-4.10',NULL,'Perl interface for ImageMagick',NULL,NULL,NULL),(1124,3,NULL,'kernel-default-nongpl','2.6.8-24.25',NULL,'Non-GPL kernel modules',NULL,NULL,NULL),(1125,3,NULL,'bind','9.2.4-3.3',NULL,'Domain Name System (DNS) server (named)',NULL,NULL,NULL),(1126,3,NULL,'php4-gd','4.3.8-8.33',NULL,'PHP4 Extension Module',NULL,NULL,NULL),(1127,3,NULL,'qt3','3.3.3-24.2',NULL,'A library for developing applications with graphical user interfaces',NULL,NULL,NULL),(1128,3,NULL,'binutils','2.15.91.0.2-7.5',NULL,'GNU Binutils',NULL,NULL,NULL),(1129,3,NULL,'jpackage-utils','1.5.38-3',NULL,'JPackage utilities',NULL,NULL,NULL),(1130,3,NULL,'perl-Net_SSLeay','1.25-29.1',NULL,'Net::SSLeay Perl Module',NULL,NULL,NULL),(1131,3,NULL,'gpg-pubkey','3d25d3d9-36e12d04',NULL,'gpg(SuSE Security Team <security@suse.de>)',NULL,NULL,NULL),(1132,3,NULL,'suse-release','9.2-3',NULL,'SuSE release version files',NULL,NULL,NULL),(1133,3,NULL,'sash','3.7-31',NULL,'A stand-alone shell with built-in commands',NULL,NULL,NULL),(1134,3,NULL,'cabextract','1.0-19',NULL,'A Program to Extract Microsoft Cabinet files',NULL,NULL,NULL),(1135,3,NULL,'lsof','4.72-2',NULL,'A program that lists information about files opened by processes',NULL,NULL,NULL),(1136,3,NULL,'netcat','1.10-867',NULL,'A simple but powerful network tool',NULL,NULL,NULL),(1137,3,NULL,'mktemp','1.5-731',NULL,'A utility for tempfiles',NULL,NULL,NULL),(1138,3,NULL,'mingetty','0.9.6s-75',NULL,'Minimal Getty for Virtual Consoles Only',NULL,NULL,NULL),(1139,3,NULL,'lukemftp','1.5-580',NULL,'enhanced ftp client',NULL,NULL,NULL),(1140,3,NULL,'initviocons','0.4-300',NULL,'Terminal initialization for the iSeries virtual console',NULL,NULL,NULL),(1141,3,NULL,'libselinux','1.16-3',NULL,'SELinux Library and Utilities',NULL,NULL,NULL),(1142,3,NULL,'module-init-tools','3.1_pre5-6',NULL,'Utilities to load modules into the kernel',NULL,NULL,NULL),(1143,3,NULL,'src_vipa','2.0.0-61',NULL,'Virtual Source IP address support for HA solutions',NULL,NULL,NULL),(1144,3,NULL,'acl','2.2.25-2',NULL,'Commands for Manipulating POSIX Access Control Lists',NULL,NULL,NULL),(1145,3,NULL,'e2fsprogs','1.35-2',NULL,'Utilities for the second extended file system',NULL,NULL,NULL),(1146,3,NULL,'tar','1.14-3',NULL,'GNU implementation of tar ( (t)ape (ar)chiver )',NULL,NULL,NULL),(1147,3,NULL,'ed','0.2-868',NULL,'Standard UNIX line editor',NULL,NULL,NULL),(1148,3,NULL,'recode','3.6-490',NULL,'A character set converter',NULL,NULL,NULL),(1149,3,NULL,'yast2-theme-SuSELinux','2.10.6-2',NULL,'YaST2 - Theme (SuSE Linux)',NULL,NULL,NULL),(1150,3,NULL,'syslogd','1.4.1-526',NULL,'The Syslog daemon',NULL,NULL,NULL),(1151,3,NULL,'device-mapper','1.00.19-3',NULL,'Device Mapper Tools',NULL,NULL,NULL),(1152,3,NULL,'raidtools','1.00.3-230',NULL,'Software-raid utilities',NULL,NULL,NULL),(1153,3,NULL,'perl-Digest-SHA1','2.10-2',NULL,'A Perl Interface to the SHA-1 Algorithm',NULL,NULL,NULL),(1154,3,NULL,'procps','3.2.3-4',NULL,'ps utilities for /proc',NULL,NULL,NULL),(1155,3,NULL,'perl-Config-Crontab','1.03-48',NULL,'Read/Write Vixie compatible crontab files',NULL,NULL,NULL),(1156,3,NULL,'scpm','1.0-9',NULL,'System Configuration Profile Management',NULL,NULL,NULL),(1157,3,NULL,'yast2-mail-aliases','2.10.8-2',NULL,'YaST2 - Mail Configuration (Aliases)',NULL,NULL,NULL),(1158,3,NULL,'libusb','0.1.8-33',NULL,'USB libraries',NULL,NULL,NULL),(1159,3,NULL,'evms','2.3.3-2',NULL,'EVMS - Enterprise Volume Management System',NULL,NULL,NULL),(1160,3,NULL,'submount','0.9-47',NULL,'Auto Mounting of Removable Media',NULL,NULL,NULL),(1161,3,NULL,'ldapcpplib','0.0.3-28',NULL,'C++ API for LDAPv3',NULL,NULL,NULL),(1162,3,NULL,'bind-utils','9.2.4-3',NULL,'Utilities to query and test DNS',NULL,NULL,NULL),(1163,3,NULL,'rsh','0.17-551',NULL,'Clients for remote access commands (rsh, rlogin, and rcp)',NULL,NULL,NULL),(1164,3,NULL,'at','3.1.8-900',NULL,'A job manager',NULL,NULL,NULL),(1165,3,NULL,'mailx','11.4-2',NULL,'A MIME-capable Implementation of the mailx Command',NULL,NULL,NULL),(1166,3,NULL,'yast2-transfer','2.9.3-2',NULL,'YaST2 - Agent for Various Transfer Protocols',NULL,NULL,NULL),(1167,3,NULL,'yast2-sound','2.10.6-2',NULL,'YaST2 - Sound Configuration',NULL,NULL,NULL),(1168,3,NULL,'yast2-online-update','2.10.3-2',NULL,'YaST2 - Online Update (YOU)',NULL,NULL,NULL),(1169,3,NULL,'yast2-xml','2.10.1-2',NULL,'YaST2 - XML Agent',NULL,NULL,NULL),(1170,3,NULL,'yast2-irda','2.10.3-2',NULL,'YaST2 - Infra-Red (IrDA) Access Configuration',NULL,NULL,NULL),(1171,3,NULL,'yast2-support','2.10.1-2',NULL,'YaST2 - Support Inquiries',NULL,NULL,NULL),(1172,3,NULL,'autoyast2-installation','2.10.13-2',NULL,'YaST2 - Auto Installation Modules',NULL,NULL,NULL),(1173,3,NULL,'yast2-security','2.10.5-2',NULL,'YaST2 - Security Configuration',NULL,NULL,NULL),(1174,3,NULL,'yast2-repair','2.10.5-2',NULL,'YaST2 - System Repair Tool',NULL,NULL,NULL),(1175,3,NULL,'yast2-sysconfig','2.10.5-2',NULL,'YaST2 - Sysconfig Editor',NULL,NULL,NULL),(1176,3,NULL,'yast2-nis-server','2.10.5-2',NULL,'YaST2 - Network Information Services (NIS) Server Configuration',NULL,NULL,NULL),(1177,3,NULL,'insserv','1.00.5-6.2',NULL,'A program to arrange init-scripts',NULL,NULL,NULL),(1178,3,NULL,'bash','3.0-8.2',NULL,'The GNU Bourne-Again Shell',NULL,NULL,NULL),(1179,3,NULL,'file','4.09-4.2',NULL,'A tool to determine file types',NULL,NULL,NULL),(1180,3,NULL,'emacs-info','21.3-193',NULL,'Info files for GNU Emacs',NULL,NULL,NULL),(1181,3,NULL,'libpng','1.2.6-4',NULL,'Library for the Portable Network Graphics Format',NULL,NULL,NULL),(1182,3,NULL,'psqlODBC','07.03.0200-83',NULL,'ODBC Driver for PostgreSQL',NULL,NULL,NULL),(1183,3,NULL,'postgresql-jdbc','7.3-191',NULL,'JDBC Drivers for PostgreSQL',NULL,NULL,NULL),(1184,3,NULL,'xaw3d','1.5E-222',NULL,'3D Athena Widgets',NULL,NULL,NULL),(1185,3,NULL,'aide','0.10-47',NULL,'Advanced Intrusion Detection Environment',NULL,NULL,NULL),(1186,3,NULL,'bind-chrootenv','9.2.4-3',NULL,'Chroot environment for BIND named and lwresd',NULL,NULL,NULL),(1187,3,NULL,'dhcp-tools','1.6-29',NULL,'DHCP Tools',NULL,NULL,NULL),(1188,3,NULL,'inn','2.4.1-37',NULL,'InterNetNews',NULL,NULL,NULL),(1189,3,NULL,'liblcms','1.12-57',NULL,'Libraries for the little CMS engine',NULL,NULL,NULL),(1190,3,NULL,'linux-atm-lib','2.4.0-415',NULL,'Libraries for ATM',NULL,NULL,NULL),(1191,3,NULL,'mysql-shared','4.0.21-4',NULL,'MySQL Shared Libraries',NULL,NULL,NULL),(1192,3,NULL,'perl-Crypt-DES','2.03-361',NULL,'Crypt::DES Perl Module',NULL,NULL,NULL),(1193,3,NULL,'perl-URI','1.33-2',NULL,'Perl Interface for URI Objects',NULL,NULL,NULL),(1194,3,NULL,'python-korean','2.0.5-353',NULL,'Korean Codecs for Python',NULL,NULL,NULL),(1195,3,NULL,'rrdtool','1.0.49-2',NULL,'A tool for data logging and analysis',NULL,NULL,NULL),(1196,3,NULL,'samba-doc','3.0.7-5',NULL,'Samba Documentation',NULL,NULL,NULL),(1197,3,NULL,'suck','4.3.0-528',NULL,'Reading News Offline',NULL,NULL,NULL),(1198,3,NULL,'unixODBC','2.2.9-4',NULL,'ODBC driver manager with some drivers included',NULL,NULL,NULL),(1199,3,NULL,'xanim','2.80.2-766',NULL,'A multiformat animation viewer for the X Window System',NULL,NULL,NULL),(1200,3,NULL,'xorg-x11-Mesa','6.8.1-15',NULL,'Mesa Libraries',NULL,NULL,NULL),(1201,3,NULL,'xorg-x11-server-glx','6.8.1-15',NULL,'GLX extension and nvidia dummy driver modules',NULL,NULL,NULL),(1202,3,NULL,'Crystalcursors','0.5-25',NULL,'Mouse Cursors in Crystal Icon Style',NULL,NULL,NULL),(1203,3,NULL,'WindowMaker-applets','1.0-649',NULL,'WindowMaker applets',NULL,NULL,NULL),(1204,3,NULL,'freeglut','2.2.0-82',NULL,'Freely Licensed Alternative to the GLUT Library',NULL,NULL,NULL),(1205,3,NULL,'minicom','2.1-144',NULL,'A Terminal Program',NULL,NULL,NULL),(1206,3,NULL,'xf86tools','0.1-968',NULL,'Tools for the X Window System',NULL,NULL,NULL),(1207,3,NULL,'perl-libwww-perl','5.76-32',NULL,'Modules Providing a World Wide Web API',NULL,NULL,NULL),(1208,3,NULL,'CheckHardware','0.1-958',NULL,'CheckHardware tool',NULL,NULL,NULL),(1209,3,NULL,'w3mir','1.0.10-518',NULL,'HTTP Copying and Mirroring Tool',NULL,NULL,NULL),(1210,3,NULL,'sax2-gui','1.2-36',NULL,'SuSE advanced X Window System-configuration GUI',NULL,NULL,NULL),(1211,3,NULL,'cups-drivers','1.1.21-4',NULL,'Drivers for the Common UNIX Printing System',NULL,NULL,NULL),(1212,3,NULL,'howto','2004.10.4-1',NULL,'A Collection of How-Tos',NULL,NULL,NULL),(1213,3,NULL,'libgpg-error','0.7-6',NULL,'library that defines common error values for all GnuPG components',NULL,NULL,NULL),(1214,3,NULL,'dirmngr','0.5.5-3',NULL,'A Client for Managing and Downloading CRLs',NULL,NULL,NULL),(1215,3,NULL,'dvi2tty','5.3.1-110',NULL,'A TeX-DVI to ASCII Converter',NULL,NULL,NULL),(1216,3,NULL,'ipxrip','0.7-859.2',NULL,'IPX Routing Daemon',NULL,NULL,NULL),(1217,3,NULL,'vsftpd','2.0.1-2.2',NULL,'Very Secure FTP Daemon - Written from Scratch',NULL,NULL,NULL),(1218,3,NULL,'perl-Tie-IxHash','1.21-586',NULL,'TieIxHash Perl Module',NULL,NULL,NULL),(1219,3,NULL,'apache2-mod_auth_mysql','20030510-208',NULL,'Enables the Apache Web Server to Authenticate Users against a MySQL Database',NULL,NULL,NULL),(1220,3,NULL,'apache2-devel','2.0.50-7.2',NULL,'Apache 2.0 Header and Include Files',NULL,NULL,NULL),(1221,3,NULL,'libapr0','2.0.50-7.2',NULL,'Apache Portable Runtime (APR) Library',NULL,NULL,NULL),(1222,3,NULL,'apache2-mod_python','3.1.3-37.3',NULL,'A Python Module for the Apache 2 Web Server',NULL,NULL,NULL),(1223,3,NULL,'libstdc++-devel','3.3.4-11',NULL,'Include Files and Libraries mandatory for Development',NULL,NULL,NULL),(1224,3,NULL,'linkchecker','2.9-1',NULL,'check websites and HTML documents for broken links',NULL,NULL,NULL),(1225,3,NULL,'python-tk','2.3.4-3',NULL,'TkInter - Python Tk Interface',NULL,NULL,NULL),(1226,3,NULL,'python-idle','2.3.4-3',NULL,'An Integrated Development Environment for Python',NULL,NULL,NULL),(1227,3,NULL,'pyxml','0.8.3-185',NULL,'XML Tools in Python',NULL,NULL,NULL),(1228,3,NULL,'python-egenix-mx-base','2.0.4-203',NULL,'MX Extensions for Python (base)',NULL,NULL,NULL),(1229,3,NULL,'libmspack','0.0.20040308alpha-3',NULL,'Library that implements different Microsoft-Compressions',NULL,NULL,NULL),(1230,3,NULL,'audiofile','0.2.5-41',NULL,'An audio file library',NULL,NULL,NULL),(1231,3,NULL,'libvorbis','1.0.1-60',NULL,'The Vorbis General Audio Compression Codec',NULL,NULL,NULL),(1232,3,NULL,'SDL_image','1.2.3-224',NULL,'Simple DirectMedia Layer - Sample Image Loading Library',NULL,NULL,NULL),(1233,3,NULL,'python-pygame','1.6.2-2',NULL,'A Python Module for Interfacing with the SDL Multimedia Library',NULL,NULL,NULL),(1234,3,NULL,'python-gammu','0.6-2',NULL,'Python Module to Communicate with Mobile Phones',NULL,NULL,NULL),(1235,3,NULL,'graphviz-devel','1.12-3',NULL,'Graphiviz development package',NULL,NULL,NULL),(1236,3,NULL,'qpopper','4.0.5-175.2',NULL,'POP3 Mail Daemon from Qualcomm Inc.',NULL,NULL,NULL),(1237,3,NULL,'telnet','1.1-41.4',NULL,'A client program for the telnet remote login protocol',NULL,NULL,NULL),(1238,3,NULL,'tcpdump','3.8.3-2.3',NULL,'A packet sniffer',NULL,NULL,NULL),(1239,3,NULL,'dhcpcd','1.3.22pl4-200.2',NULL,'A DHCP client daemon',NULL,NULL,NULL),(1240,3,NULL,'zlib','1.2.1-74.4',NULL,'Data Compression Library',NULL,NULL,NULL),(1241,3,NULL,'udev','030-9.2',NULL,'A Userspace Implementation of DevFS',NULL,NULL,NULL),(1242,3,NULL,'bigsister','0.98c8-73',NULL,'The Big Sister Network and System Monitor',NULL,NULL,NULL),(1243,3,NULL,'openldap2-client','2.2.15-5.3',NULL,'OpenLDAP2 client utilities',NULL,NULL,NULL),(1244,3,NULL,'xorg-x11-Xvnc','6.8.1-15.9',NULL,'VNC Server for the X Window System',NULL,NULL,NULL),(1245,3,NULL,'giflib','4.1.3-4.2',NULL,'A Library for Working with GIF Images',NULL,NULL,NULL),(1246,3,NULL,'gtk2','2.4.9-10.3',NULL,'Library for Creation of Graphical User Interfaces',NULL,NULL,NULL),(1247,3,NULL,'VFlib3','3.6.13-264',NULL,'Versatile Font Library',NULL,NULL,NULL),(1248,3,NULL,'te_pdf','2.0.2-198',NULL,'A Version of TeX/LaTeX which Creates PDF Files',NULL,NULL,NULL),(1249,3,NULL,'perl-GDGraph','1.43-3',NULL,'package to generate charts, using Lincoln Stein\'s GD.pm',NULL,NULL,NULL),(1250,3,NULL,'fltk-devel','1.1.4-82',NULL,'Include Files and Libraries mandatory for Development.',NULL,NULL,NULL),(1251,3,NULL,'libcap','1.92-481',NULL,'library and binaries for capabilities (linux-privs) support',NULL,NULL,NULL),(1252,3,NULL,'libgsf','1.11.1-4',NULL,'GNOME Structured File Library',NULL,NULL,NULL),(1253,3,NULL,'wv2','0.2.2-4',NULL,'library to import Microsoft Word documents',NULL,NULL,NULL),(1254,3,NULL,'xpdf-config','3.00-87',NULL,'Character maps and config files required by xpdf',NULL,NULL,NULL),(1255,3,NULL,'ncftp','3.1.8-3',NULL,'A Comfortable FTP Program',NULL,NULL,NULL),(1256,3,NULL,'sysbench','0.3.2-5',NULL,'A MySQL benchmarking tool',NULL,NULL,NULL),(1257,3,NULL,'cups-client','1.1.21-5.8',NULL,'CUPS Client Programs',NULL,NULL,NULL),(1258,3,NULL,'gd','2.0.28-2.5',NULL,'A Drawing Library for programs that use PNG and JPEG Output',NULL,NULL,NULL),(1259,3,NULL,'liby2util','2.10.7-0.3',NULL,'YaST2 - Utilities Library',NULL,NULL,NULL),(1260,3,NULL,'java-1_4_2-sun-jdbc','1.4.2.11-1.1',NULL,'JDBC/ODBC bridge driver for java-1.4.2-sun',NULL,NULL,NULL),(1261,3,NULL,'pound','1.7.cvs20040910-3.4',NULL,'reverse-proxy and load-balancer',NULL,NULL,NULL),(1262,3,NULL,'postgresql-contrib','7.4.13-0.2',NULL,'Contributed Extensions and Additions to PostgreSQL',NULL,NULL,NULL),(1263,3,NULL,'postgresql-pl','7.4.13-0.2',NULL,'The PL/Tcl, PL/Perl, and PL/Python Procedural Languages for PostgreSQL',NULL,NULL,NULL),(1264,3,NULL,'wget','1.10-1.5',NULL,'A tool for mirroring FTP and HTTP servers',NULL,NULL,NULL),(1265,3,NULL,'quagga','0.96.5-2.3',NULL,'Free Routing Software (for BGP, OSPF and RIP, for example)',NULL,NULL,NULL),(1266,3,NULL,'freetype2-devel','2.1.9-3.4',NULL,'Include Files and Libraries mandatory for Development.',NULL,NULL,NULL),(1267,3,NULL,'openldap2','2.2.15-5.6',NULL,'The new OpenLDAP Server (LDAPv3)',NULL,NULL,NULL),(1268,3,NULL,'heimdal-tools','0.6.2-8.5',NULL,'Free Kerberos5 Implementation - Client Side Tools',NULL,NULL,NULL),(1269,3,NULL,'apache2','2.0.50-7.17',NULL,'The Apache web server (version 2.0)',NULL,NULL,NULL),(1270,3,NULL,'kernel-source','2.6.8-24.25',NULL,'The Linux kernel sources',NULL,NULL,NULL),(1271,3,NULL,'bind-libs','9.2.4-3.3',NULL,'Shared libraries of BIND',NULL,NULL,NULL),(1272,3,NULL,'openssl','0.9.7d-25.8',NULL,'Secure Sockets and Transport Layer Security',NULL,NULL,NULL),(1273,3,NULL,'mailman','2.1.5-5.12',NULL,'The GNU Mailing List manager',NULL,NULL,NULL),(1274,3,NULL,'update-alternatives','1.8.3-2',NULL,'Maintain symbolic links determining default commands',NULL,NULL,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `softwares` ENABLE KEYS */;

--
-- Table structure for table `sounds`
--

DROP TABLE IF EXISTS `sounds`;
CREATE TABLE `sounds` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `MANUFACTURER` varchar(255) default NULL,
  `NAME` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `sounds`
--


/*!40000 ALTER TABLE `sounds` DISABLE KEYS */;
LOCK TABLES `sounds` WRITE;
INSERT INTO `sounds` VALUES (1,2,'Avance','Avance AC\'\'97 Audio for VIA (R) Audio Controller','Avance AC\'\'97 Audio for VIA (R) Audio Controller'),(2,3,'nVidia Corporation: Unknown device 008a','Multimedia audio controller','rev a1');
UNLOCK TABLES;
/*!40000 ALTER TABLE `sounds` ENABLE KEYS */;

--
-- Table structure for table `storages`
--

DROP TABLE IF EXISTS `storages`;
CREATE TABLE `storages` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `MANUFACTURER` varchar(255) default NULL,
  `NAME` varchar(255) default NULL,
  `MODEL` varchar(255) default NULL,
  `DESCRIPTION` varchar(255) default NULL,
  `TYPE` varchar(255) default NULL,
  `DISKSIZE` int(11) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `storages`
--


/*!40000 ALTER TABLE `storages` DISABLE KEYS */;
LOCK TABLES `storages` WRITE;
INSERT INTO `storages` VALUES (1,1,'IBM',NULL,'SERVERAID','SCSI','disk',35548),(2,1,'??',NULL,'MATSHITADVD-ROM SR-8177','IDE','removable',0),(3,2,'(Standard floppy disk drives)','Floppy disk drive','Floppy disk drive','Floppy disk drive',NULL,NULL),(4,2,'(Standard disk drives)','ST340823A','//./PHYSICALDRIVE0','Disk drive','Fixed hard disk media',38162),(5,2,'(Standard CD-ROM drives)','HL-DT-ST DVDRAM GSA-4163B','HL-DT-ST DVDRAM GSA-4163B','CD-ROM Drive','CD-ROM',NULL),(6,2,'(Standard CD-ROM drives)','Generic DVD-ROM SCSI CdRom Device','Generic DVD-ROM SCSI CdRom Device','CD-ROM Drive','CD-ROM',NULL),(7,3,'??',NULL,'HL-DT-STDVD-ROM GDR8161B','IDE','removable',0),(8,3,'??',NULL,'ST3160021A','IDE','disk',156290),(9,3,'??',NULL,'ST3160021A','IDE','disk',156290);
UNLOCK TABLES;
/*!40000 ALTER TABLE `storages` ENABLE KEYS */;

--
-- Table structure for table `subnet`
--

DROP TABLE IF EXISTS `subnet`;
CREATE TABLE `subnet` (
  `NETID` varchar(15) NOT NULL default '',
  `NAME` varchar(255) default NULL,
  `ID` int(11) default NULL,
  `MASK` varchar(255) default NULL,
  PRIMARY KEY  (`NETID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `subnet`
--


/*!40000 ALTER TABLE `subnet` DISABLE KEYS */;
LOCK TABLES `subnet` WRITE;
INSERT INTO `subnet` VALUES ('172.26.0.0','Intranet',1,'255.255.255.0'),('172.26.2.0','DMZ',2,'255.255.255.0'),('192.168.198.0','VMware Local Zone',3,'255.255.255.0'),('192.168.220.0','VMware Local Zone 2',4,'255.255.255.0');
UNLOCK TABLES;
/*!40000 ALTER TABLE `subnet` ENABLE KEYS */;

--
-- Table structure for table `videos`
--

DROP TABLE IF EXISTS `videos`;
CREATE TABLE `videos` (
  `ID` int(11) NOT NULL auto_increment,
  `HARDWARE_ID` int(11) NOT NULL default '0',
  `NAME` varchar(255) default NULL,
  `CHIPSET` varchar(255) default NULL,
  `MEMORY` varchar(255) default NULL,
  `RESOLUTION` varchar(255) default NULL,
  PRIMARY KEY  (`HARDWARE_ID`,`ID`),
  KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `videos`
--


/*!40000 ALTER TABLE `videos` DISABLE KEYS */;
LOCK TABLES `videos` WRITE;
INSERT INTO `videos` VALUES (1,1,'ATI Technologies Inc Radeon RV100 QY [Radeon 7000/VE]','VGA compatible controller',NULL,NULL),(2,2,'S3 Graphics ProSavageDDR','S3 ProSavage DDR','32','1280 x 1024'),(3,2,'Mirage Driver',NULL,'0','0 x 0'),(4,3,'nVidia Corporation NV18 [GeForce4 MX - nForce GPU]','VGA compatible controller',NULL,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `videos` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

