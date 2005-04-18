<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_template">      
      <querytext>
      begin 
        :ret_val := content_template.new(
            template_id   => :template_id,
            name          => :name,
            parent_id     => :parent_id,
            creation_user => :user_id,
            creation_ip   => :ip_address
        );
        end;
      </querytext>
</fullquery>

<fullquery name="get_template_id">      
      <querytext>
      
        select acs_object_id_seq.nextval from dual

      </querytext>
</fullquery>

 
</queryset>
