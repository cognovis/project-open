<?xml version="1.0"?>
<queryset>

<fullquery name="contacts_pagination">
    <querytext>
        select acs_objects.object_id
          from $contact_tables 
         where $join_clauses
           $search_clause
         [template::list::filter_where_clauses -and -name "contacts"]
         [template::list::orderby_clause -orderby -name "contacts"]

    </querytext>
</fullquery>

<fullquery name="contacts_select">      
    <querytext>
        select * $select_string
          from $contact_tables
         where $join_clauses
         [template::list::page_where_clause -and -name "contacts" -key "acs_objects.object_id"]
         [template::list::orderby_clause -orderby -name "contacts"]
    </querytext>
</fullquery>


<fullquery name="report_contacts_select">
    <querytext>
        select distinct parties.party_id
          from parties,
               cr_items
         where parties.party_id = cr_items.item_id
           and parties.party_id in ( select group_approved_member_map.member_id
                                       from group_approved_member_map
                                      where group_approved_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_group]]) )
        [contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "cr_items.live_revision"]
    </querytext>
</fullquery>


<fullquery name="get_default_extends">
    <querytext>
        select csem.extend_id 
          from contact_search_extend_map csem,
               contact_extend_options ceo
         where ceo.extend_id = csem.extend_id
           and ceo.aggregated_p = 'f'
           and csem.search_id = :search_id 
    </querytext>
</fullquery>

<fullquery name="employees_select">
    <querytext>
        select distinct $extend_query
               rel.object_id_one as party_id,
               rel.object_id_two as employee_id
          from acs_rels rel,
               parties
         where rel.rel_type = 'contact_rels_employment'
           and rel.object_id_one = parties.party_id
        [template::list::page_where_clause -and -name "contacts" -key "party_id"]
    </querytext>
</fullquery>

<fullquery name="employees_pagination">
    <querytext>
        select rel.object_id_one as party_id,
               rel.object_id_two as employee_id
          from acs_rels rel, persons p
         where rel.rel_type = 'contact_rels_employment'
           and person_id = object_id_one
         order by last_name
    </querytext>
</fullquery>


<fullquery name="get_condition_types">
    <querytext>
        select type 
          from contact_search_conditions
         where search_id = :search_id
    </querytext>
</fullquery>

</queryset>
