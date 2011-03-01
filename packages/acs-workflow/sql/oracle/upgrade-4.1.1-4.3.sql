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
  role_key                varchar2(100),
  workflow_key            varchar2(100)
                          constraint wf_roles_workflow_fk
                          references wf_workflows(workflow_key)
                          on delete cascade,
  role_name               varchar2(100)
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

alter table wf_transitions add (
  role_key              varchar2(100)
);

alter table wf_transitions add (
  constraint wf_transition_role_fk
    foreign key (workflow_key,role_key) references wf_roles(workflow_key,role_key)
    /* We don't do on delete cascade here, because that would mean that 
     * when a role is deleted, the transitions associated with that role would be deleted, too */
);

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
  workflow_key          varchar2(100)
                        constraint wf_role_asgn_map_workflow_fk
                        references wf_workflows(workflow_key)
                        on delete cascade,
  transition_key        varchar2(100),
  assign_role_key       varchar2(100),
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
  context_key                   varchar2(100)
                                constraint wf_context_role_context_fk
                                references wf_contexts(context_key)
                                on delete cascade,
  workflow_key                  varchar2(100)
                                constraint wf_context_role_workflow_fk
                                references wf_workflows(workflow_key)
                                on delete cascade,
  role_key                      varchar2(100),
  /* 
   * Callback to programatically assign a role.
   * Must call wordflow_case.*_role_assignment to make the assignments.
   * Will be called when a transition for that role becomes enabled
   * signature: (role_key in varchar2, custom_arg in varchar2)
   */
  assignment_callback           varchar2(100),
  assignment_custom_arg         varchar2(4000),
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
 * Added column 'instructions'.
 */

alter table wf_context_transition_info add (
  instructions                  varchar2(4000)
);


/* Removed columns assignment_callback/custom_arg. */

alter table wf_context_transition_info 
  drop column assignment_callback;
alter table wf_context_transition_info 
  drop column assignment_custom_arg;

/* Added on delete cascade to columns workflow_key and .context_key */

alter table wf_context_transition_info 
  drop constraint wf_context_trans_context_fk;
alter table wf_context_transition_info 
  add constraint wf_context_trans_context_fk
  foreign key (context_key) references wf_contexts (context_key);

alter table wf_context_transition_info 
  drop constraint wf_context_trans_workflow_fk;
alter table wf_context_transition_info 
  add constraint wf_context_trans_workflow_fk
  foreign key (workflow_key) references wf_workflows (workflow_key);


/*
 * Table wf_context_workflow_info:
 * Added.
 */

create table wf_context_workflow_info (
  context_key                   varchar2(100)
                                constraint wf_context_wf_context_fk
                                references wf_contexts
                                on delete cascade,
  workflow_key                  varchar2(100)
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

alter table wf_context_task_panels add (
  /* Display this panel in place of the action panel */
  overrides_action_p            char(1) default 'f'
                                constraint wf_context_panels_ovrd_p_ck
                                check (overrides_action_p in ('t','f')),
  /* Display this panel only when the task has been started (and not finished) */
  only_display_when_started_p   char(1) default 'f'
                                constraint wf_context_panels_display_p_ck
                                check (only_display_when_started_p in ('t','f')),
  sort_order                    integer
);

/* Copy over the existing sort_key to the new sort_order */
update wf_context_task_panels
   set sort_order = sort_key;

/* Change the primary key */
alter table wf_context_task_panels drop constraint wf_context_panels_pk;
alter table wf_context_task_panels add 
  constraint wf_context_panels_pk
  primary key (context_key, workflow_key, transition_key, sort_order);

/* Drop old sort_key column */
alter table wf_context_task_panels drop column sort_key;

alter table wf_context_task_panels add constraint wf_context_sort_order_nn
  check (sort_order is not null);

/*
 * Table wf_context_assignments
 * Replaced transition_key with role_key
 */

alter table wf_context_assignments add (
  role_key			   varchar2(100),
  constraint wf_context_assign_role_fk
    foreign key (workflow_key, role_key) references wf_roles (workflow_key, role_key)
    on delete cascade
);

alter table wf_context_assignments drop constraint wf_context_assign_trans_fk;

update wf_context_assignments
   set role_key = transition_key;

alter table wf_context_assignments drop constraint wf_context_assign_pk;
alter table wf_context_assignments add constraint wf_context_assign_pk
  primary key (context_key, workflow_key, role_key, party_id);

alter table wf_context_assignments drop column transition_key;


/*
 * Table wf_case_assignments:
 * Changed transition_key to role_key
 */

alter table wf_case_assignments add (
  role_key			varchar2(100),
  constraint wf_case_assign_role_fk
    foreign key (workflow_key, role_key) references wf_roles (workflow_key, role_key)
    on delete cascade
);

update wf_case_assignments
   set role_key = transition_key;

alter table wf_case_assignments drop constraint wf_case_assign_pk;
alter table wf_case_assignments add 
  constraint wf_case_assign_pk
  primary key (case_id, role_key, party_id);

alter table wf_case_assignments drop constraint wf_case_assign_trans_fk;

alter table wf_case_assignments drop column transition_key;



/*
 * View wf_transition_contexts:
 * Added column role_key.
 */

create or replace view wf_transition_contexts as
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

create or replace view wf_transition_info as
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
from   wf_transition_contexts t, wf_context_transition_info ct
where  ct.workflow_key (+) = t.workflow_key
  and  ct.transition_key (+) = t.transition_key
  and  ct.context_key (+) = t.context_key;


/*
 * View wf_role_info:
 * Added.
 */

create or replace view wf_role_info as
select r.role_key,
       r.role_name,
       r.workflow_key,
       c.context_key,
       cr.assignment_callback,
       cr.assignment_custom_arg  
from   wf_roles r, wf_contexts c, wf_context_role_info cr
where  cr.workflow_key (+) = r.workflow_key
  and  cr.role_key (+) = r.role_key
  and  cr.context_key = c.context_key;


/*
 * View wf_enabled_transitions:
 * Added columns role_key and instructions.
 * Removed columns assignment_callback/custom_arg.
 */

create or replace view wf_enabled_transitions as 
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

create or replace view wf_user_tasks as
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

@@workflow-package.sql
@@workflow-case-package-head.sql
@@workflow-case-package-body.sql
 
