<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="copy_item">      
      <querytext>

        declare 
                copy_id integer; 
        begin 
                copy_id := content_item__copy2(
                                :template_id, :folder_id, :creation_user, :creation_ip
                           );

                insert into cr_templates (template_id) values (copy_id);

                return null;
        end;

      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      select content_item__get_path(:folder_id, null) 
      </querytext>
</fullquery>

 
</queryset>
