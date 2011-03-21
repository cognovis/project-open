<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

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
      from   workflows w left outer join
             workflow_actions a on (a.workflow_id = w.workflow_id
                                and a.parent_action_id is null
                                and a.trigger_type = 'init')
      where  w.workflow_id = :workflow_id
    </querytext>
  </fullquery>


  <fullquery name="workflow::edit.do_insert">
    <querytext>
        select workflow__new (
            :attr_short_name,
            :attr_pretty_name,
            :attr_package_key,            
            :attr_object_id,
            :attr_object_type,
            :attr_creation_user,
            :attr_creation_ip,
            :attr_context_id
        );
    </querytext>
  </fullquery>

  <fullquery name="workflow::delete.do_delete">
    <querytext>
        select workflow__delete(:workflow_id);
    </querytext>
  </fullquery>
  
  <fullquery name="workflow::callback_insert.select_sort_order">
    <querytext>
        select coalesce(max(sort_order),0) + 1
        from   workflow_callbacks
        where  workflow_id = :workflow_id
    </querytext>
  </fullquery>

 </queryset>
