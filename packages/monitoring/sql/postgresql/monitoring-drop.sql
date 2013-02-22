--
-- /packages/monitoring/sql/postgresql/monitoring-drop.sql
--
-- Monitoring drop script
--
-- @author Vinod Kurup (vinod@kurup.com)
-- @creation-date 2002-08-17
-- @cvs-id $Id: monitoring-drop.sql,v 1.1.1.2 2006/08/24 14:41:36 alessandrol Exp $
--

drop sequence ad_monitoring_tab_est_seq;
drop table ad_monitoring_tables_estimated;

drop sequence ad_monitoring_top_proc_proc_id;
drop table ad_monitoring_top_proc;

drop sequence ad_monitoring_top_top_id;
drop table ad_monitoring_top;

