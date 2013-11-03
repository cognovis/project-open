<master>
<property name="title">#attachments.lt_Add_Attachment_Folder# </property>

<h3>#attachments.Add_folder_Link#</h3>

<if @root_folder_id@ eq 0>
  #attachments.lt_No_file-storage_folde#
  <form method=get action=new-root-folder-map-2>
    <input type=hidden name=package_id value=@package_id@>
    <input type=hidden name=referer value=@referer@>
    <input type=submit value="Yes">
  </form>

  <form method=get action=redirect>
    <input type=hidden name=referer value=@referer@>
    <input type=submit value="No">
  </form>

</if>
<else>
  #attachments.lt_Found_file-storage_fo#
</else>

