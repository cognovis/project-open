ad_page_contract {

    Export all relationships

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2006-04-24
    @cvs-id $Id$

} {
}


set output {"Relation ID","Relation Type","Role One","Contact ID One","Role Two","Contact ID Two"}
append output "\n"
db_foreach get_rels "
select acs_rels.rel_id,
       acs_rels.rel_type,
       roles_one.pretty_name as role_one,
       object_id_one,
       roles_two.pretty_name as role_two,
       object_id_two
  from acs_rels,
       contact_rels,
       acs_rel_types,
       ( select role, pretty_name from acs_rel_roles ) as roles_one,
       ( select role, pretty_name from acs_rel_roles ) as roles_two
 where acs_rels.rel_id = contact_rels.rel_id
   and acs_rels.rel_type = acs_rel_types.rel_type
   and acs_rel_types.role_one = roles_one.role
   and acs_rel_types.role_two = roles_two.role
   and acs_rels.object_id_one in ( select member_id from group_approved_member_map where group_id in ([template::util::tcl_to_sql_list [contacts::default_groups]]))
   and acs_rels.object_id_two in ( select member_id from group_approved_member_map where group_id in ([template::util::tcl_to_sql_list [contacts::default_groups]]))
 order by acs_rels.rel_type, acs_rels.rel_id
" {
    set rel_type [template::list::csv_quote $rel_type]
    set role_one [template::list::csv_quote [lang::util::localize $role_one]]
    set role_two [template::list::csv_quote [lang::util::localize $role_two]]
    append output "\"${rel_id}\",\"${rel_type}\",\"${role_one}\",\"${object_id_one}\",\"${role_two}\",\"${object_id_two}\"\n"

}


set output "$output\n"


set output_file [open /tmp/full-rels.csv "w+"]
puts $output_file $output
close $output_file

# now we return the file - just in case it didn't time out for the user
ns_return 200 text/plain $output
#ad_return_error "done." "<pre>$output</pre>"
