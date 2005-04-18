request create -params {
  parent_id -datatype integer -optional
  mount_point -datatype keyword -optional -value categories
}

form create add_keyword

element create add_keyword keyword_id \
  -label "Keyword ID" -datatype integer -widget hidden -optional

element create add_keyword parent_id \
  -label "Parent ID" -datatype integer -widget hidden -optional -param

element create add_keyword heading \
  -label "Heading" -datatype text -widget text -html { size 30 }

element create add_keyword description -optional \
  -label "Description" -datatype text -widget textarea -html { rows 5 cols 60 }

if { [form is_request add_keyword] } {
    set keyword_id [db_string get_keyword_id ""]
    element set_properties add_keyword keyword_id -value $keyword_id
}

if { [form is_valid add_keyword] } {

  form get_values add_keyword keyword_id heading parent_id description
  set user_id [User::getID]
  set ip [ns_conn peeraddr]

  db_transaction {

      if { ![template::util::is_nil parent_id] } {
          set pid [string trim [db_map pid]]
      } else {
          set pid ""
      }

      set keyword_id [db_exec_plsql new_keyword "
    begin :1 := content_keyword.new(
      heading => :heading, 
      description => :description, 
      keyword_id => :keyword_id,
      creation_user => :user_id,
      creation_ip => :ip$pid); end;"]
  }

  template::forward "refresh-tree?id=_all_&goto_id=$parent_id&mount_point=$mount_point"
}


  

