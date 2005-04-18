# /cms/www/modules/types/set-default-template.tcl
# Sets a template registered to a content type/context to be the default


request create
request set_param template_id  -datatype integer
request set_param context      -datatype keyword
request set_param content_type -datatype keyword
request set_param return_url   -datatype text     -optional

db_transaction {


# set the default template, automatically unsetting any preexisting default
db_exec_plsql set_default_template "
  begin
  content_type.set_default_template(
      template_id  => :template_id,
      content_type => :content_type,
      use_context  => :context );
  end;"
}

# set the default return_url if none exists
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type&mount_point=types"
}

forward $return_url
