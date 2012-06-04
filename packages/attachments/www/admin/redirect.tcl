#
#  Copyright (C) 2002 MIT
#
#  this is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  this is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

ad_page_contract {

    @author Arjun Sanyal (arjun@openforce.net)
    @cvs-id $Id$

} -query {
    {referer:notnull}
}
ad_returnredirect $referer
