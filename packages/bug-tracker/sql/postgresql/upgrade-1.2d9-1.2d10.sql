-- Fixing the implementation of the bt_bug__delete function to work with 
-- renamed workflow_case_pkg__delete function.
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- $Id$

create or replace function bt_bug__delete(
   integer                      -- bug_id
) returns integer
as '
declare
    p_bug_id                    alias for $1;
    v_case_id                   integer;
    rec                         record;
begin
    -- Every bug is associated with a workflow case
    select case_id 
    into   v_case_id 
    from   workflow_cases 
    where  object_id = p_bug_id;

    perform workflow_case_pkg__delete(v_case_id);

    -- Every bug may have notifications attached to it
    -- and there is one column in the notificaitons datamodel that doesn''t
    -- cascade
    for rec in select notification_id from notifications 
               where response_id = p_bug_id loop

        perform notification__delete (rec.notification_id);
    end loop;

    -- unset live & latest revision
--    update cr_items
--    set    live_revision = null,
--           latest_revision = null
--    where  item_id = p_bug_id;

    perform content_item__delete(p_bug_id);

    return 0;
end;
' language 'plpgsql';
