<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/intranet-mail/tcl/intranet-mail-procs.xql -->
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
      <fullquery name="acs_mail_lite::complex_sweeper.get_complex_queued_message">
        <querytext>
            select id
            from acs_mail_lite_complex_queue
            where id=:id and (locking_server = '' or locking_server is NULL)
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::complex_sweeper.lock_queued_message">
        <querytext>
            update acs_mail_lite_complex_queue
               set locking_server = :locking_server
            where id=:id
        </querytext>
    </fullquery> 

    <fullquery name="acs_mail_lite::complex_sweeper.delete_complex_queue_entry">
        <querytext>
            delete from acs_mail_lite_complex_queue
            where id=:id
        </querytext>
    </fullquery>        

</queryset>