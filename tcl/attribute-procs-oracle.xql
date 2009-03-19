<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

 
<fullquery name="delete_xt.select_attr_info">      
      <querytext>
      
        select a.object_type, a.attribute_name, 
               case when a.storage = 'type_specific' then t.table_name else a.table_name end as table_name,
	       nvl(a.column_name, a.attribute_name) as column_name
          from acs_attributes a, acs_object_types t
         where a.attribute_id = :attribute_id
           and t.object_type = a.object_type
    
      </querytext>
</fullquery>


<fullquery name="attribute::delete_xt.drop_attribute">
<querytext>
    begin 
	dynfield_attribute.del(:dynfield_attribute_id); 
    end;
</querytext>
</fullquery>

<fullquery name="attribute::delete_xt.drop_attr_column">
<querytext>
alter table $table_name drop column $column_name
</querytext>
</fullquery>


</queryset>
