ad_page_contract {
    Download file, convert it to pdf and return it
    
    @param url URL where to get the odt file from
} {
    url
} 

set page [lindex [ad_httpget -url "$url"] 1]
set oo_file [ns_tmpnam]
set file [open "$oo_file" w]
puts $file $page
flush $file
close $file

set status [catch {exec -- /bin/sh [acs_package_root_dir contacts]/bin/convert.sh $oo_file } result]

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
set pdf_filename "[file rootname $oo_file].pdf"
set mime_type "application/pdf"

if {![file exists $pdf_filename]} {
    ###############
    # this is a fix to use the oo file if pdf file could not be generated
    ###############
    set pdf_filename $oo_file
    set mime_type "application/odt"
}

ns_returnfile 200 $mime_type $pdf_filename

ns_unlink $oo_file
ns_unlink $pdf_filename