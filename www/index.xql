<?xml version="1.0"?>
<queryset>

<fullquery name="public_searches">
      <querytext>
    select acs_objects.title,
           contact_searches.search_id
      from contact_searches,
           acs_objects
     where contact_searches.owner_id = :package_id
       and contact_searches.search_id = acs_objects.object_id
       and acs_objects.title is not null
       and not contact_searches.deleted_p
     order by lower(acs_objects.title)
      </querytext>
</fullquery>

<fullquery name="my_searches">
      <querytext>
    select ao.title as my_searches_title,
           cs.search_id as my_searches_search_id
      from contact_searches cs,
           acs_objects ao
     where cs.search_id = ao.object_id
       and ao.title is not null
       and cs.owner_id = :user_id
       and not cs.deleted_p
     order by upper(ao.title)
      </querytext>
</fullquery>

<fullquery name="mapped_groups">
      <querytext>
    select ao.title as my_lists_title,
           cl.list_id as my_lists_list_id
      from contact_lists cl,
           acs_objects ao
     where cl.list_id = ao.object_id
       and ao.object_id in ( select object_id from contact_owners where owner_id in ( :user_id , :package_id ))
     order by upper(ao.title)
      </querytext>
</fullquery>

<fullquery name="my_lists">
      <querytext>
    select ao.title as my_lists_title,
           cl.list_id as my_lists_list_id
      from contact_lists cl,
           acs_objects ao
     where cl.list_id = ao.object_id
       and ao.object_id in ( select object_id from contact_owners where owner_id in ( :user_id , :package_id ))
     order by upper(ao.title)
      </querytext>
</fullquery>

</queryset>
