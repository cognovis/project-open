request create
request set_param content_type -datatype keyword -value content_revision
request set_param return_url -datatype text -value ""

# permissions check - user must have cm_examine on the types module
set types_module_id [cm::modules::get_module_id types]
content::check_access $types_module_id cm_examine -user_id [User::getID]

# default return_url
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type"
}


# fetch the content methods registered to this content type
db_multirow content_methods get_methods ""


# text_entry content method filter
# don't show text entry if a text mime type is not registered to the item
set has_text_mime_type [db_string check_status ""]

if { $has_text_mime_type == 0 } {
    set text_entry_filter_sql "and content_method != 'text_entry'"
} else {
    set text_entry_filter_sql ""
}


# fetch the content methods not register to this content type
set unregistered_content_methods [db_list_of_lists get_unregistered_methods ""]

set unregistered_method_count [llength $unregistered_content_methods]


# form to register unregistered content methods to this content type
form create register

element create register content_type \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create register return_url \
	-datatype text \
	-widget hidden \
	-value $return_url

element create register content_method \
	-datatype keyword \
	-widget select \
	-options $unregistered_content_methods
	
element create register submit \
	-datatype keyword \
	-widget submit \
	-label "Register"



if { [form is_valid register] } {

    form get_values register content_type content_method
    
    db_transaction {

        db_exec_plsql add_method "
      begin
      content_method.add_method (
          content_type   => :content_type,
          content_method => :content_method,
          is_default     => 'f'
      );
      end;
    "
    }

    content_method::flush_content_methods_cache $content_type

    template::forward $return_url
}
