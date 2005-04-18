<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_folder">      
      <querytext>
      
    begin 
    :1 := content_folder.new(
        name          => :name, 
        label         => :label, 
        description   => :description,
        parent_id     => :create_parent_id, 
        creation_user => :user_id, 
        creation_ip   => :ip ); 
    end;
      </querytext>
</fullquery>

 
<fullquery name="register_content_type">      
      <querytext>
      
	  begin
	  content_folder.register_content_type(
	      folder_id        => :folder_id,
	      content_type     => 'content_template',
	      include_subtypes => 'f' 
	  );
	  end;
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      
  select content_item.get_path(:create_parent_id) from dual

      </querytext>
</fullquery>

 
</queryset>
