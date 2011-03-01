
/*
 * Business Process Definition: Simple Publishing Workflow (publishing_wf)
 *
 *
 * Context: default
 */


/*
 * Cases table
 */
create table publishing_wf_cases (
  case_id               integer primary key
                        references wf_cases on delete cascade
);

/* 
 * Declare the object type
 */

declare
    v_workflow_key varchar2(40);
begin
    v_workflow_key := workflow.create_workflow(
        workflow_key => 'publishing_wf', 
        pretty_name => 'Simple Publishing Workflow', 
        pretty_plural => 'Simple Publishing Workflows', 
        description => 'A simple linear workflow for authoring,
                          editing and scheduling content items.', 
        table_name => 'publishing_wf_cases'
    );
end;
/
show errors

        


/*****
 * Places
 *****/

begin
    workflow.add_place(
        workflow_key => 'publishing_wf',
        place_key    => 'start', 
        place_name   => 'Created', 
        sort_order   => 1
    );
end;
/
show errors 
        
begin
    workflow.add_place(
        workflow_key => 'publishing_wf',
        place_key    => 'authored', 
        place_name   => 'Authored', 
        sort_order   => 2
    );
end;
/
show errors 
        
begin
    workflow.add_place(
        workflow_key => 'publishing_wf',
        place_key    => 'edited', 
        place_name   => 'Edited', 
        sort_order   => 3
    );
end;
/
show errors 
        
begin
    workflow.add_place(
        workflow_key => 'publishing_wf',
        place_key    => 'end', 
        place_name   => 'Approved', 
        sort_order   => 4
    );
end;
/
show errors 
        
/*****
 * Roles
 *****/


begin
    workflow.add_role(
        workflow_key => 'publishing_wf',
        role_key     => 'approval',
        role_name    => 'Approval',
        sort_order   => 3
    );
end;
/
show errors
        
begin
    workflow.add_role(
        workflow_key => 'publishing_wf',
        role_key     => 'authoring',
        role_name    => 'Authoring',
        sort_order   => 1
    );
end;
/
show errors
        
begin
    workflow.add_role(
        workflow_key => 'publishing_wf',
        role_key     => 'editing',
        role_name    => 'Editing',
        sort_order   => 2
    );
end;
/
show errors
        

/*****
 * Transitions
 *****/


begin
    workflow.add_transition(
        workflow_key    => 'publishing_wf',
        transition_key  => 'authoring',
        transition_name => 'Authoring',
        role_key        => 'authoring',
        sort_order      => 1,
        trigger_type    => 'user'
    );
end;
/
show errors
        
begin
    workflow.add_transition(
        workflow_key    => 'publishing_wf',
        transition_key  => 'editing',
        transition_name => 'Editing',
        role_key        => 'editing',
        sort_order      => 2,
        trigger_type    => 'user'
    );
end;
/
show errors
        
begin
    workflow.add_transition(
        workflow_key    => 'publishing_wf',
        transition_key  => 'approval',
        transition_name => 'Approval',
        role_key        => 'approval',
        sort_order      => 3,
        trigger_type    => 'user'
    );
end;
/
show errors
        

/*****
 * Arcs
 *****/


begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'authoring',
        place_key             => 'start',
        direction             => 'in',
        guard_callback        => '',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors

begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'authoring',
        place_key             => 'authored',
        direction             => 'out',
        guard_callback        => 'publishing_wf.is_next',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors

begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'authoring',
        place_key             => 'start',
        direction             => 'out',
        guard_callback        => '#',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors

begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'editing',
        place_key             => 'authored',
        direction             => 'in',
        guard_callback        => '',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
        
begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'editing',
        place_key             => 'authored',
        direction             => 'out',
        guard_callback        => '#',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
        


begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'editing',
        place_key             => 'edited',
        direction             => 'out',
        guard_callback        => 'publishing_wf.is_next',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors

        
begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'editing',
        place_key             => 'start',
        direction             => 'out',
        guard_callback        => 'publishing_wf.is_next',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
        
begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'approval',
        place_key             => 'edited',
        direction             => 'in',
        guard_callback        => '',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
        

        
begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'approval',
        place_key             => 'edited',
        direction             => 'out',
        guard_callback        => '#',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
               


begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'approval',
        place_key             => 'end',
        direction             => 'out',
        guard_callback        => 'publishing_wf.is_next',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
                

begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'approval',
        place_key             => 'authored',
        direction             => 'out',
        guard_callback        => 'publishing_wf.is_next',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors
        

begin
    workflow.add_arc(
        workflow_key          => 'publishing_wf',
        transition_key        => 'approval',
        place_key             => 'start',
        direction             => 'out',
        guard_callback        => 'publishing_wf.is_next',
        guard_custom_arg      => '',
        guard_description     => ''
    );
end;
/
show errors



create or replace package publishing_wf as

  -- simply check the 'next_place' attribute and return true if
  -- it matches the submitted place_key

  function is_next (
    case_id           in number, 
    workflow_key      in varchar, 
    transition_key    in varchar, 
    place_key         in varchar, 
    direction	      in varchar, 
    custom_arg	      in varchar
  ) return char;

end publishing_wf;
/
show errors

create or replace package body publishing_wf as

  function is_next (
    case_id           in number, 
    workflow_key      in varchar, 
    transition_key    in varchar, 
    place_key         in varchar, 
    direction	      in varchar, 
    custom_arg	      in varchar
  ) return char is

    v_next_place varchar(100);
    v_result char(1) := 'f';

  begin

    v_next_place := workflow_case.get_attribute_value(case_id, 'next_place');

    if v_next_place = place_key then
      v_result := 't';
    end if;
     
    return v_result;

  end is_next;
  
end publishing_wf;
/
show errors


/*****
 * Attributes
 *****/


declare
    v_attribute_id number;
begin
    v_attribute_id := workflow.create_attribute(
        workflow_key => 'publishing_wf',
        attribute_name => 'next_place',
        datatype => 'string',
        pretty_name => 'Next Place',
        default_value => 'start'
    );
end;
/
show errors
        
begin
    workflow.add_trans_attribute_map(
        workflow_key   => 'publishing_wf', 
        transition_key => 'authoring',
        attribute_name => 'next_place',
        sort_order     => 1
    );
end;
/
show errors

        
begin
    workflow.add_trans_attribute_map(
        workflow_key   => 'publishing_wf', 
        transition_key => 'editing',
        attribute_name => 'next_place',
        sort_order     => 1
    );
end;
/
show errors

begin
    workflow.add_trans_attribute_map(
        workflow_key   => 'publishing_wf', 
        transition_key => 'approval',
        attribute_name => 'next_place',
        sort_order     => 1
    );
end;
/
show errors
        

begin
    workflow.add_trans_role_assign_map(
        workflow_key   => 'publishing_wf', 
        transition_key => 'authoring',
        assign_role_key => 'authoring'
    );
end;
/
show errors
        

        
/*****
 * Transition-role-assignment-map
 *****/



/*
 * Context/Transition info
 * (for context = default)
 */



/*
 * Context/Role info
 * (for context = default)
 */



/*
 * Context Task Panels
 * (for context = default)
 */


commit;
