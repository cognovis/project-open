-- /packages/intranet-freelance/sql/postgres/intranet-freelance-score.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Procedure to score a freelancer according to a 
-- number of criterial. This function allows to
-- look for the "best matching" freelancers for 
-- a project.


-- Return type for the scoring function
-- The scoring function should execute in one
-- piece and returns a result set, instead of
-- calling the evaluation function for each freelancer.
--
CREATE TYPE im_freelance_score as (user_id integer, score real, note varchar(4000));



-----------------------------------------------------------
-- Determine the range of purchase prices for a particular
-- set of parameters
--

drop function im_freelance_score_translation_price (integer,integer,integer,integer,integer,varchar);
create or replace function im_freelance_score_translation_price (
	integer, integer, integer, integer, integer, varchar
) RETURNS real ARRAY[2] as '
declare
	p_task_type_id			alias for $1;
	p_subject_area_id		alias for $2;
 	p_source_lang_id		alias for $3;
	p_target_lang_id		alias for $4;
	p_task_uom_id			alias for $5;
	p_currency			alias for $6;

	p_source_lang			varchar;
	p_target_lang			varchar;

        row                             RECORD;
        price_row                       RECORD;

	max_price			real;
	min_price			real;
	ret				real ARRAY[2];
BEGIN
	select im_category_from_id(p_source_lang_id) into p_source_lang;
	select im_category_from_id(p_target_lang_id) into p_target_lang;

	min_price = 1000000;
	max_price = 0;
	ret = ''{1,2}'';

	FOR row IN
	    select *
	    from (
		select	u.user_id,
			im_category_from_id(slang.skill_id) as source_lang,
			im_category_from_id(tlang.skill_id) as target_lang
		from	cc_users u
			left outer join im_freelancers f on (
				u.user_id = f.user_id
			)
			left outer join im_freelance_skills slang on (
				u.user_id = slang.user_id
				and slang.skill_type_id = 2000
			)
			left outer join im_freelance_skills tlang on (
				u.user_id = tlang.user_id
				and tlang.skill_type_id = 2002
			)
		where	1=1
		) u
	    where
		substr(source_lang,1,2) = substr(p_source_lang,1,2)
		and substr(target_lang,1,2) = substr(p_target_lang,1,2)
	    order by u.user_id
	LOOP
		-- Price list - Check the relevant price for the
		-- given task_type_id, source+target lang, currency and
		-- quality level and build maximum and minimum price
		FOR price_row IN
			select
				p.relevancy,
				p.price
			from	(
				    (select
					im_trans_prices_calc_relevancy (
						p.company_id,  p.company_id,
						p.task_type_id, p_task_type_id,
						p.subject_area_id, p_subject_area_id,
						p.target_language_id, p_target_lang_id,
						p.source_language_id, p_source_lang_id
					) as relevancy,
					p.price, p.company_id,
					p.uom_id,p.task_type_id,
					p.target_language_id,p.source_language_id,
					p.subject_area_id,p.valid_from,
					p.valid_through
				    from im_trans_prices p,
					 acs_rels r
				    where
					r.object_id_one = p.company_id
					and r.object_id_two = row.user_id
					and p.uom_id = p_task_uom_id
					and currency = p_currency
				    )
				) p
			where
				relevancy >= 0
		LOOP

			IF price_row.price < min_price THEN min_price = price_row.price; END IF;
			IF price_row.price > max_price THEN max_price = price_row.price; END IF;

		END LOOP;

	END LOOP;

	ret[1] = min_price;
	ret[2] = max_price;
        RETURN ret;
end;' language 'plpgsql';


-- Test example to score freelancer in PtDemo
-- select im_freelance_score_translation_price (0,0,10067,10075,324,'EUR');






-----------------------------------------------------------
-- Score freelancers depending on how well they fit
-- with a number of parameters
--

drop function im_freelance_score_translation (integer, integer, integer, integer, integer, varchar);

create or replace function im_freelance_score_translation (
	integer, integer, integer, integer, integer, varchar
) returns setof im_freelance_score as '
declare
	p_task_type_id			alias for $1;
	p_subject_area_id		alias for $2;
 	p_source_lang_id		alias for $3;
	p_target_lang_id		alias for $4;
	p_task_uom_id			alias for $5;
	p_currency			alias for $6;
	
	p_lang_weight			real;
	p_price_weight			real;

	row				RECORD;
	price_row			RECORD;
	p_source_lang			varchar;
	p_target_lang			varchar;
	lang_match_value		real;
	min_max_price			real ARRAY[2];
	min_price			real;
	max_price			real;
	price_relevancy			real;
	price_price			real;
	lang_score			real;
	price_score			real;
	retscore			im_freelance_score%rowtype;
BEGIN
	select im_category_from_id(p_source_lang_id) into p_source_lang;
	select im_category_from_id(p_target_lang_id) into p_target_lang;

	p_lang_weight = 1;
	p_price_weight = 1;

	min_max_price = im_freelance_score_translation_price (p_task_type_id, p_subject_area_id, p_source_lang_id, p_target_lang_id, p_task_uom_id, p_currency);
	min_price = min_max_price[1];
	max_price = min_max_price[2];

	FOR row IN
	    select *
	    from (
		select	u.user_id,
			im_category_from_id(slang.skill_id) as source_lang,
			im_category_from_id(tlang.skill_id) as target_lang
		from	cc_users u
			left outer join im_freelancers f on (
				u.user_id = f.user_id
			)
			left outer join im_freelance_skills slang on (
				u.user_id = slang.user_id
				and slang.skill_type_id = 2000
			)
			left outer join im_freelance_skills tlang on (
				u.user_id = tlang.user_id
				and tlang.skill_type_id = 2002
			)
		where	1=1
		) u
	    where
		substr(source_lang,1,2) = substr(p_source_lang,1,2)
		and substr(target_lang,1,2) = substr(p_target_lang,1,2)
	    order by u.user_id
	LOOP
		lang_match_value = 0::real;

		-- Default matching for source language:
		-- "de" <-> "de_DE" = + 2
		-- "de_DE" <-> "de_DE" = +2
		-- "es" <-> "de_DE" = -10
		if substr(row.source_lang,1,2) = substr(p_source_lang,1,2) then
			-- the main part of the language have matched
			lang_match_value := lang_match_value + 2;
		else
			lang_match_value := lang_match_value - 10;
		end if;
		-- ToDo: Check the claimed vs. confirmed experience.


		-- Default matching for target language:
		-- "de" <-> "de_DE" = + 2
		-- "de_DE" <-> "de_DE" = +4
		-- "es" <-> "de_DE" = -10
		if substr(row.target_lang,1,2) = substr(p_target_lang,1,2) then
			-- the main part of the language have matched
			lang_match_value := lang_match_value + 2;
			if row.target_lang = p_target_lang then
			    -- The Country variants have matched
			    lang_match_value := lang_match_value + 0.5;
			end if;
		else
			lang_match_value := lang_match_value - 10;
		end if;
		-- ToDo: Check the claimed vs. confirmed experience.



		-- Price list - Check the relevant price for the
		-- given task_type_id, source+target lang, currency and
		-- quality level
		price_relevancy = 0;
		price_price = 0;
		FOR price_row IN

			select
				p.relevancy,
				p.price
			from	(
				    (select
					im_trans_prices_calc_relevancy (
						p.company_id,  p.company_id,
						p.task_type_id, p_task_type_id,
						p.subject_area_id, p_subject_area_id,
						p.target_language_id, p_target_lang_id,
						p.source_language_id, p_source_lang_id
					) as relevancy,
					p.price, p.company_id,
					p.uom_id,p.task_type_id,
					p.target_language_id,p.source_language_id,
					p.subject_area_id,p.valid_from,
					p.valid_through
				    from im_trans_prices p,
					 acs_rels r
				    where
					r.object_id_one = p.company_id
					and r.object_id_two = row.user_id
					and p.uom_id = p_task_uom_id
					and currency = p_currency
				    )
				) p
			where
				relevancy >= 0
		LOOP

			IF price_row.relevancy > price_relevancy THEN
				price_relevancy = price_row.relevancy;
				price_price = price_row.price;
			END IF;

		END LOOP;


		-- Combine the various scores
		lang_score = lang_match_value / 6;
		price_score = 1 - ((price_row.price - min_price) / (max_price - min_price));
		retscore.score = 
			lang_score * p_lang_weight +
			price_score * p_price_weight
		;

		retscore.user_id = row.user_id;
		retscore.note = ''uid:'' || row.user_id || '' '' ||
				''src:'' || row.source_lang || '' '' ||
				''trgt:'' || row.target_lang || '' '' ||
				''price:'' || price_price || '' '' || p_currency || '' '' ||
				''lang_score:'' || lang_score || '' '' ||
				''price_score:'' || price_score || '' '' ||
				'''';

		-- Only return the result row if the languages
		-- have matched
		IF lang_match_value >= 0 THEN
			return next retscore;
		END IF;

	END LOOP;
	RETURN;
end;' language 'plpgsql';


--	p_company_id		alias for $1;
--	p_task_type_id		alias for $2;
--	p_subject_area_id	alias for $3;
--	p_source_lang_id	alias for $4;
--	p_target_lang_id	alias for $5;
--	p_task_uom_id
--	p_currency

-- Test query
-- select * from im_freelance_score_translation (0, 0, 10067, 10075, 324, 'EUR');




