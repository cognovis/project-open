-- Table: ad_monitoring_db

-- DROP TABLE ad_monitoring_db;

CREATE TABLE ad_monitoring_db
(
  db_id int4 NOT NULL,
  "timestamp" timestamptz DEFAULT ('now'::text)::timestamp(6) with time zone,
  timehour numeric(2),
  db_size numeric,
  size_content_repository numeric,
  CONSTRAINT ad_mntr_db_id_pk PRIMARY KEY (db_id)
) 
WITH OIDS;



-- Adicionar sequencia

CREATE SEQUENCE ad_monitoring_db_db_id
   INCREMENT 1
   START 58
   MINVALUE 1
   MAXVALUE 9223372036854775807
   CACHE 1;




-- Apagar as tabelas

DROP TABLE ad_monitoring_top_proc;
DROP TABLE ad_monitoring_top;


-- Criando tabelas com a opção ON DELETE CASCADE

CREATE TABLE ad_monitoring_top
(
  top_id int4 NOT NULL,
  "timestamp" timestamptz DEFAULT ('now'::text)::timestamp(6) with time zone,
  timehour numeric(2),
  load_avg_1 numeric,
  load_avg_5 numeric,
  load_avg_15 numeric,
  memory_real numeric,
  memory_free numeric,
  memory_swap_free numeric,
  memory_swap_in_use numeric,
  procs_total int4,
  procs_sleeping int4,
  procs_zombie int4,
  procs_stopped int4,
  procs_on_cpu int4,
  cpu_idle numeric,
  cpu_user numeric,
  cpu_kernel numeric,
  cpu_iowait numeric,
  cpu_swap numeric,
  CONSTRAINT ad_mntr_top_id_pk PRIMARY KEY (top_id)
) 
WITH OIDS;


-----------------------------------------------------

CREATE TABLE ad_monitoring_top_proc
(
  proc_id int4 NOT NULL,
  top_id int4 NOT NULL,
  pid int4 NOT NULL,
  username varchar(10) NOT NULL,
  threads int4,
  priority int4,
  nice int4,
  proc_size varchar(10),
  resident_memory varchar(10),
  state varchar(10),
  cpu_total_time varchar(10),
  cpu_pct float4,
  command varchar(30) NOT NULL,
  CONSTRAINT ad_mntr_top_proc_pk PRIMARY KEY (proc_id),
  CONSTRAINT ad_mntr_top_proc_top_id_fk FOREIGN KEY (top_id)
      REFERENCES ad_monitoring_top (top_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
) 
WITH OIDS;


------------------------------------------------------------------
