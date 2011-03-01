<?xml version="1.0"?>
<queryset>

<fullquery name="contacts::default_group_not_cached.get_parent_subsite_id">
  <querytext>
    select object_id
      from site_nodes
     where tree_level(tree_sortkey) < ( select tree_level(n2.tree_sortkey) from site_nodes n2 where n2.node_id = :node_id )
       and object_id in ( select package_id
                            from apm_packages
                           where package_key = 'acs-subsite' )
     order by tree_sortkey desc
     limit 1
  </querytext>
</fullquery>

<fullquery name="contacts::default_groups_not_cached.get_child_contacts_instances">
  <querytext>
    select p.package_id
      from site_nodes n, site_nodes n2, apm_packages p
     where n2.node_id = (select coalesce(:parent_node_id, site_node__node_id('/', null)))
       and n.tree_sortkey between n2.tree_sortkey and tree_right(n2.tree_sortkey)
       and n.object_id = p.package_id
       and p.package_key = 'contacts'
       and (tree_level(n.tree_sortkey) - (select tree_level(n2.tree_sortkey) from site_nodes n2 where n2.node_id = (select coalesce(:parent_node_id, site_node__node_id('/', null))))) > 1;
  </querytext>
</fullquery>

<fullquery name="contacts::sweeper.get_persons_num">
  <querytext>
     select count(distinct person_id) from group_member_map gmm, membership_rels mr, persons left join (select item_id from cr_items where content_type = 'contact_party_revision') items on item_id = person_id
      where person_id > 0
      and gmm.rel_id = mr.rel_id
      and gmm.group_id = -2
      and gmm.member_id = persons.person_id
      and item_id is null
 </querytext>
</fullquery>

<fullquery name="contacts::sweeper.get_persons_without_items">
  <querytext>
     select distinct person_id, first_names,last_name,email 
     from group_member_map gmm, membership_rels mr, persons left join (select item_id from cr_items where content_type = 'contact_party_revision') items on item_id = person_id, parties
     where person_id > 0
      and gmm.rel_id = mr.rel_id
      and gmm.group_id = -2
      and gmm.member_id = persons.person_id
     and person_id = party_id
     and item_id is null
 </querytext>
</fullquery>

<fullquery name="contacts::sweeper.member_state">
  <querytext>
    select member_state 
      from cc_users 
     where user_id = :person_id
 </querytext>
</fullquery>

<fullquery name="contacts::sweeper.get_organizations_without_items">
  <querytext>
    select organization_id
      from organizations
     where organization_id not in ( select item_id from cr_items )
  </querytext>
</fullquery>

<fullquery name="contacts::sweeper.insert_privacy_records">
  <querytext>
    insert into contact_privacy
           ( party_id, email_p, mail_p, phone_p, gone_p )
    select p.party_id, 't'::boolean, 't'::boolean, 't'::boolean, 'f'::boolean
      from parties p left join contact_privacy c on c.party_id = p.party_id
     where c.party_id is null
  </querytext>
</fullquery>

<fullquery name="contacts::sweeper.delete_deleted_users">
  <querytext>
    delete 
      from group_element_index
     where group_id = :group_id 
     and element_id in (select member_id  from membership_rels m, group_member_map g where g.rel_id = m.rel_id and member_state = 'deleted' and group_id = -2)
 </querytext>
</fullquery>

<fullquery name="contacts::sweeper.deleted_user_items">
  <querytext>
  select item_id 
    from cr_items, membership_rels m, group_member_map g 
   where g.rel_id = m.rel_id 
     and member_state = 'deleted' 
     and group_id = -2 
     and item_id = member_id
 </querytext>
</fullquery>


<fullquery name="contact::privacy_allows_p.is_type_allowed_p">
  <querytext>
    select ${type}_p
      from contact_privacy
     where party_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::privacy_set.record_exists_p">
  <querytext>
    select 1
      from contact_privacy
     where party_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::privacy_set.update_privacy">
  <querytext>
    update contact_privacy
       set email_p = :email_p,
           mail_p = :mail_p,
           phone_p = :phone_p,
           gone_p = :gone_p
     where party_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::privacy_set.insert_privacy">
  <querytext>
    insert into contact_privacy
           ( party_id, email_p, mail_p, phone_p, gone_p )
           values
           ( :party_id, :email_p, :mail_p, :phone_p, :gone_p )
  </querytext>
</fullquery>

<fullquery name="contact::util::generate_filename.get_parties_existing_filenames">
  <querytext>
    select name
      from cr_items
     where parent_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::visible_p_not_cached.get_contact_visible_p">
  <querytext>
    select 1
      from group_approved_member_map
     where member_id = :party_id
       and group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
     limit 1
  </querytext>
</fullquery>

<fullquery name="contact::groups_list_not_cached.get_groups">
  <querytext>
    select aux_int1 as group_id,
           category as group_name,
           ( select count(distinct gamm.member_id) from group_approved_member_map gamm, persons where gamm.group_id = aux_int1 and member_id = person_id  ) as member_count,
           0 as component_count,
           1 as mapped_p,
           0 as default_p,
           1 as user_change_p,
           $dotlrn_community_p as dotlrn_community_p,
           0 as notifications_p
      from im_categories
     where category_type = 'Intranet User Type'
       and aux_int1 is not null
     order by category
  </querytext>
</fullquery>

<fullquery name="contact::groups.get_components">
  <querytext>
            select groups.group_id,
                   groups.group_name,
                   ( select count(distinct gamm.member_id) from group_approved_member_map gamm where gamm.group_id = groups.group_id ) as member_count,
                   CASE WHEN package_id is not null THEN '1' ELSE '0' END as mapped_p,
                   CASE WHEN default_p THEN '1' ELSE '0' END as default_p
              from groups left join contact_groups on ( groups.group_id = contact_groups.group_id ), group_component_map
             where group_component_map.group_id = :group_id
               and group_component_map.component_id = groups.group_id
             order by upper(groups.group_name)
  </querytext>
</fullquery>

<fullquery name="contact::group::parent.get_parent">
  <querytext>
            select group_id
              from group_component_map
             where component_id = :group_id
               and group_id != '-1'
  </querytext>
</fullquery>

<fullquery name="contact::group::new.create_group">
  <querytext>
	select acs_group__new (
                :group_id,
                'group',
                now(),
                :creation_user,
                :creation_ip,
                :email,
                :url,
                :group_name,
                :join_policy,
                :context_id
        )
  </querytext>
</fullquery>

<fullquery name="contact::group::map.map_group">
  <querytext>
        insert into contact_groups
        (group_id,default_p,notifications_p,package_id)
        values
        (:group_id,:default_p,:notifications_p,:package_id)
  </querytext>
</fullquery>

<fullquery name="contact::group::mapped_p.select_mapped_p">
  <querytext>
	select 1 from contact_groups
         where group_id = :group_id
           and package_id = :package_id
  </querytext>
</fullquery>

<fullquery name="contact::group::notifications_p.select_notifications_p">
  <querytext>
	select 1 from contact_groups
         where group_id = :group_id
           and notifications_p
         limit 1
  </querytext>
</fullquery>

<fullquery name="contact::revision::new.insert_item">
  <querytext>
         insert into cr_items
         (item_id,parent_id,name,content_type)
         values
         (:party_id,contact__folder_id(),:party_id,'contact_party_revision');
     </querytext>
</fullquery>

<fullquery name="contact::util::create_rel.rel_exists_p">
  <querytext>
  select rel_id
        from acs_rels 
       where rel_type = :rel_type
         and object_id_one = :object_id_one
         and object_id_two = :object_id_two
  </querytext>
</fullquery>

<fullquery name="contact::util::create_rel.create_rel">
  <querytext>
  select acs_rel__new (
                           :rel_id,
                           :rel_type,
                           :object_id_one,
                           :object_id_two,
                           :context_id,
                           :creation_user,
                           :creation_ip  
                          )     
    </querytext>
</fullquery>
<fullquery name="contact::util::create_rel.insert_contact_rel">
      <querytext>
insert into contact_rels
       (rel_id)
values 
       (:rel_id)
      </querytext>
</fullquery>
</queryset>
