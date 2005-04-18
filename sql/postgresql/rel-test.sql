-------------------------------------------------------------
-- This is a test of relationship UI
--
-- This file does not do anything useful; it is here only
-- to serve as an example of creating custom relationship types.
-------------------------------------------------------------


---------------------------------------------------------
-- Create a "Directional Relationship"
---------------------------------------------------------

create table cr_directional_rels (
  rel_id         integer 
                  constraint cr_dir_rels_fk references acs_objects,
  direction      varchar(20)
                 constraint cr_dir_rels_ck 
                 check (direction in ('in', 'out'))
); 

create or replace function inline_0 () returns integer as '
declare
  attr_id       integer;
begin

 PERFORM acs_object_type__create_type (
   ''cr_directional_rel'',
   ''Directional Relationship'',
   ''Directional Relationships'',
   ''cr_item_rel'',
   ''cr_directional_rels'',
   ''rel_id'',
   null,
   ''f'',
   null,
   ''acs_object__default_name''
 );

 attr_id := acs_attribute__create_attribute (
   ''cr_directional_rel'',
   ''direction'',
   ''keyword'',
   ''Direction'',
   ''Directions'',
   null,
   null,
   null,
   1,
   1,
   null,
   ''type_specific'',
   ''f''
 ); 

 PERFORM cm_form_widget__register_attribute_widget(
     ''cr_directional_rel'',
     ''direction'',
     ''select'',
     ''t''
 );

 PERFORM cm_form_widget__set_attribute_param_value(
      ''cr_directional_rel'', 
      ''direction'', 
      ''options'', 
      ''multilist'', 
      ''literal'',
      ''{In in} {Out out}''
  );

  PERFORM cm_form_widget__set_attribute_param_value(
      ''cr_directional_rel'',
      ''direction'',
      ''values'', 
      ''in'',
      ''onevalue'', 
      ''literal''
  );

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

---------------------------------------------------------
-- Create a "Weighted Relationship", child of 
-- "Directional Relationship"
---------------------------------------------------------

create table cr_weighted_rels (
  rel_id         integer 
                 constraint cr_weighted_rels_fk references acs_objects,
  weight_a       integer not null,
  weight_b       integer not null
); 

create or replace function inline_1 () returns integer as '
declare
  attr_id       integer;
begin

 PERFORM acs_object_type__create_type (
   ''cr_weighted_rel'',
   ''Weighted Relationship'',
   ''Weighted Relationships'',
   ''cr_directional_rel'',
   ''cr_weighted_rels'',
   ''rel_id'',
   null,
   ''f'',
   null,
   ''acs_object__default_name''
 );

 attr_id := acs_attribute__create_attribute (
   ''cr_weighted_rel'',
   ''weight_a'',
   ''integer'',
   ''Weight A'',
   ''Weights A'',
   null,
   null,
   null,
   1,
   1,
   null,
   ''type_specific'',
   ''f''
 ); 

 attr_id := acs_attribute__create_attribute (
   ''cr_weighted_rel'',
   ''weight_b'',
   ''integer'',
   ''Weight B'',
   ''Weights B'',
   null,
   null,
   null,
   1,
   1,
   null,
   ''type_specific'',
   ''f''
 ); 

 PERFORM cm_form_widget__register_attribute_widget (
     ''cr_weighted_rel'',
     ''weight_a'',
     ''text'',
     ''t''
 );

 PERFORM cm_form_widget__register_attribute_widget (
     ''cr_weighted_rel'',
     ''weight_b'',
     ''text'',
     ''t''
 );

end;' language 'plpgsql';


select inline_1 ();

drop function inline_1 ();
