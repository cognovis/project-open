ad_page_contract {
    Really add the attribute.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 15, 2000
    @cvs-id $Id$
} {
    workflow_key
    attribute_name
    pretty_name
    datatype
    default_value
    {return_url "attributes?[export_vars -url {workflow_key}]"}
}

db_exec_plsql create_attribute {
    declare
      v_attribute_id integer;
    begin
      v_attribute_id := workflow.create_attribute(
          workflow_key => :workflow_key,
          attribute_name => :attribute_name,
          datatype => :datatype,
          pretty_name => :pretty_name,
          default_value => :default_value
      );
    end;
}

ad_returnredirect $return_url
