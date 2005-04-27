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


declare
    v_workflow_key wf_workflows.workflow_key%TYPE;
    v_attribute_id acs_attributes.attribute_id%TYPE;
begin
    v_workflow_key := workflow.create_workflow(
	workflow_key => 'article_wf', 
	pretty_name => 'Article Publication', 
	pretty_plural => 'Article Publications', 
	description => 'Workflow for managing the publication of an article',
	table_name => 'wf_article_cases'
    );

    /*****
     * Places 
     *****/
 
    workflow.add_place(
        workflow_key => 'article_wf',
        place_key => 'start',
        place_name => 'Start place',
        sort_order => 1
    );

    workflow.add_place(
        workflow_key => 'article_wf',
        place_key => 'to_be_written', 
	place_name => 'Needs to be written', 
        sort_order => 2
    );

    workflow.add_place(
        workflow_key => 'article_wf',
        place_key => 'to_be_reviewed', 
	place_name => 'Needs review', 
        sort_order => 3
    );

    workflow.add_place(
        workflow_key => 'article_wf',
        place_key => 'to_be_published', 
	place_name => 'Ready to go to press', 
        sort_order => 4
    );

    workflow.add_place(
        workflow_key => 'article_wf',
        place_key => 'end', 
	place_name => 'End place', 
        sort_order => 5
    );

    /*****
     * Roles
     *****/

    workflow.add_role(
        workflow_key => 'article_wf',
        role_key => 'author',
        role_name => 'Author',
        sort_order => 1
    );

    workflow.add_role(
        workflow_key => 'article_wf',
        role_key => 'editor',
        role_name => 'Editor',
        sort_order => 2
    );

    /*****
     * Transitions 
     *****/

    workflow.add_transition(
        workflow_key => 'article_wf',
        transition_key => 'specify',
        transition_name => 'Describe task and assign author',
        role_key => 'editor',
        sort_order => 1,
        trigger_type => 'user'
    );
        
    workflow.add_transition(
        workflow_key => 'article_wf',
        transition_key => 'write',
        transition_name => 'Write article',
        role_key => 'author',
        sort_order => 2,
        trigger_type => 'user'
    );
        
    workflow.add_transition(
        workflow_key => 'article_wf',
        transition_key => 'review',
        transition_name => 'Review article',
        role_key => 'editor',
        sort_order => 3,
        trigger_type => 'user'
    );
        
    workflow.add_transition(
        workflow_key => 'article_wf',
        transition_key => 'publish',
        transition_name => 'Publish article',
        sort_order => 4,
        trigger_type => 'automatic'
    );

    /*****
     * Arcs 
     *****/

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_place_key => 'start',
        to_transition_key => 'specify'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_transition_key => 'specify',
        to_place_key => 'to_be_written'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_place_key => 'to_be_written',
        to_transition_key => 'write'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_transition_key => 'write',
        to_place_key => 'to_be_reviewed'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_place_key => 'to_be_reviewed',
        to_transition_key => 'review'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_transition_key => 'review',
        to_place_key => 'to_be_published',
        guard_callback => 'wf_callback.guard_attribute_true',
        guard_custom_arg => 'reviewer_ok',
        guard_description => 'Reviewer approved article'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_transition_key => 'review',
        to_place_key => 'to_be_written',
        guard_callback => '#',
        guard_description => 'Reviewer did not approve article'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_place_key => 'to_be_published',
        to_transition_key => 'publish'
    );

    workflow.add_arc(
        workflow_key => 'article_wf',
        from_transition_key => 'publish',
        to_place_key => 'end'
    );

    /*****
     * Attributes
     *****/

    v_attribute_id := workflow.create_attribute(
	workflow_key => 'article_wf',
	attribute_name => 'reviewer_ok',
	datatype => 'boolean',
	pretty_name => 'Reviewer Approval',
	default_value => 'f'
    );

    workflow.add_trans_attribute_map(
        workflow_key => 'article_wf',
        transition_key => 'review',
        attribute_name => 'reviewer_ok',
        sort_order => 1
    );

    /*****
     * Assignment
     *****/

    workflow.add_trans_role_assign_map(
        workflow_key => 'article_wf',
        transition_key => 'specify',
        assign_role_key => 'author'
    );

end;
/
show errors


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
    'wf_callback.time_sysdate_plus_x', 
    1/24
);

commit;

create or replace package wf_article_callback
is
    procedure notification(
            task_id 	in number, 
            custom_arg 	in varchar2, 
            party_to 	in integer, 
            party_from 	in integer, 
            subject 	in varchar2, 
            body 	in varchar2
    );

end wf_article_callback;
/
show errors


create or replace package body wf_article_callback
is

    procedure notification(
        task_id 	in number, 
        custom_arg 	in varchar2, 
        party_to 	in integer, 
        party_from 	in integer, 
        subject 	in varchar2, 
        body	 	in varchar2
    )
    is
	v_deadline_pretty varchar2(400);
        v_object_name varchar2(4000);
        v_transition_name wf_transitions.transition_name%TYPE;
        v_name varchar2(1000);
        v_subject varchar2(100);
        v_body varchar2(4000);
        v_request_id integer;
    begin
        select to_char(ta.deadline,'Mon fmDDfm, YYYY HH24:MI:SS'),
               acs_object.name(c.object_id),
               tr.transition_name
        into   v_deadline_pretty,
               v_object_name, 
	       v_transition_name
	from   wf_tasks ta, wf_transitions tr, wf_cases c
	where  ta.task_id = notification.task_id
        and    c.case_id = ta.case_id
        and    tr.workflow_key = c.workflow_key
        and    tr.transition_key = ta.transition_key;

	v_subject := 'Assignment: '||v_transition_name||' '||v_object_name;
	v_body := 'Dear '||acs_object.name(party_to)||'
'||'
Today, you have been assigned to a task.
'||'
Task    : '||v_transition_name||'
Object  : '||v_object_name||'
';

        if v_deadline_pretty != '' then
            v_body := v_body ||'Deadline: '||v_deadline_pretty||'
';
        end if;
        v_request_id := acs_mail_nt.post_request (       
            party_from => party_from,
            party_to => party_to,
            subject => v_subject,
            message => v_body
        );
    end notification;

end wf_article_callback;
/
show errors


update wf_context_transition_info
   set notification_callback = 'wf_article_callback.notification'
 where workflow_key = 'article_wf'
   and context_key = 'default'
   and transition_key = 'specify';

commit;
