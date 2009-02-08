ad_page_contract {
    Get a file from the /tmp directory
} {
    filename
} 

# Protection if someone wants to move out of /tmp/ directory
regsub -all {\.\.} $filename {} filename

ns_returnfile 200 application/odt "/tmp/$filename"