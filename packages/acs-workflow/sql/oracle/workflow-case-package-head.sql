--
-- acs-workflow/sql/workflow-case-package-head.sql
--
-- Creates the PL/SQL package that provides the API for interacting
-- with a workflow case.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

create or replace package workflow_case
is

    function new (
        case_id         in number default null,
        workflow_key    in varchar2,
        context_key     in varchar2 default null,
        object_id       in integer,
        creation_date   in date default sysdate,
        creation_user   in integer default null,
        creation_ip     in varchar2 default null
    ) return integer;

    procedure add_manual_assignment (
        case_id         in number,
        role_key        in varchar2,
        party_id        in number
    );
  
    procedure remove_manual_assignment (
        case_id         in number,
        role_key        in varchar2,
        party_id        in number
    );
  
    procedure clear_manual_assignments (
        case_id         in number,
        role_key        in varchar2
    );
  
    procedure start_case (
        case_id         in number,
        creation_user   in integer default null,
        creation_ip     in varchar2 default null,
        msg             in varchar2 default null
    );

    procedure del (
        case_id         in number
    );

    procedure suspend(
        case_id         in number,
        user_id         in number default null,
        ip_address      in varchar2 default null,
        msg             in varchar2 default null
    );

    procedure resume(
        case_id         in number,
        user_id         in number default null,
        ip_address      in varchar2 default null,
        msg             in varchar2 default null
    );

    procedure cancel(
        case_id         in number,
        user_id         in number default null,
        ip_address      in varchar2 default null,
        msg             in varchar2 default null
    );

    procedure fire_message_transition (
        task_id         in number
    );

    /* To perform an action on the workflow: 
     * (numbers in parenthesis is the number of times each function should get called)
     *
     * 1. begin_task_action (1) (returns journal_id)
     * 2. set_attribute_value (0..*)
     * 3. clear_manual_assignments (0..1)
     * 4. add_manual_assignment (0..*)
     * 5. end_task_action (1)
     */
    function begin_task_action (
        task_id         in number,
        action          in varchar2,
        action_ip       in varchar2,
        user_id         in number,
        msg             in varchar2 default null
    ) return number;

    procedure set_attribute_value (
        journal_id      in number,
        attribute_name  in varchar2,
        value           in varchar2
    );

    procedure end_task_action (
        journal_id      in number,
        action          in varchar2,
        task_id         in number
    );

    /* Shortcut, that does both begin and end, when you have no attributes to set or assignments to make */
    function task_action (
        task_id         in number,
        action          in varchar2,
        action_ip       in varchar2,
        user_id         in number,
        msg             in varchar2 default null
    ) return number;

    function get_attribute_value (
        case_id         in number,
        attribute_name  in varchar2
    ) return varchar2;

    procedure add_task_assignment (
        task_id         in number,
        party_id        in number,
        permanent_p     in char default 'f'
    );

    procedure remove_task_assignment (
        task_id         in number,
        party_id        in number,
        permanent_p     in char default 'f'
    );

    procedure clear_task_assignments (
        task_id         in number,
        permanent_p     in char default 'f'
    );

    procedure set_case_deadline (
        case_id         in wf_cases.case_id%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE,
        deadline        date
    );

    procedure remove_case_deadline (
        case_id         in wf_cases.case_id%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE
    );

    -- DRB: I added this function because there appeared to be no way for a
    -- client to get the task_id without querying the wf_tasks table directly,
    -- breaking the PL/SQL abstraction.

    function get_task_id (
        case_id         in wf_cases.case_id%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE
    ) return wf_tasks.task_id%TYPE;

    /* DBMS_JOBS */

    procedure sweep_timed_transitions;

    procedure sweep_hold_timeout;

end workflow_case;
/
show errors;
