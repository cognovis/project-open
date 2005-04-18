# /cms/www/modules/types/content-method-unset-default.tcl
#
# Unset the default content insertion method for a given content type


request create
request set_param content_type   -datatype keyword
request set_param return_url     -datatype text -value ""

# default return_url
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type"
}


db_transaction {
    db_exec_plsql unset_content_method_default "
  begin
    content_method.unset_default_method (
      content_type   => :content_type
    );
  end;
"
}

content_method::flush_content_methods_cache $content_type


template::forward $return_url
