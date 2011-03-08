-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-drop.sql
--
-----------------------------------------------------------------------------------------------------
-- TinyTM "Drop Script"
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
-- This script removes TinyTM completely from the database.
--
-- You can ignore errors from DROP commands below.


-- drop menus and components
select im_menu__del_module('intranet-tinytm');
select im_component_plugin__del_module('intranet-tinytm');

-- Functions
DROP FUNCTION digest(text,text);
DROP FUNCTION levenshtein (text,text);
DROP FUNCTION sha1(text);
DROP FUNCTION tinytm_authenticate(varchar);
DROP FUNCTION tinytm_current_user_id();
DROP FUNCTION tinytm_get_fuzzy_matches(varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_get_fuzzy_matches(varchar, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_lang_ids_from_lang(varchar);
DROP FUNCTION tinytm_levenshtein (text,text);
DROP FUNCTION tinytm_login(varchar,varchar);
DROP FUNCTION tinytm_match_language(varchar, varchar);
DROP FUNCTION tinytm_match_matches(numeric, numeric, numeric, numeric, varchar);
DROP FUNCTION tinytm_match_segment(varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION tinytm_new_segment(varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar);



-- Drop sequences
DROP sequence tinytm_groups_seq;
DROP sequence tinytm_segment_seq;
DROP sequence tinytm_segments_seq;
DROP sequence tinytm_tag_seq;
DROP sequence tinytm_tags_seq;
DROP sequence tinytm_users_seq;



-- Drop views from ]project-open[ data model
DROP view tinytm_categories;
DROP view tinytm_customers;
DROP view tinytm_groups;
DROP view tinytm_languages;
DROP view tinytm_segment_types;
DROP view tinytm_subject_areas;
DROP view tinytm_tags;
DROP view tinytm_users;


-- Drop tables from "standalone" data model
DROP table tinytm_categories;
DROP table tinytm_customers;
DROP table tinytm_groups;
DROP table tinytm_languages;
DROP table tinytm_segment_tag_map;
DROP table tinytm_segment_types;
DROP table tinytm_segments cascade;
DROP table tinytm_subject_areas;
DROP table tinytm_tags CASCADE;
DROP table tinytm_users;

-- Drop custom data type
DROP TYPE tinytm_fuzzy_search_result;

