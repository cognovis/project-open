--
-- packages/flexbase/sql/oracle/qt-flexbase-interfaces-create.sql
--
-- @author Toni Vila toni.vila@quest.ie
-- @creation-date 2005-03-12
--
--


-- ------------------------------------------------------------------
-- qt_flexbase_interfaces
-- ------------------------------------------------------------------



create table qt_flexbase_interfaces (
	object_type		varchar2(1000)
				constraint qt_flex_interfaces_obj_type_fk 
				references acs_object_types(object_type)
				constraint qt_flexbase_interfaces_pk 
				primary key,
	interface_type_key	varchar2(50)
				constraint qt_flex_interfaces_type_key_fk 
				references dbi_interface_types(interface_type_key)
				constraint qt_flex_interfaces_type_key_nn 
				not null,
	join_column		varchar(30)
				constraint qt_flex_interf_join_column_nn 
				not null
);
/


