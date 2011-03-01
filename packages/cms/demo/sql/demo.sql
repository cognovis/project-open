declare
  folder_id       integer;
  template_id       integer;
begin

  -- create the demo templates folder
  folder_id := content_folder.new( 
     name => 'demo',
     label => 'Demo Templates',
     parent_id => content_template.get_root_folder
  );
  
  content_folder.register_content_type(folder_id, 'content_template');

  -- create a master template
  template_id := content_template.new(
    name => 'master',
    parent_id => folder_id
  );

  -- register the master template for the basic content item
  content_type.register_template(
    content_type => 'content_revision',
    template_id => template_id,
    use_context => 'public',
    is_default => 't'
  );

end;
/
show errors                               



@@press.sql
