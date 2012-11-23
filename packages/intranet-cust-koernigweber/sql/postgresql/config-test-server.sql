

UPDATE apm_parameter_values SET attr_value=REPLACE(attr_value,'/web/projop/','/web/kw/') WHERE attr_value LIKE '/web/%';
update apm_parameter_values set attr_value = 0 where parameter_id in (select parameter_id from apm_parameters where package_key like 'intranet-cust-koernigweber' and  parameter_name = 'HTTPSFilter'); 

