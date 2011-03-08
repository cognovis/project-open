ad_proc -public im_navbar_tree_helper { 
    -user_id:required
    {-locale "" }
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }
    set wiki [im_navbar_doc_wiki]

    set show_left_functional_menu_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "ShowLeftFunctionalMenupP" -default 0]
    if {!$show_left_functional_menu_p} { return "" }

    set general_help_l10n [lang::message::lookup "" intranet-core.Home_General_Help "\]po\[ Modules Help"]
    set html "
      	<div class=filter-block>
	<ul class=mktree>
	<li><a href=\"/intranet/index\">[lang::message::lookup "" intranet-core.Home Home]</a>
	<ul>
		<li><a href=$wiki/list_modules>$general_help_l10n</a>
		[im_menu_li dashboard]
		[im_menu_li indicators]
    "
    if {$user_id == 0} {
	append html "
		<li><a href=/register/>[lang::message::lookup "" intranet-core.Login_Navbar Login]</a>
        "
    }
    if {$user_id > 0} {
	append html "
		<li><a href=/register/logout>[lang::message::lookup "" intranet-core.logout Logout]</a>
        "
    }

    append html "
	</ul>
	[if {![catch {set ttt [im_navbar_tree_project_management -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_human_resources -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[im_navbar_tree_admin -user_id $user_id -locale $locale]
      </div>
    "
}


ad_proc -public -callback intranet_fs::after_project_folder_create -impl berendsen_default_folder {
	{-project_id:required}
	{-folder_id:required}
} {
    
	Copy the default folder to the new projects

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2010-09-27
    
	@param project_id Project_id of the project
	@param folder_id FolderID of the new folder into which to copy the content
    @return             nothing
    @error
} {

    set project_type_id [db_string project_type_id "select project_type_id from im_projects where project_id = :project_id"]
    if {$project_type_id > 10000010 && $project_type_id <10000037} {
		intranet_fs::copy_folder -source_folder_id 35147 -destination_folder_id $folder_id
		intranet_fs::copy_folder -source_folder_id 35136 -destination_folder_id $folder_id
    }
}

