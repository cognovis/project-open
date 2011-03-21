create table cr_workflows (
  case_id        integer
                 constraint cr_workflows_pk 
                 primary key
                 constraint cr_workflows_case_id_fk
                 references wf_cases
);

create or replace function inline_0 ()
returns integer as '
declare
  v_workflow_key varchar(100);

begin
   raise notice ''creating publishing_wf workflow'';
   v_workflow_key := workflow__create_workflow(
      ''publishing_wf'',
      ''Simple Publishing Workflow'',
      ''Simple Publishing Workflows'',
      ''A simple linear workflow for authoring, 
        editing and scheduling content items.'',
      ''cr_workflows'',
      ''case_id''
      );

    /*****
     * Places 
     *****/

    perform workflow__add_place(
            ''publishing_wf'',
            ''start'',
            ''Created'',
            1
            );

    perform workflow__add_place(
            ''publishing_wf'',
            ''authored'',
            ''Authored'',
            2
            );

    perform workflow__add_place(
            ''publishing_wf'',
            ''edited'',
            ''Edited'',
            3
            );            

    perform workflow__add_place(
            ''publishing_wf'',
            ''end'',
            ''Approved'',
            4
            );

    /*****
     * Roles
     *****/

    perform workflow__add_role(
        ''publishing_wf'',
        ''approval'',
        ''Approval'',
        2
    );

    perform workflow__add_role(
        ''publishing_wf'',
        ''authoring'',
        ''Authoring'',
        1
    );

    perform workflow__add_role(
        ''publishing_wf'',
        ''editing'',
        ''Editing'',
        2
    );
    /*****
     * Transitions 
     *****/

    perform workflow__add_transition(
            ''publishing_wf'',
            ''authoring'',
            ''Authoring'',
            ''authoring'',
            1,
            ''user''
            );

    perform workflow__add_transition(
            ''publishing_wf'',
            ''editing'',
            ''Editing'',
            ''editing'',
            2,
            ''user''
            );

    perform workflow__add_transition(
            ''publishing_wf'',
            ''approval'',
            ''Approval'',
            ''approval'',
            3,
            ''user''
            );                                    
   return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

begin;


    select workflow__add_arc(
            'publishing_wf',
            'start',
            'authoring'
            );

    select workflow__add_arc(
            'publishing_wf',
            'authoring',
            'authored',
            'publishing_wf__is_next',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'authoring',
            'start',
            '#',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'authored',
             'editing'
           );

            
    select workflow__add_arc(
            'publishing_wf',
            'editing',
            'authored',
            '#',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'editing',
            'edited',
            'publishing_wf__is_next',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'editing',
            'start',
            'publishing_wf__is_next',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'edited',
            'approval'
            );

    select workflow__add_arc(
            'publishing_wf',
            'approval',
            'edited',
            '#',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'approval',
            'end',
            'publishing_wf__is_next',
            null,
            null
            );

    select workflow__add_arc(
            'publishing_wf',
            'approval',
            'authored',
            'publishing_wf__is_next',
            null,
            null
            );


    select workflow__add_arc(
            'publishing_wf',
            'approval',
            'start',
            'publishing_wf__is_next',
            null,
            null
            );

end;
 
-- show errors

-- create or replace package publishing_wf as
-- 
--   -- simply check the 'next_place' attribute and return true if
--   -- it matches the submitted place_key
-- 
--   function is_next (
--     case_id           in number, 
--     workflow_key      in varchar, 
--     transition_key    in varchar, 
--     place_key         in varchar, 
--     direction	      in varchar, 
--     custom_arg	      in varchar
--   ) return char;
-- 
-- end publishing_wf;

-- show errors

-- create or replace package body publishing_wf as
-- function is_next
create or replace function publishing_wf__is_next (integer,varchar,varchar,varchar,varchar,varchar)
returns char as '
declare
  p_case_id                        alias for $1;  
  p_workflow_key                   alias for $2;  
  p_transition_key                 alias for $3;  
  p_place_key                      alias for $4;  
  p_direction                      alias for $5;  
  p_custom_arg                     alias for $6;  
  v_next_place                     varchar(100);  
  v_result                         boolean;
begin

    v_next_place := workflow_case__get_attribute_value(p_case_id,''next_place'');

    if v_next_place = p_place_key then
      v_result := ''t'';
    end if;
     
    return v_result;
   
end;' language 'plpgsql';


create or replace function inline_2 ()
returns integer as '
declare
    v_attribute_id acs_attributes.attribute_id%TYPE;
begin
    v_attribute_id := workflow__create_attribute(
	''publishing_wf'',
	''next_place'',
	''string'',
	''Next Place'',
        null,
        null,
        null,
	''start'',
        1,
        1,
        null,
        ''generic''
    );

    perform workflow__add_trans_attribute_map (
            ''publishing_wf'',
            ''authoring'',
            v_attribute_id,
            1);

    perform workflow__add_trans_attribute_map (
            ''publishing_wf'',
            ''editing'',
            v_attribute_id,
            1);
            
    perform workflow__add_trans_attribute_map (
            ''publishing_wf'',
            ''approval'',
            v_attribute_id,
            1);

    perform workflow__add_trans_role_assign_map(
            ''publishing_wf'',
            ''authoring'',
            ''authoring'');

    return 0;
end;' language 'plpgsql';

select inline_2 ();

drop function inline_2 ();


-- show errors

