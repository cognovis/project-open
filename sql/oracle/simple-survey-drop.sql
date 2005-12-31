--
-- drop SQL for survsimp package
--
-- by nstrug@arsdigita.com on 29th September 2000
--
-- $Id$

@@ simple-survey-package-drop.sql

drop table survsimp_logic_surveys_map cascade constraints;

drop sequence survsimp_logic_id_sequence;
drop table survsimp_logic;
drop table survsimp_choice_scores cascade constraints;
drop table survsimp_variables_surveys_map cascade constraints;
drop table survsimp_variables;

drop sequence survsimp_variable_id_sequence;
drop view survsimp_question_responses_un;
drop table survsimp_question_responses cascade constraints;
drop view survsimnp_responses_unique;
drop table survsimp_responses cascade constraints;
drop table survsimp_question_choices cascade constraints;

drop sequence survsimp_choice_id_sequence;
drop table survsimp_questions cascade constraints;
drop table survsimp_surveys cascade constraints;

-- nuke all created objects
-- need to do this before nuking the types
delete from acs_objects where object_type = 'survsimp_response';
delete from acs_objects where object_type = 'survsimp_question';
delete from acs_objects where object_type = 'survsimp_survey';

begin
	acs_rel_type.drop_type('user_blob_response_rel');

	acs_object_type.drop_type ('survsimp_response');
	acs_object_type.drop_type ('survsimp_question');
	acs_object_type.drop_type ('survsimp_survey');

	acs_privilege.remove_child ('admin','survsimp_admin_survey');
	acs_privilege.remove_child ('read','survsimp_take_survey');
	acs_privilege.remove_child ('survsimp_admin_survey','survsimp_delete_question');
	acs_privilege.remove_child ('survsimp_admin_survey','survsimp_modify_question');
	acs_privilege.remove_child ('survsimp_admin_survey','survsimp_create_question');
	acs_privilege.remove_child ('survsimp_admin_survey','survsimp_delete_survey');
	acs_privilege.remove_child ('survsimp_admin_survey','survsimp_modify_survey');
	acs_privilege.remove_child ('survsimp_admin_survey','survsimp_create_survey');

	acs_privilege.drop_privilege('survsimp_admin_survey');
	acs_privilege.drop_privilege('survsimp_take_survey');
	acs_privilege.drop_privilege('survsimp_delete_question');
	acs_privilege.drop_privilege('survsimp_modify_question');
	acs_privilege.drop_privilege('survsimp_create_question');
	acs_privilege.drop_privilege('survsimp_delete_survey');
	acs_privilege.drop_privilege('survsimp_modify_survey');
	acs_privilege.drop_privilege('survsimp_create_survey');


end;
/
show errors

-- gilbertw - logical_negation is defined in utilities-create.sql in acs-kernel
-- drop function logical_negation;

