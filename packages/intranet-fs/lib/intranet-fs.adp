<%

    #
    #  Copyright (C) 2001, 2002 MIT
    #
    #  This file is part of dotLRN.
    #
    #  dotLRN is free software; you can redistribute it and/or modify it under the
    #  terms of the GNU General Public License as published by the Free Software
    #  Foundation; either version 2 of the License, or (at your option) any later
    #  version.
    #
    #  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
    #  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    #  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
    #  details.
    #

%>


<if @use_ajaxfs_p@ eq 1>
<include src="/packages/ajax-filestorage-ui/lib/ajaxfs-include" package_id="@file_storage_package_id@" folder_id="@folder_id@" layoutdiv="fscontainer">
</if>

<div id="fscontainer">
<include src=@scope_fs_url@ folder_id=@folder_id@ return_url=@return_url@ root_folder_id=@folder_id@ viewing_user_id=@user_id@ n_past_days=@n_past_days@ allow_bulk_actions="1" fs_url="@fs_url@" page_num="@page_num@" project_id="@project_id@">

<p>@notification_chunk;noquote@</p>

<if @webdav_url@ not nil>
      <p>#file-storage.Folder_available_via_WebDAV_at#</p>
</if>

</div>

