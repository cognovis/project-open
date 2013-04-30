ad_page_contract {
    Backup
} {
    
}

set page_title "Backup"

set context [list $page_title]


set path "[acs_root_dir]/packages/monitoring/www/backup/"
set html ""
if [catch {
   set files [glob $path*.gz]
   foreach file [lsort $files] {
     append html "
       <tr>
         <td>  <a href=[file tail $file]>[file tail $file]</a> </td> <td> ([expr [file size $file] / 1000]k) </td> <td> [ns_fmttime [file mtime $file] "%d/%m/%Y - %H:%M:%S"] </td>
      </tr> 
      "
   }


} errmsg] {
	append html "<p>N� h�arquivos compactados .gz</p>"
	ns_log notice "$errmsg"
}


