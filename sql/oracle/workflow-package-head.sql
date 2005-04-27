--
-- acs-workflow/sql/workflow-package-head.sql
--
-- Creates the PL/SQL package that provides the API for defining and dropping
-- workflow cases.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

create or replace package workflow
as

    /* Call this function after you have created a table */
    function create_workflow (
        workflow_key 		in varchar2,
        pretty_name 		in varchar2, 
        pretty_plural 		in varchar2 default null,
        description 		in varchar2 default null,
        table_name 		in varchar2,
        id_column 		in varchar2 default 'case_id'
    ) return varchar2;

    procedure drop_workflow (
        workflow_key 		in varchar2
    );

    procedure delete_cases (
	workflow_key 		in varchar2
    );

    function create_attribute ( 
        workflow_key 		in varchar2,
        attribute_name 		in varchar2,
        datatype 		in varchar2,
        pretty_name 		in varchar2,
        pretty_plural 		in varchar2 default null,
        table_name 		in varchar2 default null,
        column_name 		in varchar2 default null,
        default_value 		in varchar2 default null,
        min_n_values 		in integer default 1,
        max_n_values 		in integer default 1,
        sort_order 		in integer default null,
        storage 		in varchar2 default 'generic'
    ) return acs_attributes.attribute_id%TYPE;

    procedure drop_attribute (
        workflow_key 		in varchar2,
	attribute_name 		in varchar2
    );

    procedure add_place (
	workflow_key		in acs_object_types.object_type%TYPE,
	place_key		in wf_places.place_key%TYPE,
	place_name		in wf_places.place_name%TYPE,
	sort_order		in wf_places.sort_order%TYPE default null
    );

    procedure delete_place (
	workflow_key		in acs_object_types.object_type%TYPE,
	place_key		in wf_places.place_key%TYPE
    );

    procedure add_role (
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE,
        role_name               in wf_roles.role_name%TYPE,
        sort_order		in wf_roles.sort_order%TYPE default null
    );

    procedure move_role_up(
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE
    );

    procedure move_role_down(
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE
    );

    procedure delete_role (
        workflow_key            in acs_object_types.object_type%TYPE,
        role_key                in wf_roles.role_key%TYPE
    );        

    procedure add_transition (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_transitions.transition_key%TYPE,
	transition_name		in wf_transitions.transition_name%TYPE,
        role_key                in wf_roles.role_key%TYPE default null,
	sort_order		in wf_transitions.sort_order%TYPE default null,
	trigger_type		in wf_transitions.trigger_type%TYPE default 'user'
    );

    procedure delete_transition (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_transitions.transition_key%TYPE
    );

    procedure add_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_arcs.transition_key%TYPE,
	place_key		in wf_arcs.place_key%TYPE,
	direction 		in wf_arcs.direction%TYPE,
	guard_callback	 	in wf_arcs.guard_callback%TYPE default null,
	guard_custom_arg	in wf_arcs.guard_custom_arg%TYPE default null,
	guard_description	in wf_arcs.guard_description%TYPE default null
    );

    procedure add_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	from_transition_key  	in wf_arcs.transition_key%TYPE,
	to_place_key		in wf_arcs.place_key%TYPE,
	guard_callback	 	in wf_arcs.guard_callback%TYPE default null,
	guard_custom_arg	in wf_arcs.guard_custom_arg%TYPE default null,
	guard_description	in wf_arcs.guard_description%TYPE default null
    );

    procedure add_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	from_place_key		in wf_arcs.place_key%TYPE,
	to_transition_key  	in wf_arcs.transition_key%TYPE
    );

    procedure delete_arc (
	workflow_key		in acs_object_types.object_type%TYPE,
	transition_key  	in wf_arcs.transition_key%TYPE,
	place_key		in wf_arcs.place_key%TYPE,
	direction 		in wf_arcs.direction%TYPE
    );

    procedure add_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_id            in acs_attributes.attribute_id%TYPE,
        sort_order              in wf_transition_attribute_map.sort_order%TYPE default null
    );

    procedure add_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_name          in acs_attributes.attribute_name%TYPE,
        sort_order              in wf_transition_attribute_map.sort_order%TYPE default null
    );

    procedure delete_trans_attribute_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        attribute_id            in acs_attributes.attribute_id%TYPE
    );

    procedure add_trans_role_assign_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        assign_role_key         in wf_roles.role_key%TYPE
    );

    procedure delete_trans_role_assign_map(
        workflow_key            in wf_workflows.workflow_key%TYPE,
        transition_key          in wf_transitions.transition_key%TYPE,
        assign_role_key         in wf_roles.role_key%TYPE
    );    

    /*
     * A simple workflow is essentially one that we can display nicely using HTML tables.
     * More specifically, it's a workflow containing only sequential routing and 
     * simple iteration, where the choice is always between moving to the next task
     * in the sequence or looping back to some prior task.
     */

    function simple_p (
	workflow_key	in varchar2
    ) return char;

end workflow;
/
show errors






