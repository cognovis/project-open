<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="content_method::get_content_methods.get_default_method">      
      <querytext>
      
      select 
        content_method 
      from
        cm_content_methods m
      where
        content_method = content_method__get_method (:content_type )
      $text_entry_filter
    
      </querytext>
</fullquery>

 
<fullquery name="content_method::get_content_method_options.get_content_default_method">      
      <querytext>
      
      select
        label, content_method
      from
        cm_content_methods m
      where
        m.content_method = content_method__get_method( :content_type )
      $text_entry_filter
    
      </querytext>
</fullquery>

 
</queryset>
