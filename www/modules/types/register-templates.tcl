# query for attributes of this subclass of content_revision 
#   and display them

request create
request set_param content_type -datatype keyword


# get the content type pretty name
set object_type_pretty [db_string get_pretty_type "" -default ""]

set invalid_content_type_p f
if { [string equal $object_type_pretty ""] } {
    set invalid_content_type_p t
}



# in addition to the template_count and content_type
#   this form will contain 2 elements for each template
#   found on the clipboard
form create register_templates

element create register_templates content_type \
	-datatype keyword \
	-widget hidden \
	-param



# grab marked templates from the clipboard
#set root_id [cm::modules::templates::getRootFolderID]
set clip [clipboard::parse_cookie]
set marked_templates [clipboard::get_items $clip templates]
set marked_templates_csv [join $marked_templates ","]

if { [llength $marked_templates] == 0 } {
    set marked_templates_sql "1 = 0"
} else {
    set marked_templates_sql "t.template_id in ($marked_templates_csv)"
}

# make sure we only get content templates (not folders, symlinks,
#   etc.) that aren't already registered to this content type
set only_marked_templates [db_list_of_lists get_content_templates ""]

set template_count [llength $only_marked_templates]

element create register_templates template_count \
	-datatype integer \
	-widget hidden \
	-value $template_count


if { $template_count > 0 } {

    # for the context pick list(s)
    set cr_use_contexts [db_list_of_lists get_use_contexts ""]
}



# generate form elements for each marked template
#   ==> template_id, context
set counter 1
foreach temp $only_marked_templates {
    
    # append _# to each of the form element name tags, to 
    #   distinguish between the different templates
    set temp_name "template_name_$counter"
    set id_name "template_id_$counter"
    set context_name "context_$counter"

    set t_id [lindex $temp 0]
    set t_name [lindex $temp 1]

    element create register_templates $temp_name \
	    -datatype text \
	    -widget inform \
	    -label "Template" \
	    -value "/$t_name"

    element create register_templates $id_name \
	    -datatype integer \
	    -widget hidden \
	    -value $t_id

    element create register_templates $context_name \
	    -datatype keyword \
	    -widget select \
	    -label "Context" \
	    -options $cr_use_contexts \
	    -values public

    incr counter
}



set page_title "Register Templates for Content Type - $object_type_pretty"









if { [form is_valid register_templates] } {

    form get_values register_templates \
	    template_count content_type

    # get the variable number of elements
    for { set i 1 } { $i <= $template_count } { incr i } {
	set id_name "template_id_$i"
	set context_name "context_$i"

	form get_values register_templates \
		$id_name $context_name

	eval "set template_id $$id_name"
	eval "set context $$context_name"

        db_transaction {
            db_exec_plsql register_templates "begin
                   content_type.register_template(
                       content_type => :content_type,
	               template_id  => :template_id,
	               use_context  => :context );
                 end;"
        }

    }

    forward "index?id=$content_type"

}
