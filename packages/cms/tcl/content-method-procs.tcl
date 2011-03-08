# content-method-procs.tcl


# @namespace content_method

# Procedures regarding content methods

namespace eval content_method {}


ad_proc -public content_method::get_content_methods { content_type args } {

  Returns a list of content_methods that are associated with 
  a content type, first checking for a default method, then for registered
  content methods, and then for all content methods

  @author Michael Pih

  @param  content_type The content type
  @option get_labels   Instead of a list of content methods, return
    a list of label-value pairs of associated content methods.
  @return A list of content methods or a list of label-value pairs of 
    content methods if the "-get_labels" option is specified

  @see content_method::get_content_method_options
  @see content_method::text_entry_filter_sql

} {
    template::util::get_opts $args

    if { [info exists opts(get_labels)] } {
	set methods \
		[content_method::get_content_method_options $content_type]
	return $methods
    }

    set text_entry_filter [text_entry_filter_sql $content_type]

    # get default content method (if any)
    set default_method [db_string get_default_method ""]
    
    # if the default exists, return it
    if { ![template::util::is_nil default_method] } {
	set methods [list $default_method]
    } else {
	# otherwise look up all content method mappings

        set methods [db_list get_methods_1 ""]
    }

    # if there are no mappings, return all methods
    if { [template::util::is_nil methods] } {

        set methods [db_list get_methods_2 ""]
    }

    return $methods
}


ad_proc -private content_method::get_content_method_options { content_type } {

  Returns a list of label, content_method pairs that are associated with 
  a content type, first checking for a default method, then for registered
  content methods, and then for all content methods

  @author Michael Pih
  @param content_type The content type
  @return A list of label, value pairs of content methods

  @see content_method::get_content_methods
  @see content_method::text_entry_filter_sql

} {
    
    set text_entry_filter [text_entry_filter_sql $content_type]

    db_0or1row get_content_default_method ""

    if { ![template::util::is_nil content_method] } {
	set methods [list [list $label $content_method]]
    } else {
	# otherwise look up all content methods mappings
        set methods [db_list_of_lists get_methods_1 ""]
    }

    # if there are no mappings, return all methods
    if { [template::util::is_nil methods] } {

        set methods [db_list_of_lists get_methods_2 ""]
    }

    return $methods
}


ad_proc -private content_method::text_entry_filter_sql { content_type } {

  Generate a SQL stub that filters out the text_entry content method

  @author Michael Pih
  @param  content_type mime type 

  @return SQL stub that possibly filters out the text_entry content method

} {
    
    set text_entry_filter_sql ""

    set has_text_mime_type [db_string count_text_mime_types ""]

    if { $has_text_mime_type == 0 } {
	set text_entry_filter_sql \
		"and m.content_method <> 'text_entry'"
    }

    return $text_entry_filter_sql
}



ad_proc -public content_method::flush_content_methods_cache { {content_type ""} } {

  Flushes the cache for content_method_types for a given content type.  If no
  content type is specified, the entire content_method_types cache is
  flushed

  @author Michael Pih
  @param content_type The content type, default null

} {

    if { [template::util::is_nil content_type] } {
        # FIXME: figure out what to do with these after template::query calls
        # are gone.

	# flush the entire content_method_types cache
	template::query::flush_cache "content_method_types*"
    } else {

	# flush the content_method_types cache for a content type
	# 1) flush the default method cache 
	template::query::flush_cache \
		"content_method_types_default $content_type"
	template::query::flush_cache \
		"content_method_types_n_labels_default $content_type"

	# 2) flush the mapped methods cache
	template::query::flush_cache "content_method_types ${content_type}*"

	# 3) flush the all methods cache
	template::query::flush_cache "content_method_types"
	template::query::flush_cache "content_method_types_n_labels"
    }
}
