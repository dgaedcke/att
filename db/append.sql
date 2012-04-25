ALTER TABLE `att`.`ent_entity` DROP KEY `type_rec_id`, ADD UNIQUE `type_rec_id` (`ent_com_id`, `ent_ety_id`, `ent_xxx_id`);

/*!40101 SET NAMES utf8 */;



/*!40101 SET SQL_MODE=''*/;



/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;

/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE /*!32312 IF NOT EXISTS*/`att` /*!40100 DEFAULT CHARACTER SET utf8 */;



/* Function  structure for function  `fwwq` */



/*!50003 DROP FUNCTION IF EXISTS `fwwq` */;

DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`localhost` FUNCTION `fwwq`(pString Varchar(440), pEncode Tinyint) RETURNS varchar(450) CHARSET latin1
    NO SQL
    COMMENT 'wraps str in ""'
BEGIN
/*	Select fwwq('str',0);
	if 1&pEncode=1 then replace parens with {}
*/
	Set pString = If(1&pEncode,Replace(Replace(pString,'(','{'),')','}'),pString);
	Return Concat('"',pString,'"');
END */$$

DELIMITER ;



/* Function  structure for function  `f_User_ShashPW` */



/*!50003 DROP FUNCTION IF EXISTS `f_User_ShashPW` */;

DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`localhost` FUNCTION `f_User_ShashPW`(pUserSalt Char(2), pPWLiteralString Varchar(32)
	, pEncode Tinyint) RETURNS char(40) CHARSET latin1
    READS SQL DATA
    DETERMINISTIC
BEGIN
/*	Select f_User_ShashPW(USE_PW_Salt,'pw_string_literal',0) as HashedPW_as_Stored;
*/
	Return SHA1(concat(pUserSalt,pPWLiteralString));
END */$$

DELIMITER ;



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



/* Procedure structure for procedure `loadAttHistory` */



/*!50003 DROP PROCEDURE IF EXISTS  `loadAttHistory` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `loadAttHistory`(in p_ent_id bigint, In p_ent_ety_id int, IN p_ent_com_id INT
	, In p_att_list_or_dom_name varchar(600), In p_att_count smallint, In p_encode tinyint)
    READS SQL DATA
    COMMENT 'loads specified att (by domain) history'
sproc:BEGIN
	/*	this proc has same param and return signature as loadAtts()
	EXCEPT that it will return multiple-values per attribute if an archive exists
	otherwise it return the current and only value for the attribute
	
	call loadAttHistory(p_ent_id, p_ent_ety_id, p_ent_com_id, p_att_list_or_dom_name, p_att_count, p_encode);
format for p_att_list_or_dom_name is crucial!!  field_delim = : and row_delim = ,
so vals should come in looking like:  domain_name:attribute_name(comma)dom2:att2
		for example:
			preference:name,attribute:age,attribute:handle....etc
	*/
	declare v_dom_id int default 0;
	declare v_fld_delim, v_row_delim char(1) default ':';
	set v_row_delim = ',';
	
	if not exists(SELECT 1 FROM att.ent_entity WHERE ent_id = p_ent_id AND ent_com_id = p_ent_com_id AND ent_ety_id = p_ent_ety_id) then
		leave sproc;
	end if;
	
	-- both queries below must maintain identical return signature
	if locate(v_fld_delim,p_att_list_or_dom_name) = 0 then -- query ONLY by domain name
		if length(p_att_list_or_dom_name) > 2 then -- 3 is shortest length for a domain name
			set v_dom_id = lookupDomainType(p_att_list_or_dom_name,0);
		end if;
		SELECT STRAIGHT_JOIN D.dom_name as domain, A.att_name as attribute_name
		, COALESCE(R.var_value, V.val_value) as att_value
		, coalesce(Y.dty_name,'string') as data_type
		, COALESCE(R.var_mod_dttm, V.val_mod_dttm) as val_mod_dttm
		, V.val_id
		from val_value V 
		join dom_domain D on D.dom_id = V.val_dom_id
		Join att_attribute A on A.att_id = V.val_att_id
		LEFT OUTER JOIN var_value_archive R on R.var_val_id = V.val_id
		left outer join dxa_dom_x_att M On M.dxa_dom_id = V.val_dom_id and M.dxa_att_id = V.val_att_id
		LEFT OUTER JOIN dty_data_type Y ON Y.dty_id = Coalesce(M.dxa_dty_id, A.att_dty_id)
		where V.val_ent_id = p_ent_id AND V.val_dom_id = if(v_dom_id,v_dom_id,V.val_dom_id);
	
	else -- query by specific domain and attribute names
-- if clause handles security making sure that only authorized calls can read the atts
		SELECT STRAIGHT_JOIN S.dom_name  AS domain, S.att_name  AS attribute_name
			, COALESCE(R.var_value, V.val_value) AS att_value
			, COALESCE(Y.dty_name,'string') AS data_type
			, COALESCE(R.var_mod_dttm, V.val_mod_dttm) AS val_mod_dttm
			, V.val_id
		FROM (SELECT A.att_id, D.dom_id, T.att_name, T.dom_name, COALESCE(X.dxa_dty_id, A.att_dty_id) AS dty_id
				FROM (
					SELECT SQL_NO_CACHE
						SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_list_or_dom_name,v_fld_delim,m.id),v_row_delim,-1) AS dom_name
						, SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_list_or_dom_name,v_row_delim,m.id),v_fld_delim,-1) AS att_name
					FROM memT100 m WHERE m.id <= p_att_count
					)
				AS T
			JOIN att_attribute A ON A.att_name = T.att_name
			JOIN dom_domain D ON D.dom_name = T.dom_name
			LEFT OUTER JOIN dxa_dom_x_att X ON X.dxa_att_id = A.att_id AND X.dxa_dom_id = D.dom_id
			)
		AS S
		JOIN val_value V ON V.val_ent_id = p_ent_id AND V.val_att_id = S.att_id AND V.val_dom_id = S.dom_id
		LEFT OUTER JOIN dty_data_type Y ON Y.dty_id = S.dty_id
		LEFT OUTER JOIN var_value_archive R ON R.var_val_id = V.val_id;
	End if;
END */$$

DELIMITER ;



/* Procedure structure for procedure `loadAtts` */



/*!50003 DROP PROCEDURE IF EXISTS  `loadAtts` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `loadAtts`(in p_ent_id bigint, In p_ent_ety_id int, IN p_ent_com_id INT
	, In p_att_list_or_dom_name varchar(600), In p_att_count smallint, In p_encode tinyint)
    READS SQL DATA
    COMMENT 'loads specified atts by domain'
sproc:BEGIN
	/*	call loadAtts(p_ent_id, p_ent_ety_id, p_ent_com_id, p_att_list_or_dom_name, p_att_count, p_encode);
format for p_att_list_or_dom_name is crucial!!  field_delim = : and row_delim = ,
so vals should come in looking like:  domain_name:attribute_name(comma)dom2:att2
		for example:
			preference:name,attribute:age,attribute:handle....etc
	*/
	declare v_dom_id int default 0;
	declare v_fld_delim, v_row_delim char(1) default ':';
	set v_row_delim = ',';
	
	if not exists(SELECT 1 FROM att.ent_entity WHERE ent_id = p_ent_id AND ent_com_id = p_ent_com_id AND ent_ety_id = p_ent_ety_id) then
		leave sproc;
	end if;
	
	-- both queries below must maintain identical return signature
	if locate(v_fld_delim,p_att_list_or_dom_name) = 0 then -- query ONLY by domain name
		if length(p_att_list_or_dom_name) > 2 then -- 3 is shortest length for a domain name
			set v_dom_id = lookupDomainType(p_att_list_or_dom_name,0);
		end if;
		SELECT STRAIGHT_JOIN D.dom_name as domain, A.att_name as attribute_name
		, COALESCE(L.lva_value, V.val_value) as att_value
		, coalesce(Y.dty_name,'string') as data_type
		, V.val_mod_dttm, V.val_id
		from val_value V 
		join dom_domain D on D.dom_id = V.val_dom_id
		Join att_attribute A on A.att_id = V.val_att_id
		left outer join dxa_dom_x_att M On M.dxa_dom_id = V.val_dom_id and M.dxa_att_id = V.val_att_id
		LEFT OUTER JOIN dty_data_type Y ON Y.dty_id = Coalesce(M.dxa_dty_id, A.att_dty_id)
		LEFT OUTER JOIN lva_long_value L ON left(V.val_value,2) = '-1' and L.lva_val_id = V.val_id
		where V.val_ent_id = p_ent_id AND V.val_dom_id = if(v_dom_id,v_dom_id,V.val_dom_id);
	
	else -- query by specific domain and attribute names
-- if clause handles security making sure that only authorized calls can read the atts
		SELECT STRAIGHT_JOIN S.dom_name  AS domain, S.att_name  AS attribute_name
			, COALESCE(L.lva_value, V.val_value) AS att_value
			, COALESCE(Y.dty_name,'string') AS data_type
			, V.val_mod_dttm, V.val_id
		FROM (SELECT A.att_id, D.dom_id, T.att_name, T.dom_name, COALESCE(X.dxa_dty_id, A.att_dty_id) AS dty_id
				FROM (
					SELECT SQL_NO_CACHE
						SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_list_or_dom_name,v_fld_delim,m.id),v_row_delim,-1) AS dom_name
						, SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_list_or_dom_name,v_row_delim,m.id),v_fld_delim,-1) AS att_name
					FROM memT100 m WHERE m.id <= p_att_count
					)
				AS T
			JOIN att_attribute A ON A.att_name = T.att_name
			JOIN dom_domain D ON D.dom_name = T.dom_name
			LEFT OUTER JOIN dxa_dom_x_att X ON X.dxa_att_id = A.att_id AND X.dxa_dom_id = D.dom_id
			)
		AS S
		JOIN val_value V ON V.val_ent_id = p_ent_id AND V.val_att_id = S.att_id AND V.val_dom_id = S.dom_id
		LEFT OUTER JOIN dty_data_type Y ON Y.dty_id = S.dty_id
		LEFT OUTER JOIN lva_long_value L ON LEFT(V.val_value,2) = '-1' AND L.lva_val_id = V.val_id;
	End if;
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



/* Procedure structure for procedure `niu_loadAllAtts` */



/*!50003 DROP PROCEDURE IF EXISTS  `niu_loadAllAtts` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `niu_loadAllAtts`(in p_ent_id bigint, In p_ent_ety_id int
	, IN p_ent_com_id INT, In p_encode tinyint)
    READS SQL DATA
    COMMENT 'loads atts for specified entity'
BEGIN
	/*	this proc is NIU
	call loadAllAtts(p_ent_id, p_ent_ety_id, p_ent_com_id, p_domain_list, p_encode);
	*/
	call loadAtts(p_ent_id, p_ent_ety_id, p_ent_com_id, '', 0, 0);
	/*
	-- old code NIU below
	if exists(SELECT 1 FROM att.ent_entity WHERE ent_id = p_ent_id AND ent_com_id = p_ent_com_id AND ent_ety_id = p_ent_ety_id) then
		SELECT STRAIGHT_JOIN
			V.val_id, M.dom_name, A.att_name
			, COALESCE(L.lva_value, V.val_value) AS val_value
			, V.val_mod_dttm, V.val_encode
			-- , A.att_id, M.dom_id, V.val_version
			-- , dxa_dom_id, dxa_att_id, dxa_dty_id, dxa_att_is_long, dxa_att_is_mult, dxa_att_to_hash, dxa_att_to_version, dxa_encode, dxa_hash_salt
		FROM val_value V
		JOIN att_attribute A ON A.att_id = V.val_att_id
		JOIN dom_domain M ON M.dom_id = V.val_dom_id
		LEFT OUTER JOIN dxa_dom_x_att D ON D.dxa_att_id = V.val_att_id AND D.dxa_dom_id = V.val_dom_id
		LEFT OUTER JOIN lva_long_value L
			ON LEFT(V.val_value,2) = '-1' AND L.lva_val_id = V.val_id
		WHERE V.val_ent_id = p_ent_id; -- or V.val_dom_id in (1);
	end if;
	*/
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
	-- declare MESSAGE_TEXT varchar(200);
	-- SIGNAL SQLSTATE '45000';
	-- SET MESSAGE_TEXT = p_err_msg;
	call up_Signal_Error(p_sql_state,p_err_msg,'_proc?','','');
END */$$

DELIMITER ;



/* Procedure structure for procedure `searchForEntity` */



/*!50003 DROP PROCEDURE IF EXISTS  `searchForEntity` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`%` PROCEDURE `searchForEntity`(IN p_ent_type VARCHAR(40)
	, IN p_dom_name VARCHAR(40), IN p_att_and_val_list VARCHAR(600), in p_att_srch_count tinyint
	, IN p_com_id int, IN p_encode TINYINT)
    READS SQL DATA
    COMMENT 'find entity by type, attr & value'
BEGIN
/*  CALL searchForEntity(p_ent_type, p_dom_name, p_att_and_val_list, p_att_srch_count, p_com_id, p_encode);
	CALL searchForEntity('user', 'attribute', 'name:dewey gaedcke,age:39,dob:11081963,sex:m,', 4, 3, 0);
	search can consider or ignore company scope but looks primarily by entity type and attribute name
*/
	declare v_dom_id, v_ent_ety_id int default 0;
	DECLARE v_fld_delim, v_row_delim CHAR(1) DEFAULT ':';
	SET v_row_delim = ',', v_ent_ety_id = lookupEntityType(p_ent_type, 0), v_dom_id = lookupDomainType(p_dom_name,0);
	-- if p_com_id > 0 then -- search scope limited to company
	
	/* DECLARE v_att_name, v_val_value VARCHAR(140) DEFAULT '';
		IF p_att_srch_count = 1 THEN -- query ONLY by one att & value
		set v_att_name = SUBSTRING_INDEX(p_att_and_val_list,v_fld_delim,1)
			, v_val_value = SUBSTRING_INDEX(p_att_and_val_list,v_fld_delim,-1);
	end if; */
	/*
	SELECT SQL_NO_CACHE
				SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_and_val_list,v_fld_delim,m.id),v_row_delim,-1) AS att_name
				, SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_and_val_list,v_row_delim,m.id),v_fld_delim,-1) AS val_value
			FROM memT100 m WHERE m.id <= p_att_srch_count;
	*/
	SELECT straight_join Y.ent_xxx_id as xxx_id, count(*) as matchCount -- xxx_id is the rec_id in remote table in p_ent_type
		FROM (
			SELECT SQL_NO_CACHE
				SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_and_val_list,v_fld_delim,m.id),v_row_delim,-1) AS att_name
				, SUBSTRING_INDEX(SUBSTRING_INDEX(p_att_and_val_list,v_row_delim,m.id),v_fld_delim,-1) AS val_value
			FROM memT100 m WHERE m.id <= p_att_srch_count
			)
		AS T
	-- JOIN dom_domain D ON D.dom_id = v_dom_id -- not necessary since all search atts in same domain
	JOIN att_attribute A ON A.att_name = T.att_name
	JOIN val_value V ON V.val_att_id = A.att_id AND V.val_dom_id = v_dom_id
		and (V.val_value = T.val_value or left(V.val_value,2) = '-1')
	-- un comment next lines (+ in where clause) after basic testing to handle long val comparison
	/* left outer join lva_long_value L on LEFT(V.val_value,2) = '-1'
		and L.lva_val_id = V.val_id and L.lva_value = T.val_value */
	join ent_entity Y on Y.ent_id = V.val_ent_id and Y.ent_ety_id = v_ent_ety_id
		and Y.ent_com_id = if(p_com_id>0,p_com_id, Y.ent_com_id) -- restrict to entities in same company
	where left(V.val_value,2) <> '-1' -- or L.lva_val_id is not null
	group by V.val_ent_id having matchCount >= p_att_srch_count; 
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
sproc:BEGIN
/* call storeAtts(p_ent_id, p_com_id, p_row_count, 0,0,0, p_encode);
	pass 16 into p_encode to get some test data back
	pass 32 to DELETE ALL persistent storage and start over;  for testing only
	code for 32 is commented out by default and should be left that way
*/
	DECLARE v_inst_updt_count, v_test_mode MEDIUMINT DEFAULT 0;
	declare exit handler for 1146 begin call raiseError(1146,'priv sess table _att_stage missing',0); End;
	DECLARE EXIT HANDLER FOR 45000 BEGIN END; -- my custom err handler
	
	if not exists(SELECT 1 FROM att.ent_entity WHERE ent_id = p_ent_id AND ent_com_id = p_com_id) then
		Leave sproc; -- bail out if entity not exists or not at this company
	end if;
	
	-- *************  test code:  create missing dom & att vals so update join below works
	if 32&p_encode = 32 then -- SERIOUS DANGER; DELETES ALL data from storage;
		SET v_test_mode = v_test_mode;
		-- CALL zadm_truncTables(0); -- SERIOUS DANGER; DELETES ALL data from storage;
	end if;
	set v_test_mode = 16&p_encode = 16;
	if TRUE OR v_test_mode then -- will create missing attribute or domain names
		-- ONLY to ease Phu testing;  disable for production
		call zadm_createMissingVals(0);
	end if;
	-- ************* end test code
	
	-- lookup fkey vals only once & update an un-contended (prob-in memory) table
	update _att_stage S
	STRAIGHT_JOIN dom_domain D ON D.dom_name = S.ats_dom_name
	JOIN att_attribute A ON A.att_name = S.ats_att_name
	-- don't FORCE a rec to exist in the dxa table...it's optional to overide defaults at the att or dom level
	LEFT OUTER JOIN dxa_dom_x_att X On X.dxa_dom_id = D.dom_id and X.dxa_att_id = A.att_id
	set S.ats_dom_name = D.dom_id
	, S.ats_att_name = A.att_id
	-- , S.ats_keep_old = if(S.ats_keep_old,1,COALESCE(X.dxa_att_keep_old, A.att_keep_old, 0)) -- was set by the caller
	, S.ats_is_long = LENGTH(left(S.ats_value,142)) > 140 -- will update every row where att_name & dom_name is valid
	, S.ats_is_multi = coalesce(X.dxa_att_is_multi,0)
	, S.ats_hash_it = COALESCE(X.dxa_att_hash_it, A.att_hash_it, 0);
	-- after the update above, my ats_???_name cols now contain their respective ID's
	if row_count() < p_row_count then
		call raiseError(45000, 'att or dom_name passed does not exist in the db', 0);
	end if;
	
	IF v_test_mode THEN -- show table before inserts/ updates are run for testing
		Select ats_att_name, ats_dom_name, ats_value from _att_stage; -- test code only
	end if;
	-- archive old values if specified and if value has changed
	INSERT ignore INTO var_value_archive -- ignore for date time conflicts
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
			(val_ent_id, val_dom_id, val_att_id, val_value)
		SELECT p_ent_id, S.ats_dom_name, S.ats_att_name
		, if(S.ats_is_long, -1, if(S.ats_hash_it, hashIt(S.ats_value, 'AB'), S.ats_value)) as val_value
			-- , S.ats_keep_old
		FROM _att_stage S
		On duplicate key update val_value = values(val_value); -- val_mod_dttm set automatically ONLY if value is new
	
	Set v_inst_updt_count = row_count(); -- not accurate due to "ON DUPLICATE KEY UPDATE" returning 2; could be > than p_row_count
	
	-- recs may not be updated because vals have not changed & thus count will be low
	IF false and v_inst_updt_count < p_row_count THEN -- must b >=;  ROW_COUNT not accurate due to "ON DUPLICATE KEY UPDATE" returning 2
		CALL raiseError(45000, CONCAT('recs passed =',p_row_count,';  recs updated=',v_inst_updt_count,';  they should match'), 0);
	END IF;
	
	-- now store long vals
	INSERT INTO lva_long_value
		(lva_val_id, lva_value)
		SELECT straight_join V.val_id, IF(S.ats_hash_it, hashIt(S.ats_value, 'AB'), S.ats_value)
		FROM _att_stage S
		Join val_value V On V.val_ent_id = p_ent_id and V.val_dom_id = S.ats_dom_name
			and V.val_att_id = S.ats_att_name
		where S.ats_is_long
		ON DUPLICATE KEY UPDATE lva_value = VALUES(lva_value);
	
	-- don't count recs in lva_long_value because the val_value = -1 rec in val_value was already counted
	-- SET v_inst_updt_count = v_inst_updt_count + ROW_COUNT();
	
	truncate table _att_stage; -- clear vals for next call
	
	-- not accurate due to "ON DUPLICATE KEY UPDATE" returning 2; lowest value is accurate
	Select least(p_row_count, v_inst_updt_count) as rowcount;
END */$$

DELIMITER ;



/* Procedure structure for procedure `up_SessInit_Connect` */



/*!50003 DROP PROCEDURE IF EXISTS  `up_SessInit_Connect` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`localhost` PROCEDURE `up_SessInit_Connect`(In pCond Int)
    READS SQL DATA
    COMMENT 'this proc runs once for every user session that connects'
Init:BEGIN
If Left(User(),5) not in ('dewey','mad01') then
/*	bail out for "repl" and "nagios" users
	SUPER accounts do not call init-connect so this code does not run for dewey */
	Leave Init;
End if;
/*	this proc need only run for application connections
	all active session @vars should be documented and intialized here 
	turn on Auto Committ mode for InnoDB in case server defaul fails  
call up_SessInit_Connect(1);
*/
-- SET SESSION AUTOCOMMIT = 1;
Set SQL_LOG_BIN = 0, SQL_NOTES = 0;
/*	dont log any common or temp table stuff to the bin log; it should not replicate
	Set session wait_timeout = 7200;  also turn off logging of notes for the app session
	mysql will disconnect idle sessions after 2 hrs; app is set to validate every 6k secs
	Site specific
	@Sites_UserAttachable = current list of end user attachable sites
	@Sites_SupportMstream = sites that we currently scrape for newsfeed
*/
/*
	the following memory table is a global array used for all sorts of processing
	be VERY CAREFUL before making any changes to ttLabelValue
If common.uf_Table_DoesExist('ttLabelValue','common',0) then
End if;
*/
set autocommit=1; # turn on autocommit
CREATE TEMPORARY TABLE IF NOT EXISTS ttLabelValue LIKE _tpl_ttLabelValue;
CREATE TEMPORARY TABLE IF NOT EXISTS _att_stage LIKE _tpl_att_stage;
/*	
	perf test code below		slight perf loss  do not use this until 5.1 */
/*	Prepare parseArray from "INSERT INTO common.ttLabelValue
         (ttlabel,ttvalue)
         select SQL_NO_CACHE SUBSTRING_INDEX(SUBSTRING_INDEX(?,':',m.id),'/',-1)
                , SUBSTRING_INDEX(SUBSTRING_INDEX(?,'/',m.id),':',-1)
         from memT100 m where m.id <= ?;"; */
-- Execute parseArray Using @pMapKeys, @pMapKeys, @vValueCount;
If not Exists(Select 1 from memT100 where id = 500) then
	Call zdm_memT100_Init(1000,0);
End if;
SET storage_engine=DEFAULT; -- I dont think this is necessary as no new tables should be created by this session
Set SQL_LOG_BIN = 1;
END */$$

DELIMITER ;



/* Procedure structure for procedure `up_Signal_Error` */



/*!50003 DROP PROCEDURE IF EXISTS  `up_Signal_Error` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`localhost` PROCEDURE `up_Signal_Error`(In pErrCode Int, In pErrMsg VarChar(350), In pCallingProc Char(20)
, In pExtr2 Char(10), In pExtr3 Char(10))
    READS SQL DATA
    COMMENT 'throws error back to calling app'
BEGIN
Set SQL_LOG_BIN = 1;
/*	all loggin and cleanup is done BEFORE this proc is called in mstats.p_SP_Err_LogOrSignal()
	call up_Signal_Error(10,'pivot tbl memT100 not inited at server boot','p_MSFL_Add_inBulk','','LOG');
	table names cannot be longer than 64 but err 1103 (incorrect table name) can show more text */
Set pErrMsg = If(pErrMsg='','no_msg?',pErrMsg);
-- Set pErrMsg = Left(Concat_WS('_',pErrMsg,pErrCode,pCallingProc),64);
	Set pErrMsg = Replace(Replace(pErrMsg,' ','_'),'-','_'); -- spaces & hyphens cause a syntax error
	Set pErrMsg = Replace(pErrMsg,'__','_');
	Set pErrMsg = Replace(pErrMsg,'__','_');
	Set @equery = Concat('Update ',pErrMsg,' Set Err=1');
	Prepare sig_err from @equery;
	Execute sig_err;
	Deallocate Prepare sig_err;
END */$$

DELIMITER ;



/* Procedure structure for procedure `up_SplitStr` */



/*!50003 DROP PROCEDURE IF EXISTS  `up_SplitStr` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`localhost` PROCEDURE `up_SplitStr`(IN pMapKeys Varchar(1600),
       IN fldDelim CHAR(2), IN rowDelim CHAR(2), OUT pNumKeysInserted INTEGER, IN pAppendList Boolean)
    READS SQL DATA
    COMMENT 'Splits a supplied string using using the given fldDelim & rowDel'
BEGIN
/*	Call up_SplitStr('1:one/2:two/3:three/',':','/',@a,0);
	Important---this routine is 110% performance optimization--there are 1000 rows in t100 */
Declare  vValueCount int default 0;
/* handler should only necessary until we've fully validated that init_connect
always creates ttLabelValue for each session as they connect */
Declare Continue Handler for 1146
	Begin
		call up_Sess_LogError(1146,'up_SplitStr','ttLabelValue doesnt exist',1,'');
		Set SQL_LOG_BIN = 1;
	End;
Set SQL_LOG_BIN = 0;
If not(pAppendList) then
   Truncate TABLE ttLabelValue;  /* if fails, it's supposed to call Handler 1146 above---being inside IF puts that at risk */
End if;      /* right now, there is no scenario where it gets called FIRST time with pAppendList = 1 */
Set vValueCount = length(pMapKeys) - length(replace(pMapKeys,rowDelim,'')) ;  /* must come before TRIM or count off by 1 */
Set pMapKeys = Trim(Trailing rowDelim from pMapKeys);
/* Set cur_label = ELT(abs(cur_label)>0+1,ELT(pNumKeysInserted + 1,cur_label,f_AttLabelGetID(cur_label)),cur_label) ; 
f_AttLabelGetID  */
         INSERT INTO ttLabelValue
         (ttlabel,ttvalue)
         select SQL_NO_CACHE SUBSTRING_INDEX(SUBSTRING_INDEX(pMapKeys,fldDelim,m.id),rowDelim,-1)
                , SUBSTRING_INDEX(SUBSTRING_INDEX(pMapKeys,rowDelim,m.id),fldDelim,-1)
         from minggl.memT100 m where m.id <= vValueCount;
If pAppendList = 0 then
   SET pNumKeysInserted = row_count(); /* Return # of rows just added to the table */
Else
    Select SQL_NO_CACHE count(*) into pNumKeysInserted from ttLabelValue ;
End if ;
Set SQL_LOG_BIN = 1; /*	this cmd is messing up the Row_Count() function it seems
		Select ttlabel, ttValue from ttLabelValue;    */
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
	REGEX tester:  SELECT NOT 'SOME5123' REGEXP '^[0-9]+$' AS A;
*/
	-- DECLARE EXIT HANDLER FOR 1146 BEGIN  END;
	
	-- this proc throws warnings when it tries to cast string as int
	INSERT IGNORE INTO att.att_attribute
		(att_name)
		-- find recs where ats_att_name is NOT already an int
		SELECT DISTINCT ats_att_name FROM _att_stage where not ats_att_name REGEXP '^[0-9]+$';
	INSERT IGNORE INTO att.dom_domain
		(dom_name)
		SELECT DISTINCT ats_dom_name FROM _att_stage WHERE not ats_dom_name REGEXP '^[0-9]+$';
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



/* Procedure structure for procedure `zdm_memT100_Init` */



/*!50003 DROP PROCEDURE IF EXISTS  `zdm_memT100_Init` */;



DELIMITER $$



/*!50003 CREATE DEFINER=`deweyg`@`localhost` PROCEDURE `zdm_memT100_Init`(In pTotRowsMemT100 Int, In pNoRecursion Bool)
    MODIFIES SQL DATA
    COMMENT 'inits pivot Table'
BEGIN
/*	call zdm_memT100_Init(pTotRowsMemT100,pNoRecursion);
*/
Declare vMaxExisting, vErrCount, vInsertCount Int Default 0;
Declare Continue Handler for 1022, 1024, 1026
	Begin
		Set vErrCount = vErrCount + 1;
		insert into erl_error_log 
			(erl_Error_Code, erl_Calling_Proc, erl_Note, erl_ReferenceNum, erl_CID, erl_Version) values
			(vErrCount, 'zdm_memT100_Init', 'init of memT100 failing', vErrCount, Connection_ID(), 0);
		If vErrCount > 5 and not(pNoRecursion) then -- only try this once
			Truncate memT100;
			call zdm_memT100_Init(pTotRowsMemT100,1);
		End if;
	End;
If pTotRowsMemT100 < 1000 then
	Set pTotRowsMemT100 = 2000;
End if;
Select Coalesce(Max(id),0) into vMaxExisting from memT100 where id between 1 and pTotRowsMemT100;
If vMaxExisting < pTotRowsMemT100 then
	Set @a = 0;
	Insert ignore into memT100 (id) 
	Select A.id
	from (
		select @a:=@a+1 as id from v10000, v10 limit 100000 /* view w 100k rows */
		) as A
	Where A.id <= pTotRowsMemT100;
	Set vInsertCount = Row_Count();
-- check for errors
	If (Select Count(*) from memT100) < pTotRowsMemT100 and not(pNoRecursion) then -- or vInsertCount <> @a
		Set vErrCount = 6;
		Insert into memT100 (id) values (1); -- force throwing dup key error
	End if;
End if;
END */$$

DELIMITER ;



/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;

/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;

/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

