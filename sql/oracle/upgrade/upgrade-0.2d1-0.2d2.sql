--
-- Upgrade script
--
-- Change service contract operation names to use lowercase like the PosgreSQL version.
--
-- $Id$
--

update acs_sc_operations
set    operation_name = 'datasource'
where  operation_name = 'Datasource'
and    contract_name = 'RssGenerationSubscriber';


update acs_sc_operations
set    operation_name = 'lastUpdated'
where  operation_name = 'LastUpdated'
and    contract_name = 'RssGenerationSubscriber';


update acs_sc_impl_aliases
set    impl_operation_name = 'datasource'
where  impl_operation_name = 'Datasource'
and    impl_contract_name = 'RssGenerationSubscriber';


update acs_sc_impl_aliases
set    impl_operation_name = 'lastUpdated'
where  impl_operation_name = 'LastUpdated'
and    impl_contract_name = 'RssGenerationSubscriber';


