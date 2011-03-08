request create -params {
  revision_id -datatype integer
}


# query for the path and ID of the template
db_1row get_info "" -column_array info

# write the template to the file system

set text [content::get_content_value $revision_id]

set path [content::get_template_path]/$info(path)

util::write_file $path.adp $text

# update the live revision

set template_id $info(item_id)

db_dml update_items "update cr_items set live_revision = :revision_id
                where item_id = :template_id"


set return_url [ns_set iget [ns_conn headers] Referer]
template::forward $return_url

