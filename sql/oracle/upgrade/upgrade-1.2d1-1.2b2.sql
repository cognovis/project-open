--
-- Fixes case deletion, which can now be done completely through cascading delete
-- Also adds missing upgrade scripts from that bug fix
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$

create or replace package body workflow_case_pkg
as 
  function get_pretty_state(
    workflow_short_name in varchar,
    object_id in integer
  ) return varchar
  is 
    v_state_pretty varchar(4000);
    v_object_id integer;
  begin
   v_object_id := object_id;   

   select s.pretty_name
   into   v_state_pretty
   from   workflows w,
          workflow_cases c,
          workflow_case_fsm cfsm,
          workflow_fsm_states s
   where  w.short_name = workflow_short_name
   and    c.object_id = v_object_id
   and    c.workflow_id = w.workflow_id
   and    cfsm.case_id = c.case_id
   and    s.state_id = cfsm.current_state;

   return v_state_pretty;

  end get_pretty_state;    

  function del(
    delete_case_id in integer
  ) return integer
  is
  begin
    -- All workflow data cascades from the case id
    delete 
    from   workflow_cases
    where  object_id = workflow_case_pkg.del.delete_case_id;

    return 0;
  end del;

end workflow_case_pkg;
/
show errors



create or replace package body workflow_case_log_entry
as 
   function new(
    entry_id in integer,
    case_id in integer,
    action_id in integer,
    comment in varchar,
    comment_mime_type in varchar,
    creation_user in integer,
    creation_ip in varchar,
    content_type in varchar default 'workflow_case_log_entry'
    ) return integer
  is
    v_name                        varchar2(4000); -- XXX aufflick fix this
    v_action_short_name           varchar2(4000);
    v_action_pretty_past_tense    varchar2(4000);
    v_case_object_id              integer;
    v_item_id                     integer;
    v_revision_id                 integer;
  begin
    select short_name, pretty_past_tense
    into   v_action_short_name, v_action_pretty_past_tense
    from   workflow_actions
    where  action_id = new.action_id;

    -- use case object as context_id
    select object_id
    into   v_case_object_id
    from   workflow_cases
    where  case_id = new.case_id;

    -- build the unique name
    if entry_id is not null then
        v_item_id := entry_id;
    else
        select acs_object_id_seq.nextval into v_item_id from dual;
    end if;
    v_name := v_action_short_name || ' ' || v_item_id;

    v_item_id := content_item.new (
        item_id        => v_item_id,
        name            => v_name,
        parent_id       => v_case_object_id,
        title           => v_action_pretty_past_tense,
        creation_date   => sysdate(),
        creation_user   => creation_user,
        context_id      => v_case_object_id,
        creation_ip     => creation_ip,
        is_live         => 't',
        mime_type       => comment_mime_type,
        text            => comment,
        storage_type    => 'text',
        item_subtype    => 'content_item',
        content_type    => content_type
    );

    -- insert the row into the single-column entry revision table
    v_revision_id := content_item.get_live_revision (v_item_id);

    insert into workflow_case_log_rev (entry_rev_id)
    values (v_revision_id);

    -- insert into workflow-case-log
    -- raise_application_error(-20000, 'about to insert ' || v_item_id || ',' || new.case_id || ',' || new.action_id);
    insert into workflow_case_log (entry_id, case_id, action_id)
    values (v_item_id, new.case_id, new.action_id);

    -- return id of newly created item
    return v_item_id;
  end new;

end workflow_case_log_entry;
/
show errors
    


-- Now change parent_id of existing cases

begin
    for rec in (select c.object_id, 
                       l.entry_id 
                from   workflow_cases c, 
                       workflow_case_log l 
                where  c.case_id = l.case_id)
    loop
        update cr_items
        set    parent_id = rec.object_id
        where  item_id = rec.entry_id;
    end loop;
end;
/
show errors
