ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case acs_mail_trivial_smoke_test {
    Minimal smoke test.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # initialize random values
            set name [ad_generate_random_string]
            set name_2 [ad_generate_random_string]

            # there is no function in the api to directly retrieve a key
            # so instead we have to create a child of another and then
            # retrieve the parent's child

            set new_multipart_id [acs_mail_multipart_new     -multipart_kind mixed]

            aa_true "created a new multipart" [exists_and_not_null new_multipart_id]

            aa_true "verify that a multipart was created" [acs_mail_multipart_p $new_multipart_id]
            
            # would test that delete works but there's no relevant function in the API 
        }
}