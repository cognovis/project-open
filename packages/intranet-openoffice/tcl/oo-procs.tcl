ad_library {

    Support procs for the contacts package with regards to OpenOffice

    Before you can make use of these functions, OpenOffice 2.4 needs to be installed in your system. 
    Additionally you need ghostscript and the msttftcorefonts (so your users wont complain about wrong verdana fonts)

    @author Malte Sussdorff
    @creation-date 2006-04-18
}

namespace eval intranet_oo:: {}

ad_proc -public intranet_oo::convert {
    {-content}
} {
    Returns a string which we can insert into the content.xml file
    
    This is a replacement procedure which should hopefully deal with at least the breaks
    links and paragraphs. 
} {
    regsub -all -nocase "<br>" $content "<text:line-break/>" content
    regsub -all -nocase "<br >" $content "<text:line-break/>" content
    regsub -all -nocase "<p>" $content "<text:line-break/>" content
    regsub -all -nocase "&nbsp;" $content " " content
    regsub -all -nocase "</p>" $content "<text:line-break/>" content
    regsub -all -nocase "a href=" $content "text:a xlink:type=\"simple\" xlink:href=" content
    regsub -all -nocase "/a" $content "/text:a" content
    regsub -all -nocase "<ul>" $content "<text:list text:style-name=\"L1\">" content
    regsub -all -nocase "</ul>" $content "</text:list>" content
    regsub -all -nocase "<li>" $content "<text:list-item><text:p text:style-name=\"Standard\">" content
    regsub -all -nocase "</li>" $content "</text:p></text:list-item>" content
    regsub -all -nocase "&" $content "&amp;" content

    return [string trim $content]
}

ad_proc -public intranet_oo::jodconvert {
    {-oo_file:required}
    {-output_file:required}
} {
    Converts a file using jodconvert
} {

    set jodconverter_bin [parameter::get -parameter "jodconverterBin" -default "/usr/bin/jodconverter"]
    if {[file exists $jodconverter_bin]} { 
        set status [catch {eval exec $jodconverter_bin $oo_file $output_file} result]
        ns_log Debug "Using jodconverter"
    } else {
        set status [catch {exec -- /usr/bin/java -jar [acs_package_root_dir intranet-openoffice]/jodconverter/lib/jodconverter-cli-2.2.2.jar $oo_file $output_file} result]
    }
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
    
}

ad_proc -public intranet_oo::import_oo_pdf {
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

    # Do the conversion using jodconvert
    intranet_oo::jodconvert -oo_file $oo_file -output_file $pdf_filename

    set mime_type "application/pdf"
    if {![file exists $pdf_filename]} {
        # We could not generate the PDF, abort
        ad_return_error "Could not generate PDF" "We could not generate the PDF file. Please make sure that you have OpenOffice correctly setup and that the OpenOffice server is running. Contact your system administrator if in doubt"
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
        # ns_unlink $pdf_filename
        return [content::revision::item_id -revision_id $revision_id]
    }
}
    
ad_proc -public intranet_oo::join_pdf {
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
        #ns_unlink $pdf_filename
        return [content::revision::item_id -revision_id $revision_id]
    }
}
    

   
ad_proc -public intranet_oo::parse_content {
    -template_file_path:required
    {-output_filename ""}
    {-parent_id ""}
} {
    Extracts the provided document file template, parses it with variables found in the callers context and writes it back
    
    @param template_file_path The open-office file whose contents will be changed. This is the full path
    @param output_filename The output filename.
    @param parent_id The object_id of the parent where this file will be imported to. A new content revision will be created for this.

    @return The path to the new file.
} {
    # Deduct the filetype and output name
    set source_type [file extension $template_file_path]

    if {$output_filename ne ""} {
		set target_type [file extension $output_filename]
    } else {
		set target_type $source_type
		set output_filename [file tail $template_file_path]
    }
	
    # ------------------------------------------------
    # Create a temporary directory for our contents
    set odt_tmp_path [ns_tmpnam]
    ns_log Debug "view.tcl: odt_tmp_path=$odt_tmp_path"
    ns_mkdir $odt_tmp_path
    
    # The document 
    set odt_zip "${odt_tmp_path}${source_type}"
    set odt_content "${odt_tmp_path}/content.xml"
    set odt_styles "${odt_tmp_path}/styles.xml"

    # Create a copy of the template into the temporary dir
    ns_cp $template_file_path $odt_zip
    
    # Unzip the odt into the temorary directory
    exec unzip -d $odt_tmp_path $odt_zip 
    
    # ------------------------------------------------
    # Read the content.xml file
    set file [open $odt_content]
    fconfigure $file -encoding "utf-8"
    set odt_template_content [read $file]
    close $file

    # Perform replacements
    uplevel [list eval [template::adp_compile -string $odt_template_content]]
    upvar __adp_output content
    set content [intranet_oo::convert -content $content]
#    set content $__adp_output
    
    # Save the content to a file.
    set file [open $odt_content w]
    fconfigure $file -encoding "utf-8"
    puts $file $content
    flush $file
    close $file
    
    
    # ------------------------------------------------
    # Process the styles.xml file
    
    set file [open $odt_styles]
    fconfigure $file -encoding "utf-8"
    set style_content [read $file]
    close $file
    
    # Perform replacements
    uplevel [list eval [template::adp_compile -string $style_content]]
    upvar __adp_output style
    set style [intranet_oo::convert -content $style]

    # Save the content to a file.
    set file [open $odt_styles w]
    fconfigure $file -encoding "utf-8"
    puts $file $style
    flush $file
    close $file
    
    # ------------------------------------------------
    # Replace the files inside the odt file by the processed files
    
    # The zip -j command replaces the specified file in the zipfile 
    # which happens to be the OpenOffice File. 
    exec zip -j $odt_zip $odt_content
    exec zip -j $odt_zip $odt_styles
    switch $target_type {
        .pdf {
            if {$parent_id eq ""} {
                set import_doc [intranet_oo::import_oo_pdf -oo_file $odt_zip -no_import -return_pdf]
            } else {
                set import_doc [intranet_oo::import_oo_pdf -oo_file $odt_zip -parent_id $parent_id -return_pdf]
            }
            set return_file [lindex $import_doc 1]
            set mime_type "application/pdf"
        }
        .odt {
            set return_file $odt_zip
            set mime_type "application/odt"
        }
        .ods {
            set return_file $odt_zip
            set mime_type "application/ods"
        }
        .xls {
            set return_file "[file rootname $odt_zip].xls"
            intranet_oo::jodconvert -oo_file $odt_zip -output_file $return_file
            set mime_type "application/vnd.ms-excel"
        }
    }

    db_release_unused_handles
    
    # ------------------------------------------------
    # Return the file
    ns_log Debug "view.tcl: before returning file"
    set outputheaders [ns_conn outputheaders]
    ns_set cput $outputheaders "Content-Disposition" "attachment; filename=$output_filename"

    ns_returnfile 200 $mime_type $return_file
    
    # ------------------------------------------------
    # Delete the temporary files
    
    # delete other tmpfiles
    file delete -force $odt_tmp_path
    # ns_unlink "$return_file"
    ad_script_abort
}

ad_proc -public intranet_oo::change_content {
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


