<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="workflow::get_not_cached.workflow_info">
    <querytext>
      select w.workflow_id,
             w.short_name,
             w.pretty_name,
             w.object_id,
             w.package_key,
             w.object_type,
             w.description,
             w.description_mime_type,
             a.short_name as initial_action,
             a.action_id as initial_action_id
      from   workflows w,
             workflow_actions a
      where  w.workflow_id = :workflow_id
        and  w.workflow_id = a.workflow_id (+)
        and  a.parent_action_id is null
        and  (a.trigger_type = 'init' or a.trigger_type is null)
    </querytext>
  </fullquery>

  <fullquery name="workflow::edit.do_insert">
    <querytext>
        begin
        :1 := workflow.new (
            short_name => :attr_short_name,
            pretty_name => :attr_pretty_name,
            package_key => :attr_package_key,            
            object_id => :attr_object_id,
            object_type => :attr_object_type,
            creation_user => :attr_creation_user,
            creation_ip => :attr_creation_ip,
            context_id => :attr_context_id
        );
        end;
    </querytext>
  </fullquery>

  <fullquery name="workflow::delete.do_delete">
    <querytext>
        begin
            :1 := workflow.del(:workflow_id);
        end;
    </querytext>
  </fullquery>
 
  <fullquery name="workflow::callback_insert.select_sort_order">
    <querytext>
        select nvl(max(sort_order),0) + 1
        from   workflow_callbacks
        where  workflow_id = :workflow_id
    </querytext>
  </fullquery>

</queryset>
