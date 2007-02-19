ad_library {
    RSS feed generation procs
    
    generates an rss feed given channel information
    and item information

    @author jerry@theashergroup.com (jerry@theashergroup.com)
    @author aegrumet@alum.mit.edu
    @creation-date Fri Oct 26 11:43:26 2001
    @cvs-id $Id$
}


ad_proc rss_gen_200 {
    {-channel_title ""}
    {-channel_link ""}
    {-channel_description ""}
    {-image ""}
    {-items ""}
    {-channel_language "en-us"}
    {-channel_copyright ""}
    {-channel_managingEditor ""}
    {-channel_webMaster ""}
    {-channel_rating ""}
    {-channel_pubDate ""}
    {-channel_lastBuildDate ""}
    {-channel_skipDays ""}
    {-channel_skipHours ""}

} { 
    generate an rss 2.0 xml feed
} {

    set rss ""

    if {[empty_string_p $channel_title]} {
        error "argument channel_title not provided"
    }
    if {[empty_string_p $channel_link]} {
        error "argument channel_link not provided"
    }
    if {[empty_string_p $channel_description]} {
        error "argument channel_description not provided"
    }

    if { [empty_string_p $channel_lastBuildDate] } {
        set now_ansi [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        set now_ansi [lc_time_tz_convert -from [lang::system::timezone] -to "Etc/GMT" -time_value $now_ansi]
        set channel_lastBuildDate "[clock format [clock scan $now_ansi] -format "%a, %d %b %Y %H:%M:%S"] GMT"
    }

    append rss {<rss version="2.0">} \n
    append rss {<channel>} \n

    append rss "<title>[ad_quotehtml $channel_title]</title>" \n
    append rss "<link>$channel_link</link>" \n
    append rss "<description>[ad_quotehtml $channel_description]</description>" \n

    append rss {<generator>OpenACS 5.0</generator>} \n
    append rss "<lastBuildDate>[ad_quotehtml $channel_lastBuildDate]</lastBuildDate>" \n
    if { ![empty_string_p $channel_pubDate] } {
	append rss "<pubDate>[ad_quotehtml $channel_pubDate]</pubDate>" \n
    }

    if {[empty_string_p $image]} {
	set base     images/openacs_logo_rss.gif
        set url      [ad_url][rss_package_url]$base
        set title    $channel_title
        set link     $channel_link
        set size     [ns_gifsize [get_server_root]/packages/rss-support/www/$base]

        set image [list                                          \
                url $url                                         \
                title $title                                     \
                link $link                                       \
                width [lindex $size 0]                           \
                height [lindex $size 1]]
    }

    # image handling
    append rss "<image>\n"
    array set iarray $image

    append rss "<title>[ad_quotehtml $iarray(title)]</title>\n"
    append rss "<url>$iarray(url)</url>\n"
    append rss "<link>[ad_quotehtml $iarray(link)]</link>\n"
    if {[info exists iarray(width)]} {
        set element [ad_quotehtml $iarray(width)]
        append rss "<width>$element</width>\n"
    }
    if {[info exists iarray(height)]} {
        set element [ad_quotehtml $iarray(height)]
        append rss "<height>$element</height>\n"
    }
    if {[info exists iarray(description)]} {
        set element [ad_quotehtml $iarray(description)]
        append rss "<description>$element</description>\n"
    }

    append rss "</image>\n"

    # now top level items
    foreach item $items {
        array unset iarray
        array set iarray $item
        append rss {<item>} \n 

        append rss "<title>[ad_quotehtml $iarray(title)]</title>" \n

        append rss "<link>[ad_quotehtml $iarray(link)]</link>" \n
        append rss {<guid isPermaLink="true">} [ad_quotehtml $iarray(link)] {</guid>} \n

        if { [exists_and_not_null iarray(description) ]} {
            append rss "<description>[ad_quotehtml $iarray(description)]</description>" \n
        }

        if { [exists_and_not_null iarray(timestamp)] } {
            append rss "<pubDate>[ad_quotehtml $iarray(timestamp)]</pubDate>" \n
        }
        
        if { [exists_and_not_null iarray(category)] } {
            append rss "<category>[ad_quotehtml $iarray(category)]</category>" \n
        }

        if { [exists_and_not_null iarray(enclosure_url)] && [exists_and_not_null iarray(enclosure_length)] && [exists_and_not_null iarray(enclosure_type)]  } {
	    append rss "<enclosure url=\"[ad_quotehtml $iarray(enclosure_url)]\" length=\"$iarray(enclosure_length)\" type=\"$iarray(enclosure_type)\"/>"
	}
        append rss {</item>} \n
    }

    append rss {</channel>} \n
    append rss {</rss>} \n
 
   return $rss
}

ad_proc rss_gen_100 {
    {
        -channel_title                  ""
        -channel_link                   ""
        -channel_description            ""
        -image                          ""
        -items                          ""
        -channel_copyright              ""
        -channel_managingEditor         ""
        -channel_webMaster              ""
        -channel_pubDate                ""
    }
} { 
    generate an rss 1.0 xml feed
    very basic rss 1.0, with no modules implemented....
} {

    set rss ""

    if {[empty_string_p $channel_title]} {
        error "argument channel_title not provided"
    }
    if {[empty_string_p $channel_link]} {
        error "argument channel_link not provided"
    }
    if {[empty_string_p $channel_description]} {
        error "argument channel_description not provided"
    }

    set channel_date [clock format [clock seconds] -format "%Y-%m-%dT%H:%M"]

    append rss "<rdf:RDF "
    append rss "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\""
    append rss " xmlns:dc=\"http://purl.org/dc/elements/1.1/\""
    append rss " xmlns=\"http://purl.org/rss/1.0/\""
    append rss ">"
    append rss "<channel rdf:about=\"$channel_link\">\n"

    append rss "<title>"
    append rss [ad_quotehtml $channel_title]
    append rss "</title>\n"

    append rss "<link>"
    append rss $channel_link
    append rss "</link>\n"

    append rss "<description>"
    append rss [ad_quotehtml $channel_description]
    append rss "</description>\n"

    if {[empty_string_p $channel_pubDate]} {
        append rss "<dc:date>$channel_date</dc:date>\n"
    } else {
        append rss "<dc:date>[ad_quotehtml $channel_pubDate]</dc:date>\n"
    }

    if {![empty_string_p $channel_copyright]} {
        append rss "<dc:rights>"
        append rss [ad_quotehtml $channel_copyright]
        append rss "</dc:rights>\n"
    }

    if {![empty_string_p $channel_managingEditor]} {
        append rss "<dc:creator>"
        append rss [ad_quotehtml $channel_managingEditor]
        append rss "</dc:creator>\n"
    }

    if {![empty_string_p $channel_webMaster]} {
        append rss "<dc:publisher>"
        append rss [ad_quotehtml $channel_webMaster]
        append rss "</dc:publisher>\n"
    }


    if {[empty_string_p $image]} {
	set base     images/openacs_logo_rss.gif
        set url      [ad_url][rss_package_url]$base
        set title    $channel_title
        set link     $channel_link
        set size     [ns_gifsize [get_server_root]/packages/rss-support/www/$base]

        set image [list                                          \
                url $url                                         \
                title $title                                     \
                link $link                                       \
                width [lindex $size 0]                           \
                height [lindex $size 1]]
    }

    array set imarray $image

    # channel image handling
    append rss "<image rdf:resource=\"[ad_quotehtml $imarray(url)]\" />\n"

    append rss "<items>\n"
    append rss "<rdf:Seq>\n"

    # channel item handling
    foreach item $items {
        array unset iarray
        array set iarray $item
        append rss "<rdf:li rdf:resource=\"[ad_quotehtml $iarray(link)]\" />\n"
    }

    append rss "</rdf:Seq>\n"
    append rss "</items>\n"
    append rss "</channel>\n"

    # now top level image
    append rss "<image rdf:about=\"$imarray(url)\">\n"
    append rss "<title>[ad_quotehtml $imarray(title)]</title>\n"
    append rss "<url>$imarray(url)</url>\n"
    append rss "<link>[ad_quotehtml $imarray(link)]</link>\n"
    if {[info exists iarray(width)]} {
        set element [ad_quotehtml $iarray(width)]
        append rss "<width>$element</width>\n"
    }
    append rss "</image>\n"

    # now top level items
    foreach item $items {
        array unset iarray
        array set iarray $item
        append rss "<item rdf:about=\"[ad_quotehtml $iarray(link)]\">\n"
        set element [ad_quotehtml $iarray(title)]
        append rss "<title>$element</title>\n"
        append rss "<link>[ad_quotehtml $iarray(link)]</link>\n"
        if {[info exists iarray(description)]} {
            set element [ad_quotehtml $iarray(description)]
            append rss "<description>$element</description>\n"
        }
        if {[info exists iarray(timestamp)]} {
            set element [ad_quotehtml $iarray(timestamp)]
            append rss "<dc:date>$element</dc:date>\n"
        }
        if {[info exists iarray(author)]} {
            set element [ad_quotehtml $iarray(author)]
            append rss "<dc:creator>$element</dc:creator>\n"
        }
        if {[info exists iarray(category)]} {
            set element [ad_quotehtml $iarray(category)]
            append rss "<dc:subject>$element</dc:subject>\n"
        }

        append rss "</item>\n"
    }

    append rss "</rdf:RDF>"
    return $rss

}

ad_proc rss_gen_091 {
    {
        -channel_title                  ""
        -channel_link                   ""
        -channel_description            ""
        -channel_language               "en-us"
        -channel_copyright              ""
        -channel_managingEditor         ""
        -channel_webMaster              ""
        -channel_rating                 ""
        -channel_pubDate                ""
        -channel_lastBuildDate          ""
        -channel_skipDays               ""
        -channel_skipHours              ""
        -image                          ""
        -items                          ""
    }
} { 
    generate an rss 0.91 xml feed
} {

    set rss ""

    if {[empty_string_p $channel_title]} {
        error "argument channel_title not provided"
    }
    if {[empty_string_p $channel_link]} {
        error "argument channel_link not provided"
    }
    if {[empty_string_p $channel_description]} {
        error "argument channel_description not provided"
    }

    append rss "<rss version=\"0.91\">\n"
    append rss "<channel>\n"

    append rss "<title>"
    append rss [ad_quotehtml $channel_title]
    append rss "</title>\n"

    append rss "<link>"
    append rss [ad_quotehtml $channel_link]
    append rss "</link>\n"

    append rss "<description>"
    append rss [ad_quotehtml $channel_description]
    append rss "</description>\n"

    append rss "<language>"
    append rss [ad_quotehtml $channel_language]
    append rss "</language>\n"

    if {![empty_string_p $channel_copyright]} {
        append rss "<copyright>"
        append rss [ad_quotehtml $channel_copyright]
        append rss "</copyright>\n"
    }

    if {![empty_string_p $channel_managingEditor]} {
        append rss "<managingEditor>"
        append rss [ad_quotehtml $channel_managingEditor]
        append rss "</managingEditor>\n"
    }

    if {![empty_string_p $channel_webMaster]} {
        append rss "<webMaster>"
        append rss [ad_quotehtml $channel_webMaster]
        append rss "</webMaster>\n"
    }

    if {![empty_string_p $channel_rating]} {
        append rss "<rating>"
        append rss [ad_quotehtml $channel_rating]
        append rss "</rating>\n"
    }

    if {![empty_string_p $channel_pubDate]} {
        append rss "<pubDate>"
        append rss [ad_quotehtml $channel_pubDate]
        append rss "</pubDate>\n"
    }

    if {![empty_string_p $channel_lastBuildDate]} {
        append rss "<lastBuildDate>"
        append rss [ad_quotehtml $channel_lastBuildDate]
        append rss "</lastBuildDate>\n"
    }

    append rss "<docs>"
    append rss "http://backend.userland.com/stories/rss091"
    append rss "</docs>\n"

    if {![empty_string_p $channel_skipDays]} {
        append rss "<skipDays>"
        append rss [ad_quotehtml $channel_skipDays]
        append rss "</skipDays>\n"
    }

    if {![empty_string_p $channel_skipHours]} {
        append rss "<skipHours>"
        append rss [ad_quotehtml $channel_skipHours]
        append rss "</skipHours>\n"
    }

    if {[empty_string_p $image]} {
	set base     images/openacs_logo_rss.gif
        set url      [ad_url][rss_package_url]$base
        set title    $channel_title
        set link     $channel_link
        set size     [ns_gifsize [get_server_root]/packages/rss-support/www/$base]

        set image [list                                          \
                url $url                                         \
                title $title                                     \
                link $link                                       \
                width [lindex $size 0]                           \
                height [lindex $size 1]]
    }

    # image handling
    append rss "<image>\n"
    array set iarray $image

    append rss "<title>[ad_quotehtml $iarray(title)]</title>\n"
    append rss "<url>$iarray(url)</url>\n"
    append rss "<link>[ad_quotehtml $iarray(link)]</link>\n"
    if {[info exists iarray(width)]} {
        set element [ad_quotehtml $iarray(width)]
        append rss "<width>$element</width>\n"
    }
    if {[info exists iarray(height)]} {
        set element [ad_quotehtml $iarray(height)]
        append rss "<height>$element</height>\n"
    }
    if {[info exists iarray(description)]} {
        set element [ad_quotehtml $iarray(description)]
        append rss "<description>$element</description>\n"
    }

    append rss "</image>\n"

    # now do the items
    foreach item $items {
        array unset iarray
        array set iarray $item
        append rss "<item>\n"
        set element [ad_quotehtml $iarray(title)]
        append rss "<title>$element</title>\n"
        append rss "<link>[ad_quotehtml $iarray(link)]</link>\n"
        if {[info exists iarray(description)]} {
            set element [ad_quotehtml $iarray(description)]
            if {[info exists iarray(timestamp)]} {
                # if {[info exists iarray(timeformat)]} {
                    # set timeformat $iarray(timeformat)
                # } else {
                    set timeformat "%B %e, %Y %H:%M%p %Z"
                # }
                set timestamp [clock format [clock scan $iarray(timestamp)] \
                        -format $timeformat]
                append element " $timestamp"
            }
            append rss "<description>$element</description>\n"
        }
        append rss "</item>\n"
    }

    append rss "</channel>\n"
    append rss "</rss>\n"
    
    return $rss

}

ad_proc rss_gen {
    {
        -version                        "2.0"
        -channel_title                  ""
        -channel_link                   ""
        -channel_description            ""
        -image                          ""
        -items                          ""
        -channel_language               "en-us"
        -channel_copyright              ""
        -channel_managingEditor         ""
        -channel_webMaster              ""
        -channel_rating                 ""
        -channel_pubDate                ""
        -channel_lastBuildDate          ""
        -channel_skipDays               ""
        -channel_skipHours              ""
    }
} { 
    <pre>
    Generates an RSS XML doc given channel information and item
    information.  Supports versions .91 and 1.0.

    Does not determine if field lengths are valid, nor does it
    determine if field values are of the proper type.

    Doesn't support textInput forms

    Merely creates the XML doc.  GIGO and caveat emptor.

    version is 0.91 or 1.0.  If not present, defaults to 0.91
    
    the default image is openacs/www/graphics/openacs_logo_rss.gif 

    For 0.91, 
    pubdate, copyright, lastbuildate, skipdays, skiphours,
    webmaster, managingeditor fields,
    if not specified are not included in the xml.

    the image parameter is a property list of:
      url $url title $title link $link 
          [width $width] [height $height] [description $description]
      where the elements within brackets are optional

    items are a list of property lists, one for each item
      title $title link $link description $description

    Spec/channel docs url for 0.91 is
    http://backend.userland.com/stories/rss091
    
    For 1.0
    Spec can be found at
    http://groups.yahoo.com/group/rss-dev/files/specification.html
    The 1.0 spec is very primitive: my needs are primitive as of yet,
    and I don't grok the rss 1.0 modules stuff as yet.  Whoops p'gazonga.

    For 2.0, the spec is at 
    http://blogs.law.harvard.edu/tech/rss
    
    </pre>
} {
    set rss "<?xml version=\"1.0\"?>\n"
    switch $version {
        200 -
        2.00 -
        2.0 -
        2 {
            append rss [rss_gen_200 \
                            -channel_title $channel_title \
                            -channel_link $channel_link \
                            -channel_description $channel_description \
                            -image $image \
                            -items $items \
                            -channel_language $channel_language \
                            -channel_copyright $channel_copyright \
                            -channel_managingEditor $channel_managingEditor \
                            -channel_webMaster $channel_webMaster \
                            -channel_rating $channel_rating \
                            -channel_pubDate $channel_pubDate \
                            -channel_lastBuildDate $channel_lastBuildDate \
                            -channel_skipDays $channel_skipDays \
                            -channel_skipHours $channel_skipHours]
        }
        100 -
        1.00 -
        1.0 -
        1 {
            append rss [rss_gen_100                                      \
                    -channel_title           $channel_title              \
                    -channel_link            $channel_link               \
                    -channel_description     $channel_description        \
                    -image                   $image                      \
                    -items                   $items                      \
                    ]
        }
        default {

            append rss [rss_gen_091                                      \
                    -channel_title           $channel_title              \
                    -channel_link            $channel_link               \
                    -channel_description     $channel_description        \
                    -channel_language        $channel_language           \
                    -channel_copyright       $channel_copyright          \
                    -channel_managingEditor  $channel_managingEditor     \
                    -channel_webMaster       $channel_webMaster          \
                    -channel_rating          $channel_rating             \
                    -channel_pubDate         $channel_pubDate            \
                    -channel_lastBuildDate   $channel_lastBuildDate      \
                    -channel_skipDays        $channel_skipDays           \
                    -channel_skipHours       $channel_skipHours          \
                    -image                   $image                      \
                    -items                   $items                      \
                    ]

        }
    }
    return $rss
}
