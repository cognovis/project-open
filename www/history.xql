<?xml version="1.0"?>
<queryset>

<fullquery name="object_already_deleted_in_history">
      <querytext>
	select 1
          from contact_deleted_history
         where object_id = :delete_object_id
      </querytext>
</fullquery>

<fullquery name="delete_object_from_history">
      <querytext>
	insert into contact_deleted_history
               ( party_id, object_id, deleted_by, deleted_date )
               values
               ( :party_id, :delete_object_id, :user_id, now() )
      </querytext>
</fullquery>

</queryset>
