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
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set page_title "Customer Portal - Create Project"
set show_navbar_p 0
set show_left_navbar_p 0
set anonymous_p 1

if { "" != $security_token } {
    # set inquiry_id [db_string inq_id "select inquiry_id from im_inquiries_customer_portal where security_token = :security_token" -default 0]
    if { $inquiry_id == 0} {
	ad_return_complaint 1 "You have to register first in order to upload files. Please refer to our <a href='/intranet-customer-portal/'>Customer Portal</a>"
    }
    set master_file "../../intranet-customer-portal/www/master"
} else {
    set user_id [ad_maybe_redirect_for_registration]
    set anonymous_p 0
    set master_file "../../intranet-core/www/master"
}

# Load Sencha libs 
template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order "1"
template::head::add_javascript -src "/intranet-sencha/js/ext-all-debug-w-comments.js" -order "1"

# ---------------------------------------------------------------
# Create Project when registered user 
# ---------------------------------------------------------------



# set project nr_& project_path (by default identical)
# Make sure that constraints are enforced: 
#  - "im_projects_nr_un" UNIQUE, btree (project_nr, company_id, parent_id)
#  - "im_projects_path_un" UNIQUE, btree (project_nr, company_id, parent_id)

set parent_id 0
set company_id [db_string get_view_id "select company_id from im_inquiries_customer_portal where inquiry_id=:inquiry_id" -default 0]


# project_type -> always 'Translation Project'
set project_type_id 2500
set project_status_id 71

# if { ![auth::get_user_id] } { 

	# Set Source Path 
	set template_path [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "TempPath" -default "/tmp"]
	set tmp_sub_folder $security_token

	# Set Target Path  
	set destination_path [parameter::get -package_id [apm_package_id_from_key intranet-filestorage] -parameter "ProjectBasePathUnix" -default ""]  	
	append destination_path "/" [db_string get_company_path "select company_path from im_companies where company_id=$company_id" -default 0]

	set column_sql "
		select * from im_inquiries_files where inquiry_id = :inquiry_id
	"

	set ctr 0

	db_foreach col $column_sql {

	    set project_name "RFQ Customer Portal $inquiry_id $ctr"
	    
	    set project_nr "RFQ_Customer_Portal-$inquiry_id"    
	    append project_nr "_$ctr" "_" 

	    set project_path $project_nr

	    if { ![info exists lang_hash($source_language)] } {
			set lang_hash($source_language) 1
		        set project_id ""
		        catch {
		            set project_id [project::new \
                            -project_name       $project_name \
                            -project_nr         $project_nr \
                            -project_path       $project_path \
                            -company_id         $company_id \
                            -parent_id          $parent_id \
                            -project_type_id    $project_type_id \
                            -project_status_id  $project_status_id \
				]
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
	        	        parent_id               $parent_id
        	        	project_type_id         $project_type_id
	        	        project_status_id       $project_status_id
        	        	</pre><br>&nbsp;<br>
	                	For reference, here is the error message:<br>
		                <pre>$err_msg</pre>
        		    "
	            	ad_script_abort
		        }  

			set destination_path_project [append destination_path "/$project_nr/0_source_$source_language"]
			file mkdir $destination_path_project 
	    } else {
		set destination_path_project [append destination_path "/$project_nr/0_source_$source_language"]
	    }

	    if { [catch {
		ns_cp "$template_path/$tmp_sub_folder/$file_name" $destination_path 
	    } err_msg] } {
		ns_return 200 text/html 0
	    }
	    incr ctr
	} 
# }



