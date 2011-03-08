<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_group">      
      <querytext>
      begin acs_group.del(:id); end;
      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
  select NVL((select 'f' from dual where exists (
            select 1 from acs_rels 
              where object_id_one = :id 
              and rel_type in ('composition_rel', 'membership_rel'))),
          't') as is_empty from dual
      </querytext>
</fullquery>

 
</queryset>
