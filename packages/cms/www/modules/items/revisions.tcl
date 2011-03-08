# Display a list of revisions for the item

# page variables
template::request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# pagination vars
template::request set_param page -datatype integer -value 1

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# add content html
set content_type [db_string get_content_type ""]


# get item info
db_1row get_iteminfo ""

# get all revisions
db_multirow revisions get_revisions [pagination::paginate_query "
  select 
    revision_id, 
    trim(title) as title, 
    trim(description) as description,
    content_revision.get_number(revision_id) as revision_number
  from 
    cr_revisions r
  where 
    r.item_id = :item_id
  order by
    revision_number desc" $page]


set sql [db_map get_revisions]

set total_pages [pagination::get_total_pages $sql]

set pagination_html [pagination::page_number_links $page $total_pages]
