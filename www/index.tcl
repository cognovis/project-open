ad_page_contract {
    Loads several RSS feeds and displays them

    @author Frank Bergmann <frank.bergmann@project-open.com>
    @creation-date July 2008
    @cvs-id $Id$

} {
    {rss_feeds:multiple "" }
    {max_news_per_feed ""}
    {format ""}
}

if {"" == $rss_feeds} {
    lappend rss_feeds "http://www.project-open.org/rss/project-open-community.rss"
    lappend rss_feeds "http://sourceforge.net/export/rss2_projnews.php?group_id=86419"
}


# ------------------------------------------------------------
# Authentication & defaults
#

set user_id [auth::require_login]
set page_title [lang::message::lookup intranet-cust-project.RSS "RSS"]


# ------------------------------------------------------------
# Fetch the RSS feeds from the remote servers
#

set feed_ctr 0
set debug ""
set html "
	<head>
		<link rel=StyleSheet type=text/css href=\"/resources/acs-subsite/site-master.css\" media=all>
		<link rel=StyleSheet href=\"/intranet/style/style.default.css\" type=text/css media=screen>
		<link rel=StyleSheet type=text/css href=\"/calendar/resources/calendar.css\">
		<script src=\"/resources/acs-subsite/core.js\" language=\"javascript\"></script>
	</head>
"

foreach rss_feed $rss_feeds {

    if { [catch {
	set update_xml [util_memoize "ns_httpget $rss_feed" 3600]
    } errmsg] } {
	ad_return_complaint 1 "Error while accessing the URL '$rss_feed'.<br>
    Please check your URL. The following error was returned: <br>
    <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
	return
    }	

    if {"" == $update_xml} {
	ad_return_complaint 1 "Found an empty XML file accessing the URL '$rss_feed'.<br>
    This means that your server(!) was not able to access the URL.<br>
    Please check the the Internet and firewall configuration of your
    server and verify that the 'nsd' (Linux) or 'nsd4' (Windows) 
    process has access to the URL.<br>"
	return
    }	


    # ------------------------------------------------------------
    # Check whether it's a HTML or an XML
    #

    if {![regexp {<([^>]*)>\s*<([^>]*)>\s*<([^>]*)>} $update_xml match tag1 tag2 tag3]} {
	ad_return_complaint 1 "Error while retreiving update information from
    URL '$rss_feed'.<br>The retreived files doesn't seem to be a XML or HTML file:<br>
    <pre>$update_xml</pre>"
	return
    }

    if {[string tolower $tag1] == "html" || [string tolower $tag2] == "html" || [string tolower $tag3] == "html"} {
	ad_return_complaint 1 "Error while retreiving update information from  URL<br>
    '$rss_feed'.<br>
    The retreived result seems to be a HTML document and not an XML document.<br>
    Please check the URL above and/or send an error report to 
    <a href=\"mailto:support@project-open.com\">support@project-open.com</a>.
    <br>&nbsp;</br>
    Here is what the server returned:
    <br>&nbsp;</br>
    <pre>$update_xml</pre>"
    }

    ns_log notice "rss-reader: match=$match, tag1=$tag1, tag2=$tag2, tag3=$tag3"


    # ------------------------------------------------------------
    # Parse the XML file and generate the HTML table
    #
    # Sample File:
    #
    # <?xml version="1.0" encoding="UTF-8"?>
    # <rss version="2.0">
    # <channel>
    #	<title>]project-open[</title>
    #	<link>http://www.project-open.com</link>
    #	<description>News from the maintainers of ]project-open[</description>
    #	<language>en-us</language>
    #	<copyright>Copyright 2008 ]project-open[</copyright>
    #	<pubDate>Mon, 03 Mar 2008 11:39:00 GMT</pubDate>
    #	<lastBuildDate>Tue, 22 Jul 2008 16:30:27 GMT</lastBuildDate>
    #
    #	<item>
    #		<title>Updated Italien Localization available for download</title>
    #		<link>http://www.project-open.org/sources/italian_catalogs_update.rar</link>
    #		<description>Thanks goes to our partner ...</description>
    #		<guid isPermaLink="false">{ca01b700-eaba-981c-d97b-7280a9cbd186}</guid>
    #		<pubDate>Tue, 22 Jul 2008 16:30:27 GMT</pubDate>
    #	</item>
    #	<item>
    #		<title>Get a sneak preview of ]po[ V3.4</title>
    #		<link>http://po34demo.dnsalias.com</link>
    #		<description>New navigation elements ...</description>
    #		<guid isPermaLink="false">{2b5d3671-6aa5-6089-4b70-ca11648f2dcf}</guid>
    #		<pubDate>Thu, 26 Jun 2008 09:55:42 GMT</pubDate>
    #	</item>
    # </channel>
    # </rss>
    

    set tree [xml_parse -persist $update_xml]
    set rss_node [xml_doc_get_first_node $tree]
    set root_name [xml_node_get_name $rss_node]
    if { ![string equal $root_name "rss"] } {
	ad_return_complaint 1 "Expected 'rss' as root node of update.xml file, found: '$root_name'"
    }
    
    set channel_nodes [xml_node_get_children $rss_node]
    
    set channel_ctr 0
    foreach channel_node $channel_nodes {
	
	if {[catch {set channel_title [[$channel_node selectNodes {title}] text]} err_msg]} { set channel_title "unknown title" }
	if {[catch {set channel_link [[$channel_node selectNodes {link}] text]} err_msg]} { set channel_link "" }
	if {[catch {set channel_description [[$channel_node selectNodes {description}] text]} err_msg]} { set channel_description "" }
	if {[catch {set channel_language [[$channel_node selectNodes {language}] text]} err_msg]} { set channel_language "en_US" }
	if {[catch {set channel_copyright [[$channel_node selectNodes {copyright}] text]} err_msg]} { set channel_copyright "" }
	if {[catch {set channel_pubDate [[$channel_node selectNodes {pubDate}] text]} err_msg]} { set channel_pubDate "" }
	if {[catch {set channel_lastBuildDate [[$channel_node selectNodes {lastBuildDate}] text]} err_msg]} { set channel_lastBuildDate "" }
	
	append html "<h2><a href='$channel_link' target='_'>$channel_title</a></h2>\n"
#	append html "<p>\n$channel_description\n</p><p>&nbsp;</p>\n"
	
	# Go through each item
	#	<item>
	#		<title>Get a sneak preview of ]po[ V3.4</title>
	#		<link>http://po34demo.dnsalias.com</link>
	#		<description>New navigation elements ...</description>
	#		<guid isPermaLink="false">{2b5d3671-6aa5-6089-4b70-ca11648f2dcf}</guid>
	#		<pubDate>Thu, 26 Jun 2008 09:55:42 GMT</pubDate>
	#	</item>
	
	set item_nodes [xml_node_get_children $channel_node]
	set item_ctr 0
	foreach item_node $item_nodes {

	    if {[catch {set item_title [[$item_node selectNodes {title}] text]} err_msg]} { set item_title "" }
	    if {[catch {set item_link [[$item_node selectNodes {link}] text]} err_msg]} { set item_link "" }
	    if {[catch {set item_description [[$item_node selectNodes {description}] text]} err_msg]} { set item_description "" }
	    if {[catch {set item_guid [[$item_node selectNodes {guid}] text]} err_msg]} { set item_guid "" }
	    if {[catch {set item_pubDate [[$item_node selectNodes {pubDate}] text]} err_msg]} { set item_pubDate "" }

	    if {"" == $item_title} { continue }

	    incr item_ctr   
	    if {"" != $max_news_per_feed} {
		if {$item_ctr == [expr $max_news_per_feed+1]} { 
		    set more_news_l10n [lang::message::lookup "" intranet-rss-reader.More_news "more..."]
		    append html "<p><a href='$channel_link' target='_'>$more_news_l10n</a></p><br>\n"
		}
		if {$item_ctr > $max_news_per_feed} { continue }
	    }
	    
	    append html "<h4><a href='$item_link' target='_'>$item_title</a></h4>\n"
	    append html "<p>\n$item_description\n</p>\n"
	    
	}
    }
    
    incr feed_ctr
}

ns_return 200 "text/html" $html
