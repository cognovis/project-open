# Get the name for the current user

set user_id [User::getID]

ns_log Notice $user_id

set name [db_string get_name ""]



