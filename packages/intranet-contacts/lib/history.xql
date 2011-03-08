<?xml version="1.0"?>
<queryset>

<fullquery name="select_deleted_history">
      <querytext>
	select object_id
          from contact_deleted_history
         where party_id = :party_id
      </querytext>
</fullquery>

</queryset>
