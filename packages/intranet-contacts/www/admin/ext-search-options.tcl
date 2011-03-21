#packages/contacts/www/admin/ext-search-options.tcl
ad_page_contract {
    UI to add edit or delete options for extended search.
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Network www.viaro.net
    @creation-date 2005-09-08
} {
    extend_id:optional
    {edit_p "f"}
    {delete_p "f"}
    {orderby "var_name,asc"}
    {search_id:multiple ""}
    {aggregated_p "f"}
}

set page_title [_ intranet-contacts.Extended_search_opt]
set context [list [_ intranet-contacts.Extended_search_opt]]

if { $delete_p } {
    contact::extend::delete -extend_id $extend_id
    ad_returnredirect -message "[_ intranet-contacts.ext_del_message]" "ext-search-options"
}

ad_form -name "add_option" -form {
    extend_id:key(contact_extend_search_seq)
}
if { $edit_p } {
    ad_form -extend -name "add_option" -form {
	{var_name:text(text)
	    {label "[_ intranet-contacts.Var_name]:"}
	    {help_text "[_ intranet-contacts.var_name_help]"}
	    {mode display }
	}
    }
} else {
    ad_form -extend -name "add_option" -form {
	{var_name:text(text)
	    {label "[_ intranet-contacts.Var_name]:"}
	    {help_text "[_ intranet-contacts.var_name_help]"}
	}
    }
}

ad_form  -extend -name "add_option" -form {
    {pretty_name:text(text)
	{label "[_ intranet-contacts.Pretty_name]:"}
	{help_text "[_ intranet-contacts.pretty_name_help]"}
    }
    {subquery:text(textarea),nospell
	{label "[_ intranet-contacts.Subquery]:"}
	{html {cols 40 rows 4}}
	{help_text "[_ intranet-contacts.subquery_help]"}
    }
    {aggregated_p:text(radio)
	{label "Aggregated:"}
	{options { {[_ intranet-contacts.True] t} {[_ intranet-contacts.False] f}}}
	{value $aggregated_p}
	{help_text "[_ intranet-contacts.aggregated_help]"}
    }
    {description:text(textarea),optional,nospell
	{label "[_ intranet-contacts.Description]"}
	{html {cols 40 rows 2}}
	{help_text "[_ intranet-contacts.description_help]"}
    }
}

if { !$edit_p } {
    ad_form  -extend -name "add_option" -validate {
	{var_name
	    {![contact::extend::var_name_check -var_name $var_name]}
	    "[_ intranet-contacts.this_var_name]"
	}
    }
}

ad_form  -extend -name "add_option" -new_data {
    contact::extend::new \
	-extend_id $extend_id \
	-var_name $var_name \
	-pretty_name $pretty_name \
	-subquery $subquery \
	-description $description \
	-aggregated_p $aggregated_p

} -select_query {
    select * from contact_extend_options where extend_id = :extend_id
} -edit_data {
    contact::extend::update \
	-extend_id $extend_id \
	-var_name $var_name \
	-pretty_name $pretty_name \
	-subquery $subquery \
	-description $description \
	-aggregated_p $aggregated_p
} -after_submit {
    ad_returnredirect "ext-search-options"
}

set edit_url "ext-search-options?extend_id=@ext_options.extend_id@&edit_p=t"
set delete_url "ext-search-options?extend_id=@ext_options.extend_id@&delete_p=t"

set row_list [list]
set bulk_actions [list]
set extra_query ""
if { ![exists_and_not_null search_id] } {
    lappend row_list \
	action_buttons [list]
} else {
    set extra_query "where extend_id not in (select extend_id from contact_search_extend_map where search_id in ([template::util::tcl_to_sql_list $search_id])) and aggregated_p ='f'" 
    lappend bulk_actions "[_ intranet-contacts.Set_default]" set-default "[_ intranet-contacts.Stored_extended_default]"
    lappend row_list \
	checkbox [list]
}

lappend row_list \
    var_name [list] \
    pretty_name [list] \
    subquery [list] \
    aggregated_p [list] \
    description [list]

template::list::create \
    -name ext_options \
    -key extend_id \
    -actions "" \
    -html {width 100%} \
    -multirow ext_options \
    -bulk_actions $bulk_actions \
    -bulk_action_method post \
    -bulk_action_export_vars { search_id } \
    -selected_format "normal" \
    -elements {
	action_buttons {
	    display_template {
		<a href="$edit_url"><img src="/resources/Edit16.gif" border="0"></a>
		<a href="$delete_url"><img src="/resources/Delete16.gif" border="0"></a>
	    }
	    html { width 5% }
	}
	var_name {
	    label "[_ intranet-contacts.Var_name]"
	    html { width 10% }
	}
	pretty_name {
	    label "[_ intranet-contacts.Pretty_name]"
	    html { width 10% }
	}
	subquery {
	    label "[_ intranet-contacts.Subquery]"
	    html { width 35% }
	}
	aggregated_p {
	    label "[_ intranet-contacts.Aggregated]"
	}
	description {
	    label "[_ intranet-contacts.Description]"
	    html { width 25% }
	}
    } -filters {
	search_id {}
    } -orderby {
	var_name {
	    label "[_ intranet-contacts.Var_name]"
	    orderby_asc "var_name asc"
	    orderby_desc "var_name desc"
	}
	pretty_name {
	    label "[_ intranet-contacts.Pretty_name]"
	    orderby_asc "pretty_name asc"
	    orderby_desc "pretty_name desc"
	}
    } -formats {
	normal {
	    label "[_ intranet-contacts.Table]"
	    layout table
	    row {
		$row_list 
	    }
	}
    }

db_multirow ext_options ext_options " "


########################### Remove Default List ####################################

set def_extra_query ""
if { [exists_and_not_null search_id] } {
    set def_extra_query "where extend_id in (select extend_id from contact_search_extend_map where search_id in ([template::util::tcl_to_sql_list $search_id]))"
}
set def_bulk_actions [list "[_ intranet-contacts.Remove_default]" remove-default "[_ intranet-contacts.Remove_default_options]"]

template::list::create \
    -name def_ext_options \
    -key extend_id \
    -actions "" \
    -html {width 100%} \
    -multirow def_ext_options \
    -bulk_actions $def_bulk_actions \
    -bulk_action_method post \
    -bulk_action_export_vars { search_id } \
    -selected_format "normal" \
    -elements {
	var_name {
	    label "[_ intranet-contacts.Var_name]"
	    html { width 10% }
	}
	pretty_name {
	    label "[_ intranet-contacts.Pretty_name]"
	    html { width 10% }
	}
	subquery {
	    label "[_ intranet-contacts.Subquery]"
	    html { width 35% }
	}
	aggregated_p {	
	    label "[_ intranet-contacts.Aggregated]"
	}
	description {
	    label "[_ intranet-contacts.Description]"
	    html { width 25% }
	}
    } -filters {
	search_id {}
    }

db_multirow def_ext_options def_ext_options " "

