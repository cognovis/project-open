# packages/ams/tcl/instant-message-widgets-procs.tcl

ad_library {
    
    Widget procs for instant messaging
    
    @author Malte Sussdorff (<malte@openacs.de>)
    @creation-date 2007-01-14
    @cvs-id $Id: instant-message-widgets-procs.tcl,v 1.1 2009/01/22 19:38:47 cvs Exp $
}

namespace eval template::util::aim {}
namespace eval template::util::skype {}

ad_proc -public template::util::aim::status_img {
    -username:required
} {
# connecting to the server can be really slow, so we reutrn a url that will load in the broswer
# but not slow the loading of a page overall

    # Connect to AOL server
#    set url [socket "big.oscar.aol.com" 80]
    # Send request
#    puts $url "GET /$username?on_url=online&off_url=offline HTTP/1.0\n\n"
#    set counter 0
    # While page not completely read
#    while { ![eof $url] } {
	# Read page
#	set page [read $url 256]
#	incr counter
	# If we reach 10 attempts with no answer, consider the user offline
#	if { $counter > 10 } {
#	    set page "offline"
#	    break
#	}
#    }

    # If no time out, response will be formatted as:
    # HTTP/1.1 302 Redirection Location:online IMG SRC=online
    # or
    # HTTP/1.1 302 Redirection Location:online IMG SRC=offline
    # Search for word offline, if present then user is offline, else user is online

#    set status [string first "offline" $page]
#    if { $status >= 0 } {
#	set status "offline"
#    } else {
#	set status "online"
#    }
#    close $url
#    return status
    return "<img src=\"http://big.oscar.aol.com/$username?on_url=&off_url=\" />"
}

ad_proc -private template::util::skype::status {
    -username:required
    -response_type:required
    {-image_type "balloon"}
    {-language "en"}
    {-char_set "utf"}
} {
    This procedure would query the skypeweb database for the status of the provided username. For this procedure to retun the user status, the user should allow his status to be shown on the web in the privacy menu in thier Skype application. This procedure should not be called by the user, instead use the wrapper procedures status_txt, status_xml, status_num, and status_img, unless if you want the raw unprocessed result as it returns from the server. For more information consult the SkypeWeb Technical Whitepaper.

    @param username The username to check the status for.
    @param response_type
    Must be one of the following:
    <ul>
    <li><strong>txt</strong> - Returns status as a text. </li>
    <li><strong>xml</strong> - Returns status in XML format. </li>
    <li><strong>num</strong> - Returns status in a number code format. </li>
    <li><strong>img</strong> - Returns status as an image (PNG). </li>
    <li><strong>img_url</strong> - Returns status as an image url (PNG). </li>
    </ul>
    @param image_type
    If response_type is of type image, then image_type specifies the type of image to be returned. Available image types are:
    <ul>
    <li><strong>balloon</strong></li>
    <li><strong>big_classic</strong></li>
    <li><strong>small_classic</strong></li>
    <li><strong>small_icon</strong></li>
    <li><strong>medium_icon</strong></li>
    <li><strong>dropdown_white_bg</strong></li>
    <li><strong>dropdown_transparent_bg</strong</li>
    </ul>
    @param language The ISO code for the language that the status should be returned in. If specified language is not available, status would be returned in enlgish. Would only have meaning if response_type is txt.
    @param char_set The character set the status should be encoded in. Must be either utf (UTF-8) or iso (ISO-8859-1). Would only have meaning if response_type is txt.
} {
    #Set base URI
    set uri "http://mystatus.skype.com"

    #If response_type is image, add to URI the image type to return
    if { $response_type == "img" } {
	switch $image_type {
	    "balloon"                 {set image_type "balloon"}
	    "big_classic"             {set image_type "bigclassic"}
	    "small_classic"           {set image_type "smallclassic"}
	    "small_icon"              {set image_type "smallicon"}
	    "medium_icon"             {set image_type "mediumicon"}
	    "dropdown_white_bg"       {set image_type "dropdown-white"}
	    "dropdown_transparent_bg" {set image_type "dropdown-trans"}
	    default                   {set image_type "balloon"}
	}
	set uri ${uri}/$image_type
    }

    #To avoid ambiguity, escape the . in a username, then add it to the URI
    regsub -all {\.} $username {%2E} username
    set uri ${uri}/$username

    #If response_type is not an image, append it to the URI
    if { $response_type != "img" } {
	set uri ${uri}.$response_type
    }
    
    #If response_type is txt, check for language and character set.
    if { $response_type == "txt" } {

	#If language is specified, check for its availablity and add it to the URI
	if { ![empty_string_p $language] } {
	    string tolower $language
	    switch $language {
		"en"    {set language "en"}
		"de"    {set language "de"}
		"fr"    {set language "fr"}
		"it"    {set language "it"}
		"pl"    {set language "pl"}
		"ja"    {set language "ja"}
		"pt"    {set language "pt"}
		"pt/br" {set language "pt-br"}
		"se"    {set language "se"}
		"zh"    {set language "zh-cn"}
		"cn"    {set language "zh-cn"}
		"zh/cn" {set language "zh-cn"}
		"hk"    {set language "zh-tw"}
		"tw"    {set language "zh-tw"}
		"zh/tw" {set language "zh-tw"}
		default {set language "en"}
	    }
	    set uri ${uri}.$language
	}
	
	#If char_set is specified append it to the URI
	if { ![empty_string_p $char_set] } {
	    string tolower $char_set
	    switch $char_set {
		"utf"   {set char_set "utf8"}
		"iso"   {set char_set "latin1"}
		default {set char_set "utf8"}
	    }
	    set uri ${uri}.$char_set
	}
    }

    #By now, the uri is fully formatted and contains all the data required.

    if { $response_type eq "img" } {
	set status $uri
    } else {
	#Get user status
	set status [ns_httpget $uri]
    }

    return $status
}

ad_proc -public template::util::skype::status_txt {
    -username:required
    {-language ""}
    {-char_set ""}
} {
    This procedure is a wrapper procedure for template::util::skype::status, and should be used to get a text of the use status.

    @param username The username to check the status for.
    @param language The ISO code for the language that the status should be returned in. If specified language is not available, status would be returned in enlgish. Defaults to english.
    @param char_set The character set the status should be encoded in. Must be either utf (UTF-8) or iso (ISO-8859-1).

    @see template::util::skype::status
} {
    return [template::util::skype::status -username $username -response_type "txt" -language $language -char_set $char_set]
}

ad_proc -public template::util::skype::status_num {
    -username:required
} {
    This procedure is a wrapper procedure for template::util::skype::status. Will get a number code from the skypeweb server, and will decode it and return a text representation of the status.

    @param username The username to check the status for.

    @see template::util::skype::status
} {
    set status [template::util::skype::status -username $username -response_type "num"]

    switch $status {
	0 {set status "Unknown"}
	1 {set status "Offline"}
	2 {set status "Online"}
	3 {set status "Away"}
	4 {set status "Not Available"}
	5 {set status "Do Not Disturb"}
	6 {set status "Invisible"}
	7 {set status "Skype Me"}
    }
    return $status
}

ad_proc -public template::util::skype::status_xml {
    -username:required
    {-language}
} {
    This procedure is a wrapper procedure for template::util::skype::status. Will get an XML response, and will parse it and return a text representation of the status.

    @param username The username to check the status for.
    @param language The ISO code for the language that the status should be returned in. If specified language is not available, status would be returned in enlgish. Defaults to english.

    @see template::util::skype::status
} {
    set status [template::util::skype::status -username $username -response_type "xml"]

    #Parse XML response
    set document [dom parse $status]
    set root [$document documentElement]
    set node [$root firstChild]
    set node [$node firstChild]
    set nodelist [$node selectNodes /rdf/status/presence/text()]

    if { [empty_string_p $language] } {
	set language "en"
    }
    switch $language {
	string tolower $language
	"en"    {set status [lindex $nodelist 1]}
	"fr"    {set status [lindex $nodelist 2]}
	"de"    {set status [lindex $nodelist 3]}
	"ja"    {set status [lindex $nodelist 4]}
	"zh"    {set status [lindex $nodelist 5]}
	"cn"    {set status [lindex $nodelist 5]}
	"zh/cn" {set status [lindex $nodelist 5]}
	"hk"    {set status [lindex $nodelist 6]}
	"tw"    {set status [lindex $nodelist 6]}
	"zh/tw" {set status [lindex $nodelist 6]}
	"pt"    {set status [lindex $nodelist 7]}
	"pt/br" {set status [lindex $nodelist 8]}
	"it"    {set status [lindex $nodelist 9]}
	"es"    {set status [lindex $nodelist 10]}
	"pl"    {set status [lindex $nodelist 11]}
	"se"    {set status [lindex $nodelist 12]}
	default {set status [lindex $nodelist 1]}
    }
    return $status
}

ad_proc -public template::util::skype::status_img {
    -username:required
    {-image_type ""}
} {
    This procedure is a wrapper procedure for template::util::skype::status, and should be used to get an image of the users status.

    @param username The username to check the status for.
    @param image_type
    image_type specifies the type of image to be returned. Defaults to balloon. Available image types are:
    <ul>
    <li><strong>balloon</strong></li>
    <li><strong>big_classic</strong></li>
    <li><strong>small_classic</strong></li>
    <li><strong>small_icon</strong></li>
    <li><strong>medium_icon</strong></li>
    <li><strong>dropdown_white_bg</strong></li>
    <li><strong>dropdown_transparent_bg</strong</li>
    </ul>

    @see template::util::skype::status
} {
    #The status image url for a png image
    set uri [template::util::skype::status -username $username -response_type "img" -image_type $image_type]

    return "<img src=\"$uri\" />"
}

