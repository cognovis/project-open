set file_stub [file rootname [ad_conn file]]
set file_stub_2 [template::util::url_to_file other_name [ad_conn file]]
set key [ad_conn package_key]
set root_dir [acs_package_root_dir $key]
set root_dir_length [string length $root_dir]
set file_name [string replace $file_stub 0 [expr $root_dir_length + 4]]
set template_location "$root_dir/templates/first/$file_name"

ns_return 200 text/html "
File Stub: $file_stub<p>
Root Dir:$root_dir<p>
Trimmed Stub: $file_name<p>
Location: $template_location
"