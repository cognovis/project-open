--
-- packages/flexbase/sql/oracle/upgrade-20050419-create.sql
--
-- @author Toni Vila toni.vila@quest.ie
-- @creation-date 2005-04-19
--
--


-- ------------------------------------------------------------------
-- flexbase_attr_multi_value
-- ------------------------------------------------------------------



create table flexbase_attr_multi_value (
	attribute_id 		integer not null
				constraint flex_attr_multi_val_attr_id_fk
				references flexbase_attributes(attribute_id),
	object_id		integer not null
				constraint flex_attr_multi_val_obj_id_fk 
				references acs_objects(object_id),
	value			varchar2(400),
	sort_order		integer				
);




