<div>

  [<a href="index">Home</a>]
  | [<a href="Editing">Help</a>]
  | [<a href="Category">Categories</a>]

  <if @edit_link_p@ true> 
    | [<a href="?edit">Edit This Page</a>]
  </if>

  <if @admin_p@ true> 
    | [<a href="admin/index?folder_id=@folder_id@">Admin</a>]
    | [<a href="admin/index?folder_id=@folder_id@&modified_only=1">Changes</a>]
  </if>

</div>
