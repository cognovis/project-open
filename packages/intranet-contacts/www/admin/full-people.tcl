ad_page_contract {

    Export all people

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2006-04-24
    @cvs-id $Id$

} {
}

set party_ids [list]
db_multirow people get_people "
    select party_id,
           first_names,
           last_name,
           email,
           url
      from persons,
           parties,
           group_distinct_member_map
     where persons.person_id = parties.party_id
       and persons.person_id = group_distinct_member_map.member_id
       and group_distinct_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups]])
     order by upper(first_names), upper(last_name)
" {
    lappend party_ids $party_id
}

if { [llength $party_ids] < 10000 } {
    # postgresql cannot deal with lists larger than 10000
    set select_query [template::util::tcl_to_sql_list $party_ids]
} else {
    set select_query "select p[ad_conn user_id].party_id from parties p[ad_conn user_id]"
}

set preset_columns [template::multirow columns people]

template::multirow create ext impl type type_pretty key key_pretty

# permissions for what attributes/extensions are visible to this
# user are to be handled by this callback proc. The callback
# MUST only return keys that are visible to this user

callback contacts::extensions \
    -user_id [ad_conn user_id] \
    -multirow ext \
    -package_id [ad_conn package_id] \
    -object_type person


set output {"Person ID","First Names","Last Name","Email","URL"}
set extended_columns [list]
template::multirow foreach ext {
    if { ( $type eq "person" || $type eq "party" ) && [lsearch $preset_columns $key] >= 0 } {
	# we aren't adding the columns that are provided by the parties and persons tables
    } elseif { $type eq "person" || $type eq "party" } {
	# if you want other extend columsn they should be added here
        # you would add the type you want to show up in this list
        # by default as of the time of writing the only standard
        # extensions (i.e. not site specific) are attributes with
        # a type of object type and relationships. Since the full
        # export also exports a list of relationships that is not
        # included here, this is because:
        # - this speeds things up a little bit
        # - its confusing to have relationships in both places
        #   of a full export especially with one to many relationships
        # - when there are many related people the size of the column
        #   could be too big for programs like excel (which is one of 
        #   the primary programs this export will be looked at in)
        append output ",\"[template::list::csv_quote "$type_pretty: $key_pretty"]\""


	# for testing if you want to limit the number of columns you should do it here
        # you can simply say that if the count of extend columns > n then do not append
        # to the extend columns list
	lappend extended_columns "${type}__${key}"
    }
}

set output "$output\n"

contacts::multirow \
    -extend $extended_columns \
    -multirow people \
    -select_query $select_query \
    -format "text"


# we create a command here because it more efficient then
# iterating over all the columns in the multirow foreach
set command [list]
foreach column [template::multirow columns people] {
    lappend command "\[template::list::csv_quote \$${column}\]"
}
set command "append output \"\\\"[join $command {\",\"}]\\\"\\n\""

template::multirow foreach people {
    eval $command
}

# we save the file to /tmp/full-export.csv
# because it takes too long to process for many
# installs and this allows the http connection to
# time out while retaining the export. This output
# in the future should be saved in the database once
# there is a report storage and queueing mechanism

set output_file [open /tmp/full-people.csv "w+"]
puts $output_file $output
close $output_file

# now we return the file - just in case it didn't time out for the user
ns_return 200 text/plain $output
#ad_return_error "done." "<pre>$output</pre>"
