--
-- acs-workflow/sql/sample-article-create.sql
--
-- Creates a sample article-authoring workflow to play with
--
-- @author Kevin Scaldeferri (kevin@theory.caltech.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

/* This table will hold one row for each case using this workflow. */
create table wf_article_cases (
  case_id 		integer primary key
			constraint wf_article_cases_case_fk
			references wf_cases on delete cascade
);

create function inline_0 () returns integer as '
declare
    v_workflow_key wf_workflows.workflow_key%TYPE;
    v_attribute_id acs_attributes.attribute_id%TYPE;
begin
    v_workflow_key := workflow__create_workflow(
	''article_wf'', 
	''Article Publication'', 
	''Article Publications'', 
	''Workflow for managing the publication of an article'',
	''wf_article_cases'',
	''case_id''
    );

    /*****
     * Places 
     *****/
 
    perform workflow__add_place(
        ''article_wf'',
        ''start'',
        ''Start place'',
        1
    );

    perform workflow__add_place(
        ''article_wf'',
        ''to_be_written'', 
	''Needs to be written'', 
        2
    );

    perform workflow__add_place(
        ''article_wf'',
        ''to_be_reviewed'', 
	''Needs review'', 
        3
    );

    perform workflow__add_place(
        ''article_wf'',
        ''to_be_published'', 
	''Ready to go to press'', 
        4
    );

    perform workflow__add_place(
        ''article_wf'',
        ''end'', 
	''End place'', 
        5
    );

    /*****
     * Roles
     *****/

    perform workflow__add_role(
        ''article_wf'',
        ''author'',
        ''Author'',
        1
    );

    perform workflow__add_role(
        ''article_wf'',
        ''editor'',
        ''Editor'',
        2
    );

    /*****
     * Transitions 
     *****/

    perform workflow__add_transition(
        ''article_wf'',
        ''specify'',
        ''Describe task and assign author'',
        ''editor'',
        1,
        ''user''
    );
        
    perform workflow__add_transition(
        ''article_wf'',
        ''write'',
        ''Write article'',
        ''author'',
        2,
        ''user''
    );
        
    perform workflow__add_transition(
        ''article_wf'',
        ''review'',
        ''Review article'',
        ''editor'',
        3,
        ''user''
    );
        
    perform workflow__add_transition(
        ''article_wf'',
        ''publish'',
        ''Publish article'',
	null,
        4,
        ''automatic''
    );

    /*****
     * Arcs 
     *****/

    perform workflow__add_arc(
        ''article_wf'',
        ''start'',
        ''specify''
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''specify'',
        ''to_be_written'',
	null,
	null,
	null
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''to_be_written'',
        ''write''
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''write'',
        ''to_be_reviewed'',
	null,
	null,
	null
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''to_be_reviewed'',
        ''review''
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''review'',
        ''to_be_published'',
        ''wf_callback__guard_attribute_true'',
        ''reviewer_ok'',
        ''Reviewer approved article''
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''review'',
        ''to_be_written'',
        ''#'',
	null,
        ''Reviewer did not approve article''
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''to_be_published'',
        ''publish''
    );

    perform workflow__add_arc(
        ''article_wf'',
        ''publish'',
        ''end'',
	null,
	null,
	null
    );

    /*****
     * Attributes
     *****/

    v_attribute_id := workflow__create_attribute(
	''article_wf'',
	''reviewer_ok'',
	''boolean'',
	''Reviewer Approval'',
        null,
        null,
        null,        
        ''f'',
        1,
        1,
        null,
        ''generic''
    );

    perform workflow__add_trans_attribute_map(
        ''article_wf'',
        ''review'',
        ''reviewer_ok'',
        1
    );

    /*****
     * Assignment
     *****/

    perform workflow__add_trans_role_assign_map(
        ''article_wf'',
        ''specify'',
        ''author''
    );

    return 0;

end;' language 'plpgsql';


select inline_0 ();

drop function inline_0 ();

/* Context stuff */

insert into wf_context_transition_info (
    context_key, 
    workflow_key,
    transition_key, 
    hold_timeout_callback, 
    hold_timeout_custom_arg
) values (
    'default', 
    'article_wf', 
    'specify', 
    'wf_callback__time_sysdate_plus_x', 
    1/24
);



-- create or replace package body wf_article_callback

-- FIXME: last three variables are in/out variables.

create function wf_article_callback__notification(integer,varchar,integer,integer,varchar,varchar)
returns integer as '
declare
  notification__task_id               alias for $1; 	
  notification__custom_arg            alias for $2;
  notification__party_to              alias for $3;
  notification__party_from            alias for $4;
  notification__subject               alias for $5;
  notification__body                  alias for $6;
  v_deadline_pretty                   varchar(400);
  v_object_name                       text;
  v_transition_name                   wf_transitions.transition_name%TYPE;
  v_name                              varchar(1000);
  v_subject                           text default '''';
  v_body                              text default '''';
  v_request_id                        integer;
begin
        select to_char(ta.deadline,''Mon fmDDfm, YYYY HH24:MI:SS''),
               acs_object__name(c.object_id),
               tr.transition_name
        into   v_deadline_pretty,
               v_object_name, 
	       v_transition_name
	from   wf_tasks ta, wf_transitions tr, wf_cases c
	where  ta.task_id = notification__task_id
        and    c.case_id = ta.case_id
        and    tr.workflow_key = c.workflow_key
        and    tr.transition_key = ta.transition_key;

	v_subject := ''Assignment: '' || v_transition_name || '' '' || 
                     v_object_name;

	v_body := ''Dear '' || acs_object__name(notification__party_to) || ''
'' || ''
Today, you have been assigned to a task.
'' || ''
Task    : '' || v_transition_name || ''
Object  : '' || v_object_name || ''
'';

        if v_deadline_pretty != '''' then
           v_body := v_body || ''Deadline: '' || v_deadline_pretty || ''
'';
        end if;

        -- NOTICE, NOTICE, NOTICE
        --
        -- Since postgresql does not support out parameters, this 
        -- function call has been moved from workflow_case.notify_assignee
        -- into the callback function.

        -- If you implement a new notification callback, make sure 
        -- that this function call is included at the end of the 
        -- callback routine just as we have done for this example code.
        --
        -- DanW (dcwickstrom@earthlink.net)

        v_request_id := acs_mail_nt__post_request (       
            notification__party_from,     -- party_from
            notification__party_to,       -- party_to
            ''f'',                        -- expand_group
            v_subject,                    -- subject
            v_body,                       -- message
            0                             -- max_retries
        );

        return null;
end;' language 'plpgsql';



update wf_context_transition_info
   set notification_callback = 'wf_article_callback__notification'
 where workflow_key = 'article_wf'
   and context_key = 'default'
   and transition_key = 'specify';

