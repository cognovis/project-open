-- ported to OpenACS 4 by Gilbert Wong (gwong@orchardlabs.com) on 2001-05-20
--
-- based on student work from 6.916 in Fall 1999
-- which was in turn based on problem set 4
-- in http://photo.net/teaching/one-term-web.html
--
-- by philg@mit.edu and raj@alum.mit.edu on February 9, 2000
-- converted to ACS 4.0 by nstrug@arsdigita.com on 29th September 2000
--
-- $Id$

-- we expect this to be replaced with a more powerful survey
-- module, to be developed by buddy@ucla.edu, so we prefix
-- all of our Oracle structures with "survsimp"

-- this is a PL/SQL function that used to be in the standard ACS 3.x core - not in the
-- current ACS 4.0 core however...
-- gilbertw - logical_negation is defined in utilities-create.sql in acs-kernel
-- create function logical_negation(boolean)
-- returns boolean as '
-- declare
--     true_or_false		alias for $1;
-- begin
--   if true_or_false is null then
--     return null;
--   else 
--     if true_or_false = ''f'' then
-- 	return ''t'';
--     else
-- 	return ''f'';
--     end if;
--   end if;
-- end;' language 'plpgsql';

create function inline_0 ()
returns integer as '
begin
	PERFORM acs_privilege__create_privilege(''survsimp_create_survey'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_modify_survey'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_delete_survey'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_create_question'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_modify_question'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_delete_question'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_take_survey'', null, null);
	PERFORM acs_privilege__create_privilege(''survsimp_admin_survey'', null, null);

	return 0;

end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


begin;

	select acs_privilege__add_child('survsimp_admin_survey','survsimp_create_survey');
	select acs_privilege__add_child('survsimp_admin_survey','survsimp_modify_survey');
	select acs_privilege__add_child('survsimp_admin_survey','survsimp_delete_survey');
	select acs_privilege__add_child('survsimp_admin_survey','survsimp_create_question');
	select acs_privilege__add_child('survsimp_admin_survey','survsimp_modify_question');
	select acs_privilege__add_child('survsimp_admin_survey','survsimp_delete_question');

	select acs_privilege__add_child('read','survsimp_take_survey');


	select acs_privilege__add_child('admin','survsimp_admin_survey');

end;



create function inline_1 ()
returns integer as '
begin

  PERFORM acs_object_type__create_type (
    ''survsimp_survey'',
    ''Simple Survey'',
    ''Simple Surveys'',
    ''acs_object'',
    ''survsimp_surveys'',
    ''survey_id'',
    null,
    ''f'',
    null,
    null
   );

  PERFORM acs_object_type__create_type (
    ''survsimp_question'',
    ''Simple Survey Question'',
    ''Simple Survey Questions'',
    ''acs_object'',
    ''survsimp_questions'',
    ''question_id'',
    null,
    ''f'',
    null,
    null
  );

  PERFORM acs_object_type__create_type (
    ''survsimp_response'',
    ''Simple Survey Response'',
    ''Simple Survey Responses'',
    ''acs_object'',
    ''survsimp_responses'',
    ''response_id'',
    null,
    ''f'',
    null,
    null
  );

  PERFORM acs_rel_type__create_type (
    ''user_blob_response_rel'',
    ''User Blob Response'',
    ''User Blob Responses'',
    ''relationship'',
    ''survsimp_question_responses'',
    ''response_id'',
    ''user_blob_response_rel'',
    ''user'',
    ''user'',
    1,
    1,
    ''content_item'',
    null,
    0,
    1
  );


  return 0;

end;' language 'plpgsql';

select inline_1 ();
drop function inline_1 ();

create table survsimp_surveys (
	survey_id		integer constraint survsimp_surveys_survey_id_fk
				references acs_objects (object_id)
				on delete cascade
                                constraint survsimp_surveys_pk
				primary key,
	name			varchar(100)
				constraint survsimp_surveys_name_nn
				not null,
	-- short, non-editable name we can identify this survey by
	short_name		varchar(20)
				constraint survsimp_surveys_short_name_u
				unique
				constraint survsimp_surveys_short_name_nn
				not null,
	description		text  -- was varchar(4000)
				constraint survsimp_surveys_desc_nn
				not null,
        description_html_p      boolean,  -- was char(1)
                                --constraint survsimp_surv_desc_html_p_ck
				--check(description_html_p in ('t','f')),
	enabled_p               boolean,  -- was char(1)
				-- constraint survsimp_surveys_enabled_p_ck
				-- check(enabled_p in ('t','f')),
	-- limit to one response per user
	single_response_p	boolean,  -- was char(1)
				-- constraint survsimp_sur_single_resp_p_ck
				-- check(single_response_p in ('t','f')),
	single_editable_p	boolean,  -- was char(1)
				-- constraint survsimp_surv_single_edit_p_ck
				-- check(single_editable_p in ('t','f')),
	type                    varchar(20),               
        display_type            varchar(20),
        package_id              integer
                                constraint survsimp_package_id_nn not null
                                constraint survsimp_package_id_fk references
                                apm_packages (package_id) on delete cascade

);

-- each question can be 

create table survsimp_questions (
	question_id		integer constraint survsimp_q_question_id_fk
				references acs_objects (object_id)
				on delete cascade
				constraint survsimp_q_question_id_pk
				primary key,
	survey_id		integer constraint survsimp_q_survey_id_fk
				references survsimp_surveys
				on delete cascade,
	sort_key		integer
				constraint survsimp_q_sort_key_nn
				not null,
	question_text		text
				constraint survsimp_q_question_text_nn
				not null,
        abstract_data_type      varchar(30)
				constraint survsimp_q_abs_data_type_ck
				check (abstract_data_type in ('text', 'shorttext', 'boolean', 'number', 'integer', 'choice','date')),
	required_p		boolean, -- was char(1)
				-- constraint survsimp_q_required_p_ck
				-- check (required_p in ('t','f')),
	active_p		boolean, -- was char(1)
				-- constraint survsimp_q_qctive_p_ck
				-- check (active_p in ('t','f')),
	presentation_type	varchar(20)
				constraint survsimp_q_pres_type_nn
				not null
				constraint survsimp_q_pres_type_ck
				check(presentation_type in ('textbox','textarea','select','radio', 'checkbox', 'date', 'upload_file')),
	-- for text, "small", "medium", "large" sizes
	-- for textarea, "rows=X cols=X"
	presentation_options	varchar(50),
	presentation_alignment	varchar(15)
				constraint survsimp_q_pres_alignment_ck
            			check(presentation_alignment in ('below','beside'))    
);


-- for when a question has a fixed set of responses

create sequence survsimp_choice_id_seq;
create view survsimp_choice_id_sequence as select nextval('survsimp_choice_id_seq') as nextval;

create table survsimp_question_choices (
	choice_id	integer constraint survsimp_qc_choice_id_nn 
			not null 
			constraint survsimp_qc_choice_id_pk
			primary key,
	question_id	integer constraint survsimp_qc_question_id_nn
			not null 
			constraint survsimp_qc_question_id_fk
			references survsimp_questions
			on delete cascade,
	-- human readable 
	label		varchar(500) constraint survsimp_qc_label_nn
			not null,
	-- might be useful for averaging or whatever, generally null
	numeric_value	numeric,
	-- lower is earlier 
	sort_order	integer
);

-- this records a response by one user to one survey
-- (could also be a proposal in which case we'll do funny 
--  things like let the user give it a title, send him or her
--  email if someone comments on it, etc.)
create table survsimp_responses (
	response_id		integer constraint survsimp_resp_response_id_fk
				references acs_objects (object_id)
				on delete cascade
				constraint srvsimp_resp_response_id_pk
				primary key,
	survey_id		integer constraint survsimp_resp_survey_id_fk
				references survsimp_surveys
				on delete cascade,
	title			varchar(100),
	notify_on_comment_p	boolean -- was char(1)
				-- constraint survsimp_resp_noton_com_p_ck
				-- check(notify_on_comment_p in ('t','f'))
);


-- mbryzek: 3/27/2000
-- Sometimes you release a survey, and then later decide that 
-- you only want to include one response per user. The following
-- view includes only the latest response from all users
-- create or replace view survsimp_responses_unique as 
-- select r1.* from survsimp_responses r1
-- where r1.response_id=(select max(r2.response_id) 
--                        from survsimp_responses r2
--                       where r1.survey_id=r2.survey_id
--                         and r1.user_id=r2.user_id);

create view survsimp_responses_unique as
select r1.* from survsimp_responses r1, acs_objects a1
where r1.response_id = (select max(r2.response_id)
			from survsimp_responses r2, acs_objects a2
                        where r1.survey_id = r2.survey_id
                        and a1.object_id = r1.response_id
 			and a2.object_id = r2.response_id
			and a1.creation_user = a2.creation_user);

-- this table stores the answers to each question for a survey
-- we want to be able to hold different data types in one long skinny table 
-- but we also may want to do averages, etc., so we can't just use CLOBs

create table survsimp_question_responses (
	response_id		integer constraint survsimp_qr_response_id_nn
				not null 
				constraint survsimp_qr_response_id_fk
				references survsimp_responses
				on delete cascade,
	question_id		integer constraint survsimp_qr_question_id_nn
				not null 
				constraint survsimp_qr_question_id_fk
				references survsimp_questions
				on delete cascade,
	-- if the user picked a canned response
	choice_id		integer constraint survsimp_qr_choice_id_fk
				references survsimp_question_choices
				on delete cascade,
	boolean_answer		boolean,
				-- was char(1) 
				-- check(boolean_answer in ('t','f')),
	clob_answer		text,
	number_answer		numeric,
	varchar_answer		text,
	date_answer		timestamptz,
	-- columns useful for attachments, column names
	-- lifted from file-storage.sql and bboard.sql
	-- this is where the actual content is stored
	-- attachment_answer	blob,
	item_id			integer
				constraint survsimp_q_response_item_id_fk
				references cr_items(item_id)
				on delete cascade,
	content_length		integer,
	-- file name including extension but not path
	attachment_file_name	varchar(500),
	attachment_file_type	varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	attachment_file_extension varchar(50) 	-- e.g., "jpg"
);


-- We create a view that selects out only the last response from each
-- user to give us at most 1 response from all users.
create view survsimp_question_responses_un as
select qr.*
  from survsimp_question_responses qr, survsimp_responses_unique r
 where qr.response_id=r.response_id;  



-- sequence for variable names
create sequence survsimp_variable_id_seq;
create view survsimp_variable_id_sequence as select nextval('survsimp_variable_id_seq') as nextval;


-- variable names for scored surveys
create table survsimp_variables (
	variable_id	integer 
			constraint survsimp_variable_id_pk 
			primary key,
	variable_name	varchar(100) 
			constraint survsimp_variable_name_nn not null
);

-- map variable names to surveys
create table survsimp_variables_surveys_map (
	variable_id 	integer
			constraint survsimp_vs_map_var_id_nn not null 
			constraint survsimp_vs_map_var_id_fk 
			references survsimp_variables(variable_id)
			on delete cascade,
	survey_id	integer
			constraint survsimp_vs_map_sur_id_nn not null 
			constraint survsimp_vs_map_sur_id_fk 
			references survsimp_surveys(survey_id)
			on delete cascade
);

-- scores for scored responses
create table survsimp_choice_scores (
	choice_id	integer 
			constraint survsimp_choi_sc_ch_id_nn not null 
			constraint survsimp_choi_sc_ch_id_fk 
			references survsimp_question_choices(choice_id)
			on delete cascade,
	variable_id	integer
			constraint survsimp_choi_sc_var_id_nn not null 
			constraint survsimp_choi_sc_var_id_fk
			references survsimp_variables(variable_id)
			on delete cascade,
	score		integer 
			constraint survsimp_choi_sc_sc_nn not null
);

-- logic for scored survey redirection
create table survsimp_logic (
	logic_id	integer primary key,
	logic		text
);

create sequence survsimp_logic_id_seq;
create view survsimp_logic_id_sequence as select nextval('survsimp_logic_id_seq') as nextval;


-- map logic to surveys
create table survsimp_logic_surveys_map (
	logic_id	integer
			constraint survsimp_l_s_map_logic_id_nn not null 
			constraint survsimp_l_s_map_logic_id_fk
			references survsimp_logic(logic_id)
			on delete cascade,
	survey_id	integer
			constraint survsimp_l_s_map_sur_id_nn not null 
			constraint survsimp_l_s_map_sur_id_fk
			references survsimp_surveys(survey_id)
			on delete cascade
);
	

create index survsimp_response_index on survsimp_question_responses (response_id, question_id);

-- We create a view that selects out only the last response from each
-- user to give us at most 1 response from all users.
-- create or replace view survsimp_question_responses_un as 
-- select qr.* 
--  from survsimp_question_responses qr, survsimp_responses_unique r
--  where qr.response_id=r.response_id;

--
-- constructor function for a survsimp_survey
--

-- create or replace package body survsimp_survey
-- procedure new
create function survsimp_survey__new (integer,varchar,varchar,text,boolean,boolean,boolean,boolean,varchar,varchar,integer,integer)
returns integer as '
declare
  new__survey_id		alias for $1;  -- default null
  new__name			alias for $2;
  new__short_name		alias for $3;
  new__description		alias for $4;
  new__description_html_p	alias for $5;  -- default f
  new__single_response_p	alias for $6;  -- default f
  new__single_editable_p	alias for $7;  -- default t
  new__enabled_p		alias for $8;  -- default f
  new__type			alias for $9;  -- default general
  new__display_type             alias for $10;
  new__creation_user		alias for $11; -- default null
  new__context_id		alias for $12; -- default null
  v_survey_id			integer;
begin
    v_survey_id := acs_object__new (
	new__survey_id,
	''survsimp_survey'',
	now(),
	new__creation_user,
	null,
	new__context_id
    );

    insert into survsimp_surveys
    (survey_id, name, short_name, description, 
    description_html_p, single_response_p, single_editable_p, 
    enabled_p, type, display_type, package_id)
    values
    (v_survey_id, new__name, new__short_name, new__description, 
    new__description_html_p, new__single_response_p, new__single_editable_p, 
    new__enabled_p, new__type, new__display_type, new__context_id);

    return v_survey_id;

end;' language 'plpgsql';

-- procedure delete 
create function survsimp_survey__delete (integer)
returns integer as '
declare
  delete__survey_id		alias for $1;
begin
    delete from survsimp_surveys
    where survey_id = delete__survey_id;

    PERFORM acs_object__delete(delete__survey_id);

    return 0;

end;' language 'plpgsql';


-- create or replace package body survsimp_question
-- procedure new
create function survsimp_question__new (integer,integer,integer,text,varchar,boolean,boolean,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  new__question_id		alias for $1; -- default null
  new__survey_id		alias for $2; -- default null
  new__sort_key			alias for $3; -- default null
  new__question_text		alias for $4; -- default null
  new__abstract_data_type	alias for $5; -- default null
  new__required_p		alias for $6; -- default t
  new__active_p			alias for $7; -- default 
  new__presentation_type	alias for $8; -- default null
  new__presentation_options	alias for $9; -- default null
  new__presentation_alignment	alias for $10; -- default below
  new__creation_user		alias for $11; -- default null
  new__context_id		alias for $12; -- default null
  v_question_id			integer;
begin
    v_question_id := acs_object__new (
	new__question_id,
	''survsimp_question'',
	now(),
	new__creation_user,
	null,
	new__context_id
    );

    insert into survsimp_questions
    (question_id, survey_id, sort_key, question_text, 
    abstract_data_type, required_p, active_p, 
    presentation_type, presentation_options,
    presentation_alignment)
    values
    (v_question_id, new__survey_id, new__sort_key, new__question_text, 
    new__abstract_data_type, new__required_p, new__active_p, 
    new__presentation_type, new__presentation_options,
    new__presentation_alignment);

    return v_question_id;

end;' language 'plpgsql';

-- procedure delete 
create function survsimp_question__delete (integer)
returns integer as '
declare
  delete__question_id		alias for $1;
begin
    delete from survsimp_questions
    where question_id = delete__question_id;

    PERFORM acs_object__delete(delete__question_id);

    return 0;

end;' language 'plpgsql';


-- create or replace package body survsimp_response
-- procedure new
create function survsimp_response__new(integer,integer,varchar,boolean,integer,varchar,integer)
returns integer as '
declare
  new__response_id		alias for $1; -- default null
  new__survey_id		alias for $2; -- default null
  new__title 			alias for $3; -- default null
  new__notify_on_comment_p	alias for $4; -- default f
  new__creation_user		alias for $5; -- default null
  new__creation_ip		alias for $6; -- default null
  new__context_id		alias for $7; -- default null
  v_response_id			integer;
begin
    v_response_id := acs_object__new (
	new__response_id,
	''survsimp_response'',
	now(),
	new__creation_user,
	new__creation_ip,
	new__context_id
    );

    insert into survsimp_responses 
    (response_id, survey_id, title, notify_on_comment_p)
    values
    (v_response_id, new__survey_id, new__title, new__notify_on_comment_p);

    return v_response_id;

end;' language 'plpgsql';


-- procedure delete 
create function survsimp_response__delete(integer)
returns integer as '
declare
  delete__response_id		alias for $1;
begin
    delete from survsimp_responses
    where response_id = delete__response_id;

    PERFORM acs_object__delete(delete__response_id);

    return 0;

end;' language 'plpgsql';

