ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id$

} {
    {object_type:notnull}
    orderby:optional
    {show_interfaces_p "0"}
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

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_encoded [ns_urlencode $return_url]

acs_object_type::get -object_type $object_type -array "object_info"

set object_type_pretty_name $object_info(pretty_name)

set title "Dynfield Attributes of $object_type_pretty_name"
set context [list [list "/intranet-dynfield/" "DynField"] [list "object-types" "Object Types"] $title]


db_1row object_type_info "
select
        pretty_name as object_type_pretty_name,
        table_name,
        id_column
from
        acs_object_types
where
        object_type = :object_type
"
set main_table_name $table_name
set main_id_column $id_column
# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set dbi_interfaces ""
set dbi_inserts ""
set dbi_procs ""
# ------------------------------------------
# check if this object type have interface
# information to be generated
# ------------------------------------------
set generate_interfaces 1
if {[catch {db_1row "get interfaces info" "select interface_type_key, join_column 
	from qt_im_dynfield_interfaces
	where object_type = :object_type"} errmsg]} {
	
	set generate_interfaces 0
	ns_log notice "******************* error $errmsg *************************"
} else {
	if {!$show_interfaces_p} {
		set show_hidde_link "<a href=\"?[export_vars -base {} -url -override {{show_interfaces_p 1}} {object_type orderby show_interfaces_p}]\"> [_ intranet-dynfield.Show_interfaces]</a>"
	} else {
		set show_hidde_link "<a href=\"?[export_vars -base {} -url -override {{show_interfaces_p 0}} {object_type orderby show_interfaces_p}]\"> [_ intranet-dynfield.Hide_interfaces]</a>"
	}
}


db_multirow attributes attributes_query {} {
	

	if {[empty_string_p $table_name]} {
		set table_name $main_table_name
		set id_column $main_id_column
	} else {
		db_1row "get id_column" "select id_column 
			from acs_object_type_tables 
			where object_type = :object_type 
			and table_name = :table_name"
	}
	
	if {$generate_interfaces} {
		set proc_name "$object_type\_$attribute_name"
	
		append dbi_inserts "insert into dbi_interfaces (interface_key,pretty_name,status,interface_type_key) 
			values
			('$proc_name','$pretty_name ($object_type)','enabled',''); <br/>"
		set get_proc_name "dbi::$proc_name\::get_value"	
		append dbi_interfaces  "$get_proc_name <br/>"
		
		
		# ------------------------------------------
		# get pretty value for request attribute
		# ------------------------------------------
		
		
		switch $widget {
			"category_tree" {
				set get_column_text "category.name(t.$attribute_name) as $attribute_name"
				set set_column_text "$attribute_name = :value"
			}
			"generic_sql" {
				# -------------------------------------------
				# return default value
				# -------------------------------------------

				set generic_sql_return "t.$attribute_name as $attribute_name"
				set generic_sql_set "$attribute_name = :value"
				# -------------------------------------------
				# try to return pretty name of key
				# -------------------------------------------

				set custom_pos [lsearch $parameters "custom"]
				if {$custom_pos > -1} {
					set custom_value [lindex $parameters [expr $custom_pos + 1]]
					set sql_query [lindex $custom_value 1]
					#ns_log notice "sql_query $sql_query"

					set result [regexp -nocase {select ([^ , \" \"]+), ([^ \" \"]+) from ([^ \" \"]+)} $sql_query match key key_name table_key]
					if {$result} {
						# -------------------------------------------
						# create query to return pretty key name
						# -------------------------------------------
						set generic_sql_return " (SELECT $key_name 
									  FROM $table_key 
									  WHERE $key = t.$attribute_name) as $attribute_name "
						set generic_sql_set "$attribute_name = (SELECT $key FROM $table_name WHERE $key_name = :value)"			
					}
				}

				set get_column_text $generic_sql_return
				set set_column_text $generic_sql_set
			}
			default {
				set get_column_text "t.$attribute_name as $attribute_name"
				set set_column_text "$attribute_name = :value"
			}
		}
		
		
		set get_proc_bloc "
#############################################################################
		
ad_proc -public $get_proc_name {

  application_id

} {

  return $attribute_name

} {

  set $attribute_name \"\"


  db_transaction {
    db_0or1row get_value {
      select
	$get_column_text
      from
	ttracker_tickets tt,
	$table_name t
      where
	tt.$join_column = t.$id_column\(+)
	and tt.ticket_id = :application_id
    }
  } on_error {
    qst::log -var_list {application_id} \"Database returned error: \$errmsg\"
  }
  return \$$attribute_name

} ;# end $get_proc_name
"	
		append dbi_procs "$get_proc_bloc \n"
	
		set set_proc_name "dbi::$proc_name\::set_value"	
	
		append dbi_interfaces "$set_proc_name <br/>"
	
		set set_proc_bloc "
#############################################################################
ad_proc -public $set_proc_name {
					
  application_id
  value

} {

  Set $attribute_name name

} {

  set user_id \[ad_conn user_id]

  db_transaction {
    db_dml setfirstname {
      update $table_name
	set $set_column_text
      where $id_column = (
	  select $join_column
	    from ttracker_tickets
	   where ticket_id = :application_id
			)
    }
    set ok_p 1
  } on_error {
    set ok_p 0
    qst::log -var_list {application_id value} \"Update failed \$errmsg\"
  }

  return \$ok_p

} ;# end $set_proc_name
"
		append dbi_procs "$set_proc_bloc \n"
	}
}



# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set extension_tables_query "
    select 
	ott.*
    from 
	acs_object_type_tables ott
    where 
	ott.object_type = :object_type
"

db_multirow extension_tables extension_tables_query $extension_tables_query


# ******************************************************
# Create the list of all objects of the current type
# ******************************************************

db_multirow objects objects_query {} 
ad_return_template
