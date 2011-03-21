--
--  Copyright (C) 2001, 2002 MIT
--
--  this is free software; you can redistribute it and/or modify it under the
--  terms of the GNU General Public License as published by the Free Software
--  Foundation; either version 2 of the License, or (at your option) any later
--  version.
--
--  this is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
--  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
--  details.
--

--
-- attachments
--
-- @author arjun (arjun@openforce.net)
-- @version $Id: attachments-create.sql,v 1.5 2003/05/17 10:11:35 jeffd Exp $
--

create table attachments_fs_root_folder_map (
    package_id                  constraint attach_fldr_map_package_id_fk
                                references apm_packages (package_id)
                                constraint attach_fldr_map_package_id_un
                                unique,
    folder_id                   constraint attach_fldr_map_folder_id_fk
                                references fs_root_folders (folder_id),
    constraint                  attach_fldr_map_pk
                                primary key (package_id, folder_id)
);

--RI Indexes
create index attachments_fsr_fm_folder_id_i ON attachments_fs_root_folder_map(folder_id);

create table attachments (
    object_id                   constraint attachments_object_id_fk
                                references acs_objects (object_id)
                                on delete cascade,
    item_id                     constraint attachments_item_id_fk
                                references acs_objects (object_id)
                                on delete cascade,
    approved_p                  char(1)
                                default 't'
                                constraint attachments_approved_p_ck
                                check (approved_p in ('t', 'f'))
                                constraint attachments_approved_p_nn
                                not null,
    constraint                  attachments_pk
                                primary key (object_id, item_id)
);

--RI Indexes
create index attachments_item_id_idx ON attachments(item_id);

