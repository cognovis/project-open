<?xml version="1.0"?>
<queryset>

<fullquery name="condition_exists_p">
      <querytext>
    select owner_id
      from contact_searches
     where search_id = :search_id
      </querytext>
</fullquery>

<fullquery name="delete_column">
      <querytext>
    delete from contact_search_extend_map
     where search_id = :search_id
       and extend_column = :remove_column
      </querytext>
</fullquery>

<fullquery name="insert_column">
      <querytext>
    insert into contact_search_extend_map
           ( search_id, extend_column )
           values
           ( :search_id , :add_column )
      </querytext>
</fullquery>

<fullquery name="contacts_pagination">
      <querytext>
    select gmm.member_id as party_id
      from group_member_map gmm,
           membership_rels mr
     where gmm.rel_id = mr.rel_id
    [template::list::filter_where_clauses -and -name "contacts"]
    [template::list::orderby_clause -orderby -name "contacts"]
      </querytext>
</fullquery>

<fullquery name="pretty_roles">
      <querytext>

        select admin_role.pretty_name as admin_role_pretty,
          member_role.pretty_name as member_role_pretty
        from acs_rel_roles admin_role, acs_rel_roles member_role
        where admin_role.role = 'admin'
          and member_role.role = 'member'

      </querytext>
</fullquery>

<fullquery name="get_groups">
      <querytext>

    select groups.group_name,
           groups.group_id,
           ( select count(distinct member_id) from group_approved_member_map where group_approved_member_map.group_id = groups.group_id ) as member_count
      from groups left join ( select group_id, default_p
                                from contact_groups
                               where package_id = :package_id ) contact_groups on (groups.group_id = contact_groups.group_id)
     where groups.group_id != '-1'
    order by CASE WHEN groups.group_id = '[contacts::default_group]' THEN '000000000' ELSE upper(groups.group_name) END

      </querytext>
</fullquery>

<fullquery name="get_rels">
      <querytext>

    select arr.pretty_plural,
           art.rel_type as relation_type,
           ( select count(distinct gmm.member_id) from group_approved_member_map gmm where gmm.group_id = :group_id and gmm.rel_type = art.rel_type ) as member_count
      from acs_rel_types art,
           acs_rel_roles arr
     where art.rel_type in ( select distinct gmm.rel_type from group_approved_member_map gmm where gmm.group_id = :group_id )
       and art.role_two = arr.role

      </querytext>
</fullquery>

<fullquery name="contacts_select">      
      <querytext>
    select gmm.member_id as party_id,
           gmm.group_id,
           gmm.rel_id, 
           gmm.rel_type,
           contact__name(gmm.member_id,:name_order) as name,
           mr.member_state,
           party__email(gmm.member_id) as email,
           ( select first_names from persons where person_id = gmm.member_id ) as first_names,
           ( select last_name from persons where person_id = gmm.member_id ) as last_name,
           ( select name from organizations where organization_id = gmm.member_id ) as organization
      from group_member_map gmm,
           membership_rels mr
     where gmm.rel_id = mr.rel_id
    [template::list::filter_where_clauses -and -name "contacts"]
    [template::list::page_where_clause -and -name "contacts" -key "gmm.member_id"]
      </querytext>
</fullquery>

<fullquery name="select_member_states">
      <querytext>

        select mr.member_state as state, 
               count(mr.rel_id) as num_contacts
        from   membership_rels mr, acs_rels r
        where  r.rel_id = mr.rel_id
          and  r.object_id_one = :group_id
          and  r.rel_type = 'membership_rel'
        group  by mr.member_state

      </querytext>
</fullquery>

<fullquery name="get_search_for">
    <querytext>
	select 
		object_type
	from 
		contact_searches
	where 
		search_id = :search_id
    </querytext>
</fullquery>

<fullquery name="get_var_list">
    <querytext>	
	select
		var_list
	from
		contact_search_conditions
	where
		type = 'group'
		and search_id = :search_id
    </querytext>
</fullquery>

<fullquery name="get_ams_options">
    <querytext>
	select 
		lam.attribute_id 
	from 
		ams_list_attribute_map lam,
		ams_lists l
	where 
		lam.list_id = l.list_id
		$search_for_clause
		$attribute_values_query
    </querytext> 
</fullquery>

<fullquery name="get_ams_pretty_name">
    <querytext>
	select
		a.pretty_name
	from
	    	ams_attributes a
	where
	    	a.attribute_id = :attribute
    </querytext>
</fullquery>
 
<fullquery name="get_extend_mapped_attributes">
    <querytext>
	select
		attribute_id
	from
		contact_search_extend_map
	where
		search_id = :search_id
		and attribute_id is not null
    </querytext>
</fullquery>

<fullquery name="get_search_info">
    <querytext>
       select ao.title,
              cs.owner_id,
              cs.all_or_any,
              cs.object_type
         from contact_searches cs,
              acs_objects ao
	where cs.search_id = :search_id 
          and cs.search_id = ao.object_id
    </querytext>
</fullquery>

<fullquery name="selectqueries">
    <querytext>
        select condition_id, type as query_type, var_list as query_var_list
          from contact_search_conditions
         where search_id = :search_id
    </querytext>
</fullquery>


</queryset>
