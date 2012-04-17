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

/*Table structure for table `_tpl_att_stage` */

DROP TABLE IF EXISTS `_tpl_att_stage`;

CREATE TABLE `_tpl_att_stage` (
  `ats_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `ats_dom_name` varchar(40) NOT NULL DEFAULT '' COMMENT 'domain specified for this attribute',
  `ats_att_name` varchar(40) NOT NULL COMMENT 'attribue name',
  `ats_vers_dttm` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'for version control if needed',
  `ats_value` mediumblob NOT NULL COMMENT 'value passed to store',
  `ats_is_long` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'val is longer than allowed in val_value',
  `ats_is_multi` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'multiple vals are allowed',
  `ats_keep_old` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'true if old value should be archived',
  `ats_hash_it` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'true if value should be encrypted on disk',
  `ats_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `ats_ent_id` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT 'niu; for future batch jobs if needed',
  `ats_com_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'niu; for future batch jobs if needed',
  PRIMARY KEY (`ats_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 DELAY_KEY_WRITE=1 ROW_FORMAT=FIXED COMMENT='templt 4 isam session table for passing params to sproc';

/*Data for the table `_tpl_att_stage` */

/*Table structure for table `att_attribute` */

DROP TABLE IF EXISTS `att_attribute`;

CREATE TABLE `att_attribute` (
  `att_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `att_in_all_dom` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'include this att in all domains (via dxa)',
  `att_keep_old` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'keep old vals and version each change',
  `att_hash_it` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'encrypt stored vals',
  `att_is_long` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'true if > 140 chars',
  `att_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `att_name` varchar(40) NOT NULL COMMENT 'attribute name',
  PRIMARY KEY (`att_id`),
  UNIQUE KEY `att_name` (`att_name`),
  KEY `att_in_every_domain` (`att_in_all_dom`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

/*Data for the table `att_attribute` */

insert  into `att_attribute`(`att_id`,`att_in_all_dom`,`att_keep_old`,`att_hash_it`,`att_is_long`,`att_encode`,`att_name`) values (1,0,0,0,0,0,'age'),(2,0,0,0,0,0,'name'),(20,0,0,0,0,0,'hometown'),(23,0,0,0,0,0,'notes');

/*Table structure for table `dom_domain` */

DROP TABLE IF EXISTS `dom_domain`;

CREATE TABLE `dom_domain` (
  `dom_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dom_new_atts_on_fly` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'true if new atts can be created on the fly',
  `dom_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `dom_name` varchar(40) NOT NULL COMMENT 'domain name',
  PRIMARY KEY (`dom_id`),
  UNIQUE KEY `dom_name_add_atts_on_fly` (`dom_name`,`dom_new_atts_on_fly`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8;

/*Data for the table `dom_domain` */

insert  into `dom_domain`(`dom_id`,`dom_new_atts_on_fly`,`dom_encode`,`dom_name`) values (1,0,0,'attribute'),(2,0,0,'preference'),(3,0,0,'privilege'),(4,0,0,'type'),(5,0,0,'external');

/*Table structure for table `dty_data_type` */

DROP TABLE IF EXISTS `dty_data_type`;

CREATE TABLE `dty_data_type` (
  `dty_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dty_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `dty_name` varchar(40) NOT NULL COMMENT 'string, text, int, bool, date, blob',
  PRIMARY KEY (`dty_id`),
  UNIQUE KEY `dty_name` (`dty_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `dty_data_type` */

/*Table structure for table `dxa_dom_x_att` */

DROP TABLE IF EXISTS `dxa_dom_x_att`;

CREATE TABLE `dxa_dom_x_att` (
  `dxa_dom_id` int(10) unsigned NOT NULL COMMENT 'domain (group) for this use of the att',
  `dxa_att_id` int(10) unsigned NOT NULL COMMENT 'attribute id',
  `dxa_dty_id` int(10) unsigned NOT NULL COMMENT 'data type of value stored for this att',
  `dxa_att_is_long` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '1 if val > 140 chars',
  `dxa_att_is_multi` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '1 if > 1 val stored for this att',
  `dxa_att_hash_it` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '1 if val should be hashed',
  `dxa_att_keep_old` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '1 if changes to vals should be keep & timestamped / versioned',
  `dxa_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `dxa_hash_salt` char(3) NOT NULL DEFAULT 'abc' COMMENT 'salt for hashed vals',
  `dxa_dom_name` varchar(40) NOT NULL DEFAULT '' COMMENT 'copy down of dom name to avoid a join',
  PRIMARY KEY (`dxa_dom_id`,`dxa_att_id`),
  KEY `att_id_dty_id` (`dxa_att_id`,`dxa_dty_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `dxa_dom_x_att` */

/*Table structure for table `ent_entity` */

DROP TABLE IF EXISTS `ent_entity`;

CREATE TABLE `ent_entity` (
  `ent_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ent_com_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ent_ety_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ent_xxx_id` bigint(20) unsigned NOT NULL COMMENT 'pointer to the table in ety',
  `ent_mod_dttm` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'date time of last attribute change',
  `ent_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ent_id`),
  UNIQUE KEY `xxx_id_ety_id_com_id` (`ent_xxx_id`,`ent_ety_id`,`ent_com_id`),
  UNIQUE KEY `type_rec_id` (`ent_ety_id`,`ent_com_id`,`ent_xxx_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;

/*Data for the table `ent_entity` */

insert  into `ent_entity`(`ent_id`,`ent_com_id`,`ent_ety_id`,`ent_xxx_id`,`ent_mod_dttm`,`ent_encode`) values (13,14,4,12,'2012-04-13 14:43:03',0),(15,33,4,66,'2012-04-13 14:54:49',0),(16,0,4,66,'2012-04-13 16:34:42',0);

/*Table structure for table `ety_entity_type` */

DROP TABLE IF EXISTS `ety_entity_type`;

CREATE TABLE `ety_entity_type` (
  `ety_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ety_name` varchar(40) NOT NULL,
  `ety_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`ety_id`),
  UNIQUE KEY `ent_type_name` (`ety_name`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

/*Data for the table `ety_entity_type` */

insert  into `ety_entity_type`(`ety_id`,`ety_name`,`ety_encode`) values (1,'app_global',0),(2,'company',0),(3,'role',0),(4,'user',0),(5,'conversation',0),(6,'post',0),(7,'session',0),(8,'statistic',0),(9,'person',0),(10,'author',0),(11,'server',0);

/*Table structure for table `exd_ety_x_dom` */

DROP TABLE IF EXISTS `exd_ety_x_dom`;

CREATE TABLE `exd_ety_x_dom` (
  `exd_ety_id` int(10) unsigned NOT NULL,
  `exd_dom_id` int(10) unsigned NOT NULL,
  `exd_encode` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`exd_ety_id`,`exd_dom_id`),
  KEY `dom_id` (`exd_dom_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `exd_ety_x_dom` */

/*Table structure for table `lva_long_value` */

DROP TABLE IF EXISTS `lva_long_value`;

CREATE TABLE `lva_long_value` (
  `lva_val_id` bigint(20) unsigned NOT NULL,
  `lva_value` mediumblob NOT NULL,
  PRIMARY KEY (`lva_val_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `lva_long_value` */

insert  into `lva_long_value`(`lva_val_id`,`lva_value`) values (1,'baker ****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************bye dewey*******');

/*Table structure for table `val_value` */

DROP TABLE IF EXISTS `val_value`;

CREATE TABLE `val_value` (
  `val_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `val_ent_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `val_dom_id` smallint(10) unsigned NOT NULL DEFAULT '0' COMMENT 'domain',
  `val_att_id` mediumint(10) unsigned NOT NULL DEFAULT '0' COMMENT 'attribute',
  `val_version` smallint(5) unsigned NOT NULL DEFAULT '1' COMMENT 'value version',
  `val_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `val_mod_dttm` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `val_value` varchar(140) NOT NULL COMMENT 'value stored',
  PRIMARY KEY (`val_id`),
  UNIQUE KEY `ent_id_dom_id_att_id_value` (`val_ent_id`,`val_dom_id`,`val_att_id`),
  KEY `value_att_type` (`val_value`(30),`val_att_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

/*Data for the table `val_value` */

insert  into `val_value`(`val_id`,`val_ent_id`,`val_dom_id`,`val_att_id`,`val_version`,`val_encode`,`val_mod_dttm`,`val_value`) values (1,15,1,23,1,0,'2012-04-16 19:56:41','-1'),(2,15,1,20,1,0,'2012-04-16 19:56:41','boston'),(3,15,1,1,1,0,'2012-04-16 19:56:41','11'),(4,15,1,2,1,0,'2012-04-16 19:56:41','bob');

/*Table structure for table `var_value_archive` */

DROP TABLE IF EXISTS `var_value_archive`;

CREATE TABLE `var_value_archive` (
  `var_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `var_val_id` bigint(20) unsigned NOT NULL COMMENT 'value id',
  `var_encode` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT 'xtra bits',
  `var_mod_dttm` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `var_value` mediumblob NOT NULL COMMENT 'value',
  PRIMARY KEY (`var_id`),
  UNIQUE KEY `var_id_mod_dttm` (`var_val_id`,`var_mod_dttm`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;

/*Data for the table `var_value_archive` */

insert  into `var_value_archive`(`var_id`,`var_val_id`,`var_encode`,`var_mod_dttm`,`var_value`) values (1,1,0,'2012-04-16 19:58:05','alpha ****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************bye dewey*******'),(2,2,0,'2012-04-16 19:58:05','albany'),(3,3,0,'2012-04-16 19:58:05','10'),(4,4,0,'2012-04-16 19:58:05','adam');

/* Function  structure for function  `hashIt` */

/*!50003 DROP FUNCTION IF EXISTS `hashIt` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` FUNCTION `hashIt`(p_value varchar(140), p_salt VARCHAR(4)) RETURNS varchar(140) CHARSET utf8
    DETERMINISTIC
    COMMENT 'hashed val'
BEGIN
/* select hashIt('user', '') as A;
*/
	set p_salt = if(p_salt='','AB',p_salt);
	return concat('hs-',p_value); -- just prove that it's working; dont hash yet
END */$$
DELIMITER ;

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

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `createEntity`(IN p_ent_type VARCHAR(40), IN p_xxx_id BIGINT, IN p_com_id int, IN p_encode TINYINT, inout p_ent_id bigint)
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
			(ent_ety_id, ent_xxx_id, ent_com_id, ent_encode)
	values (v_ety_id, p_xxx_id, p_com_id, p_encode);
	Set p_ent_id = last_insert_id(); -- this is my OUT param
END */$$
DELIMITER ;

/* Procedure structure for procedure `loadAllAtts` */

/*!50003 DROP PROCEDURE IF EXISTS  `loadAllAtts` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `loadAllAtts`(in p_ent_id bigint, In p_ent_ety_id int, IN p_ent_com_id INT, In p_domain_list varchar(80), In p_encode tinyint)
    MODIFIES SQL DATA
    COMMENT 'loads atts for specified entity'
BEGIN
	/*	call loadAllAtts();
	*/
	if exists(SELECT 1 FROM att.ent_entity WHERE ent_id = p_ent_id AND ent_com_id = p_ent_com_id AND ent_ety_id = p_ent_ety_id) then
		SELECT straight_join
			V.val_id, D.dxa_dom_name as dom_name, A.att_name, A.att_id
			, coalesce(L.lva_value, V.val_value) as val_value
			, V.val_version, V.val_mod_dttm, V.val_encode
			-- , dxa_dom_id, dxa_att_id, dxa_dty_id, dxa_att_is_long, dxa_att_is_mult, dxa_att_to_hash, dxa_att_to_version, dxa_encode, dxa_hash_salt
		FROM val_value V
		JOIN att_attribute A ON A.att_id = V.val_att_id
		join dxa_domain_x_attribute D On D.dxa_att_id = V.val_att_id and D.dxa_dom_id = V.val_dom_id
		LEFT OUTER JOIN lva_long_value L
			ON left(V.val_value,2) = '-1' and L.lva_val_id = V.val_id
		WHERE V.val_ent_id = p_ent_id; -- or V.val_dom_id in (1);
	end if;
END */$$
DELIMITER ;

/* Procedure structure for procedure `loadEntity` */

/*!50003 DROP PROCEDURE IF EXISTS  `loadEntity` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `loadEntity`(in p_ent_type varchar(40), In p_xxx_id bigint, IN p_com_id INT, In p_encode tinyint)
    MODIFIES SQL DATA
    COMMENT 'finds entity & creates if missing'
BEGIN
/*	call loadEntity('user',12,14, 0);
*/
	declare v_ent_id, v_ent_xxx_id, v_ent_com_id bigint default 0;
	Declare v_not_exists, v_ent_ety_id, v_temp_ent_ety_id, v_ent_encode smallint default 0;
	DECLARE invalid_type_value CONDITION FOR 45000;
	declare continue handler for not found Begin Set v_not_exists = 1; end;
	
	set v_temp_ent_ety_id = lookupEntityType(p_ent_type,0);
	if v_temp_ent_ety_id < 1 then
		call raiseError(45000, concat('invalid entity type passed=',p_ent_type) ,0);
	end if;
	SELECT ent_id, ent_xxx_id, ent_ety_id, ent_com_id, ent_encode
	into v_ent_id, v_ent_xxx_id, v_ent_ety_id, v_ent_com_id, v_ent_encode
	FROM ent_entity
	where ent_xxx_id = p_xxx_id and ent_com_id = p_com_id
	and ent_ety_id = v_temp_ent_ety_id;
	
	if v_not_exists then
		set v_ent_id = v_temp_ent_ety_id; -- type lookup already done, so reuse it
		call createEntity(p_ent_type, p_xxx_id, p_com_id, p_encode, v_ent_id);
		-- v_ent_id is an out param with the id
		-- load vars as if initial select above had worked
		set v_ent_xxx_id = p_xxx_id, v_ent_ety_id = v_temp_ent_ety_id, v_ent_com_id = p_com_id, v_ent_encode = 0;
	END IF;
	-- query only using vars to avoid hitting disk again
	SELECT v_ent_id as ent_id, v_ent_xxx_id as ent_xxx_id, v_ent_ety_id as ent_ety_id, v_ent_com_id as ent_com_id, v_ent_encode as ent_encode;
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

/* Procedure structure for procedure `spTest` */

/*!50003 DROP PROCEDURE IF EXISTS  `spTest` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `spTest`(IN p_encode TINYINT)
    MODIFIES SQL DATA
    COMMENT 'store all passed atts'
BEGIN
/* call spTest(0);
*/
	Select dom_id, dom_name from dom_domain;
	
	Select cast(1 as unsigned) as A union select 2 union select 3;
END */$$
DELIMITER ;

/* Procedure structure for procedure `storeAtts` */

/*!50003 DROP PROCEDURE IF EXISTS  `storeAtts` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `storeAtts`(IN p_ent_id BIGINT, IN p_com_id int, IN p_row_count int, IN p_1 TINYINT, IN p_2 TINYINT, IN p_3 TINYINT, IN p_encode TINYINT)
    MODIFIES SQL DATA
    COMMENT 'store all passed atts'
BEGIN
/* call storeAtts(p_ent_id, p_com_id, p_row_count, 0,0,0, p_encode);
*/
	DECLARE v_inst_updt_count MEDIUMINT DEFAULT 0;
	declare exit handler for 1146 begin call raiseError(1146,'priv sess table _att_stage missing',0); End;
	-- *************  test code:  create missing dom & att vals so update join below works
	-- call zadm_createMissingVals(0);
	-- ************* end test code
	
	-- lookup fkey vals only once & update an un-contended table
	update _att_stage S
	STRAIGHT_JOIN dom_domain D ON D.dom_name = S.ats_dom_name
	JOIN att_attribute A ON A.att_name = S.ats_att_name
	-- don't FORCE a rec to exist in the dxa table...it's optional to overide defaults at the att or dom level
	LEFT OUTER JOIN dxa_dom_x_att X On X.dxa_dom_id = D.dom_id and X.dxa_att_id = A.att_id
	set S.ats_dom_name = D.dom_id
	, S.ats_att_name = A.att_id
	-- , S.ats_keep_old = if(S.ats_keep_old,1,COALESCE(X.dxa_att_keep_old, A.att_keep_old, 0)) -- was set by the caller
	, S.ats_is_long = LENGTH(S.ats_value) > 140 -- will update every row where att_name & dom_name is valid
	, S.ats_is_multi = coalesce(X.dxa_att_is_multi,0)
	, S.ats_hash_it = COALESCE(X.dxa_att_hash_it, A.att_hash_it, 0);
	-- after the update above, my ats_???_name cols now contain their respective ID's
	if row_count() < p_row_count then
		call raiseError(45000, 'att_name or dom_name passed does not exist in the db', 0);
	end if;
	
	-- Select ats_att_name, ats_dom_name, ats_value from _att_stage; -- test code only
	-- archive old values if specified and if value has changed
	INSERT ignore INTO att.var_value_archive -- ignore for date time conflicts
		(var_val_id, var_value, var_encode)
		SELECT straight_join V.val_id, coalesce(L.lva_value, V.val_value), V.val_encode
		FROM _att_stage S
		JOIN val_value V on V.val_dom_id = S.ats_dom_name and V.val_att_id = S.ats_att_name
			and V.val_ent_id = p_ent_id
		LEFT OUTER JOIN lva_long_value L on left(V.val_value,2) = '-1' and L.lva_val_id = V.val_id
		where S.ats_keep_old -- was set by the caller or settings in dxa_dom_x_att or att_attribute respectively
				-- only create archive rec if value has changed
			and (L.lva_val_id IS NULL and V.val_value <> S.ats_value
				or L.lva_val_id is not null and L.lva_value <> S.ats_value);
	INSERT INTO val_value
	(val_ent_id, val_dom_id, val_att_id, val_mod_dttm, val_value)
		SELECT p_ent_id, S.ats_dom_name, S.ats_att_name, now()
		, if(S.ats_is_long, -1, if(S.ats_hash_it, hashIt(S.ats_value, 'AB'), S.ats_value)) as val_value
			-- , ats_keep_old
		FROM _att_stage S
		-- Join	dom_domain D On D.dom_name = S.ats_dom_name
		-- join att_attribute A on A.att_name = S.ats_att_name
		-- where length(ats_value) < 141
		On duplicate key update val_value = values(val_value); -- val_mod_dttm set automatically
	
	Set v_inst_updt_count = row_count(); -- not accurate due to "ON DUPLICATE KEY UPDATE" returning 2
	
	-- now store long vals
	INSERT INTO lva_long_value
		(lva_val_id, lva_value)
		SELECT straight_join V.val_id, S.ats_value
		FROM _att_stage S
		Join val_value V On V.val_ent_id = p_ent_id and V.val_dom_id = S.ats_dom_name
			and V.val_att_id = S.ats_att_name
		where S.ats_is_long
		ON DUPLICATE KEY UPDATE lva_value = VALUES(lva_value);
	
	-- don't count recs in lva_long_value because the val_value = -1 rec in val_value was already counted
	-- SET v_inst_updt_count = v_inst_updt_count + ROW_COUNT();
	
	if false and v_inst_updt_count <> p_row_count then -- not accurate due to "ON DUPLICATE KEY UPDATE" returning 2
		CALL raiseError(45000, concat('recs passed =',p_row_count,';  recs updated=',v_inst_updt_count,';  they should match'), 0);
	end if;
	
	truncate table _att_stage; -- clear for next call
	Select v_inst_updt_count as rowcount;
END */$$
DELIMITER ;

/* Procedure structure for procedure `zadm_createMissingVals` */

/*!50003 DROP PROCEDURE IF EXISTS  `zadm_createMissingVals` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `zadm_createMissingVals`(IN p_encode TINYINT)
    MODIFIES SQL DATA
    COMMENT 'store all passed atts'
BEGIN
/* call zadm_createMissingVals(0);
*/
	-- DECLARE EXIT HANDLER FOR 1146 BEGIN  END;
	
	-- this proc throws warnings when it tries to cast string as int
	INSERT IGNORE INTO att.att_attribute
		(att_name)
		SELECT DISTINCT ats_att_name FROM _att_stage where cast(ats_att_name as unsigned) in (0,null);
	INSERT IGNORE INTO att.dom_domain
		(dom_name)
		SELECT DISTINCT ats_dom_name FROM _att_stage WHERE CAST(ats_dom_name AS UNSIGNED) IN (0,NULL);
END */$$
DELIMITER ;

/* Procedure structure for procedure `zadm_truncTables` */

/*!50003 DROP PROCEDURE IF EXISTS  `zadm_truncTables` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `zadm_truncTables`(IN p_encode TINYINT)
    MODIFIES SQL DATA
    COMMENT 'szadm_truncTables'
BEGIN
/* call zadm_truncTables(0);
*/
	truncate table val_value;
	TRUNCATE TABLE lva_long_value;
	TRUNCATE TABLE var_value_archive;
END */$$
DELIMITER ;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
