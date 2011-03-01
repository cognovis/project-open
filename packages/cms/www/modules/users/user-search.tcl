# This should be a search page that allows input of various user
# search criteria (start with a simple like query on screen name,
# email, and first and last name).  This page will pass along the
# group to users-add.tcl

form create user_search

element create user_search keyword \
  -label "Name" -datatype text -widget text -optional -html { size 40 }
element create user_search search_in \
  -label "Search In" -datatype text -widget checkbox \
  -options { {Name name} {{Screen Name} screen_name} {Email email}} \
  -values { screen_name }
element create user_search form_title \
  -label "Form Title" -datatype text -widget hidden -param -optional

element create user_search mount_point \
  -label "Mount Point" -datatype keyword -widget hidden -param -optional
element create user_search group_id \
  -label "Group ID" -datatype integer -widget hidden -param -optional
element create user_search return_url \
  -label "Return URL" -datatype text -widget hidden -param -optional \
  -value "one-user"
element create user_search passthrough \
  -label "Passthrough" -datatype text -widget hidden -param -optional
element create user_search result_id_ref \
  -label "Result ID reference" -datatype keyword -widget hidden -param -optional \
  -value "id"

set result_id_ref [element get_value user_search result_id_ref]

set group_id [element get_value user_search group_id]
set form_title [element get_value user_search form_title]


# Set default form title if none specified

if { [util::is_nil form_title] } {
  if { ![util::is_nil group_id] } {
      set who [db_string get_who ""]
      set form_title "Search members of $who"
  } else {
      set form_title "Search All Users"
  }
  element set_properties user_search form_title -value $form_title
}

# If form is valid, compile the query and display search results

if { [form is_valid user_search] } {

  form get_values user_search keyword mount_point group_id \
       return_url passthrough

  set extra_url [content::url_passthrough $passthrough]

  set clauses [list]
  set search_in [element get_values user_search search_in]
  set keyword [string tolower "%$keyword%"]

  if { [lsearch $search_in name] != -1 } {
    lappend clauses "lower(p.first_names) like :keyword"
    lappend clauses "lower(p.last_name) like :keyword"
  }

  if { [lsearch $search_in screen_name] != -1 } {
    lappend clauses "lower(u.screen_name) like :keyword"
  }

  if { [lsearch $search_in email] != -1 } {
    lappend clauses "lower(pp.email) like :keyword"
  }

  if { [util::is_nil group_id] } { 
    set extra_table ""
    set where_clause ""
  } else {
    set extra_table ", group_member_map m"
    set where_clause "    and 
                            m.member_id = u.user_id and m.group_id = :group_id"
  }

  set clauses [join $clauses " or "]
             
  db_multirow results get_results ""              

  template::set_file "[file dir $__adp_stub]/search-results"
}
      
  





