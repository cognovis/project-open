-- Define the attributes of a press release

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 -- create the content type
 content_type.create_type (
   supertype     => 'content_revision',
   content_type  => 'cr_demo_press_release',
   pretty_name   => 'Press Release',
   pretty_plural => 'Press Releases',
   table_name    => 'cr_demo_press_releases',
   id_column     => 'release_id'
 );

 -- create content type attributes
 attr_id := content_type.create_attribute (
   content_type   => 'cr_demo_press_release',
   attribute_name => 'location',
   datatype       => 'text',
   pretty_name    => 'Location',
   pretty_plural  => 'Location',
   column_spec    => 'varchar2(1000)'
 );

 -- choose widget for metadata forms for each attribute
 cm_form_widget.register_attribute_widget(
   content_type   => 'cr_demo_press_release',
   attribute_name => 'location',
   widget         => 'text',
   is_required    => 't'
 );
    
end;
/
show errors



-- some demo data

declare
  template_id		integer;
  item_id		integer;
  page_folder_id        integer;
  template_folder_id	integer;
begin

  item_id := content_item.new(
    name    => 'index',
    title   => 'Welcome to Demo Company',
    text    => 'Welcome to Demo Company.  We are here to serve all your
                demonstration needs...',
    is_live => 't'
  );

  item_id := content_item.new(
    name    => 'about',
    title   => 'About Demo Company',
    text    => 'Demo Company was founded in September 2000 by an intrepid
                group of programmers and developers who perceived a critical
                need for demonstration technology...',
    is_live => 't'
  );

  item_id := content_item.new(
    name    => 'contact',
    title   => 'Contacting Demo Company',
    text    => 'Please send your comments and inquiries demo@demo.com.  We
                will contact you as soon as possible if requested...',
    is_live => 't'
  );

  -- create the folder for press releases
  page_folder_id := content_folder.new( 
    name        => 'press',
    label       => 'Press Releases',
    description => 'Corporate press releases',
    parent_id   => content_item.get_root_folder
  );

  content_folder.register_content_type(
    folder_id    => page_folder_id, 
    content_type => 'cr_demo_press_release'
  );

  content_folder.register_content_type(
    folder_id    => page_folder_id, 
    content_type => 'content_revision'
  );

  -- create the press release index

  item_id := content_item.new( 
    name         => 'index',
    parent_id    => page_folder_id,
    content_type => 'content_revision',
    title        => 'Press Release Index',
    text         => 'All current press releases',
    is_live	 => 't'
  );


  -- create the folder for press release templates

  template_folder_id := 
    content_item.get_id('/demo', content_template.get_root_folder);

  content_folder.register_content_type(
    folder_id    => template_folder_id, 
    content_type => 'content_folder'
  );

  template_folder_id := content_folder.new( 
    name        => 'press',
    label       => 'Press Releases',
    description => 'Corporate press releases',
    parent_id   => template_folder_id
  );

  content_folder.register_content_type(
    folder_id    => template_folder_id, 
    content_type => 'content_template'
  );

  -- create the press release index template

  template_id := content_template.new( 
    name      => 'index',
    parent_id => template_folder_id
  );

  -- register the template for the press release index

  content_item.register_template(item_id, template_id, 'public');

  item_id := content_item.new( 
    name         => 'founding',
    parent_id    => page_folder_id,
    content_type => 'cr_demo_press_release',
    title        => 'Demo Company Founded',
    text         => 'The Demo Company was founded today'
  );

  -- insert a row into cr_demo_press_releases as well

  insert into cr_demo_press_releases values (
    content_item.get_latest_revision(item_id), 'San Francisco');

  -- register the template for the press release content type

  template_id := content_item.get_id('/demo/master', 
    content_template.get_root_folder);

  content_type.register_template(
    content_type => 'cr_demo_press_release',
    template_id  => template_id,
    use_context  => 'public',
    is_default   => 't'
  );

end;
/
show errors                               



