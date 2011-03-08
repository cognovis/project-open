# Get the name for the current user

set user_id [User::getID]

if { ! $user_id } { template::forward "signin" }

set name [db_string get_name ""]

ns_set put [ns_conn outputheaders] Pragma "No-cache"
