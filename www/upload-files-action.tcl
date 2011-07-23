# /packages/intranet-customer-portal/www/complete_inquiry.tcl
#
# Copyright (C) 2011 ]project-open[
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    @param 
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    {security_token ""}
    {inquiry_id ""}
    {btn_value ""}
    {comment ""}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set page_title "Customer Portal - Create Project"
set show_navbar_p 0
set show_left_navbar_p 0
set anonymous_p 1
set multiple_documents_p 0
set day_today [clock format [clock seconds] -format {%Y-%m-%d}]
set path ""

if { "" != $security_token } {
    # set inquiry_id [db_string inq_id "select inquiry_id from im_inquiries_customer_portal where security_token = :security_token" -default 0]
    if { $inquiry_id == 0} {
	ad_return_complaint 1 "You have to register first in order to upload files. Please refer to our <a href='/intranet-customer-portal/'>Customer Portal</a>"
    }
    set master_file "../../intranet-customer-portal/www/master"
} else {
    set anonymous_p 0
    set master_file "../../intranet-core/www/master"
}

set user_id [ad_maybe_redirect_for_registration]

# Load Sencha libs 
if {[im_openacs54_p]} {
    template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order "1"
    template::head::add_javascript -src "/intranet-sencha/js/ext-all-debug-w-comments.js" -order "1"
}

# ---------------------------------------------------------------
# Create Project when registered user 
# ---------------------------------------------------------------

if { "submit"==$btn_value } { 
	# set project nr_& project_path (by default identical)
	# Make sure that constraints are enforced: 
	#  - "im_projects_nr_un" UNIQUE, btree (project_nr, company_id, parent_id)
	#  - "im_projects_path_un" UNIQUE, btree (project_nr, company_id, parent_id)

	set company_id [db_string get_company_id "select company_id from im_inquiries_customer_portal where inquiry_id=:inquiry_id" -default 0]

	# project_type -> always 'Translation Project'
	set project_type_id 2500
	set project_status_id 71

	# Set Source Path 
	set temp_path [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "TempPath" -default "/tmp"]

	# Set Target Path  
	set destination_path [parameter::get -package_id [apm_package_id_from_key intranet-filestorage] -parameter "ProjectBasePathUnix" -default ""]  	
	append destination_path "/" [db_string get_company_path "select company_path from im_companies where company_id=$company_id" -default 0]

	# Create Parent Project if more than one source language 
	set project_nr [im_next_project_nr -customer_id $company_id]
        set project_name "$project_nr (RFQ)"
	set project_path $project_nr

	if { 1 < [db_string i "select count(*) from im_inquiries_files where inquiry_id = :inquiry_id" -default 0] } {
		# Create parent project 
		set parent_id [project::new \
			-project_name       $project_name \
			-project_nr         $project_nr \
			-project_path       $project_path \
			-company_id         $company_id \
			-project_type_id    $project_type_id \
			-project_status_id  $project_status_id \
			      ]
		# 
		# set title [db_string get_view_id "select file_name from im_inquiries_files where inquiry_id =:inquiry_id limit 1" -default ""]
		db_dml update "update im_inquiries_customer_portal set (project_id, title, status_id) = ($parent_id, '$project_name', 72) where inquiry_id = :inquiry_id"
		db_dml update "update im_projects set start_date='$day_today', end_date = '$day_today' where project_id = $parent_id"
		set multiple_documents_p 1
		im_biz_object_add_role $user_id $parent_id "1300"
	}

        set sql "
                select * from im_inquiries_files where inquiry_id = :inquiry_id order by source_language; 
        "

	set ctr 0

	# Create a project for each source language in the RFQ
	db_foreach source_language $sql {
	    if { ![info exists lang_hash($source_language)] } {

			set project_nr [im_next_project_nr -customer_id $company_id]
			set project_name "$project_nr (RFQ)"
			set project_path $project_nr

			set lang_hash($source_language) 1
		        set project_id ""
		        catch {
			    if { [info exists parent_id] } {
				set project_id [project::new \
						    -project_name       $project_name \
						    -project_nr         $project_nr \
						    -project_path       $project_path \
						    -company_id         $company_id \
						    -parent_id          $parent_id \
						    -project_type_id    $project_type_id \
						    -project_status_id  $project_status_id \
					       ]
			    } else {
                                set project_id [project::new \
                                                    -project_name       $project_name \
                                                    -project_nr         $project_nr \
                                                    -project_path       $project_path \
                                                    -company_id         $company_id \
                                                    -project_type_id    $project_type_id \
                                                    -project_status_id  $project_status_id \
						    ]

				set parent_id $project_id
			    }
			    im_biz_object_add_role $user_id $parent_id "1300"

			    set source_language_id [im_id_from_category "$source_language" "Intranet Translation Language"]
			    db_dml update "update 
						im_projects 
			                   set 
						start_date='$day_today', end_date = '$day_today', source_language_id = $source_language_id 
					   where 
						project_id = $project_id
			    "
			    
			    } err_msg

		        if {0 == $project_id || "" == $project_id} {
		            ad_return_complaint 1 "<b>Error creating project</b>:<br>
        		        We have got an error creating a new project.<br>
	        	        There is probably something wrong with the projects's parameters below:<br>&nbsp;<br>
        	        	<pre>
		                project_name            $project_name
		                project_nr              $project_nr
        		        project_path            $project_path
                		company_id              $company_id
        	        	project_type_id         $project_type_id
	        	        project_status_id       $project_status_id
        	        	</pre><br>&nbsp;<br>
	                	For reference, here is the error message:<br>
		                <pre>$err_msg</pre>
        		    "
			    ad_script_abort
		        }  

			# set message "test - mail - body"
			# notification::new \
			#    	-type_id [notification::type::get_type_id -short_name "inquiry_notif"] \
			#	-object_id $project_id \
			#        -response_id "" \
			#        -notif_subject "test mail subject" \
			#        -notif_text $message
			
		        set type_id [notification::type::get_type_id -short_name "inquiry_notif"]
			set interval_id [notification::get_interval_id -name "instant"]
        		set delivery_method_id [notification::get_delivery_method_id -name "email"]

		        # notification::request::new \
		        #    -type_id $type_id \
		        #    -user_id $user_id \
		        #    -object_id $project_id \
		        #    -interval_id $interval_id \
		        #    -delivery_method_id $delivery_method_id

			# There's only one doc in the RFQ -> no parent project 
			if { !$multiple_documents_p } {
	                	db_dml update "update im_inquiries_customer_portal set (project_id,title, status_id) = ($project_id, '$project_name',72 ) where inquiry_id = :inquiry_id"
			}
			set destination_path_project $destination_path 

	                set target_languages_list [split $target_languages ',']

                        file mkdir "$destination_path_project/$project_nr/0_source_$source_language"

        	        foreach i $target_languages_list {
                	        set lang_abbrev [im_category_from_id $i]
			        set sql "insert into im_target_languages values ($project_id, $i)"
			        db_dml insert_im_target_language $sql
			        if {[im_table_exists im_freelancers]} {
			            im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_target_language] -skill_ids $i
        			}
        	        }

			# Create forum 
			if { "" != $comment } {
			    set topic_type_id 1108
			    set forum_object_id $parent_id
			    set today [db_string get_sysdate "select sysdate from dual"]
			    set topic_id [db_nextval "im_forum_topics_seq"]		

		            db_dml topic_insert "
                		insert into im_forum_topics (
		                        topic_id, object_id, topic_type_id,topic_status_id, owner_id, subject
                	     	) values (
	                        	:topic_id, :forum_object_id, :topic_type_id, 1200, $user_id, 'Comment made by client'
                	     	)
            		    "
			    db_dml topic_update "
			        update im_forum_topics set
			                posting_date=:today,
			                owner_id=$user_id,
			                scope='pm',
			                message=:comment,
			                priority=5,
			                asignee_id=0
			        where topic_id=:topic_id
        		    "
			}
	    } 

	    # ToDo 
	    # a) Add target language to existing project only in case this hasn't been done yet 
	    # b) add target language to freelance_required_skills only in case this hasn't been done yet
	    # 
	    # else {	
            #    set target_languages_list [split $target_languages ',']
      	    #	set lang_abbrev [im_category_from_id $i] 
            #    # file mkdir "$destination_path_project/$project_nr/0_source_$lang_abbrev"
            #    foreach i $target_languages_list {
            #            set sql "insert into im_target_languages values ($project_id, $i)"
            #            db_dml insert_im_target_language $sql
            #            if {[im_table_exists im_freelancers]} {
            #                im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_target_language] -skill_ids $i
            #            }
            #    }
	    # }

	    if { [catch {
		ns_log NOTICE "KHD: Copy file to Source Folder: $temp_path/$security_token/$file_name --> $destination_path_project/$project_nr/0_source_$source_language/$file_name" 
		ns_cp "$temp_path/$security_token/$file_name" "$destination_path_project/$project_nr/0_source_$source_language/$file_name" 
	    } err_msg] } {
		ns_log NOTICE "Error copying file: $err_msg" 
		ad_return_complaint 1 $err_msg
	    }

	    incr ctr
	    set path "" 
	} 

	# create WF case 
	set workflow_key [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "KeyRFQWorkflow" -default "project_approval3_wf"]
	set context_key ""
	set case_id [wf_case_new $workflow_key $context_key $parent_id]

	# skip WF task 
 	im_workflow_skip_first_transition -case_id $case_id

	ns_returnredirect "../intranet"
} else {
	# Inquiry has been canceled
	set column_sql "select file_name from im_inquiries_files where inquiry_id=:inquiry_id"
	db_foreach col $column_sql {
        	if { [catch {
	            file delete "$temp_path/$security_token/$file_name" 
        	} err_msg] } {
	            # ad_return_complaint 1 "Could not remove files from temp directory, please check if paramter 'TempPath' of package 'intranet-customer-portal' contains a valid path."
        	}
	}

	db_dml del "delete from im_inquiries_files where inquiry_id = :inquiry_id"
	ns_returnredirect "upload-files.tcl?reset_p=1&cancel_p=1"
}



