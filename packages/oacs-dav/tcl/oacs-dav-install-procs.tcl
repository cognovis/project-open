# 

ad_library {
    
    Setup procs to run at package install, should be run only once.
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2003-09-11
    @cvs-id $Id$
    
}

namespace eval oacs_dav::install {}

ad_proc -private oacs_dav::install::package_install {} {
    setup DAV service contracts
} {
    db_transaction {
	create_service_contracts
	register_implementation
    }
}

ad_proc -private oacs_dav::install::package_uninstall {} {
    clean up for package uninstall
} {
    db_transaction {
	delete_service_contracts
	unregister_implementation
    }
}

# this is far from complete or even known to be going in the
# right direction

# somehow we need to get identication information from the
# user and send back status of permission allowed or denied

# look at the DAV spec to get an idea of what inputs and
# outputs these methods have

ad_proc -private oacs_dav::install::create_service_contracts {
} {
    create service contract for DAV methods
} {
    oacs_dav::install::create_dav_sc
    oacs_dav::install::create_dav_put_type_sc
    oacs_dav::install::create_dav_mkcol_type_sc
}

ad_proc -private oacs_dav::install::create_dav_sc {
} {
    create dav service contract spec
} {
    set contract_name "dav"
    set dav_spec {
        description "implements DAV methods"
        operations {
            get {
                description "DAV GET Method"
                output { content:string }
            }
            put {
                description "DAV PUT Method"
                output { response:string }
            }
	   propfind {
		description "DAV PROPFIND Method"
		output {
		    response:string
		}
	    }
	    delete {
		description "DAV DELETE Method"
		output {
		    response:string
		}
	    }
	    mkcol {
		description "DAV MKCOL Method"
		output {
		    response:string
		}
	    }
	    copy {
		description "DAV Copy Method"
		output {
		    response:string
		}
	    }
	    move {
		description "DAV Move Method"
		output {
        	    response:string
		}
	    }
	    proppatch {
		description "DAV PROPATCH Method"
		output {
		    response:string
		}
	    }
	    lock {
		description "DAV LOCK Method"
		output {
		    response:string
		}
	    }
	    unlock {
		description "DAV UNLOCK Method"
		output {
		    response:string
		}
	    }
	    head {
		description "DAV HEAD Method"
		output {
		    response:string
		}
	    }
        }
    }


    acs_sc::contract::new_from_spec \
	-spec [concat [list name $contract_name] $dav_spec ]
}

ad_proc -private oacs_dav::install::create_dav_put_type_sc {
} {
    create dav_put_type service contract
} {
    set contract_name "dav_put_type"
    set dav_spec {
        description "returns content type to use for PUT operation"
        operations {
            get_type {
                description "DAV PUT Content Type"
                output { content_type:string }
            }
	}
    }

    acs_sc::contract::new_from_spec \
	-spec [concat [list name $contract_name] $dav_spec ]
    
}

ad_proc -private oacs_dav::install::create_dav_mkcol_type_sc {
} {
    create dav_mkcol_type service contract
} {
    set contract_name "dav_mkcol_type"
    set spec {
        description "returns content type to use for MKCOL operation"
        operations {
            get_type {
                description "DAV MKCOL Content Type"
                output { content_type:string }
            }
	}
    }

    acs_sc::contract::new_from_spec \
	-spec [concat [list name $contract_name] $spec ]
    
}

ad_proc -private oacs_dav::install::delete_service_contracts {
} {
    remove service contracts on uninstall
} {
    acs_sc::contract::delete -name dav
    acs_sc::contract::delete -name dav_put_type
    acs_sc::contract::delete -name dav_mkcol_type
}

ad_proc -private oacs_dav::install::register_implementation {
} {
    add default content repository service contract
    implementation
} {
  
    set spec {
        name "content_revision"
        aliases {
            get oacs_dav::impl::content_revision::get
            head oacs_dav::impl::content_revision::head	    
            put oacs_dav::impl::content_revision::put
	    propfind oacs_dav::impl::content_revision::propfind
	    delete oacs_dav::impl::content_revision::delete
	    mkcol oacs_dav::impl::content_revision::mkcol
	    proppatch oacs_dav::impl::content_revision::proppatch
	    copy oacs_dav::impl::content_revision::copy
	    move oacs_dav::impl::content_revision::move
	    lock oacs_dav::impl::content_revision::lock
	    unlock oacs_dav::impl::content_revision::unlock
        }
	contract_name {dav}
	owner [oacs_dav::package_key]
    }
    
    acs_sc::impl::new_from_spec -spec $spec

   set spec {
        name "content_folder"
        aliases {
            get oacs_dav::impl::content_folder::get
            head oacs_dav::impl::content_revision::head
            put oacs_dav::impl::content_folder::put
	    propfind oacs_dav::impl::content_folder::propfind
	    delete oacs_dav::impl::content_folder::delete
	    mkcol oacs_dav::impl::content_folder::mkcol
	    proppatch oacs_dav::impl::content_folder::proppatch
	    copy oacs_dav::impl::content_folder::copy
	    move oacs_dav::impl::content_folder::move
	    lock oacs_dav::impl::content_folder::lock
	    unlock oacs_dav::impl::content_folder::unlock
        }
	contract_name {dav}
	owner [oacs_dav::package_key]
    }
    
    acs_sc::impl::new_from_spec -spec $spec
 
}


ad_proc -private oacs_dav::install::unregister_implementation {
} {
    remove default service contract implementation
} {
    acs_sc::impl::delete -contract_name dav -impl_name content_folder
    acs_sc::impl::delete -contract_name dav -impl_name content_revision
}

ad_proc -private oacs_dav::install::upgrade {
    -from_version_name
    -to_version_name
} {
    Install new DAV service contracts
} {
    apm_upgrade_logic \
	-from_version_name $from_version_name \
	-to_version_name $to_version_name \
	-spec {
	    1.0b1 1.0b2 {
		oacs_dav::install::create_dav_mkcol_type_sc
	    }
	}
}