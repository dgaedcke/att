/*
SQLyog Ultimate v8.55 
MySQL - 5.1.51 : Database - att
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`att` /*!40100 DEFAULT CHARACTER SET utf8 */;

/*Table structure for table `_note` */

DROP TABLE IF EXISTS `_note`;

CREATE TABLE `_note` (
  `not_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `not_note` varchar(500) NOT NULL,
  `not_order` smallint(5) unsigned NOT NULL DEFAULT '50',
  PRIMARY KEY (`not_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `_note` */

/*Table structure for table `att_attribute` */

DROP TABLE IF EXISTS `att_attribute`;

CREATE TABLE `att_attribute` (
  `att_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `att_in_all_dom` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'include this att in all domains (via dxa)',
  `att_version_it` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'keep old vals and version each change',
  `att_encrypt_it` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'hash stored vals',
  `att_is_long` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'true if > 140 chars',
  `att_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `att_name` varchar(40) NOT NULL COMMENT 'attribute name',
  PRIMARY KEY (`att_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `att_attribute` */

/*Table structure for table `dom_domain` */

DROP TABLE IF EXISTS `dom_domain`;

CREATE TABLE `dom_domain` (
  `dom_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dom_new_atts_on_fly` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'true if new atts can be created on the fly',
  `dom_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `dom_name` varchar(40) NOT NULL COMMENT 'domain name',
  PRIMARY KEY (`dom_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

/*Data for the table `dom_domain` */

insert  into `dom_domain`(`dom_id`,`dom_new_atts_on_fly`,`dom_encode`,`dom_name`) values (1,0,0,'attribute'),(2,0,0,'preference'),(3,0,0,'privilege'),(4,0,0,'type'),(5,0,0,'external');

/*Table structure for table `dty_data_type` */

DROP TABLE IF EXISTS `dty_data_type`;

CREATE TABLE `dty_data_type` (
  `dty_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dty_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `dty_name` varchar(40) NOT NULL COMMENT 'string, text, int, bool, date, blob',
  PRIMARY KEY (`dty_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `dty_data_type` */

/*Table structure for table `dxa_domain_x_attribute` */

DROP TABLE IF EXISTS `dxa_domain_x_attribute`;

CREATE TABLE `dxa_domain_x_attribute` (
  `dxa_dom_id` int(10) unsigned NOT NULL,
  `dxa_att_id` int(10) unsigned NOT NULL,
  `dxa_dty_id` int(10) unsigned NOT NULL,
  `dxa_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`dxa_dom_id`,`dxa_att_id`,`dxa_dty_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `dxa_domain_x_attribute` */

/*Table structure for table `ent_entity` */

DROP TABLE IF EXISTS `ent_entity`;

CREATE TABLE `ent_entity` (
  `ent_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ent_ety_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ent_xxx_id` bigint(20) unsigned NOT NULL COMMENT 'pointer to the table in ety',
  `ent_name` varchar(30) NOT NULL DEFAULT '' COMMENT 'niu',
  `ent_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ent_id`),
  UNIQUE KEY `type_rec_id` (`ent_ety_id`,`ent_xxx_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `ent_entity` */

/*Table structure for table `ety_entity_type` */

DROP TABLE IF EXISTS `ety_entity_type`;

CREATE TABLE `ety_entity_type` (
  `ety_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ety_name` varchar(40) NOT NULL,
  `ety_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ety_id`),
  UNIQUE KEY `ent_type_name` (`ety_name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

/*Data for the table `ety_entity_type` */

insert  into `ety_entity_type`(`ety_id`,`ety_name`,`ety_encode`) values (1,'app',0),(2,'company',0),(3,'role',0),(4,'user',0),(5,'conversation',0),(6,'post',0),(7,'session',0),(8,'statistic',0);

/*Table structure for table `exd_entity_x_domain` */

DROP TABLE IF EXISTS `exd_entity_x_domain`;

CREATE TABLE `exd_entity_x_domain` (
  `exd_ety_id` int(10) unsigned NOT NULL,
  `exd_dom_id` int(10) unsigned NOT NULL,
  `exd_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`exd_ety_id`,`exd_dom_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `exd_entity_x_domain` */

/*Table structure for table `lva_long_value` */

DROP TABLE IF EXISTS `lva_long_value`;

CREATE TABLE `lva_long_value` (
  `lva_val_id` bigint(20) unsigned NOT NULL,
  `lva_value` mediumblob NOT NULL,
  PRIMARY KEY (`lva_val_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `lva_long_value` */

/*Table structure for table `val_value` */

DROP TABLE IF EXISTS `val_value`;

CREATE TABLE `val_value` (
  `val_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `val_dom_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'domain',
  `val_att_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'attribute',
  `val_version` smallint(5) unsigned NOT NULL DEFAULT '1' COMMENT 'value version',
  `val_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `val_value` varchar(140) NOT NULL COMMENT 'value stored',
  PRIMARY KEY (`val_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `val_value` */

/*Table structure for table `var_value_archive` */

DROP TABLE IF EXISTS `var_value_archive`;

CREATE TABLE `var_value_archive` (
  `var_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `var_val_id` bigint(20) unsigned NOT NULL COMMENT 'value id',
  `var_version` smallint(5) unsigned NOT NULL COMMENT 'version of this value',
  `var_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `var_value` varchar(2000) NOT NULL COMMENT 'value',
  PRIMARY KEY (`var_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `var_value_archive` */

/* Function  structure for function  `lookupDomainType` */

/*!50003 DROP FUNCTION IF EXISTS `lookupDomainType` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` FUNCTION `lookupDomainType`(p_dom_name varchar(40), p_encode tinyint) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'returns id for given domain type'
BEGIN
/* select lookupDomainType('preferences',0) as A;
*/
	return coalesce((SELECT dom_id FROM dom_domain WHERE dom_name = p_dom_name),0);
END */$$
DELIMITER ;

/* Function  structure for function  `lookupEntityType` */

/*!50003 DROP FUNCTION IF EXISTS `lookupEntityType` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` FUNCTION `lookupEntityType`(p_ety_name varchar(40), p_encode tinyint) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'returns id for given entity type'
BEGIN
/* select lookupEntityType('user',0) as A;
*/
	return coalesce((SELECT ety_id FROM ety_entity_type WHERE ety_name = p_ety_name),0);
END */$$
DELIMITER ;

/* Procedure structure for procedure `createEntity` */

/*!50003 DROP PROCEDURE IF EXISTS  `createEntity` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `createEntity`(IN p_ent_type VARCHAR(40), IN p_xxx_id BIGINT, IN p_encode TINYINT, inout p_ent_id bigint)
    MODIFIES SQL DATA
    COMMENT 'create entity if missing'
BEGIN
/* p_ent_id should come in as ZERO unless it's being used as a shortcut to skip a
	func call and db lookup
*/
	declare v_ety_id int default p_ent_id;
	if v_ety_id < 1 then
		SET v_ety_id = lookupEntityType(p_ent_type,0);
	end if;
	insert into att.ent_entity
	(ent_ety_id, ent_xxx_id, ent_encode)
	values (v_ety_id, p_xxx_id, p_encode);
Set p_ent_id = last_insert_id(); -- this is my OUT param
END */$$
DELIMITER ;

/* Procedure structure for procedure `loadEntity` */

/*!50003 DROP PROCEDURE IF EXISTS  `loadEntity` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `loadEntity`(in p_ent_type varchar(40), In p_xxx_id bigint, In p_encode tinyint)
    MODIFIES SQL DATA
    COMMENT 'finds entity & creates if missing'
BEGIN
	declare v_ent_id, v_ent_xxx_id bigint default 0;
	Declare v_not_exists, v_ent_ety_id, v_temp_ent_ety_id, v_ent_encode smallint default 0;
	DECLARE invalid_type_value CONDITION FOR 45000;
	declare continue handler for not found Begin Set v_not_exists = 1; end;
	
	set v_temp_ent_ety_id = lookupEntityType(p_ent_type,0);
	if v_temp_ent_ety_id < 1 then
		call raiseError(45000, concat('invalid entity type passed=',p_ent_type) ,0);
	end if;
	SELECT ent_id, ent_xxx_id, ent_ety_id, ent_encode
	into v_ent_id, v_ent_xxx_id, v_ent_ety_id, v_ent_encode
	FROM att.ent_entity
	where ent_xxx_id = p_xxx_id
	and ent_ety_id = v_temp_ent_ety_id;
	
	if v_not_exists then
		set v_ent_id = v_temp_ent_ety_id; -- type lookup already done, so reuse it
		call createEntity(p_ent_type, p_xxx_id, p_encode, v_ent_id);
		-- v_ent_id is an out param with the id
		set v_ent_xxx_id = p_xxx_id, v_ent_ety_id = v_temp_ent_ety_id, v_ent_encode = p_encode;
	END IF;
	-- query only using vars to avoid hitting disk again
	SELECT v_ent_id as ent_id, v_ent_xxx_id as ent_xxx_id, v_ent_ety_id as ent_ety_id, v_ent_encode as ent_encode;
END */$$
DELIMITER ;

/* Procedure structure for procedure `raiseError` */

/*!50003 DROP PROCEDURE IF EXISTS  `raiseError` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `raiseError`(IN p_sql_state varchar(8), IN p_err_msg VARCHAR(200), IN p_encode TINYINT)
    NO SQL
    COMMENT 'throw error back to app'
BEGIN
/*  the SIGNAL stmt requires mysql 5.5 or newer 
	MESSAGE_TEXT is placeholder until I upgrade mysql
	http://dev.mysql.com/doc/refman/5.5/en/signal.html
	To signal a generic SQLSTATE value, use '45000', which means “unhandled user-defined exception.” 
*/
	declare MESSAGE_TEXT varchar(200);
	-- SIGNAL SQLSTATE '45000';
	SET MESSAGE_TEXT = p_err_msg;
END */$$
DELIMITER ;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
