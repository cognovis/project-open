<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_target_types">      
      <querytext>
      
  select
    lpad(' ', level, '-') || pretty_name, object_type
  from
    acs_object_types
  connect by
    prior object_type = supertype
  start with
    object_type = 'content_revision'

      </querytext>
</fullquery>

<fullquery name="register_rel_types">      
      <querytext>

	  begin
          content_type.${register_method} (
	      $content_key => :content_type,
	      $target_key  => :target_type,
	      relation_tag => :relation_tag,
              min_n        => :min_n,
              max_n        => :max_n
          );
          end;

      </querytext>
</fullquery>

</queryset>
