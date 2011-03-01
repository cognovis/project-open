-- Drop procedural database code for the workflow package, a package in the OpenACS system.
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

---------------------------------
-- Workflow level, Generic Model
---------------------------------

-- Drop all functions
drop function workflow__delete (integer);

drop function workflow__new (
    varchar, -- short_name
    varchar, -- pretty_name
    varchar, -- package_key
    integer, -- object_id
    varchar, -- object_type
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
);

drop function workflow_case_log_entry__new (
    integer,                  -- item_id
    varchar,                  -- content_type
    integer,                  -- case_id
    integer,                  -- action_id
    varchar,                  -- content
    varchar,                  -- mime_type
    integer,                  -- creation_user
    varchar                   -- creation_ip
);

drop function workflow_case_pkg__delete (integer);

drop function workflow_case_pkg__get_pretty_state (
    varchar, -- workflow_short_name
    integer  -- object_id
);


delete from acs_function_args
where  function = 'workflow_case_log_entry__new';
