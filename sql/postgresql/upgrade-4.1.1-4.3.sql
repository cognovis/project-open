/*
 * We've added support for roles, which is an intermediate step between 
 * transitions and assignments. A role is a relationship to a process, e.g.,
 * an editor, publisher, submitter, fixer, doctor, manager, etc.
 * A task is performed by a role, but one role may have many tasks to perform.
 * The idea is that when you reassign a role, it affects all the tasks that role 
 * has been assigned to.
 *
 * For the upgrade, we simply create one role per transtiion, and change 
 * all the other tables correspondingly. This will execute exactly equivalent
 * to the way it would have without the roles refactoring.
 *
 * We've also added other minor things, such as task instructions and gotten rid
 * of wf_attribute_info.
 */



/*
 * Table wf_roles: 
 * Added.
 */

create table wf_roles (
  role_key                varchar(100),
  workflow_key            varchar(100)
                          constraint wf_roles_workflow_fk
                          references wf_workflows(workflow_key)
                          on delete cascade,
  role_name               varchar(100)
                          constraint wf_role_role_name_nn
                          not null,
  -- so we can display roles in some logical order --
  sort_order              integer
                          constraint wf_roles_order_ck
                          check (sort_order > 0),
  -- table constraints --
  constraint wf_role_pk
    primary key (workflow_key, role_key),
  constraint wf_roles_wf_key_role_name_un
    unique (workflow_key, role_name)
);

comment on table wf_roles is '
  A process has certain roles associated with it, such as "submitter", 
  "reviewer", "editor", "claimant", etc. For each transition, then, you
  specify what role is to perform that task. Thus, two or more tasks can be
  performed by one and the same role, so that when the role is reassigned,
  it reflects assignments of both tasks. Users and parties are then assigned
  to roles instead of directly to tasks.
';



/*
 * Now populate the roles table:
 * We just create a role per transition, then hook them up
 */

insert into wf_roles 
 (workflow_key,
  role_key,
  role_name,
  sort_order)
select workflow_key, transition_key, transition_name, sort_order
  from wf_transitions;


/*
 * Table wf_transitions: 
 * Added column role_key.
 * Added foreign key constraint wf_transition_role_fk.
 */

alter table wf_transitions add role_key varchar(100);


alter table wf_transitions add constraint wf_transition_role_fk
    foreign key (workflow_key,role_key) references wf_roles(workflow_key,role_key);
    /* We don't do on delete cascade here, because that would mean that 
     * when a role is deleted, the transitions associated with that role would be deleted, too */


/* Now populate the new column corresponding to the roles we just created:
 * Since there's a one-to-one role per transition, and the have the same keys, 
 * we just set role_key = transition_key 
 */

update wf_transitions
   set role_key = transition_key;

/*
 * Table wf_transition_role_assign_map: 
 * Added.
 * This replaces wf_transtiion_assign_map, since transitions now assign 
 * roles instead of other transitions.
 */

create table wf_transition_role_assign_map (
  workflow_key          varchar(100)
                        constraint wf_role_asgn_map_workflow_fk
                        references wf_workflows(workflow_key)
                        on delete cascade,
  transition_key        varchar(100),
  assign_role_key       varchar(100),
  -- table constraints --
  constraint wf_role_asgn_map_pk
    primary key (workflow_key, transition_key, assign_role_key),
  constraint wf_role_asgn_map_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade,
  constraint wf_tr_role_asgn_map_asgn_fk
    foreign key (workflow_key, assign_role_key) references wf_roles(workflow_key, role_key)
    on delete cascade
);

create index wf_role_asgn_map_wf_trans_idx on wf_transition_role_assign_map(workflow_key, transition_key);
create index wf_role_asgn_map_wf_as_tr_idx on wf_transition_role_assign_map(workflow_key, assign_role_key);

comment on table wf_transition_role_assign_map is '
  When part of the output of one task is to assign users to a role,
  specify that this is the case by inserting a row here.
';

comment on column wf_transition_role_assign_map.transition_key is '
  transition_key is the assigning transition.
';

comment on column wf_transition_role_assign_map.assign_role_key is '
  assign_role_key is the role being assigned a user to.
';


/* Populate new wf_transition_role_assign_map with the rows from
 * wf_transition_assignment_map. Since role_key map one-to-one with transition_keys
 * in this upgrade, that's pretty straight-forward.
 */

insert into wf_transition_role_assign_map
 (workflow_key,
  transition_key,
  assign_role_key)
select workflow_key,
       transition_key,
       assign_transition_key
  from wf_transition_assignment_map;

/*
 * Table wf_transition_assignment_map:
 * Dropped.
 * This table is no longer releavnt, since transitions don't assign other 
 * transitions, they assign roles.
 */

drop table wf_transition_assignment_map;


/*
 * Table wf_attribute_info:
 * Dropped.
 * This table was a hang-over from earlier versions and is no longer necessary.
 */

drop table wf_attribute_info;

/*
 * Table wf_context_role_info:
 * Added.
 */

create table wf_context_role_info (
  context_key                   varchar(100)
                                constraint wf_context_role_context_fk
                                references wf_contexts(context_key)
                                on delete cascade,
  workflow_key                  varchar(100)
                                constraint wf_context_role_workflow_fk
                                references wf_workflows(workflow_key)
                                on delete cascade,
  role_key                      varchar(100),
  /* 
   * Callback to programatically assign a role.
   * Must call wordflow_case.*_role_assignment to make the assignments.
   * Will be called when a transition for that role becomes enabled
   * signature: (role_key in varchar2, custom_arg in varchar2)
   */
  assignment_callback           varchar(100),
  assignment_custom_arg         text,
  -- table constraints --
  constraint wf_context_role_role_fk
    foreign key (workflow_key, role_key) references wf_roles(workflow_key, role_key)
    on delete cascade,
  constraint wf_context_role_info_pk
    primary key (context_key, workflow_key, role_key)
);

comment on table wf_context_role_info is '
  This table holds context-dependent info for roles, currently only the assignment callback
';


/* Populate by a straight copy from wf_context_transition_info */

insert into wf_context_role_info
 (context_key,
  workflow_key,
  role_key,
  assignment_callback,
  assignment_custom_arg)
select context_key,
       workflow_key,
       transition_key,
       assignment_callback,
       assignment_custom_arg
  from wf_context_transition_info
 where assignment_callback is not null
    or assignment_custom_arg is not null;

/* 
 * Table wf_context_transition_info:
 */
create table temp as select 
  context_key,
  workflow_key,
  transition_key,
  estimated_minutes,
  ''::text as instructions,
  enable_callback,
  enable_custom_arg,
  fire_callback,
  fire_custom_arg,
  time_callback,
  time_custom_arg,
  deadline_callback,
  deadline_custom_arg,
  deadline_attribute_name,
  hold_timeout_callback,
  hold_timeout_custom_arg,
  notification_callback,
  notification_custom_arg,
  unassigned_callback,
  unassigned_custom_arg
from wf_context_transition_info;

drop table wf_context_transition_info;

create table wf_context_transition_info (
  context_key                   varchar(100)
                                constraint wf_context_trans_context_fk
                                references wf_contexts,
  workflow_key                  varchar(100)
                                constraint wf_context_trans_workflow_fk
                                references wf_workflows,
  transition_key                varchar(100),
  /* information for the transition in the context */
  /* The integer of minutes this task is estimated to take */
  estimated_minutes             integer,
  /* Instructions for how to complete the task. Will be displayed on the task page. */
  instructions                  text,
  /*
   * Will be called when the transition is enabled/fired.
   * signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2)
   */
  enable_callback               varchar(100),
  enable_custom_arg             text,
  fire_callback                 varchar(100),
  fire_custom_arg               text,
  /* 
   * Must return the date that the timed transition should fire
   * Will be called when the transition is enabled
   * signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2) return date
   */
  time_callback                 varchar(100),
  time_custom_arg               text,
  /*
   * Returns the deadline for this task.
   * Will be called when the transition becomes enabled
   * Signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2) return date
   */
  deadline_callback             varchar(100),
  deadline_custom_arg           text,
  /* The name of an attribute that holds the deadline */
  deadline_attribute_name       varchar(100),
  /*
   * Must return the date that the user's hold on the task times out.
   * called when the user starts the task.
   * signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2) return date
   */
  hold_timeout_callback         varchar(100),
  hold_timeout_custom_arg       text,
  /* 
   * Notification callback
   * Will be called when a notification is sent i.e., when a transition is enabled,
   * or assignment changes.
   * signature: (task_id        in integer, 
   *             custom_arg     in varchar, 
   *             party_to       in integer, 
   *             party_from     in out integer, 
   *             subject        in out varchar, 
   *             body           in out varchar)
   */
  notification_callback         varchar(100),
  notification_custom_arg       text,
  /*
   * Callback to handle unassigned tasks.
   * Will be called when an enabled task becomes unassigned.
   * Signature: (task_id in number, custom_arg in varchar2)
   */
  unassigned_callback       varchar(100),
  unassigned_custom_arg     text,
  -- table constraints --
  constraint wf_context_trans_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade,
  constraint wf_context_transition_pk
    primary key (context_key, workflow_key, transition_key)
);

create index wf_ctx_trans_wf_trans_idx on wf_context_transition_info(workflow_key, transition_key);

comment on table wf_context_transition_info is '
  This table holds information that pertains to a transition in a specific context.
  It will specifically hold 
';

insert into wf_context_transition_info select * from temp;
drop table temp;


/*
 * Table wf_context_workflow_info:
 * Added.
 */

create table wf_context_workflow_info (
  context_key                   varchar(100)
                                constraint wf_context_wf_context_fk
                                references wf_contexts
                                on delete cascade,
  workflow_key                  varchar(100)
                                constraint wf_context_wf_workflow_fk
                                references wf_workflows
                                on delete cascade,
  /* The principal is the user/party that sends out email assignment notifications 
   * And receives email when a task becomes unassigned (for more than x minutes?)
   */
  principal_party               integer
                                constraint wf_context_wf_principal_fk
                                references parties
                                on delete set null,
  -- table constraints --
  constraint wf_context_workflow_pk
    primary key (context_key, workflow_key)
);

/* Insert someone for all existing processes. Hopefully this will be the administrator user. */

insert into wf_context_workflow_info
 (context_key,
  workflow_key,
  principal_party)
select 'default', workflow_key, (select min(party_id) from parties)
  from wf_workflows;


/*
 * Table wf_context_task_panels:
 * Added columns overrides_action_p and only_display_when_started_p 
 * Renamed column sort_key to sort_order for consistency
 */
create table temp as select
context_key,
workflow_key,
transition_key,
sort_key as sort_order,
header,
template_url
from wf_context_task_panels;

drop table wf_context_task_panels;


create table wf_context_task_panels (
  context_key                   varchar(100) not null
                                constraint wf_context_panels_context_fk
                                references wf_contexts(context_key)
                                on delete cascade,
  workflow_key                  varchar(100) not null
                                constraint wf_context_panels_workflow_fk
                                references wf_workflows(workflow_key)
                                on delete cascade,
  transition_key                varchar(100) not null,
  sort_order                    integer not null,
  header                        varchar(200) not null,
  template_url                  varchar(500) not null,
  /* Display this panel in place of the action panel */
  overrides_action_p            char(1) default 'f'
                                constraint wf_context_panels_ovrd_p_ck
                                check (overrides_action_p in ('t','f')),
  /* Display this panel only when the task has been started (and not finished) */
  only_display_when_started_p   char(1) default 'f'
                                constraint wf_context_panels_display_p_ck
                                check (only_display_when_started_p in ('t','f')),
  -- table constraints --
  constraint wf_context_panels_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) 
    on delete cascade,
  constraint wf_context_panels_pk
    primary key (context_key, workflow_key, transition_key, sort_order)
);

create index wf_ctx_panl_workflow_trans_idx on wf_context_task_panels(workflow_key, transition_key);

comment on table wf_context_task_panels is '
  Holds information about the panels to be displayed on the task page.
';

insert into wf_context_task_panels select * from temp;
drop table temp;



/*
 * Table wf_context_assignments
 * Replaced transition_key with role_key
 */
create table temp as select
  context_key,
  workflow_key,
  transition_key as role_key,
  party_id
from wf_context_assignments;

drop table wf_context_assignments;

create table wf_context_assignments (
  context_key                   varchar(100)
                                constraint wf_context_assign_context_fk
                                references wf_contexts(context_key)
                                on delete cascade,
  workflow_key                  varchar(100)
                                constraint wf_context_assign_workflow_fk
                                references wf_workflows(workflow_key)
                                on delete cascade,
  role_key                      varchar(100),
  party_id                      integer
                                constraint wf_context_assign_party_fk
                                references parties(party_id)
                                on delete cascade,
  -- table constraints --
  constraint wf_context_assign_pk
    primary key (context_key, workflow_key, role_key, party_id),
  constraint wf_context_assign_role_fk
    foreign key (workflow_key, role_key) references wf_roles(workflow_key, role_key) 
    on delete cascade
);

create index wf_ctx_assg_workflow_trans_idx on wf_context_assignments(workflow_key, role_key);

comment on table wf_context_assignments is '
  Static (default) per-context assignments of roles to parties. 
';

insert into wf_context_assignments select * from temp;
drop table temp;



/*
 * Table wf_case_assignments:
 * Changed transition_key to role_key
 */

create table temp as select
  case_id,
  workflow_key,
  transition_key as role_key,
  party_id
from wf_case_assignments;

drop table wf_case_assignments;
  
create table wf_case_assignments (
  case_id               integer
                        constraint wf_case_assign_fk
                        references wf_cases(case_id)
                        on delete cascade,
  workflow_key          varchar(100),
  role_key              varchar(100),
  party_id              integer
                        constraint wf_case_assign_party_fk
                        references parties(party_id)
                        on delete cascade,
  -- table constraints --
  constraint wf_case_assign_pk
    primary key (case_id, role_key, party_id),
  constraint wf_case_assign_role_fk
    foreign key (workflow_key, role_key) references wf_roles(workflow_key, role_key)
    on delete cascade
);

create index wf_case_assgn_party_idx on wf_case_assignments(party_id);

comment on table wf_case_assignments is '
  Manual per-case assignments of roles to parties.
';

insert into wf_case_assignments select * from temp;
drop table temp;


/*
 * View wf_transition_contexts:
 * Added column role_key.
 */
drop view wf_transition_contexts;
create view wf_transition_contexts as
select t.transition_key, 
       t.transition_name, 
       t.workflow_key, 
       t.sort_order, 
       t.trigger_type,
       t.role_key,
       c.context_key,
       c.context_name
from   wf_transitions t, wf_contexts c;



/*
 * View wf_transition_info:
 * Added columns role_key and instructions.
 * Removed columns assignment_callback/custom_arg.
 */
drop view wf_transition_info;
create view wf_transition_info as
select t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type,
       t.context_key, 
       t.role_key,
       ct.estimated_minutes,
       ct.instructions,
       ct.enable_callback, 
       ct.enable_custom_arg,
       ct.fire_callback, 
       ct.fire_custom_arg,
       ct.time_callback, 
       ct.time_custom_arg,
       ct.deadline_callback, 
       ct.deadline_custom_arg,
       ct.deadline_attribute_name,
       ct.hold_timeout_callback,
       ct.hold_timeout_custom_arg,
       ct.notification_callback,
       ct.notification_custom_arg,
       ct.unassigned_callback,
       ct.unassigned_custom_arg
from   wf_transition_contexts t LEFT OUTER JOIN wf_context_transition_info ct ON (
       ct.workflow_key = t.workflow_key
  and  ct.transition_key = t.transition_key
  and  ct.context_key = t.context_key);


/*
 * View wf_role_info:
 * Added.
 */

-- drop view wf_role_info;
create view wf_role_info as
select r.role_key,
       r.role_name,
       r.workflow_key,
       c.context_key,
       cr.assignment_callback,
       cr.assignment_custom_arg  
from   wf_contexts c, wf_roles r LEFT OUTER JOIN wf_context_role_info cr ON (
       cr.workflow_key = r.workflow_key
  and  cr.role_key = r.role_key)
where  cr.context_key = c.context_key;


/*
 * View wf_enabled_transitions:
 * Added columns role_key and instructions.
 * Removed columns assignment_callback/custom_arg.
 */

drop view wf_enabled_transitions;
create view wf_enabled_transitions as 
select c.case_id, 
       t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type, 
       t.context_key, 
       t.role_key,
       t.enable_callback, 
       t.enable_custom_arg,
       t.fire_callback,
       t.fire_custom_arg,
       t.time_callback, 
       t.time_custom_arg,
       t.deadline_callback,
       t.deadline_custom_arg,
       t.deadline_attribute_name,
       t.hold_timeout_callback, 
       t.hold_timeout_custom_arg,
       t.notification_callback,
       t.notification_custom_arg,
       t.estimated_minutes,
       t.instructions,
       t.unassigned_callback,
       t.unassigned_custom_arg
  from wf_transition_info t, 
       wf_cases c
 where t.workflow_key = c.workflow_key
   and t.context_key = c.context_key
   and c.state = 'active'
   and not exists 
   (select tp.place_key
    from   wf_transition_places tp
    where  tp.transition_key = t.transition_key
      and  tp.workflow_key = t.workflow_key
      and  tp.direction = 'in'
      and  not exists 
       (select tk.token_id
        from   wf_tokens tk
        where  tk.place_key = tp.place_key
          and  tk.case_id = c.case_id
          and  tk.state = 'free'
       )
    );


/*
 * View wf_user_tasks:
 * Added column instructions
 * Added "and tr.workflow_key = ta.workflow_key" to where clause
 * (looks like a bug)
 */

drop view wf_user_tasks;
create view wf_user_tasks as
select distinct ta.task_id, 
       ta.case_id, 
       ta.workflow_key,
       ta.transition_key, 
       tr.transition_name, 
       tr.instructions,
       ta.enabled_date, 
       ta.started_date, 
       u.user_id, 
       ta.state, 
       ta.holding_user, 
       ta.hold_timeout,
       ta.deadline,
       ta.estimated_minutes
from   wf_tasks ta,
       wf_task_assignments tasgn,
       wf_cases c,
       wf_transition_info tr,
       party_approved_member_map m,
       users u
where  ta.state in ( 'enabled','started')
and    c.case_id = ta.case_id
and    c.state = 'active'
and    tr.transition_key = ta.transition_key
and    tr.workflow_key = ta.workflow_key
and    tr.trigger_type = 'user'
and    tr.context_key = c.context_key
and    tasgn.task_id = ta.task_id
and    m.party_id = tasgn.party_id
and    u.user_id = m.member_id;



drop function __workflow__simple_p (varchar,integer);
drop table guard_list;
drop table target_place_list;
drop table previous_place_list;
drop sequence workflow_session_id;
drop function sweep_hold_timeout ();
drop function sweep_timed_transitions ();

select drop_package('workflow');
select drop_package('workflow_case');


\i workflow-package.sql
\i workflow-case-package-head.sql
\i workflow-case-package-body.sql
 
