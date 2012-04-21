ad_page_contract {
    The display for the task base data 
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-07

} 
set user_id [ad_conn user_id] 

# get the current users permissions for this project
im_project_permissions $user_id $task_id view read write admin

# ---------------------------------------------------------------------
# Get Everything about the task
# ---------------------------------------------------------------------
db_1row task_info "select project_name as task_name, project_nr as task_nr, parent_id as project_id, im_name_from_id(parent_id) as project_name from im_projects where project_id = :task_id"

set project_url [export_vars -base "/intranet/projects/view" -url {project_id}]
im_dynfield::object_array -array_name task -object_id $task_id
set object_type_id $task(object_type_id)

# ---------------------------------------------------------------------
# Add DynField Columns to the display
set old_section ""

db_multirow -extend {attrib_var value} task_info dynfield_attribs_sql "
      select
      		aa.pretty_name,
      		aa.attribute_name,
                tam.section_heading,
                w.widget, w.widget_name
      from
      		im_dynfield_widgets w,
      		acs_attributes aa,
                im_dynfield_type_attribute_map tam,
      		im_dynfield_attributes da, 
                im_dynfield_layout la
      where
                da.widget_name = w.widget_name and
                da.acs_attribute_id = aa.attribute_id and
                da.attribute_id = tam.attribute_id and
                tam.object_type_id = :object_type_id and
                la.attribute_id = da.attribute_id and
                acs_permission__permission_p(da.attribute_id,:user_id,'read') = 't' and
                tam.display_mode in ('edit','display')
      order by la.pos_y
" {

    set heading ""    
    if {$old_section != $section_heading} {
        set heading $section_heading
        set old_section $section_heading
    }   
   
    # Set the field name
    set pretty_name_key "intranet-core.[lang::util::suggest_key $pretty_name]"
    set pretty_name [lang::message::lookup "" $pretty_name_key $pretty_name]

    if {$widget eq "richtext"} {
	set value [template::util::richtext::get_property contents $value]
	ds_comment "richtext:: $value"
    }

    # Set the value
    if {[info exists task($attribute_name)]} { 
	set value $task($attribute_name)
    } else {
	set value ""
    }

    if {$attribute_name eq "material_id"} {
	set value [db_string material_name "select material_name from im_materials where material_id = $task(material_id_orig)"]
    }

}

set current_user_id [ad_conn user_id]
im_project_permissions $current_user_id $task_id view read write admin

if {$write eq 0} {
    im_project_permissions $current_user_id $parent_id view_project read_project write admin_project
}

if {[exists_and_not_null no_write_p]} {
    set write 0
}
