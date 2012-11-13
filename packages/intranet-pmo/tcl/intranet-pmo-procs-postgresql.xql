<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/intranet-pmo/tcl/intranet-pmo-procs-postgresql.xql -->
<!-- 
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
-->
<!-- @author Malte Sussdorff (malte.sussdorff@cognovis.de) -->
<!-- @creation-date 2012-11-13 -->
<!-- @cvs-id $Id$ -->
<queryset>

  <rdbms>
    <type>postgresql</type>
    <version>8.4</version>
  </rdbms>
  
    <fullquery name="planning_item::new.create_new_planning_item">
    <querytext>

select im_planning_item__new (
        NULL,         
        'im_planning_item',
        :creation_date,
        :creation_user,
        :creation_ip,
        :context_id,
        :item_object_id,
        :item_type_id,
        :item_status_id,
        :item_value,
        :item_note,
        :item_project_phase_id,
        :item_project_member_id,
        :item_cost_type_id,
        :item_date
);
    </querytext>
  </fullquery>
</queryset>
