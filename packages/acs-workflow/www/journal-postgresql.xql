<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="journal_select">      
      <querytext>

    select j.journal_id,
           j.action,
           j.action_pretty,
           o.creation_date,
           to_char(o.creation_date, :date_format) as creation_date_pretty,
           o.creation_user,
           acs_object__name(o.creation_user) as creation_user_name,
	   o.creation_ip,
           j.msg,
           a.attribute_name as attribute_name, 
	   a.pretty_name as attribute_pretty_name,
	   a.datatype as attribute_datatype, 
	   v.attr_value as attribute_value
    from   (journal_entries j LEFT OUTER JOIN wf_attribute_value_audit v 
	     on (j.journal_id = v.journal_id)) LEFT OUTER JOIN acs_attributes a 
	       on (v.attribute_id = a.attribute_id), 
	   acs_objects o
    where  j.object_id = :case_id
      and  o.object_id = j.journal_id
    order  by o.creation_date $sql_order, j.journal_id $sql_order

      </querytext>
</fullquery>

 
</queryset>
