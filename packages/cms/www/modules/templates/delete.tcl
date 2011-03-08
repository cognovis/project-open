request create -params {
  folder_id -datatype integer
}

if { ! [request is_valid] } { return }

# check for a submission

set submit [ns_queryget submit] 

if { ! [string equal $submit {}] } {

  if { $submit == "Delete" } {

      db_transaction {

          foreach template_id [ns_querygetall template_id] {
              db_exec_plsql delete "begin content_template.del(:template_id); end;"
          }
      }
  }

  template::forward [ns_queryget return_url]
}

