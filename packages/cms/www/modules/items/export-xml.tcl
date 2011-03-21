request create -params {
  revision_id -datatype integer
}

db_transaction {
    set doc_id [db_exec_plsql export_revision "
                             begin
                                 :1 := content_revision.export_xml(:revision_id);
                             end;"]

    set xml_doc [db_string get_xml_doc ""]
}

ns_return 200 text/xml $xml_doc

