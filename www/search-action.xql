<?xml version="1.0"?>
<queryset>

<fullquery name="select_search_info">
      <querytext>
      select title,
             owner_id as old_owner_id,
             all_or_any,
             contact_searches.object_type
        from contact_searches,
             acs_objects
       where search_id = object_id
         and search_id = :search_id
      </querytext>
</fullquery>

<fullquery name="update_owner">
      <querytext>
      update contact_searches
         set owner_id = :owner_id
       where search_id = :search_id
      </querytext>
</fullquery>

<fullquery name="select_similar_titles">
      <querytext>
      select title
        from contact_searches,
             acs_objects
       where search_id = object_id
         and owner_id = :owner_id
         and upper(title) like upper('${sql_title}%')
      </querytext>
</fullquery>

<fullquery name="select_search_conditions">
      <querytext>
      select type,
             var_list
        from contact_search_conditions
       where search_id = :search_id
      </querytext>
</fullquery>

</queryset>
