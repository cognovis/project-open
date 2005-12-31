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

-- gilbertw - logical_negation is defined in utilities-create.sql in acs-kernel
-- this is a PL/SQL function that used to be in the standard ACS 3.x core - not in the
-- current ACS 4.0 core however...
-- create or replace function logical_negation(true_or_false IN varchar)
-- return varchar
-- is
-- BEGIN
--   IF true_or_false is null THEN
--     return null;
--   ELSIF true_or_false = 'f' THEN
--     return 't';
--   ELSE
--     return 'f';
--   END IF;
-- END logical_negation;
-- /
-- show errors

begin

	acs_privilege.create_privilege('survsimp_create_survey');
	acs_privilege.create_privilege('survsimp_modify_survey');
	acs_privilege.create_privilege('survsimp_delete_survey');
	acs_privilege.create_privilege('survsimp_create_question');
	acs_privilege.create_privilege('survsimp_modify_question');
	acs_privilege.create_privilege('survsimp_delete_question');
	acs_privilege.create_privilege('survsimp_take_survey');

	acs_privilege.create_privilege('survsimp_admin_survey');

	acs_privilege.add_child('survsimp_admin_survey','survsimp_create_survey');
	acs_privilege.add_child('survsimp_admin_survey','survsimp_modify_survey');
	acs_privilege.add_child('survsimp_admin_survey','survsimp_delete_survey');
	acs_privilege.add_child('survsimp_admin_survey','survsimp_create_question');
	acs_privilege.add_child('survsimp_admin_survey','survsimp_modify_question');
	acs_privilege.add_child('survsimp_admin_survey','survsimp_delete_question');

	acs_privilege.add_child('read','survsimp_take_survey');
	acs_privilege.add_child('admin','survsimp_admin_survey');

	acs_object_type.create_type (
		supertype => 'acs_object',
		object_type => 'survsimp_survey',
		pretty_name => 'Simple Survey',
		pretty_plural => 'Simple Surveys',
		table_name => 'SURVSIMP_SURVEYS',
		id_column => 'SURVEY_ID'
	);

	acs_object_type.create_type (
		supertype => 'acs_object',
		object_type => 'survsimp_question',
		pretty_name => 'Simple Survey Question',
		pretty_plural => 'Simple Survey Questions',
		table_name => 'SURVSIMP_QUESTIONS',
		id_column => 'QUESTION_ID'
	);

	acs_object_type.create_type (
		supertype => 'acs_object',
		object_type => 'survsimp_response',
		pretty_name => 'Simple Survey Response',
		pretty_plural => 'Simple Survey Responses',
		table_name => 'SURVSIMP_RESPONSES',
		id_column => 'RESPONSE_ID'
	);

	acs_rel_type.create_type (
		rel_type => 'user_blob_response_rel',
		pretty_name => 'User Blob Response',
		pretty_plural => 'User Blob Responses',
		object_type_one => 'user',
		role_one => 'user',
		table_name => 'survsimp_question_responses',
		id_column => 'response_id',
		package_name => 'user_blob_response_rel',
		min_n_rels_one => 1,
		max_n_rels_one => 1,
		object_type_two => 'content_item',
		min_n_rels_two => 0,
		max_n_rels_two => 1
	);

end;
/
show errors

create table survsimp_surveys (
	survey_id		constraint survsimp_surveys_survey_id_fk
				references acs_objects (object_id)
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
	description		varchar(4000)
				constraint survsimp_surveys_desc_nn
				not null,
        description_html_p      char(1)
                                constraint survsimp_surv_desc_html_p_ck
				check(description_html_p in ('t','f')),
	enabled_p               char(1)
				constraint survsimp_surveys_enabled_p_ck
				check(enabled_p in ('t','f')),
	-- limit to one response per user
	single_response_p	char(1)
				constraint survsimp_sur_single_resp_p_ck
				check(single_response_p in ('t','f')),
	single_editable_p	char(1)
				constraint survsimp_surv_single_edit_p_ck
				check(single_editable_p in ('t','f')),
	type                    varchar(20),
        display_type            varchar(20),
        package_id              integer
                                constraint survsimp_package_id_nn not null
                                constraint survsimp_package_id_fk references
                                apm_packages (package_id) on delete cascade
);

-- each question can be 

create table survsimp_questions (
	question_id		constraint survsimp_q_question_id_fk
				references acs_objects (object_id)
				constraint survsimp_q_question_id_pk
				primary key,
	survey_id		constraint survsimp_q_survey_id_fk
				references survsimp_surveys,
	sort_key		integer
				constraint survsimp_q_sort_key_nn
				not null,
	question_text		clob
				constraint survsimp_q_question_text_nn
				not null,
        abstract_data_type      varchar(30)
				constraint survsimp_q_abs_data_type_ck
				check (abstract_data_type in ('text', 'shorttext', 'boolean', 'number', 'integer', 'choice', 'date')),
	required_p		char(1)
				constraint survsimp_q_required_p_ck
				check (required_p in ('t','f')),
	active_p		char(1)
				constraint survsimp_q_qctive_p_ck
				check (active_p in ('t','f')),
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

create sequence survsimp_choice_id_sequence start with 1;

create table survsimp_question_choices (
        choice_id       integer constraint survsimp_qc_choice_id_nn
                        not null
                        constraint survsimp_qc_choice_id_pk
                        primary key,
        question_id     constraint survsimp_qc_question_id_nn
                        not null
                        constraint survsimp_qc_question_id_fk
                        references survsimp_questions,
        -- human readable
        label           varchar(500) constraint survsimp_qc_label_nn                                    not null,
        -- might be useful for averaging or whatever, generally null
        numeric_value   number,
        -- lower is earlier
        sort_order      integer
);

-- this records a response by one user to one survey
-- (could also be a proposal in which case we'll do funny 
--  things like let the user give it a title, send him or her
--  email if someone comments on it, etc.)
create table survsimp_responses (
	response_id		constraint survsimp_resp_response_id_fk
				references acs_objects (object_id)
				constraint srvsimp_resp_response_id_pk
				primary key,
	survey_id		constraint survsimp_resp_survey_id_fk
				references survsimp_surveys,
	title			varchar(100),
	notify_on_comment_p	char(1)
				constraint survsimp_resp_noton_com_p_ck
				check(notify_on_comment_p in ('t','f'))
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

create or replace view survsimp_responses_unique as
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
	response_id		not null references survsimp_responses,
	question_id		not null references survsimp_questions,
	-- if the user picked a canned response
	choice_id		references survsimp_question_choices,
	boolean_answer		char(1) check(boolean_answer in ('t','f')),
	clob_answer		clob,
	number_answer		number,
	varchar_answer		varchar(4000),
	date_answer		date,
	-- columns useful for attachments, column names
	-- lifted from file-storage.sql and bboard.sql
	-- this is where the actual content is stored
	attachment_answer	blob,
	-- file name including extension but not path
	attachment_file_name	varchar(500),
	attachment_file_type	varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	attachment_file_extension varchar(50) 	-- e.g., "jpg"
);

-- We create a view that selects out only the last response from each
-- user to give us at most 1 response from all users.
create or replace view survsimp_question_responses_un as
select qr.*
  from survsimp_question_responses qr, survsimp_responses_unique r
 where qr.response_id=r.response_id;  

-- sequence for variable names
create sequence survsimp_variable_id_sequence start with 1;

-- variable names for scored surveys
create table survsimp_variables (
	variable_id	integer primary key,
	variable_name	varchar(100) not null
);

-- map variable names to surveys
create table survsimp_variables_surveys_map (
	variable_id 	not null references survsimp_variables,
	survey_id	not null references survsimp_surveys
);

-- scores for scored responses
create table survsimp_choice_scores (
	choice_id	not null references survsimp_question_choices,
	variable_id	not null references survsimp_variables,
	score		integer not null
);

-- logic for scored survey redirection
create table survsimp_logic (
	logic_id	integer primary key,
	logic		clob
);

create sequence survsimp_logic_id_sequence start with 1;

-- map logic to surveys
create table survsimp_logic_surveys_map (
	logic_id	not null references survsimp_logic,
	survey_id	not null references survsimp_surveys
);
	
create index survsimp_response_index on survsimp_question_responses (response_id, question_id);

-- We create a view that selects out only the last response from each
-- user to give us at most 1 response from all users.
-- create or replace view survsimp_question_responses_un as 
-- select qr.* 
--  from survsimp_question_responses qr, survsimp_responses_unique r
--  where qr.response_id=r.response_id;

@@ simple-survey-package-create.sql
