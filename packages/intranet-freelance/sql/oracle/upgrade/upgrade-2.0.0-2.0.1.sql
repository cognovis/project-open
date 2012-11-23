

alter table im_freelancers add
	rec_source              varchar(400);

alter table im_freelancers add 
	rec_status_id           integer
                                constraint im_freelancers_rec_stat_fk
                                references im_categories;
alter table im_freelancers add
	rec_test_type           varchar(400);

alter table im_freelancers add 
	rec_test_result_id      integer
                                constraint im_freelancers_rec_test_fk
                                references im_categories;
