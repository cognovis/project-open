--
-- drop SQL for survsimp package
--
-- by nstrug@arsdigita.com on 29th September 2000
--
-- $Id$

select drop_package('survsimp_response');
select drop_package('survsimp_question');
select drop_package('survsimp_survey');

drop table survsimp_logic_surveys_map;
drop view survsimp_logic_id_sequence;
drop sequence survsimp_logic_id_seq;
drop table survsimp_logic;
drop table survsimp_choice_scores;
drop table survsimp_variables_surveys_map;
drop table survsimp_variables;
drop view survsimp_variable_id_sequence;
drop sequence survsimp_variable_id_seq;
drop view survsimp_question_responses_un;
drop table survsimp_question_responses;
drop view survsimp_responses_unique;
drop table survsimp_responses;
drop table survsimp_question_choices;
drop view survsimp_choice_id_sequence;
drop sequence survsimp_choice_id_seq;
drop table survsimp_questions;
drop table survsimp_surveys;

-- nuke all created objects
-- need to do this before nuking the types
delete from acs_objects where object_type = 'survsimp_response';
delete from acs_objects where object_type = 'survsimp_question';
delete from acs_objects where object_type = 'survsimp_survey';

create function inline_0 ()
returns integer as '
begin
  PERFORM acs_rel_type__drop_type (''user_blob_response_rel'',''f'');

  PERFORM acs_object_type__drop_type (''survsimp_response'',''f'');
  PERFORM acs_object_type__drop_type (''survsimp_question'',''f'');
  PERFORM acs_object_type__drop_type (''survsimp_survey'',''f'');

  PERFORM acs_privilege__remove_child (''admin'',''survsimp_admin_survey'');
  PERFORM acs_privilege__remove_child (''read'',''survsimp_take_survey'');
  PERFORM acs_privilege__remove_child (''survsimp_admin_survey'',''survsimp_delete_question'');
  PERFORM acs_privilege__remove_child (''survsimp_admin_survey'',''survsimp_modify_question'');
  PERFORM acs_privilege__remove_child (''survsimp_admin_survey'',''survsimp_create_question'');
  PERFORM acs_privilege__remove_child (''survsimp_admin_survey'',''survsimp_delete_survey'');
  PERFORM acs_privilege__remove_child (''survsimp_admin_survey'',''survsimp_modify_survey'');
  PERFORM acs_privilege__remove_child (''survsimp_admin_survey'',''survsimp_create_survey'');
  
  PERFORM acs_privilege__drop_privilege(''survsimp_admin_survey''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_take_survey''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_delete_question''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_modify_question''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_create_question''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_delete_survey''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_modify_survey''); 
  PERFORM acs_privilege__drop_privilege(''survsimp_create_survey''); 

  return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();

-- gilbertw - logical_negation is defined in utilities-create.sql in acs-kernel
-- drop function logical_negation(boolean);


