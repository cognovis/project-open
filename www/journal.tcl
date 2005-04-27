# assume that the following are set:
#    case_id

if { ![info exists date_format] || [empty_string_p $date_format] } {
    set date_format "Mon fmDDfm, YYYY HH24:MI:SS"
}

if { ![info exists order] || [empty_string_p $order] } {
    set order latest_first
}

if { ![info exists comment_link] || [empty_string_p $comment_link] } {
    set comment_link 1
}

switch -- $order {
    latest_first {
	set sql_order "desc"
    }
    latest_last {
	set sql_order "asc"
    }
    default {
	return -code error "Order must be latest_first or latest_last"
    }
}

set entries [list]
db_multirow journal journal_select "
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
"

# lars, 1/23/01:
# We include journal_id in the sort order under the assumption that journal entries will get
# assigned increasing journal_id's, so that we get 'Case finished' as the last journal entry,
# even though it has the exact same date as the last task finishing.
