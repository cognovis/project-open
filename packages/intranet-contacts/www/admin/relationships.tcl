# /packages/mbryzek-subsite/www/admin/rel-types/index.tcl

ad_page_contract {

    Shows list of all defined relationship types, excluding the parent
    type "relationship"

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 17:10:56 2000
    @cvs-id $Id$

} {
} -properties {
    context:onevalue
    rel_types:multirow
}

set title "[_ intranet-contacts.Relationship_types]"
set context [list $title]

set package_id [ad_conn package_id]
set url [ad_conn url]
# Select out all relationship types, excluding the parent type names 'relationship'
# Count up the number of relations that exists for each type.
db_multirow -extend { primary_type_pretty secondary_type_pretty rel_form_url } rel_types get_rels {

select CASE WHEN primary_object_type = 'party' THEN '1' WHEN primary_object_type = 'person' THEN '2' ELSE '3' END as sort_one,
       CASE WHEN secondary_object_type = 'party' THEN '2' WHEN secondary_object_type = 'person' THEN '3' ELSE '4' END as sort_two,
       acs_rel_type__role_pretty_name(primary_role) as primary_role_pretty,
       acs_rel_type__role_pretty_name(secondary_role) as secondary_role_pretty,
       contact_rel_types.*,
       acs_object_types.pretty_name
  from contact_rel_types, acs_object_types
 where contact_rel_types.rel_type = acs_object_types.object_type
order by sort_one, sort_two, primary_role_pretty

} {
    set primary_type_pretty [intranet-contacts::object_type_pretty -object_type $primary_object_type]
    set secondary_type_pretty [intranet-contacts::object_type_pretty -object_type $secondary_object_type]

    set rel_form_url [ams::list::url \
                          -package_key "contacts" \
                          -object_type ${rel_type} \
                          -list_name ${rel_type} \
                          -pretty_name ${pretty_name} \
                          -return_url ${url} \
                          -return_url_label "[_ intranet-contacts.Return_to_title]"]

}
ad_return_template
