<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="register_mime_type">      
      <querytext>
      
      begin
        content_type.register_mime_type (
            content_type => :content_type,
            mime_type    => :mime_type
        );
      end;
      </querytext>
</fullquery>

 
</queryset>
