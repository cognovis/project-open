<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="journal_select">      
      <querytext>
      
    select j.journal_id,
           j.action,
           j.action_pretty,
           o.creation_date,
           to_char(o.creation_date, :date_format) as creation_date_pretty,
           o.creation_user,
           acs_object.name(o.creation_user) as creation_user_name,
	   p.email as creation_user_email, 
	   o.creation_ip,
           j.msg,
           a.attribute_name as attribute_name, 
	   a.pretty_name as attribute_pretty_name,
	   a.datatype as attribute_datatype, 
	   v.attr_value as attribute_value
    from   journal_entries j, acs_objects o, parties p,
           wf_attribute_value_audit v, acs_attributes a
    where  j.object_id = :case_id
      and  o.object_id = j.journal_id
      and  p.party_id (+) =  o.creation_user
      and  v.journal_id (+) = j.journal_id
      and  a.attribute_id (+) = v.attribute_id
    order  by o.creation_date $sql_order, j.journal_id $sql_order

      </querytext>
</fullquery>

 
</queryset>
