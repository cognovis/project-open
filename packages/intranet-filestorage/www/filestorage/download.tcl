# /file-storage/download.tcl

ad_page_contract {
    see if this person is authorized to read the file in question
    guess the MIME type from the original client filename
    have the Oracle driver grab the BLOB and write it to the connection

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id download.tcl,v 3.4.2.3 2000/07/27 21:22:13 jwong Exp

    modified by randyg@arsdigita.com, January 2000 to use the general
    permissions module
} {
    file_name:notnull
    project_id:integer
}  -errors {
    file_name:notnull {No file was specified}
    project_id:integer {The project_id specified doesn't look like an integer.}
}

set user_id [ad_maybe_redirect_for_registration]
set project_path [im_filestorage_project_path $project_id]

set file "$project_path/$file_name"
set guessed_file_type [ns_guesstype $file]

ns_log notice "file_name=$file_name"
ns_log notice "file=$file"
ns_log notice "file_type=$guessed_file_type"


db_dml insert_action "
insert into im_fs_actions (
        action_type_id
        user_id
        action_date
        file_name
) values (
        [im_file_action_download],
        :user_id,
        now(),
        :file_name
)"


if [file readable $file] {
    ad_returnfile 200 $guessed_file_type $file
} else {
    ad_returnredirect "/error.tcl"
}
