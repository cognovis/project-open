# Move selected keywords into the target category

request create
# Move marked keywords into this category
request set_param target_id -datatype integer
# Mount point for the tree
request set_param mount_point -datatype keyword -optional \
  -value "categories"
# Parent id for the tree
request set_param parent_id -datatype integer -optional

if { [template::util::is_nil target_id] } {
  set update_value "null"
} else {
  set update_value "$target_id"
}

set clip [clipboard::parse_cookie]

db_transaction {

    clipboard::map_code $clip $mount_point {
        if { [catch { 
            db_dml move_keyword_item "
       update cr_items set parent_id = $update_value
         where item_id = $item_id
         and exists (
           select 1 from cr_keywords where keyword_id = item_id
         )" 

            db_dml move_keyword_keyword "
       update cr_keywords set parent_id = $update_value
         where keyword_id = $item_id" 
        } errmsg] } {
        }    
    }
}

clipboard::free $clip

# Specify a null id so that the entire branch will be refreshed
template::forward "refresh-tree?goto_id=$target_id&mount_point=$mount_point"


 
  
  
  

