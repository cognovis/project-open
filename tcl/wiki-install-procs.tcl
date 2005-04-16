# 

ad_library {
    
    Install callbacks for wiki package
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-09-06
    @arch-tag: 86a85f67-568e-422f-bd56-6c8fba89f1a2
    @cvs-id $Id$
}

namespace eval wiki::install {}

ad_proc -public wiki::install::package_install {
} {
    Callback for package install
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-09-06
    
    @return 
    
    @error 
} {

    content::type::register_relation_type \
        -content_type "content_revision" \
        -target_type "acs_object" \
        -relation_tag "wiki_referece"
}

ad_proc -public wiki::install::after_instantiate {
    -package_id
    -node_id
} {
    After instantiate callback for wiki package
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-09-06
    
    @param package_id

    @param node_id

    @return 
    
    @error 
} {
    # create new folder
    set folder_id [content::folder::new \
                       -name $package_id \
                       -label "Wiki Folder" \
                       -package_id $package_id \
                       -context_id $package_id]

    # register content types
    content::folder::register_content_type \
        -folder_id $folder_id \
        -content_type "content_revision" \
        -include_subtypes "t"
    
    # TODO: setup default page to fill in index
    set index_page_id [content::item::new \
                           -name "index" \
                           -parent_id $folder_id \
                           -title "New Wiki" \
                           -storage_type "text"]
    db_dml set_live "update cr_items set live_revision=latest_revision where item_id=:index_page_id"
    
}

