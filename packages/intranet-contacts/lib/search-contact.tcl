# /packages/project-manager/lib/search-jobid.tcl
#
# Include that searchs for the name of a contact
# and redirects to the found project if it's just one or to
# first one if there are various.
# 
# @author Miguel Marin (miguelmarin@viaro.net)
# @author Viaro Networks www.viaro.net
#
# Usage:
# ADP File:
# <include src="/packages/intranet-contacts/lib/search-contact" keyword="@keyword@" return_url="@return_url@">
#
# Expects:
# keyword     The keyword to search projects
# contacts_url The URL for the contacts package to be used.
# return_url  The return_url to return if no project is found. It would be the same page if empty.


if { ![exists_and_not_null contacts_url]} {
    set contacts_url [ad_conn package_url]
}

if { ![exists_and_not_null return_url] } {
    set return_url [ad_return_url]
}

