<?xml version="1.0"?>

<queryset>


<fullquery name="get_results">      
      <querytext>

    select 
      distinct u.user_id, u.screen_name,
      p.first_names || ' ' || p.last_name as name,
      pp.email
    from
      users u, persons p, parties pp $extra_table
    where 
      ($clauses)
    and
      p.person_id = u.user_id
    and
      pp.party_id = u.user_id
      $where_clause

      </querytext>
</fullquery>

 
</queryset>
