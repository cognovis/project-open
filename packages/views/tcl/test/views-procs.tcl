ad_library {
	Test cases for views
}

aa_register_case \
	-cats {api} \
	-procs {views::record_view views::get views::viewed_p} \
	view_api_test_without_type \
	{
		A simple test that adds, retrieves and check a record 
	} {
		aa_run_with_teardown \
			-rollback \
			-test_code  {
				set viewer_id_list [db_list get_viewer_id_list "select user_id from users where user_id != 0"]
				set viewer_id [lindex [util::randomize_list $viewer_id_list] 0]
				#Object_id not in views_by_type
				set object_id_list [db_list get_object_id_list "select ao.object_id from acs_objects ao left outer join (select object_id from views_views where viewer_id != :viewer_id) vt on ao.object_id = vt.object_id"]
				set object_id [lindex [util::randomize_list $object_id_list] 0]
				
				aa_false "User view object_id" [expr [views::viewed_p -object_id $object_id -user_id 0] > 0]
				
				aa_log "User_id is $viewer_id, object is $object_id"
				
				views::record_view -object_id $object_id -viewer_id $viewer_id
				
				set count_record [db_string count_record "select count(*) from  views_views where object_id = :object_id and viewer_id = :viewer_id" -default 0]
				
				aa_true "Record add" [expr $count_record > 0]
				
				set count_views [db_string count_views "select views_count from views_views where object_id = :object_id and viewer_id = :viewer_id" -default 0]
				
				views::record_view -object_id $object_id -viewer_id $viewer_id
				#Update count views
				set count_record [db_string count_record "select count(*) from  views_views where object_id = :object_id and viewer_id = :viewer_id" -default 0]
				
				aa_true "Update record but don't insert new row" [expr $count_record == 1]
				
				set count_views2 [db_string count_views2 "select views_count from views_views where object_id = :object_id and viewer_id = :viewer_id" -default 0]
				
				aa_true "Count_view is updated" [expr $count_views2 > $count_views]
				
				set get [views::get -object_id $object_id]
				aa_log "Return of function views::get $get"
				
				aa_true "User view object_id" [expr [views::viewed_p -object_id $object_id -user_id $viewer_id] > 0]
				
				set all_views_count [db_string count_views_views "select sum(views_count) from views_views where object_id = :object_id"]
				set view_count_aggregates [db_string get_views_count "select views_count from view_aggregates where object_id = :object_id"]
				aa_equals "views_count on view_aggregates is equal to sum views_count on views_views" $view_count_aggregates $all_views_count
			}
	}

	
aa_register_case \
-cats {api} \
-procs {views::record_view views::get views::viewed_p} \
view_api_test_with_type \
{
	A simple test that adds, retrieves and check a record with type 
} {
	aa_run_with_teardown \
		-rollback \
		-test_code  {
			set viewer_id_list [db_list get_viewer_id_list "select user_id from users where user_id != 0"]
			set viewer_id [lindex [util::randomize_list $viewer_id_list] 0]
			#Object_id not in views_by_type
			set object_id_list [db_list get_object_id_list "select ao.object_id from acs_objects ao left outer join (select object_id from views_by_type where viewer_id != :viewer_id) vt on ao.object_id = vt.object_id"]
			set object_id [lindex [util::randomize_list $object_id_list] 0]
			
			set type test
			
			aa_false "User has viewed object_id" [expr [views::viewed_p -object_id $object_id -user_id $viewer_id -type $type] > 0]
			
			aa_log "User_id is $viewer_id, object is $object_id and type $type"
			
			views::record_view -object_id $object_id -viewer_id $viewer_id -type $type
			
			set count_record [db_string count_record "select count(*) from  views_by_type where object_id = :object_id and viewer_id = :viewer_id" -default 0]
			
			aa_true "Record add" [expr $count_record > 0]
			
			set count_views [db_string count_views "select views_count from views_by_type where object_id = :object_id and viewer_id = :viewer_id" -default 0]
			
			views::record_view -object_id $object_id -viewer_id $viewer_id -type $type
			#Update count views
			set count_record [db_string count_record "select count(*) from  views_by_type where object_id = :object_id and viewer_id = :viewer_id" -default 0]
			
			aa_true "Update record but don't insert new row" [expr $count_record == 1]
			
			set count_views2 [db_string count_views2 "select views_count from views_by_type where object_id = :object_id and viewer_id = :viewer_id" -default 0]
			
			aa_true "Count_view is updated" [expr $count_views2 > $count_views]
			
			set get [views::get -object_id $object_id]
			aa_log "Return of function views::get $get"
			
			aa_true "User has viewed object_id" [expr [views::viewed_p -object_id $object_id -user_id $viewer_id -type $type] > 0]
			set all_views_count [db_string count_views_views "select sum(views_count) from views_by_type where object_id = :object_id and view_type=:type"]
			set view_count_aggregates [db_string get_views_count "select views_count from view_aggregates_by_type where object_id = :object_id and view_type=:type"]
			aa_equals "views_count on view_aggregates is equal to sum views_count on views_views" $view_count_aggregates $all_views_count
		}
}
