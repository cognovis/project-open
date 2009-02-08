<master src="/packages/intranet-contacts/lib/contact-master">
<property name="party_id">@party_id@</property>

  <if @folder_id@ ge 0>
    <include src="/packages/file-storage/www/folder-chunk" folder_id="@folder_id@" allow_bulk_actions="1" fs_url="@base_url@">
  </if>
    <if @upload_count@ eq 1 and @files:rowcount@ gt 0>
      <listtemplate name="files"></listtemplate>
    </if>
    <br />
    <formtemplate id="upload_files" style="../../../contacts/resources/forms/file-upload"></formtemplate>
