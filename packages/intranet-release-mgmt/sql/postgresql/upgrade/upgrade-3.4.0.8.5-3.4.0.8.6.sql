-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-release-mgmt/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');



SELECT im_category_new(27000, '0-Developing', 'Intranet Release Status',null);
SELECT im_category_new(27040, '1-Ready for Review', 'Intranet Release Status',null);
SELECT im_category_new(27050, '2-Ready for Integration', 'Intranet Release Status',null);
SELECT im_category_new(27060, '3-Ready for Integration Test', 'Intranet Release Status',null);
SELECT im_category_new(27070, '4-Ready for Acceptance Test', 'Intranet Release Status',null);
SELECT im_category_new(27085, '5-Ready for Production', 'Intranet Release Status',null);
SELECT im_category_new(27090, '6-Ready to be closed', 'Intranet Release Status',null);
SELECT im_category_new(27095, '7-Closed', 'Intranet Release Status',null);


--  category_id |            category
-- -------------+--------------------------------
--         4500 | 0 - Developing
--         4540 | 1 - Ready for Review
--         4550 | 2 - Ready for Integration
--         4560 | 3 - Ready for Integration Test
--         4570 | 4 - Ready for Acceptance Test
--         4585 | 5 - Ready for Production
--         4590 | 6 - Ready to be closed
--         4595 | 7 - Closed
--        27000 | 0-Developing
--        27040 | 1-Ready for Review
--        27050 | 2-Ready for Integration
--        27060 | 3-Ready for Integration Test
--        27070 | 4-Ready for Acceptance Test
--        27085 | 5-Ready for Production
--        27090 | 6-Ready to be closed
--        27095 | 7-Closed


update im_release_items set release_status_id = 27000 where release_status_id = 4500;
update im_release_items set release_status_id = 27040 where release_status_id = 4540;
update im_release_items set release_status_id = 27050 where release_status_id = 4550;
update im_release_items set release_status_id = 27060 where release_status_id = 4560;
update im_release_items set release_status_id = 27070 where release_status_id = 4570;
update im_release_items set release_status_id = 27085 where release_status_id = 4585;
update im_release_items set release_status_id = 27090 where release_status_id = 4590;
update im_release_items set release_status_id = 27095 where release_status_id = 4595;

delete	from im_categories
where	category_type = 'Intranet Release Status' and
	category_id between 4500 and 4599;
