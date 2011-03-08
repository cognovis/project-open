-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-create-projectopen.sql
--
-----------------------------------------------------------------------------------------------------
-- TinyTM "]project-open[" Data Model
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


-----------------------------------------------------------------------------------------------------
-- This is the ]project-open[ version of the creation script.
-- 
-- This script asumes that ]project-open[ V3.2 or higher is
-- already installed in the database and sets up database "views"
-- instead of "tables".
--
-- This way, you can use the ]project-open[ user and category
-- maintenance screens in order to add new users etc.


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

-- Define "tinytm_users" in the context of ]project-open[ as a view This definition will fail in a 
-- "standalone" installation, giving way to the definition as a table below.
CREATE or REPLACE view tinytm_users as
SELECT
	u.user_id,
	u.username,
	pa.email,
	pe.first_names,
	pe.last_name,
	u.password,
	u.salt
FROM
	parties pa,
	persons pe,
	users u,
	group_member_map m,
	membership_rels mr
WHERE
	pa.party_id = pe.person_id AND
	pe.person_id = u.user_id AND
	u.user_id = m.member_id AND
	m.group_id = acs__magic_object_id('registered_users'::character varying) AND
	m.rel_id = mr.rel_id AND
	m.container_id = m.group_id AND
	m.rel_type::text = 'membership_rel'::text AND
	mr.member_state = 'approved'
;



-----------------------------------------------------------------------------------------------------
-- Groups
-----------------------------------------------------------------------------------------------------
--
-- Groups may be "open" (everybody can add himself to a group), "needs approval" (requrest membership) 
-- or "closed" (only the group admins can add the user).


-- In the context of ]project-open[ we define tinytm_groups as a view showing the contents of OpenACS 
-- group. This line will fail in a "standalone" installation, so the table is created correctly.
CREATE or REPLACE view tinytm_groups as
SELECT * FROM groups;



-----------------------------------------------------------------------------------------------------
-- Segment Types
--

-- Segment types from ]project-open[
CREATE or REPLACE view tinytm_segment_types as
SELECT	category_id as segment_type_id,
	category as segment_type,
	category_description as description
FROM	im_categories
WHERE	category_type = 'Intranet TinyTM Segment Type';

-- 24000-24999  Intranet TinyTM (1000)
-- 24000-24099	Intranet Segment Type (100)

SELECT im_category_new(24000, 'Segment', 'Intranet TinyTM Segment Type');
SELECT im_category_new(24002, 'Sentence', 'Intranet TinyTM Segment Type');
SELECT im_category_new(24004, 'Paragraph', 'Intranet TinyTM Segment Type');
SELECT im_category_new(24006, 'Word', 'Intranet TinyTM Segment Type');



-----------------------------------------------------------------------------------------------------
-- Languages
--

-- Languages from ]project-open[
CREATE or REPLACE view tinytm_languages as
SELECT	category_id as language_id,
	category as language,
	category_description as description
FROM	im_categories
WHERE	category_type = 'Intranet Translation Language';



-----------------------------------------------------------------------------------------------------
-- Subject Areas
--

-- Subject Areas from ]project-open[
CREATE or REPLACE view tinytm_subject_areas as
SELECT	category_id as subject_area_id,
	category as subject_area,
	category_description as description
FROM	im_categories
WHERE	category_type = 'Intranet Translation Subject Area';



----------------------------------------------------------------------------------------------------
-- Customers
--

-- Customers from ]project-open[
CREATE or REPLACE view tinytm_customers as
SELECT	company_id as customer_id,
	company_name as customer_name,
	note as customer_note
FROM	im_companies
WHERE	company_type_id in (select * from im_sub_categories(57));



-----------------------------------------------------------------------------------------------------
-- TinyTM Tags
--
-- A Tag is a type of shallow semantic markup, roughly corresponding to "Prim" concepts in Description 
-- Logics.

-- drop view tinytm_segment_types;

CREATE or REPLACE view tinytm_tags as
SELECT	category_id as tag_id,
	category as tag,
	category_description as description
FROM	im_categories
WHERE	category_type = 'Intranet TinyTM Tag';

-- 24000-24999  Intranet TinyTM (1000)
-- 24000-24099	Intranet TinyTM Segment Type (100)
-- 24100-24199	Intranet TinyTM Tag (100)

SELECT im_category_new(24100, 'Sample Tag', 'Intranet TinyTM Tag');
SELECT im_category_new(24101, 'Test', 'Intranet TinyTM Tag');
SELECT im_category_new(24102, 'Draft Translation', 'Intranet TinyTM Tag');
SELECT im_category_new(24103, ']project-open[ Related', 'Intranet TinyTM Tag');



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
				references users,
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
				references im_categories
				constraint tinytm_segment_type_nn
				not null,
	-- Text Type
	text_type		varchar(50),
	-- Document reference. For future use.
	document_key		varchar(1000),
	-- Subject Area
	subject_area_id		integer
				constraint tinytm_subject_area_fk
				references im_categories,
	-- Source and target language
	source_lang_id		integer
				constraint tinytm_source_lang_fk
				references im_categories
				constraint tinytm_source_lang_nn
				not null,
	target_lang_id		integer
				constraint tinytm_target_lang_fk
				references im_categories
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

