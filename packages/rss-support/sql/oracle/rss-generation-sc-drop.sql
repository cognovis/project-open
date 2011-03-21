declare
begin

    acs_sc_operation.del(contract_name => 'RssGenerationSubscriber',operation_name => 'datasource');

    acs_sc_msg_type.del(msg_type_name => 'RssGenerationSubscriber.Datasource.InputType');
    acs_sc_msg_type.del(msg_type_name => 'RssGenerationSubscriber.Datasource.OutputType');

    acs_sc_operation.del(contract_name => 'RssGenerationSubscriber',operation_name => 'lastUpdated');

    acs_sc_msg_type.del(msg_type_name => 'RssGenerationSubscriber.LastUpdated.InputType');
    acs_sc_msg_type.del(msg_type_name => 'RssGenerationSubscriber.LastUpdated.OutputType');

    acs_sc_contract.del(contract_name => 'RssGenerationSubscriber');

end;
/
show errors

delete from acs_sc_bindings where contract_id = acs_sc_contract.get_id('RssGenerationSubscriber');
