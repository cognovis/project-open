# footer for wiki pages shows edit, recent changes, search etc...
# show last modified

if {![exists_and_not_null edit_link_p]} {
    set edit_link_p "f"
}

if {![exists_and_not_null admin_p]} {
    set admin_p "f"
}

