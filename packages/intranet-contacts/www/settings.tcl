ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
}

set title "[_ intranet-contacts.Settings]"
set context [list $title]
set package_id [ad_conn package_id]
set party_id [ad_conn user_id]
set admin_p [ad_permission_p [ad_conn package_id] admin]

template::list::create \
    -name "signatures" \
    -multirow "signatures" \
    -row_pretty_plural "[_ intranet-contacts.signatures]" \
    -actions [list [_ intranet-contacts.Add_Signature] "signature" [_ intranet-contacts.Add_Signature]] \
    -elements {
	default_p {
	    label ""
	    display_template {
		<if @signatures.default_p@>
		Default Signature
		</if>
	    }
	}
	title {
	    label ""
	    display_col title
	    link_url_eval $signature_url
	}
	signature {
	    label ""
	    display_template {@signatures.signature;noquote@}
	}
    } -filters {
    } -orderby {
    }

	
db_multirow -extend { signature_url } signatures select_signatures {
    select signature_id,
           title,
           signature,
           default_p
      from contact_signatures
     where party_id = :party_id
     order by default_p, upper(title), upper(signature)
} {
    
    set signature [template::util::richtext::get_property contents $signature]
    set signature_url [export_vars -base signature -url {signature_id }]
}



ad_return_template
