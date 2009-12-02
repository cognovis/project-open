# /packages/intranet-reste/www/index.tcl
#
# Copyright (C) 2009 ]project-open[
#

ad_page_contract {
    Home page for REST service, when accessing from the browser.
    The page shows a link to the documentation Wiki and a status
    of CRUD for every object type.
    
    @author frank.bergmann@project-open.com
} {

}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-rest.REST_API_Overview "REST API Overview"]
set context_bar [im_context_bar $page_title]


# ---------------------------------------------------------
# What operations are currently implemented on the REST API?
# ---------------------------------------------------------

array set crud_hash {
	group R
	im_biz_object_member CRUD
	im_company CRUD
	im_company_employee_rel CRUD
	im_cost_center R
	im_dynfield_attribute R
	im_dynfield_widget R
	im_invoice CRUD
	im_key_account_rel CRUD
	im_material R
	im_menu R
	im_note R
	im_office R
	im_profile R
	im_project CRUD
	im_repeating_cost R
	im_report R
	im_ticket CRUD
	im_ticket_ticket_rel CRUD
	im_timesheet_task CRUD
	im_trans_invoice CRUD
	im_trans_task CRUD
	im_user_absence CRUD
	membership_rel CRUD
	user CRU
}


array set wiki_hash {
	object_typ_im_indicator 1
	object_type_acs_attribute 1
	object_type_acs_object 1
	object_type_acs_object_type 1
	object_type_acs_permission 1
	object_type_acs_privilege 1
	object_type_acs_rel 1
	object_type_apm_package 1
	object_type_cal_item 1
	object_type_calendar 1
	object_type_group 1
	object_type_im_biz_object 1
	object_type_im_category 1
	object_type_im_company 1
	object_type_im_component_plugin 1
	object_type_im_conf_item 1
	object_type_im_cost 1
	object_type_im_cost_center 1
	object_type_im_dynfield_attribute 1
	object_type_im_employee 1
	object_type_im_expense 1
	object_type_im_expense_bundle 1
	object_type_im_forum_topic 1
	object_type_im_forum_topic_name 1
	object_type_im_fs_file 1
	object_type_im_hour 1
	object_type_im_indicator 1
	object_type_im_invoice 1
	object_type_im_material 1
	object_type_im_menu 1
	object_type_im_office 1
	object_type_im_payment 1
	object_type_im_profile 1
	object_type_im_project 1
	object_type_im_report 1
	object_type_im_ticket 1
	object_type_im_ticket_ticket_rel 1
	object_type_im_timesheet_invoice 1
	object_type_im_timesheet_price 1
	object_type_im_timesheet_task 1
	object_type_im_user_absence 1
	object_type_im_view 1
	object_type_object 1
	object_type_party 1
	object_type_person 1
	object_type_user 1
}


# ---------------------------------------------------------
# 
# ---------------------------------------------------------

list::create \
    -name object_types \
    -multirow object_types \
    -key object_type \
    -row_pretty_plural "Object Types" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -elements {
        object_type {
            display_col object_type
            label "Object Type"
            link_url_eval $object_type_url
        }        
        pretty_name {
            display_col pretty_name
            label "Pretty Name"
        }
	crud_status {
            label "CRUD<br>Status"
	}
	wiki {
            label "Wiki"
            link_url_eval $object_wiki_url
	}
    }


db_multirow -extend { object_type_url crud_status object_wiki_url wiki} object_types select_object_types {
	select	object_type,
    		pretty_name
	from	acs_object_types
	where	object_type not in (
			'acs_activity',
			'acs_event',
			'acs_mail_body',
			'acs_mail_gc_object',
			'acs_mail_link',
			'acs_mail_multipart',
			'acs_mail_queue_message',
			'acs_message',
			'acs_message_revision',
			'acs_named_object',
			'acs_object',
			'acs_reference_repository',
			'acs_sc_contract',
			'acs_sc_implementation',
			'acs_sc_msg_type',
			'acs_sc_operation',
			'admin_rel',
			'ams_object_revision',
			'apm_application',
			'apm_package',
			'apm_package_version',
			'apm_parameter',
			'apm_parameter_value',
			'apm_service',
			'application_group',
			'authority',
			'composition_rel',
			'content_extlink',
			'content_folder',
			'content_item',
			'content_keyword',
			'content_module',
			'content_revision',
			'content_symlink',
			'content_template',
			'cr_item_child_rel',
			'cr_item_rel',
			'dynamic_group_type',
			'etp_page_revision',
			'image',
			'im_biz_object',
			'journal_article',
			'journal_entry',
			'journal_issue',
			'news_item',
			'postal_address',
			'rel_segment',
			'rel_constraint',
			'site_node',
			'user_blob_response_rel',
			'user_portrait_rel',
			'workflow_lite'
		)
		-- exclude object types created for workflows
		and object_type not like '%wf'
	order by
		object_type
} {
    set object_type_url "/intranet-rest/$object_type/"
    set crud_status "R"
    if {[info exists crud_hash($object_type)]} { set crud_status $crud_hash($object_type) }

    set wiki_key "object_type_$object_type"
    set wiki "Wiki"
    set object_wiki_url "http://www.project-open.org/documentation/object_type_$object_type"
    if {![info exists wiki_hash($wiki_key)]} {
	set wiki ""
	set object_wiki_url ""
    }
}

