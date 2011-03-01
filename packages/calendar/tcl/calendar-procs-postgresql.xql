<?xml version="1.0"?>

<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="calendar::create.create_new_calendar">      
  <querytext>
    select calendar__new(
    	null,
    	:calendar_name,
    	'calendar',
    	:owner_id,
    	:private_p,
    	:package_id,
    	null,
    	now(),
    	:creation_user,
    	:creation_ip
    );
  </querytext>
</fullquery>
 
<fullquery name="calendar::calendar_list.select_calendar_list">
  <querytext>
    select calendar_name, 
           calendar_id, 
           acs_permission__permission_p(calendar_id, :user_id, 'calendar_admin') as calendar_admin_p
    from   calendars
    where  (private_p = 'f' and package_id = :package_id $permissions_clause) or 
           (private_p = 't' and owner_id = :user_id)
    order  by private_p asc, upper(calendar_name)
  </querytext>
</fullquery>

<partialquery name="calendar::calendar_list.permissions_clause">
  <querytext>
        and acs_permission__permission_p(calendar_id, :user_id, :privilege) = 't'
  </querytext>
</partialquery>

<fullquery name="calendar::delete.delete_calendar">
  <querytext>
        select calendar__delete(:calendar_id)
  </querytext>
</fullquery>

</queryset>
