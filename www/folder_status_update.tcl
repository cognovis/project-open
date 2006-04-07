# /packages/intranet-filestorage/www/folder_status_update.tcl

ad_page_contract {
    Index page of filestorage
    @author frank.bergmann@project-open.com
    @author santitrenchs@santitrenchs.com
} {
    object_id:integer
    rel_path
    { status "c" }
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
ns_log Notice "folder_status_update: return_url=$return_url"

# ToDo: No permissions yet.
# I'm not sure whether it's necessary, because the effect
# of this operation is neglectable (open/close a "+" folder)..


# change the folder status from open to close and vice versa
if { $status == "o" } {
    set status "c"
} else {
    set status "o"
}

# Check whether the DB-entry already exists
set exists_status_p [db_string folder_status_exists "
select
	count(*) 
from 
	im_fs_folders f,
	im_fs_folder_status s
where 
	f.object_id = :object_id 
	and f.path = :rel_path 
	and s.user_id = :user_id
	and f.folder_id = s.folder_id
"]

if {!$exists_status_p} {

    # The status doesn't exist, but maybe the folder
    # has been inserted already...

    set folder_id [db_string exists_folder "
	select	f.folder_id
	from	im_fs_folders f
	where	f.object_id = :object_id 
		and f.path = :rel_path 
    " -default 0]

    if {!$folder_id} {

	set folder_id [db_nextval im_fs_folder_status_seq]
	db_dml insert_folder "
	insert into im_fs_folders (
		folder_id,
	        object_id,
	        path
	) values (
		:folder_id,
	        :object_id,
	        :rel_path
	)"
    }

    # Create a folder status DB-entry
    db_dml insert_folder_status "
	insert into im_fs_folder_status (
		folder_id,
	        user_id,
	        open_p
	) values (
	        :folder_id,
	        :user_id,
	        :status
	)
    "
}

db_dml update_folder_status "
	update	im_fs_folder_status
	set	open_p = :status
	where	user_id = :user_id
		and folder_id in (
		    select	folder_id
		    from	im_fs_folders
		    where	object_id = :object_id 
				and path = :rel_path
		)
"

ad_returnredirect $return_url
