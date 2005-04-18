<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<partialquery name="get_groups_1">      
      <querytext>

    select
      g.group_id, g.group_name,
      NVL(pg.email, '&nbsp;') as email,
      (select count(*) from group_member_map 
       where group_id = g.group_id) as user_count
    from 
      groups g, parties pg, acs_rels rg, composition_rels rc
    where
      g.group_id = pg.party_id
    and
      rg.object_id_one = :id
    and
      rg.object_id_two = g.group_id
    and
      rc.rel_id = rg.rel_id
    order by
      upper(g.group_name)

      </querytext>
</partialquery>

<partialquery name="get_users_1">      
      <querytext>

    select
      u.user_id, ppu.first_names || ' ' || ppu.last_name as pretty_name,
      NVL(u.screen_name, '&nbsp;') as screen_name,
      pu.email, aru.member_state,
      aru.rel_id
    from
      users u, persons ppu, parties pu, 
      acs_rels ru, membership_rels aru
    where
      u.user_id = ppu.person_id
    and
      u.user_id = pu.party_id
    and
      ru.object_id_one = :id
    and
      ru.object_id_two = u.user_id
    and
      aru.rel_id = ru.rel_id
    and
      (aru.member_state <> 'deleted' or aru.member_state is null)
    order by
      upper(pretty_name)

      </querytext>
</partialquery>

<partialquery name="get_groups_2">      
      <querytext>

    select
      g.group_id, g.group_name,
      NVL(pg.email, '&nbsp;') as email, 
      (select count(*) from group_member_map 
       where group_id = g.group_id) as user_count
    from 
      groups g, parties pg
    where
      g.group_id = pg.party_id
    and
      not exists (
        select 1 from acs_rels ar, composition_rels cr
        where ar.rel_id = cr.rel_id
        and ar.object_id_two = g.group_id)
    order by
      g.group_name

      </querytext>
</partialquery>

<partialquery name="get_users_2">      
      <querytext>

    select
      u.user_id, ppu.first_names || ' ' || ppu.last_name as pretty_name,
      NVL(u.screen_name, '&nbsp;') as screen_name,
      pu.email, '' as member_state,
      null as rel_id       
    from
      users u, persons ppu, parties pu
    where
      u.user_id = ppu.person_id
    and
      u.user_id = pu.party_id
    and
      not exists (
        select 1 from acs_rels ar, membership_rels mr
        where ar.rel_id = mr.rel_id
        and ar.object_id_two = u.user_id)
    order by
      pretty_name

      </querytext>
</partialquery>

<fullquery name="check_admin">      
      <querytext>
      
  select 
    cms_permission.permission_p (:module_id, :user_id, 'cm_admin')
  from
    dual
      </querytext>
</fullquery>

 
<fullquery name="check_perm">      
      <querytext>
      
  select 
    cms_permission.permission_p (:module_id, :user_id, 'cm_perm')
  from
    dual
      </querytext>
</fullquery>

 
<fullquery name="get_info1">      
      <querytext>
      
    select 
      g.group_id, g.group_name, p.email, p.url,
      NVL((select 'f' from dual where exists (
            select 1 from acs_rels 
              where object_id_one = :id 
              and rel_type in ('composition_rel', 'membership_rel'))),
          't') as is_empty 
    from 
      groups g, parties p
    where
      g.group_id = :id
    and
      p.party_id = :id
      </querytext>
</fullquery>

 
</queryset>
