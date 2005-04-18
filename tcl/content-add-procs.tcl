# content-add-procs.tcl


# @namespace content_add

# Procedures regarding content methods

namespace eval content_add {}



# @public content_method_html

# Generates HTML stub for revision content method choices for a content item

# @author Michael Pih

# @param db A database handle
# @param content_type The content type of the item
# @param item_id The item id

ad_proc -public content_add::content_method_html { content_type item_id } {


  @public content_method_html

  Generates HTML stub for revision content method choices for a content item

  @author Michael Pih

  @param db A database handle
  @param content_type The content type of the item
  @param item_id The item id

} {
    
    set content_method_html ""

    set target "revision-add-2?item_id=$item_id"

    set has_text_mime_type [db_string count_text_mime_types ""]
    set mime_type_count [db_string count_mime_types ""]

    if { $mime_type_count > 0 } {

	append content_method_html "Add revised content via \["

	if { $has_text_mime_type > 0 } {
	    append content_method_html "
	      <a href=\"$target&content_method=text_entry\">Text Entry</a> | "
	}

	append content_method_html "
	  <a href=\"$target&content_method=file_upload\">File Upload</a> | "

	if { $has_text_mime_type > 0 } {
	    append content_method_html "
	      <a href=\"revision-upload?item_id=$item_id&content_type=$content_type\">XML Import</a> | "
	}

	append content_method_html "
	  <a href=\"$target&content_method=no_content\">No Content</a> "

	append content_method_html " \]"
    } else {
	append content_method_html "
          \[<a href=\"$target&content_method=no_content\">Add</a>\]"
    }
    return $content_method_html
}

