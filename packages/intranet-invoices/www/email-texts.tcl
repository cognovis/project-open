# packages/intranet-invoices/www/email-texts.tcl
#
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
 
ad_page_contract {
    
    Page to quickly add the texts
    
    @author malte.sussdorff@cognovis.de
    @creation-date 2012-03-01
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

set first_names ""
set last_name ""
set email_texts_html "<table border=1 cellspacing=5><tr><th>#intranet-cost.Document_Type#</th><th>#acs-mail-lite.Subject#</th><th>#acs-mail-lite.Message#</th></tr>"
db_foreach category "select parent_id, category_id from im_categories left outer join im_category_hierarchy on (child_id = category_id) where category_type = 'Intranet Cost Type' order by category_id" {
    if {"" != $parent_id} {
	set parent "[im_category_from_id $parent_id] -- "
    } else {
	set parent ""
    }
    append email_texts_html "<tr><td>$parent[im_category_from_id $category_id]</td><td>#intranet-invoices.invoice_email_subject_${category_id}#</td><td>#intranet-invoices.invoice_email_body_${category_id}#</td>"
}
append email_texts_html "</table>"

set page_title "Email Texts"
set sub_navbar [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list]] 
