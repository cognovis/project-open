ad_library {

    Support procs for the contacts package with regards to OpenOffice

    Before you can make use of these functions, OpenOffice 2.4 needs to be installed in your system. 
    Additionally you need ghostscript and the msttftcorefonts (so your users wont complain about wrong verdana fonts)

    @author Malte Sussdorff
    @creation-date 2006-04-18
}

namespace eval contact::oo:: {}

ad_proc -public contact::oo::convert {
    {-content}
} {
    Returns a string which we can insert into the content.xml file
    
    This is a replacement procedure which should hopefully deal with at least the breaks
    links and paragraphs. 
} {
    regsub -all -nocase "<br>" $content "<text:line-break/>" content
    regsub -all -nocase "<p>" $content "<text:line-break/>" content
    regsub -all -nocase "&nbsp;" $content " " content
    regsub -all -nocase "</p>" $content "<text:line-break/>" content
    regsub -all -nocase "a href=" $content "text:a xlink:type=\"simple\" xlink:href=" content
    regsub -all -nocase "/a" $content "/text:a" content
    regsub -all -nocase "<ul>" $content "<text:list text:style-name=\"L1\">" content
    regsub -all -nocase "</ul>" $content "</text:list>" content
#    regsub -all -nocase "<li>" $content "<text:list-item><text:p text:style-name=\"Standard\">" content
#    regsub -all -nocase "</li>" $content "</text:p></text:list-item>" content

    return [string trim $content]
}
    
#----------------------------------------------------------------------
# ????/??/?? Developed/Created by ...
# 2006/11/06 Renamed from contact::oo::import_oo_pdf
#                      to contact::oo::import_oo_pdf_using_soffice
#                      by Cognovis/NFL
#            (contact::oo::import_oo_pdf will be the name of a new
#             meta function that wraps ..._using_jooconverter and .._soffice)
#----------------------------------------------------------------------    



ad_proc -public contact::oo::import_oo_pdf_using_soffice {
    -oo_file:required
    {-title ""}
    {-item_id ""}
    {-parent_id ""}
    {-no_import:boolean}
    {-return_pdf:boolean}
    {-return_pdf_with_id:boolean}
} {
    Imports an OpenOffice file (.sxw / .odt) as a PDF file into the content repository. If item_id is specified a new revision of that item is created, else a new item is created.
    
    @param oo_file The full path to the OpenOffice file that contains the data to be exported as PDF.
    @param title Title which will be used for the resulting content item and file name if none was given in the item
    @param item_id The item_id of the content item to which the content should be associated.
    @param parent_id Needed to set the parent of this object
    @param no_import If this flag is specified the location of the generated PDF will be returned, but the pdf will not be stored in the content repository
    @param return_pdf If this flag is specified the location of the generated PDF will be returned and the PDF will be stored in the content repository (in contrast to "no_import"
    @param return_pdf_with_id Same as return_pdf but it will return a list with three elements: file_item_id, file_mime_type and pdf_filename
    @return item_id of the revision that contains the file
    @return file location of the file if "no_import" has been specified.
} {
    set pdf_filename "[file rootname $oo_file].pdf"
    set status [catch {exec -- /usr/bin/java -jar /web/jodconverter-2.2.1/lib/jodconverter-cli-2.2.1.jar $oo_file $pdf_filename} result]

    if { $status == 0 } {

        # The command succeeded, and wrote nothing to stderr.
        # $result contains what it wrote to stdout, unless you
        # redirected it

    } elseif { [string equal $::errorCode NONE] } {

        # The command exited with a normal status, but wrote something
        # to stderr, which is included in $result.

    } else {

        switch -exact -- [lindex $::errorCode 0] {

            CHILDKILLED {
                foreach { - pid sigName msg } $::errorCode break

                # A child process, whose process ID was $pid,
                # died on a signal named $sigName.  A human-
                # readable message appears in $msg.

            }

            CHILDSTATUS {

                foreach { - pid code } $::errorCode break

                # A child process, whose process ID was $pid,
                # exited with a non-zero exit status, $code.

            }

            CHILDSUSP {

                foreach { - pid sigName msg } $::errorCode break

                # A child process, whose process ID was $pid,
                # has been suspended because of a signal named
                # $sigName.  A human-readable description of the
                # signal appears in $msg.

            }

            POSIX {

                foreach { - errName msg } $::errorCode break

                # One of the kernel calls to launch the command
                # failed.  The error code is in $errName, and a
                # human-readable message is in $msg.

            }

        }
    }
    
    # Strip the extension.

    set mime_type "application/pdf"
    if {![file exists $pdf_filename]} {
	###############
	# this is a fix to use the oo file if pdf file could not be generated
	###############
	set pdf_filename $oo_file
	set mime_type "application/odt"
    } else {
#	ns_unlink $oo_file
	ds_comment $oo_file
    }

    if {$no_import_p} {
	return [list $mime_type $pdf_filename]
    }

    set pdf_filesize [file size $pdf_filename]
    
    set file_name [file tail $pdf_filename]
    if {$title eq ""} {
	set title $file_name
    }
    
    if {[exists_and_not_null $item_id]} {
	set parent_id [get_parent -item_id $item_id]
	
	set revision_id [cr_import_content \
			     -title $title \
			     -item_id $item_id \
			     $parent_id \
			     $pdf_filename \
			     $pdf_filesize \
			     $mime_type \
			     $file_name ]
    } else {
	set revision_id [cr_import_content \
			     -title $title \
			     $parent_id \
			     $pdf_filename \
			     $pdf_filesize \
			     $mime_type \
			     $file_name ]
    }	



    content::item::set_live_revision -revision_id $revision_id
    if {$return_pdf_p} {
	return [list $mime_type $pdf_filename]
    } elseif {$return_pdf_with_id_p} {
	return [list [content::revision::item_id -revision_id $revision_id] $mime_type $pdf_filename]
    } else  {
	ns_unlink $pdf_filename
	return [content::revision::item_id -revision_id $revision_id]
    }
}

ad_proc -public contact::oo::join_pdf {
    -filenames:required
    {-title ""}
    {-item_id ""}
    {-parent_id ""}
    {-no_import:boolean}
    {-return_pdf:boolean}
} {
    Joins given pdf files and inserts the resulting PDF file into the content repository. If item_id is specified a new revision of that item is created, else a new item is created.
    
    @param filenames The full path to the pdf-files to be joined.
    @param title Title which will be used for the resulting content item and file name if none was given in the item
    @param item_id The item_id of the content item to which the content should be associated.
    @param parent_id Needed to set the parent of this object
    @param no_import If this flag is specified the location of the generated PDF will be returned, but the pdf will not be stored in the content repository
    @param return_pdf If this flag is specified the location of the generated PDF will be returned and the PDF will be stored in the content repository (in contrast to "no_import"
    @return item_id of the revision that contains the file
    @return file location of the file if "no_import" has been specified.
} {
    # This exec command is missing all the good things about openacs
    # Add the parameter to whatever package you put this procedure in.
    set pdfjoin_bin [parameter::get -parameter "PdfJoinBin" -default "/usr/bin/pdfjoin"]
    set pdf_filename "[ns_tmpnam].pdf"

    catch {eval exec $pdfjoin_bin --outfile $pdf_filename [join $filenames " "]} result
    set mime_type "application/pdf"

    if {![file exists $pdf_filename]} {
	error "$result - couldn't join pdfs"
	return
    }

    if {$no_import_p} {
	return [list $mime_type $pdf_filename]
    }

    set pdf_filesize [file size $pdf_filename]
    
    set file_name [file tail $pdf_filename]
    if {$title eq ""} {
	set title $file_name
    }
    
    if {[exists_and_not_null $item_id]} {
	set parent_id [get_parent -item_id $item_id]
	
	set revision_id [cr_import_content \
			     -title $title \
			     -item_id $item_id \
			     $parent_id \
			     $pdf_filename \
			     $pdf_filesize \
			     $mime_type \
			     $file_name ]
    } else {
	set revision_id [cr_import_content \
			     -title $title \
			     $parent_id \
			     $pdf_filename \
			     $pdf_filesize \
			     $mime_type \
			     $file_name ]
    }	

    content::item::set_live_revision -revision_id $revision_id
    if {$return_pdf_p} {
	return [list $mime_type $pdf_filename]
    } else {
	ns_unlink $pdf_filename
	return [content::revision::item_id -revision_id $revision_id]
    }
}

ad_proc -public contact::oo::change_content {
    -path:required
    -document_filename:required
    -contents:required
    {-encoding "utf-8"}
} {
    Takes the provided contents and places them in the content.xml file of the sxw file, effectivly changing the content of the file.

    @param path Path to the file containing the content
    @param document_filename The open-office file whose contents will be changed.
    @param contents This is a list of key-values (to be used as an array) of filenames and contents
                    to be replaced in the oo-file.
    @return The path to the new file.
} {
    # Create a temporary directory
    set dir [ns_tmpnam]
    ns_mkdir $dir

    array set content_array $contents
    foreach filename [array names content_array] {
	# Save the content to a file.
	set file [open "${dir}/$filename" w]
	fconfigure $file -encoding $encoding
	puts $file [contact::oo::convert -content $content_array($filename)]
	flush $file
	close $file
    }

    # copy the document
    ns_cp "${path}/$document_filename" "${dir}/$document_filename"

    # Replace old content in document with new content
    # The zip command should replace the content.xml in the zipfile which
    # happens to be the OpenOffice File. 
    foreach filename [array names content_array] {
	exec zip -j "${dir}/$document_filename" "${dir}/$filename"
    }

    # copy odt file
    set new_file "[ns_tmpnam].odt"
    ns_cp "${dir}/$document_filename" $new_file

    # delete other tmpfiles
    ns_unlink "${dir}/$document_filename"
    foreach filename [array names content_array] {
	ns_unlink "${dir}/$filename"
    }
    ns_rmdir $dir

    return $new_file
}


# 2006/11/07 NFL: Hilfsfunktion: ASCII-Code eines Zeichens zurueckliefern (Q&D, keine Abbruchbedingung, irgendwas 0-255 wird vorausgesz.)
ad_proc -public contact::oo::get_ASCII_code {
  -char:required
} {
    set code 0
    while { $char!=[format %c $code]} {
	incr code 
    }
    return $code
}



#----------------------------------------------------------------------
# This function is a meta/wrapper function to
# contact::oo::import_oo_pdf_using_jooconverter and
# contact::oo::import_oo_pdf_using_soffice (formerly import_oo_pdf itself) 
#----------------------------------------------------------------------
# 2006/11/06 Developed/Created by Cognovis/NFL
# 2006/11/07 New optional -force-switches to force one conv. method (NFL)
# 2006/11/08 New third method contact::oo::import_oo_pdf_using_remote_cognovis_converter
#----------------------------------------------------------------------  
ad_proc -public contact::oo::import_oo_pdf {
    -oo_file:required
	{-printer_name "pdfconv"}
	{-title ""}
	{-item_id ""}
	{-parent_id ""}
	{-no_import:boolean}
	{-return_pdf:boolean}
	{-return_pdf_with_id:boolean}
        {-force_local_soffice:boolean}
        {-force_jooconverter:boolean}
} {
    This function is a meta/wrapper function to<br>
    contact::oo::import_oo_pdf_using_jooconverter and<br>
    contact::oo::import_oo_pdf_using_soffice (formerly import_oo_pdf itself)<br>
    <br>
    Please look at the documentation there for further information.<br>
    <br>
    This function will try import_oo_pdf_using_jooconverter first and on exception
    it will fallback to import_oo_pdf_using_soffice<br>
    <br>
    @param force_local_soffice Forces the function to use contact::oo::import_oo_pdf_using_soffice
    @param force_jooconverter Forces the function to use contact::oo::import_oo_pdf_using_jooconverter

    @author Nils Lohse (nils.lohse@cognovis.de)
    @creation-date 6 November 2006                      
} {
    # set the parameters that are needed for any/every function call
    set command_parameter " -oo_file \"$oo_file\""
    if {[exists_and_not_null title]} {
	append command_parameter " -title \"$title\""
    }
    if {[exists_and_not_null item_id]} {
        append command_parameter " -item_id \"$item_id\""
    }
    if {[exists_and_not_null parent_id]} {
        append command_parameter " -parent_id $parent_id"
    }
    if {[info exists no_import_p]} {
	if {$no_import_p} {
	    append command_parameter " -no_import"
	}
    }
    if {[info exists return_pdf_p]} {
        if {$return_pdf_p} {
            append command_parameter " -return_pdf"
        }
    }          
    if {[info exists return_pdf_with_id_p]} {
        if {$return_pdf_with_id_p} {
            append command_parameter " -return_pdf_with_id"
        }
    }                 

    if {$force_jooconverter_p} {
	ns_log Notice "PDF conversion uses JooConverter(f): $oo_file"
	set command "contact::oo::import_oo_pdf_using_jooconverter"
    }

    if {$force_local_soffice_p} {
	ns_log Notice "PDF conversion uses local SOffice(f): $oo_file" 
	set command "contact::oo::import_oo_pdf_using_soffice"
	if {[info exists printer_name]} {
	    append command_parameter " -printer_name \"$printer_name\""
	}
    } 
    
    # no conversion was forced, now lets go for the parameter

    set webservice_url [parameter::get -parameter OORemoteConverter]
    if { $webservice_url ne ""} {
	ns_log Notice "PDF conversion uses Jooonverter(f): $oo_file"
	set command "contact::oo::import_oo_pdf_using_jooconverter -webservice_url $webservice_url"
    } else {
	set command "contact::oo::import_oo_pdf_using_soffice"
    }

    ns_log Notice "COMMAND:: $command"

    append command $command_parameter
    set result [eval $command]
    return $result   
}



#----------------------------------------------------------------------
# To use this function, you will need a full installation of JooConverter
# including Apache Tomcat, see http://jooreports.sourceforge.net/?q=jooconverter/guide
# To test if all components (including OpenOffice 2.0.3 or higher)
# will run, you can execute a wget call (with wget 1.10 or higher).
#----------------------------------------------------------------------
# This function will convert a source (file or data) to a PDF.
#----------------------------------------------------------------------
# 2006/10/31 Developed/Created by Cognovis/NFL
# 2006/11/01 Development continued by Cognovis/NFL
# 2006/11/02 Finished development of first version by Cognovis/NFL
#                                          currently under construction (BETA)
# 2006/11/06 Some test ns_log Notices remarked by Cognovis/NFL
#                                          currently testing state (BETA/GAMMA)
# 2006/11/07 All test ns_log Notices remarked (NFL)        (BETA/GAMMA)
# ... U.C./TEST
#----------------------------------------------------------------------


ad_proc -public contact::oo::convert_to_pdf_using_jooconverter {
    -source_type:required
    {-source_file}
    {-source_data}
    {-webservice_url "http://192.168.1.19"}
    {-timeout 30}
} {
    Converts a source (file or data) into PDF using the JooConverter running on Apache/Tomcat as a webservice.<br>
    <br>
    To use this function, you will need a full installation of JooConverter
    including Apache Tomcat, see http://jooreports.sourceforge.net/?q=jooconverter/guide<br>
    To test if all components (including OpenOffice 2.0.3 or higher)
    will run, you can execute a wget call (with wget 1.10 or higher).<br>
    <br>
    At this time this function supports converting from Text (source_type TXT), OpenOffice-Writer (source_type ODT)
    and Rich Text Format (source_type RTF) to the Portable Document Format (PDF).<br>
    <br>
    Either specify a fully qualified filename as source (source_file) or direct data (source_data). In case of a
    file, the function will read the content from the file.<br>
    <br>
    Specify webservice_url and timeout for your connection to your running JooConverver webservice (e.g.
    http://www.example.com:8080/converter/service)<br>
    <br>
    If everything runs fine, the function will return a PDF document. You can check this, if the returned value
    will start with %PDF- (e.g. %PDF-1.4 will indicate PDF version 1.4). If you get a different return value,
    an error is occured. Check this before you go on with further processing, e.g. saving the return value
    to a file.<br>
    <br>
    A simple example:<br>
    contact::oo::convert_to_pdf_using_jooconverter -source_type TXT -source_data "Hello world!"<br>
    will convert the given text "Hello world!" into a PDF using the default webservice_url.<br>
    
    @author Nils Lohse (nils.lohse@cognovis.de)
    @creation-date 31 October 2006

    @param source_file The full path to the file that containst the data to be exported as PDF.
    @param source_data If no source_filename is specified, you can put the source data here in.
    @param source_type The type of the source, could be ODT, TXT, ...
    @param webservice_url The URL running the JooConverter/ApacheTomcat webservice
    @param timeout Timeout in seconds for the JooC-Server

    @return PDF on success, other on error
} {
    set url "${webservice_url}/converter/service"
    if {![info exists source_file] && ![info exists source_data]} {
        error "Either -source_file or -source_data must be specified"
    }

    if {[info exists source_file]} {
        if {![file exists $source_file]} {
            error "Error reading file: $source_file not found"
        }

        if {![file readable $source_file]} {
            error "Error reading file: $source_file permission denied"
        }

        set fp [open $source_file]
        fconfigure $fp -translation binary
        set source_data [read $fp]
        close $fp
    }

    set content_type "text/plain"
    # if source_type is TXT, nothing will be changed. text/plain is default, too.
    if {$source_type == "ODT"} { set content_type "application/vnd.oasis.opendocument.text" }
    if {$source_type == "RTF"} { set content_type "text/rtf" }
    
    set r [::xo::HttpRequest new \
               -url $url \
	       -post_data $source_data \
	       -accept "application/pdf" \
	       -content_type "$content_type" \
	  ]
    return [$r set data]
}


ad_proc -public contact::oo::convert_to_pdf_using_jooconverter2 {
    -source_type:required
    {-source_file}
    {-source_data}
    {-webservice_url "http://192.168.1.19"}
    {-timeout 30}
} {
    Converts a source (file or data) into PDF using the JooConverter running on Apache/Tomcat as a webservice.<br>
    <br>
    To use this function, you will need a full installation of JooConverter
    including Apache Tomcat, see http://jooreports.sourceforge.net/?q=jooconverter/guide<br>
    To test if all components (including OpenOffice 2.0.3 or higher)
    will run, you can execute a wget call (with wget 1.10 or higher).<br>
    <br>
    At this time this function supports converting from Text (source_type TXT), OpenOffice-Writer (source_type ODT)
    and Rich Text Format (source_type RTF) to the Portable Document Format (PDF).<br>
    <br>
    Either specify a fully qualified filename as source (source_file) or direct data (source_data). In case of a
    file, the function will read the content from the file.<br>
    <br>
    Specify webservice_url and timeout for your connection to your running JooConverver webservice (e.g.
    http://www.example.com:8080/converter/service)<br>
    <br>
    If everything runs fine, the function will return a PDF document. You can check this, if the returned value
    will start with %PDF- (e.g. %PDF-1.4 will indicate PDF version 1.4). If you get a different return value,
    an error is occured. Check this before you go on with further processing, e.g. saving the return value
    to a file.<br>
    <br>
    A simple example:<br>
    contact::oo::convert_to_pdf_using_jooconverter -source_type TXT -source_data "Hello world!"<br>
    will convert the given text "Hello world!" into a PDF using the default webservice_url.<br>
    
    @author Nils Lohse (nils.lohse@cognovis.de)
    @creation-date 31 October 2006

    @param source_file The full path to the file that containst the data to be exported as PDF.
    @param source_data If no source_filename is specified, you can put the source data here in.
    @param source_type The type of the source, could be ODT, TXT, ...
    @param webservice_url The URL running the JooConverter/ApacheTomcat webservice
    @param timeout Timeout in seconds for the JooC-Server

    @return PDF on success, other on error
} {
    ns_log Notice "*** STARTING jooc"

    set method "POST"

    set url "${webservice_url}/converter/service"
    #set timeout 30
    set http_referer ""
    #nfl set formvars ""

    # sanity checks on switches given
    if {[info exists source_file] && [info exists source_data]} {
        error "Both -source_file and -source_data are mutually exclusive; can't use both"
    }
    if {![info exists source_file] && ![info exists source_data]} {
        error "Either -source_file or -source_data must be specified"
    }

    if {[info exists source_file]} {
        if {![file exists $source_file]} {
            error "Error reading file: $source_file not found"
        }

        if {![file readable $source_file]} {
            error "Error reading file: $source_file permission denied"
        }

        set fp [open $source_file]
        fconfigure $fp -translation binary
        set source_data [read $fp]
        close $fp
    }

    set content_type "text/plain"
    # if source_type is TXT, nothing will be changed. text/plain is default, too.
    if {$source_type == "ODT"} { set content_type "application/vnd.oasis.opendocument.text" }
    if {$source_type == "RTF"} { set content_type "text/rtf" }
    
    ns_log Notice "Calling JooConverter webservice at $url"
    
    #--- http open

    if { ![string match http://* $url] } {
        return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
    }
    set url [split $url /]
    set hp [split [lindex $url 2] :]
    set host [lindex $hp 0]
    set port [lindex $hp 1]
    if { [string match $port ""] } {set port 80}
    set uri /[join [lrange $url 3 end] /]
    set fds [ns_sockopen -nonblock $host $port]
    set rfd [lindex $fds 0]
    set wfd [lindex $fds 1]
    if { [catch {
        _ns_http_puts $timeout $wfd "$method $uri HTTP/1.1\r"
        _ns_http_puts $timeout $wfd "Host: $host\r"
	
        _ns_http_puts $timeout $wfd "Accept: application/pdf \r"
	
        if { $http_referer != ""} {
            _ns_http_puts $timeout $wfd "Referer: $http_referer \r"
        }
	
    } errMsg] } {
        global errorInfo
        #close $wfd
        #close $rfd
        if { [info exists rpset] } {ns_set free $rpset}
        #ns_log Notice "*** ERROR";
        # error schmeissen!
        #nfl return -1
    }
    #nfl return [list $rfd $wfd ""]
    set http [list $rfd $wfd ""]
    
    #--- http post
    
    #nfl ohne rqset, gibt's Standardheader! set http [util_httpopen POST $url "" $timeout $http_referer]
    #nfl - wie soll man so ein key/value_ns_set angeben? set http [util_httpopen POST $url [list "Accept" "application/pdf"] $timeout $http_referer]
    set rfd [lindex $http 0]
    set wfd [lindex $http 1]
    #ns_log Notice "*** http=$http"
    #ns_log Notice "*** rfd=$rfd"
    #ns_log Notice "*** wfd=$wfd"

    #headers necesary for a post and the form variables

    #_ns_http_puts $timeout $wfd "Content-type: text/plain \r"
    _ns_http_puts $timeout $wfd "Content-type: $content_type \r"
    _ns_http_puts $timeout $wfd "Content-length: [string length $source_data]\r"
    #ns_log Notice "*** content-length of source_data=[string length $source_data]"
    
    #nfl _ns_http_puts $timeout $wfd "Content-length: [string length $formvars]\r"
    #nfl _ns_http_puts $timeout $wfd \r
    #nfl _ns_http_puts $timeout $wfd "$formvars\r"
    #nfl _ns_http_puts $timeout $wfd "Accept: application/pdf \r"
    _ns_http_puts $timeout $wfd "\r"
    #_ns_http_puts $timeout $wfd "Hello world - a simple test text (not an ODT)\r"
    _ns_http_puts $timeout $wfd $source_data
    #ns_log Notice "*** source_data=$source_data"

    flush $wfd
    close $wfd

    set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
    #ns_log Notice "*** rpset=$rpset"
    while 1 {
	set line [_ns_http_gets $timeout $rfd]
	if { ![string length $line] } break
        ns_parseheader $rpset $line
        #ns_log Notice "*** line=$line"
    }
    
    set headers $rpset
    set response [ns_set name $headers]
    #ns_log Notice "*** response=$response"
    set status [lindex $response 1]
    #ns_log Notice "*** status=$status"
    ns_log Notice "JooConverter on Apache/Tomcat returns HTTP status $status: $response"
    if {$status == 302} {
	set location [ns_set iget $headers location]
	if {$location != ""} {
            ns_set free $headers
            close $rfd
	    return [util_httpget $location {}  $timeout $depth]
	}
    }
    set length [ns_set iget $headers content-length]
    #ns_log Notice "*** length=$length"
    set transfer_encoding [ns_set iget $headers transfer-encoding]
    #ns_log Notice "*** transfer_encoding=$transfer_encoding"
    if {$transfer_encoding=="chunked"} {
        # Transfer-Encoding: chunked
        # The transmission is chunked.
        # Chunk size <CR><LF> Message part <CR><LF>
        # End:0<CR><LF>
	# (2006/11/01/nfl) http://www.html-world.de/program/http_9.php
	# (2006/11/06/nfl) http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.6.1
	
        set PDF_document ""
	
	#set buf "(startvalue)"
	set buf "0"        
	set line "" 
        while 1 {
            # read chunk size
            while { $buf!=[format %c 13] && $buf!=[format %c 10] && $buf!="" && [string is xdigit -strict $buf]} {
                set buf [_ns_http_read $timeout $rfd 1]
                if {[string is xdigit -strict $buf]} { append line $buf }
		#if {[string is xdigit -strict $buf]} { ns_log Notice "+++ buf=$buf" } else { ns_log Notice "+++ buf is non xdigit!" }
            }
            #ns_log Notice "+++ line=|$line| buf=|$buf|"
            if {$line != ""} { set chunk_size [expr 0x$line] } else { set chunk_size 0 }
	    #ns_log Notice "+++ line to chunk_size=$chunk_size"
            if {$chunk_size == 0} { break }
            if {$buf == ""} { break }
            #if {$buf == "(startvalue)"} { break }
	    if {$line == ""} { break }
	  	    
            # read not needed CR/LF just in case
            while { $buf==[format %c 13] || $buf==[format %c 10]} {
                set buf [_ns_http_read $timeout $rfd 1]
                #ns_log Notice "+1+ buf=|$buf|"
            }
	    #ns_log Notice "+++ After first CR/LF-'overread'"
            if {$buf==""} {break}
	    
            # now buf should contain the first char of the chunk
            set chunk $buf
            append chunk [_ns_http_read $timeout $rfd [expr $chunk_size - 1]]
            append PDF_document $chunk
            #ns_log Notice "+++ chunk len=[string length $chunk]"
            #ns_log Notice "+++ PDFd. len=[string length $PDF_document]"
	  
	    # read not needed CR/LF just in case
	    set buf [format %c 13]
            while { $buf==[format %c 13] || $buf==[format %c 10]} {
                set buf [_ns_http_read $timeout $rfd 1]
                #ns_log Notice "+2+ buf=|$buf| ([contact::oo::get_ASCII_code -char $buf])"
            }
	    # now buf should contain the first char of the next chunk size!
	    if {[string is xdigit -strict $buf]} { set line $buf }
	    # ... and now continue the loop and read more of the chunk size, if exist
	    #ns_log Notice "+++ After second CR/LF-'overread'"

	    # TEST:
	    #set buf [_ns_http_read $timeout $rfd 20]
	    #ns_log Notice "+20 buf=$buf"
	    #break
        }
        #ns_log Notice "+++ finished loop"
	
        ns_set free $headers
        close $rfd
	
    } else {
        # do the usual stuff
	
        if { [string match "" $length] } {set length -1}
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { [string match "" $buf] } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
            # now we save the resulting PDF document in the variable PDF_document
            #ns_log Notice "*** page=$page"
            set PDF_document $page
        } errMsg]
        ns_set free $headers
        close $rfd
        if $err {
            global errorInfo
            return -code error -errorinfo $errorInfo $errMsg
        }
    }
    
    #ns_log Notice "*** ENDING jooc"
    return $PDF_document
}
#----------------------------------------------------------------------



#----------------------------------------------------------------------
# This function will convert a source (file or data) to a PDF file.
#----------------------------------------------------------------------
# 2006/11/01 Developed/Created by Cognovis/NFL
#----------------------------------------------------------------------
ad_proc -public contact::oo::convert_to_pdf_file_using_jooconverter {
    -destination_file:required
    {-source_file}
    {-source_data}
    {-source_type}
    {-webservice_url}
    {-timeout}
} {
    Converts a source (file or data) into PDF using the function contact::oo::convert_to_pdf_using_jooconverter
    (please read the documentation there) and saves the result to a file named as specified in destination_file.<br>
    <br>
    A simple example:<br>
    contact::oo::convert_to_pdf_file_using_jooconverter -source_type TXT -source_data "Hello world!" 
    -destination_file "/home/exampleuser/test.pdf"<br>
    will convert the given text "Hello world!" into a PDF file test.pdf in /home/exampleuser/
    using the default webservice_url.<br>
    <br>
    Returns 0 (FALSE) on an error and 1 (TRUE) on success.<br>

    @author Nils Lohse (nils.lohse@cognovis.de)
    @creation-date 1 November 2006

    @param destination_file The full path including the file name for the wanted output file.
    @param source_file The full path to the file that containst the data to be exported as PDF.
    @param source_data If no source_filename is specified, you can put the source data here in.
    @param source_type The type of the source, could be ODT, TXT, ...
    @param webservice_url The URL running the JooConverter/ApacheTomcat webservice
    @param timeout Timeout in seconds for the JooC-Server

    @return 0 on error, 1 on success
} {
    set command "contact::oo::convert_to_pdf_using_jooconverter"
    set command_parameter ""
    if {[info exists source_file]} {
	append command_parameter " -source_file \"$source_file\""
    }
    if {[info exists source_data]} {
        append command_parameter " -source_data \"$source_data\""
    }
    if {[info exists source_type]} {
        append command_parameter " -source_type $source_type"
    }
    if {[info exists webservice_url]} {
        append command_parameter " -webservice_url $webservice_url"
    }
    if {[info exists timeout]} {
        append command_parameter " -timeout $timeout"
    }
    ns_log Notice "**** command_parameter=$command_parameter"
    append command $command_parameter
    ns_log Notice "**** command=$command"

    set result [eval $command]
    ns_log Notice "**** result=$result"

    if {[string first "%PDF-" $result]==-1} {
	# an error occured, return 0 (FALSE)
	return 0 
    } else {
	# save the result to destination_file
	set fp [open $destination_file w]
        fconfigure $fp -translation binary
	puts -nonewline $fp $result
        close $fp

	# everything is fine, return 1 (TRUE)
	return 1
    }
}
#----------------------------------------------------------------------



#----------------------------------------------------------------------
# This function does the same as contact::oo::import_oo_pdf (same API)
# but it's using the JooConverter functions to convert into pdf.
#----------------------------------------------------------------------
# 2006/11/01 Developed/Created by Cognovis/NFL
# 2006/11/07 PDF-Check by Cognovis/MalteS.
#----------------------------------------------------------------------
ad_proc -public contact::oo::import_oo_pdf_using_jooconverter {
    -oo_file:required
    {-printer_name "pdfconv"}
    {-title ""}
    {-item_id ""}
    {-parent_id ""}
    {-webservice_url ""}
    {-no_import:boolean}
    {-return_pdf:boolean}
    {-return_pdf_with_id:boolean}
} {
    Imports an OpenOffice file (.sxw / .odt) as a PDF file into the content repository. If item_id is specified a new revision of that item is created, else a new item is created.<br>
    <br>
    This function does the same as contact::oo::import_oo_pdf (same API, that means same function call)
    but it's using the JooConverter functions to convert into PDF.<br>
    <br>
    The following parameters are not really used (and stay just here for compatibility reasons):<br>
    -printer_name<br>
    
    @param oo_file The full path to the OpenOffice file that contains the data to be exported as PDF.
    @param printer_name (NOT USED here: The name of the printer that is assigned as the PDF converter. Defaults to "pdfconv".)
    @param title Title which will be used for the resulting content item and file name if none was given in the item
    @param item_id The item_id of the content item to which the content should be associated.
    @param parent_id Needed to set the parent of this object
    @param no_import If this flag is specified the location of the generated PDF will be returned, but the pdf will not be stored in the content repository
    @param return_pdf If this flag is specified the location of the generated PDF will be returned and the PDF will be stored in the content repository (in contrast to "no_import"
    @param return_pdf_with_id Same as return_pdf but it will return a list with three elements: file_item_id, file_mime_type and pdf_filename
    @return item_id of the revision that contains the file
    @return file location of the file if "no_import" has been specified.

    @creation-date 1 November 2006
} {
    set destination_file "[file rootname $oo_file].pdf"
    set result [contact::oo::convert_to_pdf_file_using_jooconverter -destination_file $destination_file -source_file $oo_file -source_type ODT -webservice_url $webservice_url]


    #--- the following code is identical to contact::oo::import_oo_pdf (on 2006/11/01) ---
    
    # Strip the extension.
    set pdf_filename "[file rootname $oo_file].pdf"
    set mime_type "application/pdf"
    if {![file exists $pdf_filename]} {
	###############
	# this is a fix to use the oo file if pdf file could not be generated
	###############
	set pdf_filename $oo_file
	set mime_type "application/odt"
    } else {
	ns_unlink $oo_file
    }
    
    if {$no_import_p} {
	return [list $mime_type $pdf_filename]
    }
    
    set pdf_filesize [file size $pdf_filename]
    
    set file_name [file tail $pdf_filename]
    if {$title eq ""} {
	set title $file_name
    }
    
    if {[exists_and_not_null $item_id]} {
	set parent_id [get_parent -item_id $item_id]
	
	set revision_id [cr_import_content \
			     -title $title \
			     -item_id $item_id \
			     $parent_id \
			     $pdf_filename \
			     $pdf_filesize \
			     $mime_type \
			     $file_name ]
    } else {
	set revision_id [cr_import_content \
			     -title $title \
			     $parent_id \
			     $pdf_filename \
			     $pdf_filesize \
			     $mime_type \
			     $file_name ]
    }	
    
    
    content::item::set_live_revision -revision_id $revision_id
    if {$return_pdf_p} {
	return [list $mime_type $pdf_filename]
    } elseif {$return_pdf_with_id_p} {
	return [list [content::revision::item_id -revision_id $revision_id] $mime_type $pdf_filename]
    } else  {
#	ns_unlink $pdf_filename
	return [content::revision::item_id -revision_id $revision_id]
    }
}
#----------------------------------------------------------------------

