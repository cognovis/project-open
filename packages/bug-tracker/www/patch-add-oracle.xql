<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    

<fullquery name="new_patch">
  <querytext>
      begin
        :1 := bt_patch.new(
                patch_id               => :patch_id,
                project_id             => :package_id,
                component_id           => :component_id,
                summary                => :summary,
                description            => :description,
                description_format     => :description_format,
                content                => :content,
                generated_from_version => :version_id,
                creation_user          => :user_id,
                creation_ip            => :ip_address
            );
        end;
  </querytext>
</fullquery>

</queryset>

