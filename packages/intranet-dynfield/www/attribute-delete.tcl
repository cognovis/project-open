# packages/intranet-dynfield/www/attribute-delete.tcl

ad_page_contract {

    Bulk delete attributes

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2005-01-25
    @cvs-id
} {
    attribute_ids:multiple,integer,notnull
    object_type:notnull
    return_url
    continue_p:optional
} -properties {
} -validate {
} -errors {
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set title "[_ intranet-dynfield.Delete_Warning]"
set context [list [list "object-types" "Object Types"] [list "$return_url" "$object_type"] $title]
set html_warning ""

if {![exists_and_not_null continue_p]} {
	set continue_p "1"
	foreach attr_id $attribute_ids {
		db_1row "get attribute" "select attribute_name 
			from acs_attributes 
			where attribute_id = (select acs_attribute_id 
					      from im_dynfield_attributes 
					      where attribute_id = :attr_id)"
		# -------------------------------
		# check if attr_id has references
		# -------------------------------
		set proc_name "$object_type\_$attribute_name"
		if {[apm_package_enabled_p "template-letter"]} {
			set letter_types [db_list "get letter types" "select name 
				from template_letter_types
				where letter_type_id in (select letter_type_id 
							   from template_letter_merge_fields 
							   where tcl_proc = :proc_name)"]
			if {[llength $letter_types] > 0} {
				set continue_p 0
				append html_warning " <br/> $attribute_name [_ intranet-dynfield.have_template_letter_references] ... <ul> "
				foreach l_t $letter_types {
					append html_warning " <li>$l_t</li> "
				}
				append html_warning " </ul> "
				
			}
		}
		
		if {[apm_package_enabled_p "smart-forms"]} {
			set questions_list [db_list_of_lists "get smart-forms questions" "select distinct sgqn.section_no, 
				sgqn.question_no 
				from survsimp_grouped_question_nos sgqn,
				     survsimp_questions sq,
				     survsimp_question_keys sqk
				where sqk.interface_key = :proc_name
				and sqk.question_key = sq.question_key
				and sq.grouped_question_no_id = sgqn.grouped_question_no_id"]
			if {[llength $questions_list] > 0} {
				set continue_p 0
				append html_warning " <br/> $attribute_name [_ intranet-dynfield.have_smart_form_references] ... <ul> "
				foreach question_pair $questions_list {
					set section_no [lindex $question_pair 0]
					set question_no [lindex $question_pair 1]
					append html_warning " <li>[_ intranet-dynfield.Section]: $section_no [_ intranet-dynfield.Question]: $question_no</li> "
				}
				append html_warning " </ul> "

			}
		}
	}

}




if {$continue_p} {
	foreach attr_id $attribute_ids {
		    attribute::delete_xt $attr_id
	}
	ad_returnredirect $return_url
}

ad_return_template