ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2009-09-04
    @cvs-id $Id: index.tcl,v 1.8 2011/03/09 12:42:10 po34demo Exp $

} {
    {orderby "name"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-cvs-integration.CVS_Integration "CVS Integration"]
set context_bar [im_context_bar [list /intranet-cvs-integration/ "CVS Integration"] $page_title]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set return_url [im_url_with_query]

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

set bulk_action_list [list \
	"[lang::message::lookup {} intranet-cvs-integration.Full_CVS_Import {Full CVS Import}]" "action-full-import" "" \
]

set cvs_repository_type_id [im_conf_item_type_cvs_repository]
set new_repository_url [export_vars -base "/intranet-confdb/new" {{form_mode edit} {conf_item_type_id $cvs_repository_type_id} {return_url}}]
set action_list [list \
	"[lang::message::lookup {} intranet-cvs-integration.Create_New_Repository "Create New Repository"]" $new_repository_url "" \
]


list::create \
    -name cvs_repositories \
    -multirow cvs_repositories \
    -key repository_id \
    -row_pretty_plural "[lang::message::lookup {} intranet-cvs-integration.CVS_Repositories {CVS Repositories}]" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions $action_list \
    -bulk_actions $bulk_action_list \
    -bulk_action_export_vars {
        repository_id
    } -elements {
        repository_name {
            label "[lang::message::lookup {} intranet-cvs-integration.Repository {Conf Item Name}]"
            link_url_eval $repository_url
        }
        cvs_protocol {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_Protocol {Protocol}]"
        }
        cvs_user {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_User {User}]"
        }
        cvs_password {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_Password {Password}]"
        }
        cvs_hostname {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_Hostname {Hostname}]"
        }
        cvs_port {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_Port {Port}]"
        }
        cvs_path {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_Path {Path}]"
        }
        cvs_repository {
            label "[lang::message::lookup {} intranet-cvs-integration.CVS_Repository {Repository}]"
        }
        num_commits {
            label "[lang::message::lookup {} intranet-cvs-integration.Num_Commits Commits]"
        }
    }


db_multirow -extend { repository_url } cvs_repositories select_cvs_repositories {
	select	conf_item_id as repository_id,
		conf_item_name as repository_name,
		cvs_protocol,
		cvs_repository,
		cvs_user,
		cvs_password,
		cvs_hostname,
		cvs_port,
		cvs_path,
		conf_item_nr as repository,
		stats.*
	from	im_conf_items ci
		LEFT OUTER JOIN (
			select	count(*) as num_commits,
				cvs_conf_item_id
			from	im_cvs_logs
			group by cvs_conf_item_id
		) stats ON ci.conf_item_id = stats.cvs_conf_item_id
	where	cvs_path is not NULL
	order by
		lower(conf_item_name)
} {
    set repository_url [export_vars -base "/intranet-confdb/new" {{conf_item_id $repository_id} {form_mode display}}]
}


ad_return_template
