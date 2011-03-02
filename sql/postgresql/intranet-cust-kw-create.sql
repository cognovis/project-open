-- /packages/intranet-cust-kw/sql/postgres/intranet-cust-kw-create.sql
--
-- Copyright (C) 1999-2011 various parties
--
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author	klaus.hofeditz@project-open.com

-------------------------------------------------------------

select acs_object_type__create_type (
        'project_approval2_wf',           -- object_type
        'Project Close Approval',              -- pretty_name
        'Project Close Approval',            -- pretty_plural
        'workflow',        -- supertype
        'project_approval2_wf_cases',         -- table_name
        'case_id',           -- id_column
        'project_approval2_wf',           -- package_name
        'f',                    -- abstract_p
        null,                   -- type_extension_table
        'null'      -- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column) values ('project_approval2_wf', 'project_approval2_wf_cases', 'case_id');


create function im_workflow__assign_to_project_manager(int4, text) returns int4 as '
 declare
        p_task_id               alias for $1;
        p_custom_arg            alias for $2;

        v_transition_key        varchar;
        v_object_type           varchar;
        v_case_id               integer;
        v_object_id             integer;
        v_creation_user         integer;
        v_creation_ip           varchar;
        v_project_manager_id    integer;
        v_project_manager_name  varchar;

        v_journal_id            integer;

 begin
        -- Get information about the transition and the ''environment''
        select  tr.transition_key, t.case_id, c.object_id, o.creation_user, o.creation_ip, o.object_type
        into    v_transition_key, v_case_id, v_object_id, v_creation_user, v_creation_ip, v_object_type
        from    wf_tasks t, wf_cases c, wf_transitions tr, acs_objects o
        where   t.task_id = p_task_id
                and t.case_id = c.case_id
                and o.object_id = t.case_id
                and t.workflow_key = tr.workflow_key
                and t.transition_key = tr.transition_key;

        select  project_lead_id into v_project_manager_id from im_projects
        where   project_id = v_object_id;

        select im_name_from_id(v_project_manager_id) into v_project_manager_name;

        IF v_project_manager_id is not null THEN
                v_journal_id := journal_entry__new(
                    null, v_case_id,
                    v_transition_key || '' assign_to_project_manager '' || v_project_manager_name,
                    v_transition_key || '' assign_to_project_manager '' || v_project_manager_name,
                    now(), v_creation_user, v_creation_ip,
                    ''Assigning to user'' || v_project_manager_name
                );
                PERFORM workflow_case__add_task_assignment(p_task_id, v_project_manager_id, ''f'');
                PERFORM workflow_case__notify_assignee (p_task_id, v_project_manager_id, null, null,
                        ''wf_'' || v_object_type || ''_assignment_notif'');
        END IF;
        return 0;
end;' language 'plpgsql';
