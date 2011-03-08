<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="add_method">      
      <querytext>
      
      begin
      content_method.add_method (
          content_type   => :content_type,
          content_method => :content_method,
          is_default     => 'f'
      );
      end;
    
      </querytext>
</fullquery>

 
</queryset>
