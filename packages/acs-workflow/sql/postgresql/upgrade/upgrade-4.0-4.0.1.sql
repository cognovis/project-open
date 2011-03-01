-- Recreating almost all foreign key constraints in order to add "on delete cascade"

-- wf_workflows

alter table wf_workflows drop constraint wf_workflows_workflow_key_fk;
alter table wf_workflows add (
    constraint wf_workflows_workflow_key_fk
    foreign key(workflow_key) references acs_object_types(object_type) on delete cascade
);

-- wf_places

alter table wf_places drop constraint wf_place_workflow_fk;
alter table wf_places add (
    constraint wf_place_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

-- wf_transitions

alter table wf_transitions drop constraint wf_transition_workflow_fk;
alter table wf_transitions add (
    constraint wf_transition_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

-- wf_arcs

alter table wf_arcs drop constraint wf_ts_arc_workflow_fk;
alter table wf_arcs add (
    constraint wf_ts_arc_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

alter table wf_arcs drop constraint wf_arc_transition_fk;
alter table wf_arcs add (
    constraint wf_arc_transition_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

alter table wf_arcs drop constraint wf_arc_place_fk;
alter table wf_arcs add (
    constraint wf_arc_place_fk
    foreign key(workflow_key, place_key) references wf_places(workflow_key, place_key) on delete cascade
);

create index wf_arcs_wf_key_trans_key_idx on wf_arcs(workflow_key, transition_key); 
create index wf_arcs_wf_key_place_key_idx on wf_arcs(workflow_key, place_key); 

-- wf_attribute_info

alter table wf_attribute_info add (
    constraint wf_attribute_info_attribute_pk primary key(attribute_id) 
);

alter table wf_attribute_info drop constraint wf_attribute_info_attribute_fk;
alter table wf_attribute_info add (
    constraint wf_attribute_info_attribute_fk
    foreign key(attribute_id) references acs_attributes(attribute_id) on delete cascade
);

-- wf_transition_attribute_map

alter table wf_transition_attribute_map drop constraint wf_trans_attr_map_workflow_fk;
alter table wf_transition_attribute_map add (
    constraint wf_trans_attr_map_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

alter table wf_transition_attribute_map drop constraint wf_trans_attr_map_trans_fk;
alter table wf_transition_attribute_map add (
    constraint wf_trans_attr_map_trans_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

-- wf_transition_assignment_map

alter table wf_transition_assignment_map drop constraint wf_trans_asgn_map_workflow_fk;
alter table wf_transition_assignment_map add (
    constraint wf_trans_asgn_map_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

alter table wf_transition_assignment_map drop constraint wf_trans_asgn_map_trans_fk;
alter table wf_transition_assignment_map add (
    constraint wf_trans_asgn_map_trans_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

alter table wf_transition_assignment_map drop constraint wf_tr_asgn_map_asgn_trans_fk;
alter table wf_transition_assignment_map add (
    constraint wf_tr_asgn_map_asgn_trans_fk
    foreign key(workflow_key, assign_transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

create index wf_trans_asgn_map_wf_trans_idx on wf_transition_assignment_map(workflow_key, transition_key); 
create index wf_trans_asgn_map_wf_as_tr_idx on wf_transition_assignment_map(workflow_key, assign_transition_key); 

-- wf_context_transition_info

alter table wf_context_transition_info drop constraint wf_context_trans_trans_fk;
alter table wf_context_transition_info add (
    constraint wf_context_trans_trans_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

create index wf_ctx_trans_wf_trans_idx on wf_context_transition_info(workflow_key, transition_key);

-- wf_context_assignments

alter table wf_context_assignments drop constraint wf_context_assign_context_fk;
alter table wf_context_assignments add (
    constraint wf_context_assign_context_fk
    foreign key(context_key) references wf_contexts(context_key) on delete cascade
);

alter table wf_context_assignments drop constraint wf_context_assign_workflow_fk;
alter table wf_context_assignments add (
    constraint wf_context_assign_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

alter table wf_context_assignments drop constraint wf_context_assign_party_fk;
alter table wf_context_assignments add (
    constraint wf_context_assign_party_fk
    foreign key(party_id) references parties(party_id) on delete cascade
);

alter table wf_context_assignments drop constraint wf_context_assign_trans_fk;
alter table wf_context_assignments add (
    constraint wf_context_assign_trans_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

create index wf_ctx_assg_workflow_trans_idx on wf_context_assignments(workflow_key, transition_key);

-- wf_cases

alter table wf_cases drop constraint wf_cases_acs_object_fk;
alter table wf_cases add (
    constraint wf_cases_acs_object_fk
    foreign key(case_id) references acs_objects(object_id) on delete cascade
);

alter table wf_cases drop constraint wf_cases_workflow_fk;
alter table wf_cases add (
    constraint wf_cases_workflow_fk
    foreign key(workflow_key) references wf_workflows(workflow_key) on delete cascade
);

alter table wf_cases drop constraint wf_cases_context_fk;
alter table wf_cases add (
    constraint wf_cases_context_fk
    foreign key(context_key) references wf_contexts(context_key) on delete cascade
);

alter table wf_cases drop constraint wf_cases_object_fk;
alter table wf_cases add (
    constraint wf_cases_object_fk
    foreign key(object_id) references acs_objects(object_id) on delete cascade
);

create index wf_cases_workflow_key_idx on wf_cases(workflow_key); 
create index wf_cases_context_key_idx on wf_cases(context_key); 
create index wf_cases_object_id_idx on wf_cases(object_id); 

-- wf_case_assignments

alter table wf_case_assignments drop constraint wf_case_assign_fk;
alter table wf_case_assignments add (
    constraint wf_case_assign_fk
    foreign key(case_id) references wf_cases(case_id) on delete cascade
);

alter table wf_case_assignments drop constraint wf_case_assign_party_fk;
alter table wf_case_assignments add (
    constraint wf_case_assign_party_fk
    foreign key(party_id) references parties(party_id) on delete cascade
);

alter table wf_case_assignments drop constraint wf_case_assign_trans_fk;
alter table wf_case_assignments add (
    constraint wf_case_assign_trans_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

create index wf_case_assgn_party_idx on wf_case_assignments(party_id);

-- wf_case_deadlines

alter table wf_case_deadlines drop constraint wf_case_deadline_fk;
alter table wf_case_deadlines add (
    constraint wf_case_deadline_fk
    foreign key(case_id) references wf_cases(case_id) on delete cascade
);

alter table wf_case_deadlines drop constraint wf_case_deadline_trans_fk;
alter table wf_case_deadlines add (
    constraint wf_case_deadline_trans_fk
    foreign key(workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) on delete cascade
);

-- wf_tasks

alter table wf_tasks drop constraint wf_task_case_fk;
alter table wf_tasks add (
    constraint wf_task_case_fk
    foreign key(case_id) references wf_cases(case_id) on delete cascade
);

alter table wf_tasks drop constraint wf_task_holding_user_fk;
alter table wf_tasks add (
    constraint wf_task_holding_user_fk
    foreign key(holding_user) references users(user_id) on delete cascade
);

create index wf_tasks_case_id_idx on wf_tasks(case_id); 
create index wf_tasks_holding_user_idx on wf_tasks(holding_user); 

-- wf_task_assignments

alter table wf_task_assignments drop constraint wf_task_assign_task_fk;
alter table wf_task_assignments add (
    constraint wf_task_assign_task_fk
    foreign key(task_id) references wf_tasks(task_id) on delete cascade
);

alter table wf_task_assignments drop constraint wf_task_party_fk;
alter table wf_task_assignments add (
    constraint wf_task_party_fk
    foreign key(party_id) references parties(party_id) on delete cascade
);

create index wf_task_asgn_party_id_idx on wf_task_assignments(party_id);

-- wf_tokens

alter table wf_tokens drop constraint wf_token_workflow_instance_fk;
alter table wf_tokens add (
    constraint wf_token_workflow_instance_fk
    foreign key(case_id) references wf_cases(case_id) on delete cascade
);

create index wf_tokens_case_id_idx on wf_tokens(case_id);

-- wf_attribute_value_audit

alter table wf_attribute_value_audit drop constraint wf_attr_val_audit_case_fk;
alter table wf_attribute_value_audit add (
    constraint wf_attr_val_audit_case_fk
    foreign key(case_id) references wf_cases(case_id) on delete cascade
);

alter table wf_attribute_value_audit drop constraint wf_attr_val_audit_attr_fk;
alter table wf_attribute_value_audit add (
    constraint wf_attr_val_audit_attr_fk
    foreign key(attribute_id) references acs_attributes(attribute_id) on delete cascade
);

create index wf_attr_val_aud_attr_id_idx on wf_attribute_value_audit(attribute_id);


-- Added a column to wf_tasks

alter table wf_tasks add (estimated_minutes integer);


-- We've added the column estimated_minutes to this view.

create or replace view wf_enabled_transitions as 
select c.case_id, 
       t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type, 
       t.context_key, 
       t.enable_callback, 
       t.enable_custom_arg,
       t.fire_callback,
       t.fire_custom_arg,
       t.assignment_callback, 
       t.assignment_custom_arg,
       t.time_callback, 
       t.time_custom_arg,
       t.deadline_callback,
       t.deadline_custom_arg,
       t.deadline_attribute_name,
       t.hold_timeout_callback, 
       t.hold_timeout_custom_arg,
       t.estimated_minutes
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


-- We've added the column workflow_key to this view

create or replace view wf_user_tasks as
select distinct ta.task_id,
       ta.case_id,
       ta.workflow_key,
       ta.transition_key,
       tr.transition_name,
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
and    tr.trigger_type = 'user'
and    tr.context_key = c.context_key
and    tasgn.task_id = ta.task_id
and    m.party_id = tasgn.party_id
and    u.user_id = m.member_id;



