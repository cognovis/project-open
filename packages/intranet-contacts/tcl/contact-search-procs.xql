<?xml version="1.0"?>
<queryset>

<fullquery name="contact::search::log.log_search">
  <querytext>
    select contact_search__log(:search_id,:user_id)
  </querytext>
</fullquery>

<fullquery name="contact::search::title.select_title">
  <querytext>
    select title
      from acs_objects
     where object_id = :search_id
  </querytext>
</fullquery>

<fullquery name="contact::search::permitted.select_search_info">
  <querytext>
    select cs.owner_id,
           ao.package_id
      from contact_searches cs,
           acs_objects ao
     where cs.search_id = ao.object_id
       and cs.search_id = :search_id
      </querytext>
</fullquery>

<fullquery name="contact::search::get.select_search_info">
  <querytext>
    select contact_searches.*, acs_objects.title, acs_objects.package_id
      from contact_searches, acs_objects
     where contact_searches.search_id = :search_id
       and contact_searches.search_id = acs_objects.object_id
  </querytext>
</fullquery>

<fullquery name="contact::search_pretty_not_cached.select_conditions">
  <querytext>
    select type,
           var_list
      from contact_search_conditions
     where search_id = :search_id
  </querytext>
</fullquery>


<fullquery name="contact::search::results_count_not_cached.get_condition_types">
  <querytext>
    select type 
      from contact_search_conditions
     where search_id = :search_id
  </querytext>
</fullquery>

<fullquery name="contact::search::results_count_not_cached.select_results_count">
  <querytext>
    select count(acs_objects.object_id)
      from $contact_tables
     where $join_clauses
  </querytext>
</fullquery>


<fullquery name="contact::search::results.select_party_results">
  <querytext>
    select distinct parties.party_id
      from parties, $cr_from group_approved_member_map
     where parties.party_id = group_approved_member_map.member_id
	$cr_where
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
	$search_clause
  </querytext>
</fullquery>

<fullquery name="contact::search::results.get_condition_types">
  <querytext>
    select type 
      from contact_search_conditions
     where search_id = :search_id
  </querytext>
</fullquery>

<fullquery name="contact::search::results.select_person_results">
  <querytext>
    select distinct person_id
      from persons, $cr_from group_approved_member_map
     where persons.person_id = group_approved_member_map.member_id
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
	$cr_where
	$search_clause
  </querytext>
</fullquery>

<fullquery name="contact::search::results.select_organization_results">
  <querytext>
    select distinct organization_id
      from organizations, $cr_from
           group_approved_member_map
     where organizations.organization_id = group_approved_member_map.member_id
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
	$cr_where
	$search_clause
  </querytext>
</fullquery>

<fullquery name="contact::search::results.select_employee_results">
  <querytext>
    select distinct person_id
      from persons, $cr_from
           group_approved_member_map,
           acs_rels
     where persons.person_id = group_approved_member_map.member_id
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
       and persons.person_id = acs_rels.object_id_one
       and acs_rels.rel_type = 'contact_rels_employment'
        $cr_where
        $search_clause
  </querytext>
</fullquery>

<fullquery name="contact::search::results.select_employees_results">
  <querytext>
    select object_id_two
      from acs_rels
     where rel_type = 'im_employment_rel'
  </querytext>
</fullquery>


<fullquery name="contact::party_id_in_sub_search_clause.get_condition_types">
  <querytext>
    select type 
      from contact_search_conditions
     where search_id = :search_id
  </querytext>
</fullquery>

<fullquery name="contact::party_id_in_sub_search_clause.select_party">
    <querytext>
    select distinct parties.party_id
      from parties, $cr_from group_approved_member_map
     where parties.party_id = group_approved_member_map.member_id
	$cr_where
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
	$search_clause
    </querytext>
</fullquery>

<fullquery name="contact::party_id_in_sub_search_clause.select_person">
    <querytext>
        select distinct persons.person_id as party_id
      from persons, $cr_from group_approved_member_map
     where persons.person_id = group_approved_member_map.member_id
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
	$cr_where
	$search_clause
  </querytext>
</fullquery>

<fullquery name="contact::party_id_in_sub_search_clause.select_organization">
    <querytext>
        select distinct organizations.organization_id as party_id, 
      from organizations, $cr_from
           group_approved_member_map
     where organizations.organization_id = group_approved_member_map.member_id
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
	$cr_where
	$search_clause
  </querytext>
</fullquery>

<fullquery name="contact::party_id_in_sub_search_clause.select_employee">
    <querytext>
        select distinct persons.person_id as party_id
      from persons, $cr_from
           group_approved_member_map,
           acs_rels
     where persons.person_id = group_approved_member_map.member_id
       and group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
       and persons.person_id = acs_rels.object_id_one
       and acs_rels.rel_type = 'contact_rels_employment'
        $cr_where
        $search_clause
  </querytext>
</fullquery>

<fullquery name="contact::search::party_p_not_cached.party_in_search_p">
  <querytext>
    select 1
      from cr_items
     where item_id = $party_id
       and item_id in ( select member_id from group_approved_member_map where group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]]))
    [contact::search_clause -and -search_id $search_id -party_id "cr_items.item_id" -revision_id "cr_items.live_revision"]
  </querytext>
</fullquery>

<fullquery name="contact::search::where_clause_not_cached.get_search_info">
  <querytext>
    select owner_id,
           all_or_any,
           object_type
      from contact_searches
     where search_id = :search_id
  </querytext>
</fullquery>

<fullquery name="contact::search::where_clause_not_cached.select_queries">
  <querytext>
    select type,
           var_list
      from contact_search_conditions
     where search_id = :search_id
  </querytext>
</fullquery>

<fullquery name="contact::search::object_type_not_cached.get_object_type">
  <querytext>
  select object_type 
    from contact_searches 
   where search_id = :search_id
     </querytext>
</fullquery>
</queryset>
