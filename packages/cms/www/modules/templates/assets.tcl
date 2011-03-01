# Regexp out all the <img> tags. Determine whether the image files
# exist, and whether they reference CMS items.

request create
request set_param template_id -datatype integer 

### Load the template ADP file

set template_revision [item::get_best_revision $template_id] 
if { [template::util::is_nil template_revision] } {
  set template_exists f
  return
} 

set template_exists t

set text [content::get_content_value $template_revision]
if { [template::util::is_nil text] } {
  set body_exists f
  return
} 

set body_exists t

# Get page root for checking whether images exist
set page_root [publish::get_page_root]

### Parse the file for <img> tags, stick the result into a
### multirow datasource
set columns [list src width height alt exists_some missing_some \
               missing_files item_id title status auto_width auto_height]

eval multirow create assets $columns

while { \
  [regexp -nocase -- {< *img +([^>]+) *>(.*)} $text match img_body rest] \
} {

  # Parse the tag
  regexp -nocase -- {src *= *\"*([a-zA-Z0-9_/\.\-]+)\"*} $img_body match src
  regexp -nocase -- {width *= *\"*([0-9]+)\"*} $img_body match width
  regexp -nocase -- {height *= *\"*([0-9]+)\"*} $img_body match height
 
  # Try to get the alt with and without quotes
  if { ![regexp -nocase -- {alt *= *\"([^\"]+)\"} $img_body match alt] } {
    regexp -nocase -- {alt *= *([^ ]+)} $img_body match alt  
  }

  set auto_width f
  set auto_height f

  if { ![template::util::is_nil src] } {

    # Detetmine all the publish roots where the src exists
    set exists_some 0
    set missing_some 0
    publish::foreach_publish_path $src {
      if { [file exists $filename] } {
        set exists_some 1
      } else {
        set missing_some 1
        append missing_files \
          "<font size=-2>Missing from: $current_page_root</font><br> "
      }
    }

    set item_id [item::get_id $src]
    if { ![template::util::is_nil item_id] } {
      set title [item::get_title $item_id]
      set status [string totitle [item::get_publish_status $item_id]]
  
      # Get width/height if not specified in the tag
      if { [template::util::is_nil width] || \
           [template::util::is_nil height] } {
        set revision_id [item::get_best_revision $item_id]
        db_1row get_image_info "" -column_array image_info

        if { [template::util::is_nil width] } {
          set width $image_info(width)
          set auto_width t
	} 
        
        if { [template::util::is_nil height] } {
          set height $image_info(height)
          set auto_height t
	} 
      }
    }
  }

  # Append the columns to the multirow datasource
  set code [list template::multirow append assets]

  foreach column $columns {
    if { [template::util::is_nil $column] } {
      lappend code "-"
    } else {
      lappend code [set $column]
    }

    # Clear the variable for next iteration
    set $column ""
  }

  eval $code

  set text $rest
}

