<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="copy_item">      
      <querytext>
      declare copy_id integer; begin 
        copy_id := content_item.copy2(
          :template_id, :folder_id, :creation_user, :creation_ip
        );
        insert into cr_templates (template_id) values (copy_id);
      end;
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      select content_item.get_path(:folder_id) from dual
      </querytext>
</fullquery>

 
</queryset>
