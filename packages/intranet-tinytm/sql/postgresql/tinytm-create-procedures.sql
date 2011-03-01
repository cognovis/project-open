-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-create.sql
--
-----------------------------------------------------------------------------------------------------
-- TinyTM "Procedures"
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
-- These are the common TinyTM Pl/SQL procedures. These
-- procedures should work bothh on the "Standalone" and on
-- the "]project-open[" data model.



-----------------------------------------------------------------------------------------------------
-- Protocol
-----------------------------------------------------------------------------------------------------
--
-- The following functions represent the externally available API functions.
-- Authentication is done on the ODBC/PostgreSQL level
--
-- Retreive fuzzy mathces.
-- tinytm_get_fuzzy_matches(varchar, varchar, varchar, varchar, varchar, varchar)
-- tinytm_get_fuzzy_matches(source_lang, target_lang, source_text, tag_string, penalties) 
-- 	-> List of (score, target_text)
--
-- API call to insert a new segment into the TM.
--
-- Short version: tinytm_new_segment(source_lang, target_lang, source_text, target_text)
-- Long version: tinytm_new_segment(
--	segment_key, parent_key, creation_ip, customer_name, 
--	segment_type, text_type, document_key, 
--	source_lang, target_lang, source_text, target_text, 
--	tag_string
-- )
--
-- tinytm_get_fuzzy_matches(source_lang, target_lang, source_text)
--	-> List of tinytm_fuzzy_search_result(score, source_text, target_text)
-- tinytm_get_fuzzy_matches(source_lang, target_lang, source_text, max_results, tag_string, penalty_string)
--	-> List of tinytm_fuzzy_search_result(score, source_text, target_text)




-----------------------------------------------------------------------------------------------------
-- Recursive Levenshtein
-----------------------------------------------------------------------------------------------------

-- The levenshtein "editing distance" function gets slow when comparing long segments
-- (complexity n * m, with n and m being the length of the segments).
-- Therefore we split the segments into two pieces if the length exceeds a certain limit.
-- Then we apply levenshtein on the pieces and add the sums.
-- 
-- This "recursive levenshtein" does not give the 100% "correct" distance.
-- However, it returns "0" in the case of identical strings and it returns
-- a slightly higher distance for more complex strings. This should be OK 
-- in our context.
CREATE or REPLACE FUNCTION tinytm_levenshtein(text, text)
returns integer as '
DECLARE
	p_source		alias for $1;
	p_target		alias for $2;

	v_source_left		text;
	v_target_left		text;
	v_source_right		text;
	v_target_right		text;

	v_source_len		integer;
	v_target_len		integer;
	v_source_len_half	integer;
	v_target_len_half	integer;
	v_distance		integer;
BEGIN
	v_source_len := length(p_source);
	v_target_len := length(p_target);

	-- Quick check if the lengths are too different.
	-- In this case (>50% difference) we dont need to know the exact levenshtein.
	IF v_source_len > v_target_len * 1.5 THEN return round(v_source_len * 0.5); END IF;
	IF v_target_len > v_source_len * 1.5 THEN return round(v_target_len * 0.5); END IF;


	-- Check if the pieces exceed a certain size (20 .. 120). The smaller the value the faster.
	IF v_source_len > 80 THEN

		v_source_len_half := round(v_source_len / 2);
		v_target_len_half := round(v_target_len / 2);

		v_source_left := substring(p_source, 1, v_source_len_half);
		v_target_left := substring(p_target, 1, v_target_len_half);

		v_source_right := substring(p_source, v_source_len_half+1, v_source_len-v_source_len_half+1);
		v_target_right := substring(p_target, v_target_len_half+1, v_target_len-v_target_len_half+1);

		v_distance = tinytm_levenshtein(v_source_left, v_target_left) + tinytm_levenshtein(v_source_right, v_target_right);
	ELSE
		v_distance = levenshtein(p_source, p_target);
	END IF;

	RETURN v_distance;
END;' language 'plpgsql';



-----------------------------------------------------------------------------------------------------
-- Helper functions
-----------------------------------------------------------------------------------------------------

-- Determines the user_id of the currently connected user
--
CREATE or REPLACE FUNCTION tinytm_current_user_id()
returns integer as '
DECLARE
	v_user_id		integer;
BEGIN
	select	user_id into v_user_id
	from	tinytm_users where username = current_user;

	IF v_user_id is null THEN
		select	user_id into v_user_id
		from	tinytm_users where email like current_user || ''%'';
	END IF;

	IF v_user_id is null THEN
		RAISE EXCEPTION 
			''tinytm_current_user_id: Could not determine user_id for current user "%".'', 
			current_user;
	END IF;

	return v_user_id;
END;' language 'plpgsql';


-- Determine the list of language_ids from a textual language
--
CREATE or REPLACE FUNCTION tinytm_lang_ids_from_lang(varchar)
returns setof integer as '
DECLARE
	p_lang			alias for $1;

	v_lang_id		integer;
	row			RECORD;
BEGIN
	FOR row IN
		SELECT	language_id
		FROM	tinytm_languages 
		WHERE	substring(lower(language), 1, length(p_lang)) = lower(p_lang)
	LOOP
		RETURN NEXT row.language_id;
	END LOOP;
END;' language 'plpgsql';



-- Determine the list of language_ids from a textual language
--

CREATE or REPLACE FUNCTION tinytm_segment_type_id_from_string(varchar)
RETURNS INTEGER AS 'SELECT segment_type_id from tinytm_segment_types where segment_type = $1;'
LANGUAGE SQL;


CREATE or REPLACE FUNCTION tinytm_language_id_from_string(varchar)
RETURNS INTEGER AS 'SELECT language_id from tinytm_languages where language = $1;'
LANGUAGE SQL;





-----------------------------------------------------------------------------------------------------
-- Public API Functions
-----------------------------------------------------------------------------------------------------

-- Insert a new segment into the database. This procedure hides the TM implementation from the 
-- TinyTM client. 
CREATE or REPLACE FUNCTION tinytm_new_segment (
	varchar, varchar, varchar, varchar, varchar, varchar, varchar, 
	varchar, varchar, varchar, varchar, 
	varchar
) returns integer as '
DECLARE
	p_segment_key		alias for $1;
	p_parent_key		alias for $2;
	p_creation_ip		alias for $3;
	p_customer_name		alias for $4;
	p_segment_type		alias for $5;
	p_text_type		alias for $6;
	p_document_key		alias for $7;

	p_source_lang		alias for $8;
	p_target_lang		alias for $9;
	p_source_text		alias for $10;
	p_target_text		alias for $11;
	p_tag_string		alias for $12;

	v_segment_id		integer;
	v_user_id		integer;
	v_parent_id		integer;
	v_customer_id		integer;
	v_segment_type_id	integer;
	v_source_lang_id	integer;
	v_target_lang_id	integer;
	v_source_lang		varchar;
	v_target_lang		varchar;
BEGIN
	-- convert string input parameters into IDs
	SELECT segment_type_id INTO v_segment_type_id FROM tinytm_segment_types 
	WHERE lower(segment_type) = lower(p_segment_type);
	IF v_segment_type_id is null THEN 
		raise EXCEPTION ''tinytm_new_segment(...,%,...): Bad segment type'', p_segment_type;
	END IF;

	-- convert source_language string to ID
	SELECT language_id INTO v_source_lang_id FROM tinytm_languages
	WHERE lower(language) = lower(regexp_replace(p_source_lang, ''[-]'', ''_''));
	IF v_source_lang_id is null THEN 
		raise EXCEPTION ''tinytm_new_segment(...,%,...): Bad source language'', p_source_lang;
	END IF;

	-- convert target_language string to ID
	SELECT language_id INTO v_target_lang_id FROM tinytm_languages
	WHERE lower(language) = lower(regexp_replace(p_target_lang, ''[-]'', ''_''));
	IF v_target_lang_id is null THEN 
		raise EXCEPTION ''tinytm_new_segment(...,%,...): Bad target language'', p_target_lang;
	END IF;

	-- get the parent_id if available
	SELECT segment_id INTO v_parent_id FROM tinytm_segments
	where segment_key = p_parent_key;

	-- get the customer (if specified)
	SELECT customer_id INTO v_customer_id FROM tinytm_customers
	WHERE lower(customer_name) = lower(p_customer_name);

	-- get the user_id
	v_user_id :=  tinytm_current_user_id();

	-- just take the next segment_id
	v_segment_id := nextval(''tinytm_segments_seq'');

	insert into tinytm_segments (
		segment_id,
		segment_key,
		parent_id,
		owner_id,
		creation_date,
		creation_ip,
		customer_id,
		segment_type_id,
		text_type,
		document_key,
		source_lang_id,
		target_lang_id,
		tags,
		source_text,
		target_text
	) values (
		v_segment_id,
		p_segment_key,
		v_parent_id,
		v_user_id,
		now(),
		p_creation_ip,
		v_customer_id,
		v_segment_type_id,
		p_text_type,
		p_document_key,
		v_source_lang_id,
		v_target_lang_id,
		p_tag_string,
		p_source_text,
		p_target_text
	);
	RETURN v_segment_id;
END;' language 'plpgsql';


-- Shortened version of tinytm_new_segment
CREATE or REPLACE FUNCTION tinytm_new_segment (
	varchar, varchar, varchar, varchar
) returns integer as '
DECLARE
	p_source_lang		alias for $1;
	p_target_lang		alias for $2;
	p_source_text		alias for $3;
	p_target_text		alias for $4;

	v_segment_id		integer;
BEGIN
	v_segment_id := tinytm_new_segment (
		null,
		null,
		''0.0.0.0'',
		null,
		''Paragraph'',
		''text/plain'',
		null,
		p_source_lang,
		p_target_lang,
		p_source_text,
		p_target_text,
		null
	);
	RETURN v_segment_id;
END;' language 'plpgsql';



-- Main retrieval API function.
-- The function returns a "set of" results, allowing the client to display the results
-- using a cursor function.

CREATE TYPE tinytm_fuzzy_search_result AS (score numeric, source_text text, target_text text);

CREATE or REPLACE FUNCTION tinytm_get_fuzzy_matches(varchar, varchar, varchar, varchar, varchar)
returns setof tinytm_fuzzy_search_result as '
DECLARE
	p_source_lang		alias for $1;
	p_target_lang		alias for $2;
	p_source_text		alias for $3;
	p_tag_string		alias for $4;
	p_penalty_string	alias for $5;

	result			tinytm_fuzzy_search_result%ROWTYPE;
	row			RECORD;
BEGIN
	FOR row IN
		SELECT
			100 * (source_len - levenshtein) / source_len as score,
			ts.source_text,
			ts.target_text,
			source_len
		FROM
			(select distinct
				tinytm_levenshtein(trim(p_source_text), ts.source_text) * 1.0 as levenshtein,
				length(p_source_text) * 1.0 as source_len,
				sl.language as source_lang,
				tl.language as target_lang,
				source_text,
				target_text
			from
				tinytm_segments ts
				LEFT OUTER JOIN tinytm_languages sl ON (ts.source_lang_id = sl.language_id)
				LEFT OUTER JOIN tinytm_languages tl ON (ts.target_lang_id = tl.language_id)
			where
				source_lang_id in (select * from tinytm_lang_ids_from_lang(p_source_lang)) and
				target_lang_id in (select * from tinytm_lang_ids_from_lang(p_target_lang))
			order by
				levenshtein
			LIMIT 20
			) ts
		where
			source_len > 5
	LOOP
		IF row.score > 50.0 THEN
			result.score := row.score::numeric(6,1);
			result.source_text = row.source_text;
			result.target_text = row.target_text;
			RETURN NEXT result;
		END IF;
	END LOOP;
	RETURN;
END;' language 'plpgsql';






-- /packages/intranet-tinytm/sql/postgresql/intranet-tinytm-create-demousers.sql
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


-- Initialize the TM with some sample data.
CREATE or REPLACE FUNCTION inline_0()
returns integer as '
DECLARE
	row		RECORD;
BEGIN
	PERFORM tinytm_new_segment(''en'', ''de'', ''This is a book'', ''Dies ist ein Buch'');
	PERFORM tinytm_new_segment(''en'', ''de'', ''These are books'', ''Dies sind Buecher'');
	PERFORM tinytm_new_segment(''en'', ''de'', ''These are trees'', ''Dies sind Baeume'');
	PERFORM tinytm_new_segment(''en'', ''de'', ''Books, books'', ''Buecher, buecher'');

	RETURN 0;
END;' language 'plpgsql';
select inline_0();
DROP FUNCTION inline_0();


-- Test the tinytm_get_fuzzy_matches function.
CREATE or REPLACE FUNCTION inline_0()
returns integer as '
DECLARE
	row		RECORD;
BEGIN
	FOR row IN
		select *
		from	tinytm_get_fuzzy_matches(''en'', ''de'', ''AGREEMENT'', '''', '''')
	LOOP
		RAISE NOTICE ''inline_0: result = %,%,%'', row.score, row.source_text, row.target_text;
	END LOOP;

	RETURN 0;
END;' language 'plpgsql';
select inline_0();
DROP FUNCTION inline_0();

