DROP TABLE import_users;
CREATE TABLE import_users (
        email           text,
        username        text,
        first_names     text,
        last_name       text,
        group1          text,
        costs_day       text,
        costs_hour      text
);

COPY import_users (email, username, first_names, last_name, group1, costs_day, costs_hour) from stdin;
project_manager@champ.areo	PM2	SP	Project Manager	Skill Profile	1200.00	150.00
project_leader@champ.areo	PM1	SP	Project Leader	Skill Profile	900.00	112.50
project_administrator@champ.areo	PM1a	SP	Project Administrator	Skill Profile	500.00	62.50
solution_architect@champ.areo	SOLA	SP	Solution Architect	Skill Profile	1200.00	150.00
technical_architect@champ.areo	TECA	SP	Technical Architect	Skill Profile	1000.00	125.00
senior_implementation_consultant@champ.areo	IMPC3	SP	Senior Implementation Consultant 	Skill Profile	1200.00	150.00
implementation_consultant@champ.areo	IMPC2	SP	Implementation Consultant 	Skill Profile	900.00	112.50
junior_implementation_consultant@champ.areo	IMPC1	SP	Junior Implementation Consultant	Skill Profile	500.00	62.50
senior_cutover_consultant@champ.areo	CUTC3	SP	Senior Cutover Consultant	Skill Profile	1200.00	150.00
cutover_consultant@champ.areo	CUTC2	SP	Cutover Consultant 	Skill Profile	900.00	112.50
support_leader@champ.areo	SUP2	SP	Support Leader	Skill Profile	800.00	100.00
support_@champ.areo	SUP1	SP	Support 	Skill Profile	600.00	75.00
quallity_manager@champ.areo	QM	SP	Quallity Manager 	Skill Profile	800.00	100.00
lead_analyst_onshore@champ.areo	BUSA2	SP	Lead Analyst (onshore)	Skill Profile	1000.00	125.00
analyst_onshore@champ.areo	BUSA1	SP	Analyst (onshore)	Skill Profile	850.00	106.25
lead_developer_onshore@champ.areo	DEV3	SP	Lead Developer (onshore)	Skill Profile	750.00	93.75
developer_onshore@champ.areo	DEV2	SP	Developer (onshore)	Skill Profile	700.00	87.50
analyst_offshore@champ.areo	BUSA1 O/S	SP	Analyst (offshore)	Skill Profile	650.00	81.25
lead_developer_offshore@champ.areo	DEV3 O/S	SP	Lead Developer (offshore)	Skill Profile	350.00	43.75
developer_offshore@champ.areo	DEV2 O/S	SP	Developer (offshore)	Skill Profile	200.00	25.00
junior_developer_offshore@champ.areo	DEV1 O/S	SP	Junior Developer (offshore)	Skill Profile	150.00	18.75
lead_tester_onshore@champ.areo	TEST2	SP	Lead Tester (onshore)	Skill Profile	600.00	75.00
tester_onshore@champ.areo	TEST1	SP	Tester (onshore)	Skill Profile	500.00	62.50
lead_tester_offshore@champ.areo	TEST2 O/S	SP	Lead Tester (offshore)	Skill Profile	150.00	18.75
tester_offshore@champ.areo	TEST1 O/S	SP	Tester (offshore)	Skill Profile	350.00	43.75
principal_consultant_external@champ.areo	PCON2	SP	Principal Consultant External	Skill Profile	1500.00	187.50
principal_consultant_internal@champ.areo	PCON1	SP	Principal Consultant - Internal	Skill Profile	1350.00	168.75
lead_consultant@champ.areo	LCON	SP	Lead Consultant	Skill Profile	1250.00	156.25
business_consultant@champ.areo	BCON	SP	Business Consultant	Skill Profile	1100.00	137.50
consultant@champ.areo	CONS	SP	Consultant	Skill Profile	900.00	112.50
business_process_modeller/manager_senior@champ.areo	BPM2	SP	Business Process Modeller/Manager Senior	Skill Profile	1200.00	150.00
business_process_modeller@champ.areo	BPM1	SP	Business Process Modeller	Skill Profile	950.00	118.75
functional_sap_business_consultant_senior@champ.areo	SAPC2	SP	Functional SAP Business Consultant Senior	Skill Profile	1200.00	150.00
functional_sap_consultant@champ.areo	SAPC1	SP	Functional SAP Consultant	Skill Profile	950.00	118.75
technical_sap_consultant_senior@champ.areo	SAPT2	SP	Technical SAP Consultant Senior	Skill Profile	1200.00	150.00
technical_sap_consultant@champ.areo	SAPT1	SP	Technical SAP Consultant	Skill Profile	950.00	118.75
lead_bi_consultant@champ.areo	BICON2	SP	Lead BI Consultant	Skill Profile	1000.00	125.00
bi_consultant@champ.areo	BICON1	SP	BI Consultant	Skill Profile	800.00	100.00
training_consultant_generic_product@champ.areo	TCON	SP	Training Consultant (generic product)	Skill Profile	1000.00	125.00
sap_trainer@champ.areo	SAPC1a	SP	SAP Trainer	Skill Profile	900.00	112.50
bi_trainer@champ.areo	BICON1a	SP	BI Trainer	Skill Profile	950.00	118.75
cargospot_trainer_lead@champ.areo	TRNR2	SP	Cargospot Trainer (Lead)	Skill Profile	800.00	100.00
cargospot_trainer@champ.areo	TRNR1	SP	Cargospot Trainer	Skill Profile	700.00	87.50
manage_infrastructure_services@champ.areo	MGRIS	SP	Manage Infrastructure Services	Skill Profile	1000.00	125.00
lead_systems_engineer@champ.areo	SYSENG2	SP	Lead Systems Engineer	Skill Profile	850.00	106.25
systems_engineer@champ.areo	SYSENG1	SP	Systems Engineer	Skill Profile	700.00	87.50
lead_network_engineer@champ.areo	NETENG2	SP	Lead Network Engineer	Skill Profile	850.00	106.25
network_engineer@champ.areo	NETENG1	SP	Network Engineer	Skill Profile	700.00	87.50
team_leader_infrastructure_services@champ.areo	TLDRIS	SP	Team Leader Infrastructure Services	Skill Profile	850.00	106.25
service_desk@champ.areo	SDAGT	SP	Service Desk	Skill Profile	650.00	81.25
administrator@champ.areo	ADMIN	SP	Administrator	Skill Profile	400.00	50.00
director@champ.areo	BDIR	SP	Director	Skill Profile	1200.00	150.00
regional_service_head@champ.areo	HRSM	SP	Regional Service Head	Skill Profile	1200.00	150.00
regional_service_manager@champ.areo	RSM	SP	Regional Service Manager	Skill Profile	1200.00	150.00
service_manager@champ.areo	SM	SP	Service Manager	Skill Profile	800.00	100.00
\.

create or replace function lookup_user (varchar, varchar)
returns integer as '
DECLARE
        p_email         alias for $1;
        p_purpose       alias for $2;

        v_user_id       integer;
BEGIN
        IF p_email is null THEN return null; END IF;
        IF p_email = '''' THEN return null; END IF;

        SELECT  p.party_id INTO v_user_id
        FROM    parties p
        WHERE   lower(p.email) = lower(p_email);

        IF v_user_id is null THEN
                SELECT  u.user_id INTO v_user_id
                FROM    users u
                WHERE   lower(u.username) = lower(p_email);
        END IF;

        IF v_user_id is null AND p_email is not null THEN
                RAISE NOTICE ''lookup_user(%) for %: Did not find user'', p_email, p_purpose;
        END IF;

        RETURN v_user_id;
END;' language 'plpgsql';

create or replace function import_users ()
returns integer as '
DECLARE
        row             RECORD;
        v_user_id       integer;
        v_exists_p      integer;
        v_authority_id  integer;
        v_group_id      integer;
BEGIN
    FOR row IN
        select  *
        from import_users
    LOOP
        -- Check if the user already exists / has been imported already
        -- during the last run of this script
        select count(*) into v_exists_p from parties p
        where trim(lower(p.email)) = trim(lower(row.email));

        -- Create a new user if the user wasnt there
        IF v_exists_p = 0 THEN
                RAISE NOTICE ''Insert User: %'', row.email;
                v_user_id := acs__add_user(
                        null, ''user'', now(), 0, ''0.0.0.0'',
                        null, row.username, row.email, null,
                        row.first_names, row.last_name,
                        ''hashed_password'', ''salt'',
                        row.username, ''t'', ''approved''
                );
                INSERT INTO users_contact (user_id) VALUES (v_user_id);
                INSERT INTO im_employees (employee_id) VALUES (v_user_id);
        END IF;

        -- This is the main part of the import process, this part is
        -- executed for every line in the import_users table every time
        -- this script is executed.
        -- Update the users information, no matter whether its a new or
        -- an already existing user.
        v_user_id := lookup_user(row.email, ''import_users'');

        RAISE NOTICE ''Update User: %'', row.email;
        update users set
                        username = row.username
        where user_id = v_user_id;

        update persons set
                        first_names = row.first_names,
                        last_name = row.last_name
        where person_id = v_user_id;

        update parties set
                        url = null
        where party_id = v_user_id;

	-- Assign to group "Skill Profile"
        PERFORM im_profile_add_user(''Skill Profile'', v_user_id);

        update im_employees set
                        hourly_cost = row.costs_hour::numeric
        where employee_id = v_user_id;
	      
    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_users ();


-- ***************************************************************************************

create or replace function im_update_hourly_costs_based_on_skill_profiles ()
returns integer as '
DECLARE
        row             RECORD;
      v_hourly_cost   numeric;
    
   BEGIN
   FOR row IN
        select
                u.party_id,
              u.first_names,
              u.last_name,
              (select im_category_from_id(e.skill_role_id)) as category_name, 
              e.role_function_id
        from
                persons p,
                cc_users u
                LEFT JOIN im_employees e ON (u.party_id = e.employee_id)
                LEFT JOIN users_contact c ON (u.party_id = c.user_id),
                (select member_id from group_distinct_member_map m where group_id = ''463'') m
        where
                p.person_id = u.party_id
                and u.party_id = m.member_id
                and u.member_state = ''approved''
    LOOP

        RAISE NOTICE ''Updating user_id / first name / last_name: %,%,%'', row.party_id, row.first_names, row.last_name;
        RAISE NOTICE ''Updating role_function_id /category_name: %,%'', row.role_function_id, row.category_name;

        select  ee.hourly_cost 
        into        v_hourly_cost
        from        users uu
                LEFT JOIN im_employees ee ON (uu.user_id = ee.employee_id) 
        where   uu.username = row.category_name;

        RAISE NOTICE ''Found hourly_cost: %'', v_hourly_cost;
        
            update im_employees set
                         hourly_cost = v_hourly_cost::numeric
            where employee_id = row.party_id;
    END LOOP;
    RETURN 0;
END;' language 'plpgsql';

select im_update_hourly_costs_based_on_skill_profiles(); 



