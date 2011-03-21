delete from acs_sc_bindings
where contract_id = acs_sc_contract__get_id('RssGenerationSubscriber');

select acs_sc_operation__delete ('RssGenerationSubscriber','datasource');

select acs_sc_operation__delete ('RssGenerationSubscriber','lastUpdated');

select acs_sc_msg_type__delete('RssGenerationSubscriber.LastUpdated.InputType');
select acs_sc_msg_type__delete('RssGenerationSubscriber.LastUpdated.OutputType');
select acs_sc_msg_type__delete('RssGenerationSubscriber.Datasource.InputType');
select acs_sc_msg_type__delete('RssGenerationSubscriber.Datasource.OutputType');

select acs_sc_contract__delete('RssGenerationSubscriber');

