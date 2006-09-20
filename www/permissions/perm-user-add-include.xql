<?xml version="1.0"?>

<queryset>

<fullquery name="users_who_dont_have_any_permissions">
      <querytext>

    select u.user_id,
           u.first_names || ' ' || u.last_name as name,
           u.email
    from   cc_users u
    where  1 = 1
           $page_where_clause
    order  by upper(first_names), upper(last_name)

      </querytext>
</fullquery>

<fullquery name="users_who_dont_have_any_permissions_paginator">
      <querytext>

    select u.user_id
    from   cc_users u
    where  1 = 1
    order  by upper(first_names), upper(last_name)

      </querytext>
</fullquery>

</queryset>
