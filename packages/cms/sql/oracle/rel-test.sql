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
  direction      varchar2(20)
                 constraint cr_dir_rels_ck 
                 check (direction in ('in', 'out'))
); 

declare
  attr_id integer;
begin

 acs_object_type.create_type (
   supertype => 'cr_item_rel',
   object_type => 'cr_directional_rel',
   pretty_name => 'Directional Relationship',
   pretty_plural => 'Directional Relationships',
   table_name => 'cr_directional_rels',
   id_column => 'rel_id',
   name_method => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_directional_rel',
   attribute_name => 'direction',
   datatype => 'keyword',
   pretty_name => 'Direction',
   pretty_plural => 'Directions'
 ); 

 cm_form_widget.register_attribute_widget(
     content_type   => 'cr_directional_rel',
     attribute_name => 'direction',
     widget	    => 'select',
     is_required    => 't'
 );

 cm_form_widget.set_attribute_param_value(
      content_type   => 'cr_directional_rel', 
      attribute_name => 'direction', 
      param	     => 'options', 
      param_type     => 'multilist', 
      param_source   => 'literal',
      value	     => '{In in} {Out out}'
  );

  cm_form_widget.set_attribute_param_value(
      content_type   => 'cr_directional_rel',
      attribute_name => 'direction',
      param	     => 'values', 
      param_type     => 'onevalue', 
      param_source   => 'literal', 
      value	     => 'in'
  );

end;
/
show errors


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

declare
  attr_id integer;
begin

 acs_object_type.create_type (
   supertype => 'cr_directional_rel',
   object_type => 'cr_weighted_rel',
   pretty_name => 'Weighted Relationship',
   pretty_plural => 'Weighted Relationships',
   table_name => 'cr_weighted_rels',
   id_column => 'rel_id',
   name_method => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_weighted_rel',
   attribute_name => 'weight_a',
   datatype => 'integer',
   pretty_name => 'Weight A',
   pretty_plural => 'Weights A'
 ); 

 attr_id := acs_attribute.create_attribute (
   object_type => 'cr_weighted_rel',
   attribute_name => 'weight_b',
   datatype => 'integer',
   pretty_name => 'Weight B',
   pretty_plural => 'Weights B'
 ); 

 cm_form_widget.register_attribute_widget (
     content_type   => 'cr_weighted_rel',
     attribute_name => 'weight_a',
     widget	    => 'text',
     is_required    => 't'
 );

 cm_form_widget.register_attribute_widget (
     content_type   => 'cr_weighted_rel',
     attribute_name => 'weight_b',
     widget	    => 'text',
     is_required    => 't'
 );

end;
/
show errors
