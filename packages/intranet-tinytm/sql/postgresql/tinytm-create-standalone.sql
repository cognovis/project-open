-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-create-standalone.sql
--
-----------------------------------------------------------------------------------------------------
-- TinyTM "Standalone" Data Model
-----------------------------------------------------------------------------------------------------
--
-- Copyright (c) 2008 ]project-open[
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- Please see the GNU General Public License for more details.
--
-- @author      frank.bergmann@project-open.com
--
-----------------------------------------------------------------------------------------------------
-- This script creates the data model for TinyTM V0.1 inside
-- a PostgreSQL 8.2 database. 
-- In order to run this script you need to 1) install PostgreSQL 8.2 
-- on your local computer and 2) paste this code into thee pgAdminIII's 
-- "SQL" window.
--
-- There is currently no "administration" applications available
-- for the data in this data model, so you probably need to use
-- pgAdminIII for that purpose.


-----------------------------------------------------------------------------------------------------
-- Crypto-Extensions for PostgreSQL
--
-- We need the "sha1(text)" function to calculate a hash value for Internet autentication.

-- Adjust this setting to control where the objects get created.
SET search_path = public;

-- Create a PlPg/SQL function for the existing C .so library.
CREATE OR REPLACE FUNCTION digest(text, text) 
RETURNS bytea AS '$libdir/pgcrypto', 'pg_digest' 
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gen_salt(text)
RETURNS text
AS '$libdir/pgcrypto', 'pg_gen_salt'
LANGUAGE 'C';

CREATE OR REPLACE FUNCTION gen_salt(text, int4)
RETURNS text
AS '$libdir/pgcrypto', 'pg_gen_salt_rounds'
LANGUAGE 'C';

-- Shortcut for SHA-1 Crypto function
CREATE OR REPLACE FUNCTION sha1(text) 
RETURNS text AS 'SELECT upper(encode(digest(coalesce($1,''''), ''sha1''),''hex'')) AS result' 
LANGUAGE 'SQL'; 



-----------------------------------------------------------------------------------------------------
-- Fuzzy Searching Extensions for PostgreSQL
-----------------------------------------------------------------------------------------------------

-- Adjust this setting to control where the objects get created.
SET search_path = public;

-- Levenshtein distance calculates the "editing distance" between two strings. This distance is the 
-- main measure of "fuzzyness" in a translation memory. We are lucky that PostgreSQL already provides
-- us this function in an optimized version written in C.
CREATE or REPLACE FUNCTION levenshtein (text,text) 
RETURNS int AS '$libdir/fuzzystrmatch','levenshtein' 
LANGUAGE C IMMUTABLE STRICT;




-----------------------------------------------------------------------------------------------------
-- Users
-----------------------------------------------------------------------------------------------------
--
-- Users refer to phsical persons who can logon to TinyTM. Autentication uses as salt/password crypt 
-- scheme so that we don't have to transport the user's password in clear text through an unencrypted 
-- ODBC channel.


-- "Standalone" definition for the TinyTM user's table. 
CREATE sequence tinytm_users_seq start with 1;
CREATE table tinytm_users (
	user_id		integer
			constraint tinytm_users_pk
			primary key,
			-- username is always lower case!
	username	varchar(100)
			constraint tinytm_users_username_un
			unique,
			-- email is always lower case!
	email		varchar(100)
			constraint tinytm_users_email_nn
			not null
			constraint tinytm_users_email_un
			unique,
	first_names	varchar(100)
			constraint tinytm_users_first_names_nn
			not null,
	last_name	varchar(100)
			constraint tinytm_users_last_name_nn
			not null,
	password	char(40)	
			constraint tinytm_users_password_nn
			not null,
	salt		char(40)	
			constraint tinytm_users_salt_nn
			not null
);

-- Create a new default user. The funny sha1(gen_salt('md5')) creates a "salt" (=random data 
-- to mix with password) for cryptographic reasons. Then set the user's password. The password 
-- is "system". However, we don't want to store the plain-text password in the DB, so we only 
-- store a cryptographic hash value.
insert into tinytm_users values (
	nextval('tinytm_users_seq'),
	'sysadmin@tigerpond.com',
	'System',
	'Administrator',
	'',
	sha1(gen_salt('md5'))
);
update	tinytm_users set password = sha1('system' || salt)
where	email = 'sysadmin@tigerpond.com';


-----------------------------------------------------------------------------------------------------
-- Groups
-----------------------------------------------------------------------------------------------------
--
-- Groups may be "open" (everybody can add himself to a group), "needs approval" (requrest membership) 
-- or "closed" (only the group admins can add the user).


-- Define table and sequence for "standalone" operations. 
CREATE sequence tinytm_groups_seq start with 1;
CREATE table tinytm_groups (
	group_id	integer
			constraint tinytm_groups_pk
			primary key,
	group_name	varchar(1000)
			constraint tinytm_groups_group_name_nn
			not null,
	join_policy	varchar(30)
			constraint tinytm_groups_join_policy_nn
			not null
			constraint tinytm_groups_join_policy_ck
			CHECK (
				join_policy = 'open' OR 
				join_policy = 'needs approval' OR 
				join_policy = 'closed'
			)
);


-----------------------------------------------------------------------------------------------------
-- Segment Types
--

create table tinytm_segment_types (
	segment_type_id		integer
				constraint tinytm_segment_types_pk
				primary key,
	segment_type		varchar(50),
	description		text
);

insert into tinytm_segment_types values (1, 'Segment', '');
insert into tinytm_segment_types values (2, 'Sentence', '');
insert into tinytm_segment_types values (3, 'Paragraph', '');
insert into tinytm_segment_types values (4, 'Word', '');




-----------------------------------------------------------------------------------------------------
-- Languages
--

create table tinytm_languages (
	language_id		integer
				constraint tinytm_languages_pk
				primary key,
	language		varchar(50),
	description		text
);


insert into tinytm_languages values ('1','ca_ES','Catalan (Spain)');
insert into tinytm_languages values ('2','da','Danish');
insert into tinytm_languages values ('3','de','German');
insert into tinytm_languages values ('4','de_CH','Swiss German');
insert into tinytm_languages values ('5','de_DE','German German');
insert into tinytm_languages values ('6','el','Greek');
insert into tinytm_languages values ('7','en','English');
insert into tinytm_languages values ('8','en_AU','English (Australia)');
insert into tinytm_languages values ('9','en_CA','English (Canada)');
insert into tinytm_languages values ('10','en_GB|');
insert into tinytm_languages values ('11','en_IE','English (Ireland)');
insert into tinytm_languages values ('12','en_UK','English (UK)');
insert into tinytm_languages values ('13','en_US','English (US)');
insert into tinytm_languages values ('14','es','Spanish');
insert into tinytm_languages values ('15','es_AR','Spanish (Argentina)');
insert into tinytm_languages values ('16','es_ES','Spanish (Spain)');
insert into tinytm_languages values ('17','es_LA','Spanish (Latin America)');
insert into tinytm_languages values ('18','es_MX','Spanish (Mexico)');
insert into tinytm_languages values ('19','es_PE','Spanish (Peru)');
insert into tinytm_languages values ('20','es_US','Spanish (US)');
insert into tinytm_languages values ('21','es_UY','Spanish (Uruguay)');
insert into tinytm_languages values ('22','es_VE','Spanish (Venezuea)');
insert into tinytm_languages values ('23','eu','Euskera');
insert into tinytm_languages values ('24','fr','French');
insert into tinytm_languages values ('25','fr_BE','French (Belgium)');
insert into tinytm_languages values ('26','fr_CH','French (Switzerland)');
insert into tinytm_languages values ('27','fr_FR','French (France)');
insert into tinytm_languages values ('28','gl','Galician');
insert into tinytm_languages values ('29','gr','Greek');
insert into tinytm_languages values ('30','it','Italian');
insert into tinytm_languages values ('31','it_IT','Italian Italy');
insert into tinytm_languages values ('32','ja','Japanese (Japan)');
insert into tinytm_languages values ('33','nl','Dutch');
insert into tinytm_languages values ('34','nl_BE','Duch (Belgium)');
insert into tinytm_languages values ('35','nl_NL','Duch (The Netherlands)');
insert into tinytm_languages values ('36','none','No Language');
insert into tinytm_languages values ('37','pt','Portuguese');
insert into tinytm_languages values ('38','pt_BR','Portuguese (Brazil)');
insert into tinytm_languages values ('39','pt_PT','Portuguese (Portugal)');
insert into tinytm_languages values ('40','ru','Russian');
insert into tinytm_languages values ('41','ru_RU','Russian (Russian Federation)');
insert into tinytm_languages values ('42','ru_UA','Russian (Ukrainia)');
insert into tinytm_languages values ('43','zh_cn','Chinese Simplified');
insert into tinytm_languages values ('44','zh_tw','Chinese Traditional');


-----------------------------------------------------------------------------------------------------
-- SubjectaAreas
--

create table tinytm_subject_areas (
	subject_area_id		integer
				constraint tinytm_subject_areas_pk
				primary key,
	subject_area		varchar(50),
	description		text
);

insert into tinytm_subject_areas values (1, 'Loc', '');
insert into tinytm_subject_areas values (2, 'Tec', '');
insert into tinytm_subject_areas values (3, 'Tech-Auto', '');
insert into tinytm_subject_areas values (4, 'Tech-Aero', '');
insert into tinytm_subject_areas values (5, 'Tech-Mech. eng', '');
insert into tinytm_subject_areas values (6, 'Tech-Telcos', '');
insert into tinytm_subject_areas values (7, 'Tech-Gen', '');
insert into tinytm_subject_areas values (8, 'Biz', '');
insert into tinytm_subject_areas values (9, 'Com', '');
insert into tinytm_subject_areas values (10, 'Gen', '');
insert into tinytm_subject_areas values (11, 'Bio', '');
insert into tinytm_subject_areas values (12, 'Law', '');
insert into tinytm_subject_areas values (13, 'Eco', '');
insert into tinytm_subject_areas values (14, 'Lit', '');
insert into tinytm_subject_areas values (15, 'Med', '');
insert into tinytm_subject_areas values (16, 'Mkt', '');



----------------------------------------------------------------------------------------------------
-- Customers
--

create table tinytm_customers (
	customer_id		integer
				constraint tinytm_customers_pk
				primary key,
	customer_name		varchar(1000),
	note			text
);

insert into tinytm_customers values (1, 'Sample Customer','');



-----------------------------------------------------------------------------------------------------
-- TinyTM Tags
--
-- A Tag is a type of shallow semantic markup, roughly corresponding to "Prim" concepts in Description 
-- Logics.

CREATE sequence tinytm_tags_seq start with 1;
CREATE table tinytm_tags (
	tag_id			integer
				constraint tinytm_tags_pk
				primary key,
	tag_name		varchar(100)
				constraint tinytm_tag_name_nn
				not null,
	description		text
);

insert into tinytm_tags values (1, 'Sample Tag', '');



-----------------------------------------------------------------------------------------------------
-- TinyTM Segments
--
-- Just a simple list of bi-lingual segments. The "tags" field associates a number of tags with each segment.


CREATE sequence tinytm_segments_seq start with 1;
CREATE table tinytm_segments (
	-- The primary key. This is a unique integer that can be
	-- taken from nextval('tinytm_segments_seq') for example.
	segment_id		integer
				constraint tinytm_segment_pk
				primary key,
	-- Identifier (translation key). Not used currently.
	segment_key		varchar(100),
	-- Is this segment based on another segment? This provides us
	-- information about the usefullness of segments.
	parent_id		integer
				constraint tinytm_segment_parent_fk
				references tinytm_segments,
	-- Who has created this segment, when and from which IP?
	owner_id		integer
				constraint tinytm_segments_creation_user_nn
				not null
				constraint tinytm_segments_creation_user_fk
				references tinytm_users,
	creation_date		timestamptz
				constraint tinytm_segments_creation_date_nn
				not null,
	creation_ip		varchar(50)
				constraint tinytm_segments_creation_ip_nn
				not null,
	-- The context (characteristics) of this segment
	-- Who paid for this segment?
	customer_id		integer,
	-- Sentence, Paragraph or Word?
	segment_type_id		integer
				constraint tinytm_segment_type_fk
				references tinytm_segment_types
				constraint tinytm_segment_type_nn
				not null,
	-- Text Type
	text_type		varchar(50),
	-- Document reference. For future use.
	document_key		varchar(1000),
	-- Subject Area
	subject_area_id		integer
				constraint tinytm_subject_area_fk
				references tinytm_subject_areas,
	-- Source and target language
	source_lang_id		integer
				constraint tinytm_source_lang_fk
				references tinytm_languages
				constraint tinytm_source_lang_nn
				not null,
	target_lang_id		integer
				constraint tinytm_target_lang_fk
				references tinytm_languages
				constraint tinytm_target_lang_nn
				not null,
	-- Tags are a kind of light-weight semantic indexing. 
	tags			text,
	-- The source text is available in original form. 
	source_text		text
				constraint tinytm_segments_source_text_nn
				not null,
	-- The translated text without any formatting.
	target_text		text
				constraint tinytm_segments_target_text_nn
				not null
);

