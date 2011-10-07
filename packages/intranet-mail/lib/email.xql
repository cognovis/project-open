<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/intranet-mail/lib/email.xql -->
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
<!-- @creation-date 2011-04-21 -->
<!-- @cvs-id $Id$ -->
<queryset>
  <fullquery name="get_file_title">
    <querytext>
      select 
      title 
      from 
      cr_revisions 
      where 
      revision_id = :file
    </querytext>
</fullquery>
</queryset>