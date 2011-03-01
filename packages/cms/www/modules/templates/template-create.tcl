# /templates/template-create.tcl 
# create a content_template

request create
request set_param parent_id -datatype integer -optional

# Cannot use -value due to negative values
if { [template::util::is_nil parent_id] } {
  set parent_id [cm::modules::templates::getRootFolderID]
}

set folder_name [db_string get_folder_name "" -default ""]

if { [string equal $folder_name ""] } {
    set folder_name "/"
}


set page_title "Add a Template to $folder_name"


# Create a new item and an initial revision for a content item (generic)
form create create_template -elements {
    template_id -datatype integer -widget hidden
    parent_id -datatype integer -widget hidden -param -optional
    name -datatype keyword -widget text -label "File Name"
}

set parent_id [element get_value create_template parent_id]

if { [form is_request create_template] } {

    # to avoid dupe submits
    set template_id [db_string get_template_id ""]
    element set_properties create_template template_id -value $template_id
}


if { [form is_valid create_template] } {

    form get_values create_template name parent_id template_id
    set user_id [User::getID]
    set ip_address [ns_conn peeraddr]
    
    if { [util::is_nil parent_id] } {
      set parent_id [cm::modules::templates::getRootFolderID]
    }
 
    db_transaction {

        set ret_val [db_exec_plsql new_template "begin 
        :1 := content_template.new(
            template_id   => :template_id,
            name          => :name,
            parent_id     => :parent_id,
            creation_user => :user_id,
            creation_ip   => :ip_address
        );
        end;"]
    }

    template::forward ../templates/template?template_id=$template_id
}

