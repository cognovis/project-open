<?xml version="1.0"?>
<queryset>

<fullquery name="select_lists">
      <querytext>
    select contact_lists.list_id, title, members.members
      from contact_lists left join ( select count(1) as members, list_id from contact_list_members group by list_id ) members on ( contact_lists.list_id = members.list_id),
           acs_objects
     where contact_lists.list_id = acs_objects.object_id
       and acs_objects.package_id = :package_id
       and contact_lists.list_id in ( select object_id from contact_owners where owner_id = :user_id or owner_id = :package_id )
     order by upper(title), contact_lists.list_id
      </querytext>
</fullquery>

</queryset>
