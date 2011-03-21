if { [string is false [contact::exists_p -party_id $party_id]] } {
    error "[_ intranet-contacts.lt_The_party_id_specifie]"
}

if { ![exists_and_not_null revision_id] } {
    set revision_id ""
}
 
template::list::create \
    -name changes \
    -multirow changes \
    -elements {
	revision_id {
	    display_template {
		<a href="?revision_id=@changes.revision_id@">@changes.revision_id@</a>
		<if "$revision_id" eq @changes.revision_id@>
		   <b> << </b>
                </if>
	    }
	}
	publish_date {
	    label "[_ intranet-contacts.Changed_date]"
	}
	name {
	    label "[_ intranet-contacts.Modify_by]"
	}
	latest_revision {
	    display_template {
		<if @changes.revision_id@ eq @changes.live_revision@>
		    <b>#contacts.Latest#</b>
		</if>
	    }
	}
    }


db_multirow changes get_changes { }


