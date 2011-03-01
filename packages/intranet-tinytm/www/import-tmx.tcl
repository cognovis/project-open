# /package/intranet-tinymt/www/import-tmx.tcl
#
# Copyright (C) 2008 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Page to select the TMX file to import
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date April 2008
} {
    { return_url "/intranet-tinytm/" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-tinytm.Import_TMX "Import TMX"]
set context_bar [im_context_bar $page_title]

set encoding_options {
     "utf-8"	"UTF-8 (default)" 
     "unicode" "16 bit Unicode (used by MS, DGT, ...)" 
     "iso8859-1" "Latin-1 (iso8859-1)" 
}