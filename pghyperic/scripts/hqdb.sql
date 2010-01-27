--
-- PostgreSQL database dump
--

SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

CREATE ROLE hqadmin;
ALTER ROLE hqadmin WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN;
ALTER ROLE hqadmin PASSWORD 'hqadmin';

--
-- Name: "HQ"; Type: DATABASE; Schema: -; Owner: hqadmin
--

CREATE DATABASE "HQ" WITH TEMPLATE = template0;


ALTER DATABASE "HQ" OWNER TO hqadmin;

\connect "HQ"

SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: hqadmin
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: eam_action; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_action (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    classname character varying(200) NOT NULL,
    config bytea,
    parent_id integer,
    alert_definition_id integer,
    deleted boolean NOT NULL
);


ALTER TABLE public.eam_action OWNER TO hqadmin;

--
-- Name: eam_action_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_action_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_action_id_seq OWNER TO hqadmin;

--
-- Name: eam_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_action_id_seq', 10001, false);


--
-- Name: eam_agent; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_agent (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    address character varying(255) NOT NULL,
    port integer NOT NULL,
    authtoken character varying(100) NOT NULL,
    agenttoken character varying(100) NOT NULL,
    version character varying(20),
    ctime bigint,
    mtime bigint,
    unidirectional boolean NOT NULL,
    agent_type_id integer
);


ALTER TABLE public.eam_agent OWNER TO hqadmin;

--
-- Name: eam_agent_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_agent_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_agent_id_seq OWNER TO hqadmin;

--
-- Name: eam_agent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_agent_id_seq', 10001, false);


--
-- Name: eam_agent_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_agent_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(80),
    ctime bigint,
    mtime bigint
);


ALTER TABLE public.eam_agent_type OWNER TO hqadmin;

--
-- Name: eam_agent_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_agent_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_agent_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_agent_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_agent_type_id_seq', 10001, false);


--
-- Name: eam_ai_agent_report; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ai_agent_report (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    agent_id integer NOT NULL,
    report_time bigint NOT NULL,
    service_dirty boolean NOT NULL
);


ALTER TABLE public.eam_ai_agent_report OWNER TO hqadmin;

--
-- Name: eam_ai_agent_report_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_ai_agent_report_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_ai_agent_report_id_seq OWNER TO hqadmin;

--
-- Name: eam_ai_agent_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_ai_agent_report_id_seq', 10001, false);


--
-- Name: eam_aiq_ip; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_aiq_ip (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    aiq_platform_id integer,
    address character varying(64) NOT NULL,
    netmask character varying(64),
    mac_address character varying(64),
    queuestatus integer,
    diff bigint,
    ignored boolean,
    ctime bigint,
    mtime bigint
);


ALTER TABLE public.eam_aiq_ip OWNER TO hqadmin;

--
-- Name: eam_aiq_ip_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_aiq_ip_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_aiq_ip_id_seq OWNER TO hqadmin;

--
-- Name: eam_aiq_ip_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_aiq_ip_id_seq', 10001, false);


--
-- Name: eam_aiq_platform; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_aiq_platform (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(300),
    os character varying(80),
    osversion character varying(80),
    arch character varying(80),
    fqdn character varying(200) NOT NULL,
    agenttoken character varying(100) NOT NULL,
    certdn character varying(200),
    queuestatus integer,
    diff bigint,
    ignored boolean,
    ctime bigint,
    mtime bigint,
    lastapproved bigint,
    "location" character varying(100),
    cpu_speed integer,
    cpu_count integer,
    ram integer,
    gateway character varying(64),
    dhcp_server character varying(64),
    dns_server character varying(64),
    custom_properties bytea,
    product_config bytea,
    control_config bytea,
    measurement_config bytea
);


ALTER TABLE public.eam_aiq_platform OWNER TO hqadmin;

--
-- Name: eam_aiq_platform_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_aiq_platform_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_aiq_platform_id_seq OWNER TO hqadmin;

--
-- Name: eam_aiq_platform_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_aiq_platform_id_seq', 10001, false);


--
-- Name: eam_aiq_server; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_aiq_server (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    aiq_platform_id integer,
    autoinventoryidentifier character varying(255),
    name character varying(200) NOT NULL,
    description character varying(300),
    active character(1) DEFAULT 't'::bpchar,
    servertypename character varying(200) NOT NULL,
    installpath character varying(255),
    servicesautomanaged boolean,
    custom_properties bytea,
    product_config bytea,
    control_config bytea,
    responsetime_config bytea,
    measurement_config bytea,
    queuestatus integer,
    diff bigint,
    ignored boolean,
    ctime bigint,
    mtime bigint
);


ALTER TABLE public.eam_aiq_server OWNER TO hqadmin;

--
-- Name: eam_aiq_server_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_aiq_server_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_aiq_server_id_seq OWNER TO hqadmin;

--
-- Name: eam_aiq_server_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_aiq_server_id_seq', 10001, false);


--
-- Name: eam_aiq_service; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_aiq_service (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(200) NOT NULL,
    description character varying(300),
    servicetypename character varying(200) NOT NULL,
    queuestatus integer,
    diff bigint,
    ignored boolean,
    ctime bigint,
    mtime bigint,
    custom_properties bytea,
    product_config bytea,
    control_config bytea,
    measurement_config bytea,
    responsetime_config bytea,
    server_id integer NOT NULL
);


ALTER TABLE public.eam_aiq_service OWNER TO hqadmin;

--
-- Name: eam_aiq_service_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_aiq_service_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_aiq_service_id_seq OWNER TO hqadmin;

--
-- Name: eam_aiq_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_aiq_service_id_seq', 10001, false);


--
-- Name: eam_alert; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_alert (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    ctime bigint NOT NULL,
    fixed boolean NOT NULL,
    alert_definition_id integer NOT NULL
);


ALTER TABLE public.eam_alert OWNER TO hqadmin;

--
-- Name: eam_alert_action_log; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_alert_action_log (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    detail character varying(500) NOT NULL,
    alert_id integer,
    alert_type integer NOT NULL,
    action_id integer,
    subject_id integer
);


ALTER TABLE public.eam_alert_action_log OWNER TO hqadmin;

--
-- Name: eam_alert_action_log_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_alert_action_log_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_alert_action_log_id_seq OWNER TO hqadmin;

--
-- Name: eam_alert_action_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_alert_action_log_id_seq', 10001, false);


--
-- Name: eam_alert_condition; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_alert_condition (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    "type" integer NOT NULL,
    required boolean NOT NULL,
    measurement_id integer,
    name character varying(100),
    comparator character varying(2),
    threshold double precision,
    option_status character varying(25),
    alert_definition_id integer,
    trigger_id integer
);


ALTER TABLE public.eam_alert_condition OWNER TO hqadmin;

--
-- Name: eam_alert_condition_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_alert_condition_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_alert_condition_id_seq OWNER TO hqadmin;

--
-- Name: eam_alert_condition_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_alert_condition_id_seq', 10001, false);


--
-- Name: eam_alert_condition_log; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_alert_condition_log (
    id integer NOT NULL,
    value character varying(250),
    alert_id integer,
    condition_id integer
);


ALTER TABLE public.eam_alert_condition_log OWNER TO hqadmin;

--
-- Name: eam_alert_condition_log_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_alert_condition_log_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_alert_condition_log_id_seq OWNER TO hqadmin;

--
-- Name: eam_alert_condition_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_alert_condition_log_id_seq', 10001, false);


--
-- Name: eam_alert_def_state; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_alert_def_state (
    alert_definition_id integer NOT NULL,
    last_fired bigint NOT NULL
);


ALTER TABLE public.eam_alert_def_state OWNER TO hqadmin;

--
-- Name: eam_alert_definition; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_alert_definition (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    ctime bigint NOT NULL,
    mtime bigint NOT NULL,
    parent_id integer,
    description character varying(250),
    priority integer NOT NULL,
    active boolean NOT NULL,
    enabled boolean NOT NULL,
    frequency_type integer NOT NULL,
    count bigint,
    trange bigint,
    will_recover boolean NOT NULL,
    notify_filtered boolean NOT NULL,
    control_filtered boolean NOT NULL,
    deleted boolean NOT NULL,
    escalation_id integer,
    resource_id integer
);


ALTER TABLE public.eam_alert_definition OWNER TO hqadmin;

--
-- Name: eam_alert_definition_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_alert_definition_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_alert_definition_id_seq OWNER TO hqadmin;

--
-- Name: eam_alert_definition_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_alert_definition_id_seq', 10001, false);


--
-- Name: eam_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_alert_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_alert_id_seq OWNER TO hqadmin;

--
-- Name: eam_alert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_alert_id_seq', 10001, false);


--
-- Name: eam_app_service; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_app_service (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    service_id integer,
    group_id integer,
    application_id integer,
    isgroup boolean NOT NULL,
    ctime bigint,
    mtime bigint,
    modified_by character varying(100),
    fentry_point boolean NOT NULL,
    service_type_id integer
);


ALTER TABLE public.eam_app_service OWNER TO hqadmin;

--
-- Name: eam_app_service_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_app_service_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_app_service_id_seq OWNER TO hqadmin;

--
-- Name: eam_app_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_app_service_id_seq', 10001, false);


--
-- Name: eam_app_type_service_type_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_app_type_service_type_map (
    application_type_id integer NOT NULL,
    service_type_id integer NOT NULL
);


ALTER TABLE public.eam_app_type_service_type_map OWNER TO hqadmin;

--
-- Name: eam_application; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_application (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    cid integer,
    description character varying(500),
    ctime bigint,
    mtime bigint,
    modified_by character varying(100),
    "location" character varying(100),
    eng_contact character varying(100),
    ops_contact character varying(100),
    bus_contact character varying(100),
    application_type_id integer NOT NULL,
    resource_id integer
);


ALTER TABLE public.eam_application OWNER TO hqadmin;

--
-- Name: eam_application_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_application_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_application_id_seq OWNER TO hqadmin;

--
-- Name: eam_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_application_id_seq', 10001, false);


--
-- Name: eam_application_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_application_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(200) NOT NULL,
    sort_name character varying(200),
    cid integer,
    description character varying(200),
    ctime bigint,
    mtime bigint
);


ALTER TABLE public.eam_application_type OWNER TO hqadmin;

--
-- Name: eam_application_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_application_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_application_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_application_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_application_type_id_seq', 10001, false);


--
-- Name: eam_audit; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_audit (
    id integer NOT NULL,
    klazz character varying(255) NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint NOT NULL,
    nature integer NOT NULL,
    purpose integer NOT NULL,
    importance integer NOT NULL,
    original boolean NOT NULL,
    field character varying(100),
    old_val character varying(1000),
    new_val character varying(1000),
    message character varying(1000) NOT NULL,
    parent_id integer,
    resource_id integer NOT NULL,
    subject_id integer NOT NULL
);


ALTER TABLE public.eam_audit OWNER TO hqadmin;

--
-- Name: eam_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_audit_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_audit_id_seq OWNER TO hqadmin;

--
-- Name: eam_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_audit_id_seq', 10001, false);


--
-- Name: eam_autoinv_history; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_autoinv_history (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    group_id integer,
    batch_id integer,
    entity_type integer NOT NULL,
    entity_id integer NOT NULL,
    subject character varying(32) NOT NULL,
    scheduled boolean NOT NULL,
    date_scheduled bigint NOT NULL,
    starttime bigint NOT NULL,
    status character varying(64) NOT NULL,
    endtime bigint NOT NULL,
    duration bigint NOT NULL,
    scanname character varying(100),
    scandesc character varying(200),
    description character varying(500),
    message character varying(500),
    config bytea NOT NULL
);


ALTER TABLE public.eam_autoinv_history OWNER TO hqadmin;

--
-- Name: eam_autoinv_history_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_autoinv_history_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_autoinv_history_id_seq OWNER TO hqadmin;

--
-- Name: eam_autoinv_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_autoinv_history_id_seq', 10001, false);


--
-- Name: eam_autoinv_schedule; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_autoinv_schedule (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    entity_id integer NOT NULL,
    entity_type integer NOT NULL,
    subject character varying(32) NOT NULL,
    schedulevaluebytes bytea,
    nextfiretime bigint NOT NULL,
    triggername character varying(128) NOT NULL,
    jobname character varying(128) NOT NULL,
    job_order_data character varying(500),
    scanname character varying(100),
    scandesc character varying(200),
    config bytea
);


ALTER TABLE public.eam_autoinv_schedule OWNER TO hqadmin;

--
-- Name: eam_autoinv_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_autoinv_schedule_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_autoinv_schedule_id_seq OWNER TO hqadmin;

--
-- Name: eam_autoinv_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_autoinv_schedule_id_seq', 10001, false);


--
-- Name: eam_calendar; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_calendar (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.eam_calendar OWNER TO hqadmin;

--
-- Name: eam_calendar_ent; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_calendar_ent (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    calendar_id integer NOT NULL
);


ALTER TABLE public.eam_calendar_ent OWNER TO hqadmin;

--
-- Name: eam_calendar_ent_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_calendar_ent_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_calendar_ent_id_seq OWNER TO hqadmin;

--
-- Name: eam_calendar_ent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_calendar_ent_id_seq', 10001, false);


--
-- Name: eam_calendar_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_calendar_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_calendar_id_seq OWNER TO hqadmin;

--
-- Name: eam_calendar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_calendar_id_seq', 10001, false);


--
-- Name: eam_calendar_week; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_calendar_week (
    calendar_week_id integer NOT NULL,
    weekday integer NOT NULL,
    starttime integer NOT NULL,
    endtime integer NOT NULL
);


ALTER TABLE public.eam_calendar_week OWNER TO hqadmin;

--
-- Name: eam_config_props; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_config_props (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    prefix character varying(80),
    propkey character varying(80),
    propvalue character varying(300),
    default_propvalue character varying(300),
    fread_only boolean
);


ALTER TABLE public.eam_config_props OWNER TO hqadmin;

--
-- Name: eam_config_props_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_config_props_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_config_props_id_seq OWNER TO hqadmin;

--
-- Name: eam_config_props_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_config_props_id_seq', 10001, false);


--
-- Name: eam_config_response; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_config_response (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    product_response bytea,
    control_response bytea,
    measurement_response bytea,
    autoinventory_response bytea,
    response_time_response bytea,
    usermanaged boolean NOT NULL,
    validationerr character varying(512)
);


ALTER TABLE public.eam_config_response OWNER TO hqadmin;

--
-- Name: eam_config_response_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_config_response_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_config_response_id_seq OWNER TO hqadmin;

--
-- Name: eam_config_response_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_config_response_id_seq', 10001, false);


--
-- Name: eam_control_history; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_control_history (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    group_id integer,
    batch_id integer,
    entity_type integer NOT NULL,
    entity_id integer NOT NULL,
    subject character varying(32) NOT NULL,
    scheduled boolean NOT NULL,
    date_scheduled bigint NOT NULL,
    starttime bigint NOT NULL,
    status character varying(64) NOT NULL,
    endtime bigint NOT NULL,
    description character varying(500),
    message character varying(500),
    "action" character varying(32) NOT NULL,
    args character varying(500)
);


ALTER TABLE public.eam_control_history OWNER TO hqadmin;

--
-- Name: eam_control_history_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_control_history_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_control_history_id_seq OWNER TO hqadmin;

--
-- Name: eam_control_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_control_history_id_seq', 10001, false);


--
-- Name: eam_control_schedule; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_control_schedule (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    entity_id integer NOT NULL,
    entity_type integer NOT NULL,
    subject character varying(32) NOT NULL,
    schedulevaluebytes bytea NOT NULL,
    nextfiretime bigint NOT NULL,
    triggername character varying(128) NOT NULL,
    jobname character varying(128) NOT NULL,
    job_order_data character varying(500),
    "action" character varying(32) NOT NULL
);


ALTER TABLE public.eam_control_schedule OWNER TO hqadmin;

--
-- Name: eam_control_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_control_schedule_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_control_schedule_id_seq OWNER TO hqadmin;

--
-- Name: eam_control_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_control_schedule_id_seq', 10001, false);


--
-- Name: eam_cprop; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_cprop (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    appdef_id integer NOT NULL,
    keyid integer NOT NULL,
    value_idx integer NOT NULL,
    propvalue character varying(1000) NOT NULL
);


ALTER TABLE public.eam_cprop OWNER TO hqadmin;

--
-- Name: eam_cprop_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_cprop_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_cprop_id_seq OWNER TO hqadmin;

--
-- Name: eam_cprop_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_cprop_id_seq', 10001, false);


--
-- Name: eam_cprop_key; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_cprop_key (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    appdef_type integer NOT NULL,
    appdef_typeid integer NOT NULL,
    propkey character varying(100) NOT NULL,
    description character varying(200) NOT NULL
);


ALTER TABLE public.eam_cprop_key OWNER TO hqadmin;

--
-- Name: eam_cprop_key_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_cprop_key_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_cprop_key_id_seq OWNER TO hqadmin;

--
-- Name: eam_cprop_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_cprop_key_id_seq', 10001, false);


--
-- Name: eam_crispo; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_crispo (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.eam_crispo OWNER TO hqadmin;

--
-- Name: eam_crispo_array; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_crispo_array (
    opt_id integer NOT NULL,
    val character varying(4000) NOT NULL,
    idx integer NOT NULL
);


ALTER TABLE public.eam_crispo_array OWNER TO hqadmin;

--
-- Name: eam_crispo_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_crispo_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_crispo_id_seq OWNER TO hqadmin;

--
-- Name: eam_crispo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_crispo_id_seq', 10001, false);


--
-- Name: eam_crispo_opt; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_crispo_opt (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    propkey character varying(255) NOT NULL,
    val character varying(4000),
    crispo_id integer NOT NULL
);


ALTER TABLE public.eam_crispo_opt OWNER TO hqadmin;

--
-- Name: eam_crispo_opt_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_crispo_opt_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_crispo_opt_id_seq OWNER TO hqadmin;

--
-- Name: eam_crispo_opt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_crispo_opt_id_seq', 10001, false);


--
-- Name: eam_criteria; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_criteria (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    list_index integer NOT NULL,
    resource_group_id integer NOT NULL,
    klazz character varying(256) NOT NULL,
    string_prop character varying(1024),
    date_prop bigint,
    resource_id_prop integer,
    numeric_prop numeric(24,5),
    enum_prop integer
);


ALTER TABLE public.eam_criteria OWNER TO hqadmin;

--
-- Name: eam_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_criteria_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_criteria_id_seq OWNER TO hqadmin;

--
-- Name: eam_criteria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_criteria_id_seq', 10001, false);


--
-- Name: eam_dash_config; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_dash_config (
    id integer NOT NULL,
    config_type character varying(255) NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    crispo_id integer NOT NULL,
    role_id integer,
    user_id integer
);


ALTER TABLE public.eam_dash_config OWNER TO hqadmin;

--
-- Name: eam_dash_config_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_dash_config_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_dash_config_id_seq OWNER TO hqadmin;

--
-- Name: eam_dash_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_dash_config_id_seq', 10001, false);


--
-- Name: eam_error_code; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_error_code (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    code integer NOT NULL,
    description character varying(64) NOT NULL
);


ALTER TABLE public.eam_error_code OWNER TO hqadmin;

--
-- Name: eam_error_code_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_error_code_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_error_code_id_seq OWNER TO hqadmin;

--
-- Name: eam_error_code_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_error_code_id_seq', 10001, false);


--
-- Name: eam_escalation; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_escalation (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(200) NOT NULL,
    description character varying(250),
    allow_pause boolean NOT NULL,
    max_wait_time bigint NOT NULL,
    notify_all boolean NOT NULL,
    ctime bigint NOT NULL,
    mtime bigint NOT NULL,
    frepeat boolean NOT NULL
);


ALTER TABLE public.eam_escalation OWNER TO hqadmin;

--
-- Name: eam_escalation_action; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_escalation_action (
    escalation_id integer NOT NULL,
    wait_time bigint NOT NULL,
    action_id integer NOT NULL,
    idx integer NOT NULL
);


ALTER TABLE public.eam_escalation_action OWNER TO hqadmin;

--
-- Name: eam_escalation_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_escalation_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_escalation_id_seq OWNER TO hqadmin;

--
-- Name: eam_escalation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_escalation_id_seq', 10001, false);


--
-- Name: eam_escalation_state; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_escalation_state (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    next_action_idx integer NOT NULL,
    next_action_time bigint NOT NULL,
    escalation_id integer NOT NULL,
    alert_def_id integer NOT NULL,
    alert_id integer NOT NULL,
    alert_type integer NOT NULL,
    acknowledged_by integer
);


ALTER TABLE public.eam_escalation_state OWNER TO hqadmin;

--
-- Name: eam_escalation_state_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_escalation_state_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_escalation_state_id_seq OWNER TO hqadmin;

--
-- Name: eam_escalation_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_escalation_state_id_seq', 10001, false);


--
-- Name: eam_event_log; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_event_log (
    id integer NOT NULL,
    detail character varying(4000) NOT NULL,
    "type" character varying(100) NOT NULL,
    "timestamp" bigint NOT NULL,
    resource_id integer NOT NULL,
    subject character varying(100),
    status character varying(100),
    instance_id integer
);


ALTER TABLE public.eam_event_log OWNER TO hqadmin;

--
-- Name: eam_event_log_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_event_log_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_event_log_id_seq OWNER TO hqadmin;

--
-- Name: eam_event_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_event_log_id_seq', 10001, false);


--
-- Name: eam_exec_strategies; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_exec_strategies (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    def_id integer NOT NULL,
    config_id integer NOT NULL,
    partition integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE public.eam_exec_strategies OWNER TO hqadmin;

--
-- Name: eam_exec_strategies_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_exec_strategies_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_exec_strategies_id_seq OWNER TO hqadmin;

--
-- Name: eam_exec_strategies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_exec_strategies_id_seq', 10001, false);


--
-- Name: eam_exec_strategy_types; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_exec_strategy_types (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    type_class character varying(255) NOT NULL
);


ALTER TABLE public.eam_exec_strategy_types OWNER TO hqadmin;

--
-- Name: eam_exec_strategy_types_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_exec_strategy_types_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_exec_strategy_types_id_seq OWNER TO hqadmin;

--
-- Name: eam_exec_strategy_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_exec_strategy_types_id_seq', 10001, false);


--
-- Name: eam_galert_action_log; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_galert_action_log (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    detail character varying(1024) NOT NULL,
    galert_id integer NOT NULL,
    alert_type integer NOT NULL,
    action_id integer,
    subject_id integer
);


ALTER TABLE public.eam_galert_action_log OWNER TO hqadmin;

--
-- Name: eam_galert_action_log_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_galert_action_log_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_galert_action_log_id_seq OWNER TO hqadmin;

--
-- Name: eam_galert_action_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_galert_action_log_id_seq', 10001, false);


--
-- Name: eam_galert_aux_logs; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_galert_aux_logs (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    "timestamp" bigint NOT NULL,
    auxtype integer NOT NULL,
    description character varying(255) NOT NULL,
    galert_id integer NOT NULL,
    parent integer,
    def_id integer NOT NULL
);


ALTER TABLE public.eam_galert_aux_logs OWNER TO hqadmin;

--
-- Name: eam_galert_aux_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_galert_aux_logs_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_galert_aux_logs_id_seq OWNER TO hqadmin;

--
-- Name: eam_galert_aux_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_galert_aux_logs_id_seq', 10001, false);


--
-- Name: eam_galert_defs; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_galert_defs (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    descr character varying(255),
    severity integer NOT NULL,
    enabled boolean NOT NULL,
    ctime bigint NOT NULL,
    mtime bigint NOT NULL,
    deleted boolean NOT NULL,
    last_fired bigint,
    group_id integer NOT NULL,
    escalation_id integer
);


ALTER TABLE public.eam_galert_defs OWNER TO hqadmin;

--
-- Name: eam_galert_defs_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_galert_defs_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_galert_defs_id_seq OWNER TO hqadmin;

--
-- Name: eam_galert_defs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_galert_defs_id_seq', 10001, false);


--
-- Name: eam_galert_logs; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_galert_logs (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    "timestamp" bigint NOT NULL,
    fixed boolean NOT NULL,
    def_id integer NOT NULL,
    short_reason character varying(256) NOT NULL,
    long_reason character varying(2048) NOT NULL,
    partition integer NOT NULL
);


ALTER TABLE public.eam_galert_logs OWNER TO hqadmin;

--
-- Name: eam_galert_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_galert_logs_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_galert_logs_id_seq OWNER TO hqadmin;

--
-- Name: eam_galert_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_galert_logs_id_seq', 10001, false);


--
-- Name: eam_gtrigger_types; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_gtrigger_types (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    type_class character varying(255) NOT NULL
);


ALTER TABLE public.eam_gtrigger_types OWNER TO hqadmin;

--
-- Name: eam_gtrigger_types_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_gtrigger_types_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_gtrigger_types_id_seq OWNER TO hqadmin;

--
-- Name: eam_gtrigger_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_gtrigger_types_id_seq', 10001, false);


--
-- Name: eam_gtriggers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_gtriggers (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    config_id integer NOT NULL,
    type_id integer NOT NULL,
    strat_id integer NOT NULL,
    lidx integer NOT NULL
);


ALTER TABLE public.eam_gtriggers OWNER TO hqadmin;

--
-- Name: eam_gtriggers_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_gtriggers_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_gtriggers_id_seq OWNER TO hqadmin;

--
-- Name: eam_gtriggers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_gtriggers_id_seq', 10001, false);


--
-- Name: eam_ip; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ip (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    platform_id integer NOT NULL,
    address character varying(64) NOT NULL,
    netmask character varying(64),
    mac_address character varying(64),
    ctime bigint,
    mtime bigint,
    cid integer
);


ALTER TABLE public.eam_ip OWNER TO hqadmin;

--
-- Name: eam_ip_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_ip_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_ip_id_seq OWNER TO hqadmin;

--
-- Name: eam_ip_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_ip_id_seq', 10001, false);


--
-- Name: eam_measurement; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    instance_id integer NOT NULL,
    template_id integer NOT NULL,
    mtime bigint NOT NULL,
    enabled boolean NOT NULL,
    coll_interval bigint NOT NULL,
    dsn character varying(2048) NOT NULL,
    resource_id integer
);


ALTER TABLE public.eam_measurement OWNER TO hqadmin;

--
-- Name: eam_measurement_bl; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement_bl (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    measurement_id integer,
    compute_time bigint NOT NULL,
    user_entered boolean NOT NULL,
    mean double precision,
    min_expected_val double precision,
    max_expected_val double precision
);


ALTER TABLE public.eam_measurement_bl OWNER TO hqadmin;

--
-- Name: eam_measurement_bl_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_measurement_bl_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_measurement_bl_id_seq OWNER TO hqadmin;

--
-- Name: eam_measurement_bl_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_measurement_bl_id_seq', 10001, false);


--
-- Name: eam_measurement_cat; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement_cat (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.eam_measurement_cat OWNER TO hqadmin;

--
-- Name: eam_measurement_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_measurement_cat_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_measurement_cat_id_seq OWNER TO hqadmin;

--
-- Name: eam_measurement_cat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_measurement_cat_id_seq', 10001, false);


--
-- Name: eam_measurement_data_1d; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement_data_1d (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5),
    "minvalue" numeric(24,5),
    "maxvalue" numeric(24,5)
);


ALTER TABLE public.eam_measurement_data_1d OWNER TO hqadmin;

--
-- Name: eam_measurement_data_1h; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement_data_1h (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5),
    "minvalue" numeric(24,5),
    "maxvalue" numeric(24,5)
);


ALTER TABLE public.eam_measurement_data_1h OWNER TO hqadmin;

--
-- Name: eam_measurement_data_6h; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement_data_6h (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5),
    "minvalue" numeric(24,5),
    "maxvalue" numeric(24,5)
);


ALTER TABLE public.eam_measurement_data_6h OWNER TO hqadmin;

--
-- Name: eam_measurement_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_measurement_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_measurement_id_seq OWNER TO hqadmin;

--
-- Name: eam_measurement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_measurement_id_seq', 10001, false);


--
-- Name: eam_measurement_templ; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_measurement_templ (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    alias character varying(100) NOT NULL,
    units character varying(50) NOT NULL,
    collection_type integer DEFAULT 0 NOT NULL,
    default_on boolean NOT NULL,
    default_interval bigint DEFAULT 60000 NOT NULL,
    designate boolean NOT NULL,
    "template" character varying(800) NOT NULL,
    plugin character varying(250) NOT NULL,
    ctime bigint NOT NULL,
    mtime bigint NOT NULL,
    monitorable_type_id integer NOT NULL,
    category_id integer NOT NULL
);


ALTER TABLE public.eam_measurement_templ OWNER TO hqadmin;

--
-- Name: eam_measurement_templ_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_measurement_templ_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_measurement_templ_id_seq OWNER TO hqadmin;

--
-- Name: eam_measurement_templ_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_measurement_templ_id_seq', 10001, false);


--
-- Name: eam_metric_aux_log_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_metric_aux_log_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_metric_aux_log_id_seq OWNER TO hqadmin;

--
-- Name: eam_metric_aux_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_metric_aux_log_id_seq', 10001, false);


--
-- Name: eam_metric_aux_logs; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_metric_aux_logs (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    aux_log_id integer NOT NULL,
    metric_id integer NOT NULL,
    def_id integer NOT NULL
);


ALTER TABLE public.eam_metric_aux_logs OWNER TO hqadmin;

--
-- Name: eam_metric_prob; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_metric_prob (
    measurement_id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    additional integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    "type" integer NOT NULL
);


ALTER TABLE public.eam_metric_prob OWNER TO hqadmin;

--
-- Name: eam_monitorable_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_monitorable_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    appdef_type integer NOT NULL,
    plugin character varying(250) NOT NULL
);


ALTER TABLE public.eam_monitorable_type OWNER TO hqadmin;

--
-- Name: eam_monitorable_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_monitorable_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_monitorable_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_monitorable_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_monitorable_type_id_seq', 10001, false);


--
-- Name: eam_numbers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_numbers (
    i bigint NOT NULL
);


ALTER TABLE public.eam_numbers OWNER TO hqadmin;

--
-- Name: eam_operation; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_operation (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    resource_type_id integer
);


ALTER TABLE public.eam_operation OWNER TO hqadmin;

--
-- Name: eam_operation_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_operation_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_operation_id_seq OWNER TO hqadmin;

--
-- Name: eam_operation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_operation_id_seq', 10001, false);


--
-- Name: eam_platform; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_platform (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    fqdn character varying(200) NOT NULL,
    certdn character varying(200),
    cid integer,
    description character varying(256),
    ctime bigint,
    mtime bigint,
    modified_by character varying(100),
    "location" character varying(100),
    comment_text character varying(256),
    cpu_count integer,
    platform_type_id integer NOT NULL,
    config_response_id integer,
    agent_id integer,
    resource_id integer
);


ALTER TABLE public.eam_platform OWNER TO hqadmin;

--
-- Name: eam_platform_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_platform_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_platform_id_seq OWNER TO hqadmin;

--
-- Name: eam_platform_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_platform_id_seq', 10001, false);


--
-- Name: eam_platform_server_type_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_platform_server_type_map (
    platform_type_id integer NOT NULL,
    server_type_id integer NOT NULL
);


ALTER TABLE public.eam_platform_server_type_map OWNER TO hqadmin;

--
-- Name: eam_platform_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_platform_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(80) NOT NULL,
    sort_name character varying(80),
    cid integer,
    description character varying(256),
    ctime bigint,
    mtime bigint,
    os character varying(80),
    osversion character varying(80),
    arch character varying(80),
    plugin character varying(250)
);


ALTER TABLE public.eam_platform_type OWNER TO hqadmin;

--
-- Name: eam_platform_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_platform_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_platform_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_platform_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_platform_type_id_seq', 10001, false);


--
-- Name: eam_plugin; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_plugin (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(200) NOT NULL,
    path character varying(500) NOT NULL,
    md5 character varying(100) NOT NULL,
    ctime bigint NOT NULL
);


ALTER TABLE public.eam_plugin OWNER TO hqadmin;

--
-- Name: eam_plugin_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_plugin_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_plugin_id_seq OWNER TO hqadmin;

--
-- Name: eam_plugin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_plugin_id_seq', 10001, false);


--
-- Name: eam_principal; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_principal (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    principal character varying(64) NOT NULL,
    "password" character varying(64) NOT NULL
);


ALTER TABLE public.eam_principal OWNER TO hqadmin;

--
-- Name: eam_principal_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_principal_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_principal_id_seq OWNER TO hqadmin;

--
-- Name: eam_principal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_principal_id_seq', 10001, false);


--
-- Name: eam_registered_trigger; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_registered_trigger (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    frequency bigint DEFAULT 0 NOT NULL,
    classname character varying(200) NOT NULL,
    config bytea,
    alert_definition_id integer
);


ALTER TABLE public.eam_registered_trigger OWNER TO hqadmin;

--
-- Name: eam_registered_trigger_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_registered_trigger_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_registered_trigger_id_seq OWNER TO hqadmin;

--
-- Name: eam_registered_trigger_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_registered_trigger_id_seq', 10001, false);


--
-- Name: eam_request_stat; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_request_stat (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    ipaddr character varying(20) NOT NULL,
    min double precision NOT NULL,
    max double precision NOT NULL,
    total double precision NOT NULL,
    count integer NOT NULL,
    begintime bigint NOT NULL,
    endtime bigint NOT NULL,
    svctype integer NOT NULL,
    svcreq_id integer
);


ALTER TABLE public.eam_request_stat OWNER TO hqadmin;

--
-- Name: eam_request_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_request_stat_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_request_stat_id_seq OWNER TO hqadmin;

--
-- Name: eam_request_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_request_stat_id_seq', 10001, false);


--
-- Name: eam_res_grp_res_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_res_grp_res_map (
    id integer NOT NULL,
    resource_id integer NOT NULL,
    resource_group_id integer NOT NULL,
    entry_time bigint NOT NULL
);


ALTER TABLE public.eam_res_grp_res_map OWNER TO hqadmin;

--
-- Name: eam_res_grp_res_map_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_res_grp_res_map_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_res_grp_res_map_id_seq OWNER TO hqadmin;

--
-- Name: eam_res_grp_res_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_res_grp_res_map_id_seq', 10001, false);


--
-- Name: eam_resource; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_resource (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    resource_type_id integer,
    instance_id integer,
    subject_id integer,
    proto_id integer NOT NULL,
    name character varying(500),
    sort_name character varying(500),
    fsystem boolean,
    mtime bigint DEFAULT 0
);


ALTER TABLE public.eam_resource OWNER TO hqadmin;

--
-- Name: eam_resource_aux_log_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_resource_aux_log_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_resource_aux_log_id_seq OWNER TO hqadmin;

--
-- Name: eam_resource_aux_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_resource_aux_log_id_seq', 10001, false);


--
-- Name: eam_resource_aux_logs; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_resource_aux_logs (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    aux_log_id integer NOT NULL,
    appdef_type integer NOT NULL,
    appdef_id integer NOT NULL,
    def_id integer NOT NULL
);


ALTER TABLE public.eam_resource_aux_logs OWNER TO hqadmin;

--
-- Name: eam_resource_edge; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_resource_edge (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    from_id integer NOT NULL,
    to_id integer NOT NULL,
    rel_id integer NOT NULL,
    distance integer NOT NULL
);


ALTER TABLE public.eam_resource_edge OWNER TO hqadmin;

--
-- Name: eam_resource_edge_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_resource_edge_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_resource_edge_id_seq OWNER TO hqadmin;

--
-- Name: eam_resource_edge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_resource_edge_id_seq', 10001, false);


--
-- Name: eam_resource_group; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_resource_group (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    description character varying(100),
    "location" character varying(100),
    fsystem boolean,
    has_or_criteria boolean NOT NULL,
    grouptype integer DEFAULT 11,
    cluster_id integer DEFAULT -1,
    ctime bigint DEFAULT 0,
    mtime bigint DEFAULT 0,
    modified_by character varying(100),
    resource_prototype integer,
    resource_id integer NOT NULL
);


ALTER TABLE public.eam_resource_group OWNER TO hqadmin;

--
-- Name: eam_resource_group_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_resource_group_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_resource_group_id_seq OWNER TO hqadmin;

--
-- Name: eam_resource_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_resource_group_id_seq', 10001, false);


--
-- Name: eam_resource_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_resource_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_resource_id_seq OWNER TO hqadmin;

--
-- Name: eam_resource_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_resource_id_seq', 10001, false);


--
-- Name: eam_resource_relation; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_resource_relation (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    is_hier boolean NOT NULL
);


ALTER TABLE public.eam_resource_relation OWNER TO hqadmin;

--
-- Name: eam_resource_relation_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_resource_relation_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_resource_relation_id_seq OWNER TO hqadmin;

--
-- Name: eam_resource_relation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_resource_relation_id_seq', 10001, false);


--
-- Name: eam_resource_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_resource_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    resource_id integer,
    fsystem boolean
);


ALTER TABLE public.eam_resource_type OWNER TO hqadmin;

--
-- Name: eam_resource_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_resource_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_resource_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_resource_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_resource_type_id_seq', 10001, false);


--
-- Name: eam_role; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_role (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    sort_name character varying(100),
    description character varying(100),
    fsystem boolean,
    resource_id integer
);


ALTER TABLE public.eam_role OWNER TO hqadmin;

--
-- Name: eam_role_calendar; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_role_calendar (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    role_id integer NOT NULL,
    calendar_id integer NOT NULL,
    caltype integer NOT NULL
);


ALTER TABLE public.eam_role_calendar OWNER TO hqadmin;

--
-- Name: eam_role_calendar_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_role_calendar_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_role_calendar_id_seq OWNER TO hqadmin;

--
-- Name: eam_role_calendar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_role_calendar_id_seq', 10001, false);


--
-- Name: eam_role_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_role_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_role_id_seq OWNER TO hqadmin;

--
-- Name: eam_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_role_id_seq', 10001, false);


--
-- Name: eam_role_operation_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_role_operation_map (
    role_id integer NOT NULL,
    operation_id integer NOT NULL
);


ALTER TABLE public.eam_role_operation_map OWNER TO hqadmin;

--
-- Name: eam_role_resource_group_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_role_resource_group_map (
    role_id integer NOT NULL,
    resource_group_id integer NOT NULL
);


ALTER TABLE public.eam_role_resource_group_map OWNER TO hqadmin;

--
-- Name: eam_server; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_server (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    cid integer,
    description character varying(300),
    ctime bigint,
    mtime bigint,
    modified_by character varying(100),
    "location" character varying(100),
    platform_id integer,
    autoinventoryidentifier character varying(250),
    runtimeautodiscovery boolean,
    wasautodiscovered boolean,
    servicesautomanaged boolean,
    autodiscovery_zombie boolean,
    installpath character varying(200),
    server_type_id integer NOT NULL,
    config_response_id integer,
    resource_id integer
);


ALTER TABLE public.eam_server OWNER TO hqadmin;

--
-- Name: eam_server_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_server_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_server_id_seq OWNER TO hqadmin;

--
-- Name: eam_server_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_server_id_seq', 10001, false);


--
-- Name: eam_server_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_server_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(200) NOT NULL,
    sort_name character varying(200),
    cid integer,
    description character varying(200),
    ctime bigint,
    mtime bigint,
    plugin character varying(250),
    fvirtual boolean
);


ALTER TABLE public.eam_server_type OWNER TO hqadmin;

--
-- Name: eam_server_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_server_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_server_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_server_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_server_type_id_seq', 10001, false);


--
-- Name: eam_service; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_service (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    cid integer,
    description character varying(200),
    ctime bigint,
    mtime bigint,
    modified_by character varying(100),
    "location" character varying(100),
    autodiscovery_zombie boolean,
    service_rt boolean,
    enduser_rt boolean,
    parent_service_id integer,
    server_id integer,
    autoinventoryidentifier character varying(250),
    service_type_id integer NOT NULL,
    config_response_id integer,
    resource_id integer
);


ALTER TABLE public.eam_service OWNER TO hqadmin;

--
-- Name: eam_service_dep_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_service_dep_map (
    id integer NOT NULL,
    ctime bigint,
    mtime bigint,
    appservice_id integer,
    dependent_service_id integer
);


ALTER TABLE public.eam_service_dep_map OWNER TO hqadmin;

--
-- Name: eam_service_dep_map_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_service_dep_map_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_service_dep_map_id_seq OWNER TO hqadmin;

--
-- Name: eam_service_dep_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_service_dep_map_id_seq', 10001, false);


--
-- Name: eam_service_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_service_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_service_id_seq OWNER TO hqadmin;

--
-- Name: eam_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_service_id_seq', 10001, false);


--
-- Name: eam_service_request; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_service_request (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    serviceid integer NOT NULL,
    url character varying(767) NOT NULL
);


ALTER TABLE public.eam_service_request OWNER TO hqadmin;

--
-- Name: eam_service_request_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_service_request_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_service_request_id_seq OWNER TO hqadmin;

--
-- Name: eam_service_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_service_request_id_seq', 10001, false);


--
-- Name: eam_service_type; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_service_type (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(500) NOT NULL,
    sort_name character varying(500),
    cid integer,
    description character varying(200),
    ctime bigint,
    mtime bigint,
    plugin character varying(250),
    finternal boolean,
    server_type_id integer
);


ALTER TABLE public.eam_service_type OWNER TO hqadmin;

--
-- Name: eam_service_type_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_service_type_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_service_type_id_seq OWNER TO hqadmin;

--
-- Name: eam_service_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_service_type_id_seq', 10001, false);


--
-- Name: eam_srn; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_srn (
    instance_id integer NOT NULL,
    appdef_type integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    srn integer NOT NULL
);


ALTER TABLE public.eam_srn OWNER TO hqadmin;

--
-- Name: eam_stat_errors; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_stat_errors (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    count integer NOT NULL,
    error_id integer,
    reqstat_id integer
);


ALTER TABLE public.eam_stat_errors OWNER TO hqadmin;

--
-- Name: eam_stat_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_stat_errors_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_stat_errors_id_seq OWNER TO hqadmin;

--
-- Name: eam_stat_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_stat_errors_id_seq', 10001, false);


--
-- Name: eam_subject; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_subject (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    dsn character varying(100) NOT NULL,
    sort_name character varying(100),
    first_name character varying(100),
    last_name character varying(100),
    email_address character varying(100),
    sms_address character varying(100),
    phone_number character varying(100),
    department character varying(100),
    factive boolean NOT NULL,
    fsystem boolean NOT NULL,
    html_email boolean NOT NULL,
    resource_id integer,
    pref_crispo_id integer
);


ALTER TABLE public.eam_subject OWNER TO hqadmin;

--
-- Name: eam_subject_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_subject_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_subject_id_seq OWNER TO hqadmin;

--
-- Name: eam_subject_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_subject_id_seq', 10001, false);


--
-- Name: eam_subject_role_map; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_subject_role_map (
    role_id integer NOT NULL,
    subject_id integer NOT NULL
);


ALTER TABLE public.eam_subject_role_map OWNER TO hqadmin;

--
-- Name: eam_ui_attach_admin; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_attach_admin (
    attach_id integer NOT NULL,
    category character varying(255) NOT NULL
);


ALTER TABLE public.eam_ui_attach_admin OWNER TO hqadmin;

--
-- Name: eam_ui_attach_mast; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_attach_mast (
    attach_id integer NOT NULL,
    category character varying(255) NOT NULL
);


ALTER TABLE public.eam_ui_attach_mast OWNER TO hqadmin;

--
-- Name: eam_ui_attach_rsrc; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_attach_rsrc (
    attach_id integer NOT NULL,
    resource_id integer NOT NULL,
    category character varying(255) NOT NULL
);


ALTER TABLE public.eam_ui_attach_rsrc OWNER TO hqadmin;

--
-- Name: eam_ui_attachment; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_attachment (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    attach_time bigint NOT NULL,
    view_id integer NOT NULL
);


ALTER TABLE public.eam_ui_attachment OWNER TO hqadmin;

--
-- Name: eam_ui_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_ui_attachment_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_ui_attachment_id_seq OWNER TO hqadmin;

--
-- Name: eam_ui_attachment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_ui_attachment_id_seq', 10001, false);


--
-- Name: eam_ui_plugin; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_plugin (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    name character varying(100) NOT NULL,
    plugin_version character varying(30) NOT NULL
);


ALTER TABLE public.eam_ui_plugin OWNER TO hqadmin;

--
-- Name: eam_ui_plugin_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_ui_plugin_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_ui_plugin_id_seq OWNER TO hqadmin;

--
-- Name: eam_ui_plugin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_ui_plugin_id_seq', 10001, false);


--
-- Name: eam_ui_view; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_view (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    path character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    attach_type integer NOT NULL,
    ui_plugin_id integer NOT NULL
);


ALTER TABLE public.eam_ui_view OWNER TO hqadmin;

--
-- Name: eam_ui_view_admin; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_view_admin (
    view_id integer NOT NULL
);


ALTER TABLE public.eam_ui_view_admin OWNER TO hqadmin;

--
-- Name: eam_ui_view_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_ui_view_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_ui_view_id_seq OWNER TO hqadmin;

--
-- Name: eam_ui_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_ui_view_id_seq', 10001, false);


--
-- Name: eam_ui_view_masthead; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_view_masthead (
    view_id integer NOT NULL
);


ALTER TABLE public.eam_ui_view_masthead OWNER TO hqadmin;

--
-- Name: eam_ui_view_resource; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_ui_view_resource (
    view_id integer NOT NULL
);


ALTER TABLE public.eam_ui_view_resource OWNER TO hqadmin;

--
-- Name: eam_update_status; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_update_status (
    id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    report character varying(4000),
    upmode integer NOT NULL,
    ignored boolean NOT NULL
);


ALTER TABLE public.eam_update_status OWNER TO hqadmin;

--
-- Name: eam_update_status_id_seq; Type: SEQUENCE; Schema: public; Owner: hqadmin
--

CREATE SEQUENCE eam_update_status_id_seq
    START WITH 10001
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.eam_update_status_id_seq OWNER TO hqadmin;

--
-- Name: eam_update_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hqadmin
--

SELECT pg_catalog.setval('eam_update_status_id_seq', 10001, false);


--
-- Name: eam_virtual; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE eam_virtual (
    resource_id integer NOT NULL,
    version_col bigint DEFAULT 0 NOT NULL,
    process_id integer NOT NULL,
    physical_id integer
);


ALTER TABLE public.eam_virtual OWNER TO hqadmin;

--
-- Name: hq_avail_data_rle; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_avail_data_rle (
    measurement_id integer NOT NULL,
    startime bigint NOT NULL,
    endtime bigint DEFAULT 9223372036854775807::bigint NOT NULL,
    availval double precision NOT NULL
);


ALTER TABLE public.hq_avail_data_rle OWNER TO hqadmin;

--
-- Name: hq_metric_data_0d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_0d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_0d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_0d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_0d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_0d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_1d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_1d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_1d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_1d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_1d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_1d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_2d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_2d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_2d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_2d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_2d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_2d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_3d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_3d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_3d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_3d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_3d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_3d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_4d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_4d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_4d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_4d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_4d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_4d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_5d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_5d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_5d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_5d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_5d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_5d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_6d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_6d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_6d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_6d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_6d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_6d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_7d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_7d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_7d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_7d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_7d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_7d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_8d_0s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_8d_0s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_8d_0s OWNER TO hqadmin;

--
-- Name: hq_metric_data_8d_1s; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_8d_1s (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_8d_1s OWNER TO hqadmin;

--
-- Name: hq_metric_data_compat; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE hq_metric_data_compat (
    "timestamp" bigint NOT NULL,
    measurement_id integer NOT NULL,
    value numeric(24,5)
);


ALTER TABLE public.hq_metric_data_compat OWNER TO hqadmin;

--
-- Name: qrtz_blob_triggers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_blob_triggers (
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    blob_data bytea
);


ALTER TABLE public.qrtz_blob_triggers OWNER TO hqadmin;

--
-- Name: qrtz_calendars; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_calendars (
    calendar_name character varying(200) NOT NULL,
    calendar bytea NOT NULL
);


ALTER TABLE public.qrtz_calendars OWNER TO hqadmin;

--
-- Name: qrtz_cron_triggers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_cron_triggers (
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    cron_expression character varying(200) NOT NULL,
    time_zone_id character varying(80)
);


ALTER TABLE public.qrtz_cron_triggers OWNER TO hqadmin;

--
-- Name: qrtz_fired_triggers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_fired_triggers (
    entry_id character varying(95) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    instance_name character varying(200) NOT NULL,
    fired_time bigint NOT NULL,
    state character varying(16) NOT NULL,
    is_volatile boolean NOT NULL,
    job_name character varying(200),
    job_group character varying(200),
    is_stateful boolean,
    requests_recovery boolean,
    priority integer NOT NULL
);


ALTER TABLE public.qrtz_fired_triggers OWNER TO hqadmin;

--
-- Name: qrtz_job_details; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_job_details (
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    description character varying(250),
    job_class_name character varying(250) NOT NULL,
    is_durable boolean NOT NULL,
    is_volatile boolean NOT NULL,
    is_stateful boolean NOT NULL,
    requests_recovery boolean NOT NULL,
    job_data bytea
);


ALTER TABLE public.qrtz_job_details OWNER TO hqadmin;

--
-- Name: qrtz_job_listeners; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_job_listeners (
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    job_listener character varying(200) NOT NULL
);


ALTER TABLE public.qrtz_job_listeners OWNER TO hqadmin;

--
-- Name: qrtz_locks; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_locks (
    lock_name character varying(40) NOT NULL
);


ALTER TABLE public.qrtz_locks OWNER TO hqadmin;

--
-- Name: qrtz_paused_trigger_grps; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_paused_trigger_grps (
    trigger_group character varying(200) NOT NULL
);


ALTER TABLE public.qrtz_paused_trigger_grps OWNER TO hqadmin;

--
-- Name: qrtz_scheduler_state; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_scheduler_state (
    instance_name character varying(200) NOT NULL,
    last_checkin_time bigint NOT NULL,
    checkin_interval bigint NOT NULL
);


ALTER TABLE public.qrtz_scheduler_state OWNER TO hqadmin;

--
-- Name: qrtz_simple_triggers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_simple_triggers (
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    repeat_count bigint NOT NULL,
    repeat_interval bigint NOT NULL,
    times_triggered bigint NOT NULL
);


ALTER TABLE public.qrtz_simple_triggers OWNER TO hqadmin;

--
-- Name: qrtz_trigger_listeners; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_trigger_listeners (
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    trigger_listener character varying(200) NOT NULL
);


ALTER TABLE public.qrtz_trigger_listeners OWNER TO hqadmin;

--
-- Name: qrtz_triggers; Type: TABLE; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE TABLE qrtz_triggers (
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    is_volatile boolean NOT NULL,
    description character varying(250),
    next_fire_time bigint,
    prev_fire_time bigint,
    trigger_state character varying(16) NOT NULL,
    trigger_type character varying(8) NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint,
    calendar_name character varying(200),
    misfire_instr integer,
    job_data bytea,
    priority integer
);


ALTER TABLE public.qrtz_triggers OWNER TO hqadmin;

--
-- Data for Name: eam_action; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_action (id, version_col, classname, config, parent_id, alert_definition_id, deleted) FROM stdin;
\.


--
-- Data for Name: eam_agent; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_agent (id, version_col, address, port, authtoken, agenttoken, version, ctime, mtime, unidirectional, agent_type_id) FROM stdin;
\.


--
-- Data for Name: eam_agent_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_agent_type (id, version_col, name, ctime, mtime) FROM stdin;
1	0	covalent-eam	\N	\N
2	0	hyperic-hq-remoting	\N	\N
\.


--
-- Data for Name: eam_ai_agent_report; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ai_agent_report (id, version_col, agent_id, report_time, service_dirty) FROM stdin;
\.


--
-- Data for Name: eam_aiq_ip; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_aiq_ip (id, version_col, aiq_platform_id, address, netmask, mac_address, queuestatus, diff, ignored, ctime, mtime) FROM stdin;
\.


--
-- Data for Name: eam_aiq_platform; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_aiq_platform (id, version_col, name, description, os, osversion, arch, fqdn, agenttoken, certdn, queuestatus, diff, ignored, ctime, mtime, lastapproved, "location", cpu_speed, cpu_count, ram, gateway, dhcp_server, dns_server, custom_properties, product_config, control_config, measurement_config) FROM stdin;
\.


--
-- Data for Name: eam_aiq_server; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_aiq_server (id, version_col, aiq_platform_id, autoinventoryidentifier, name, description, active, servertypename, installpath, servicesautomanaged, custom_properties, product_config, control_config, responsetime_config, measurement_config, queuestatus, diff, ignored, ctime, mtime) FROM stdin;
\.


--
-- Data for Name: eam_aiq_service; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_aiq_service (id, version_col, name, description, servicetypename, queuestatus, diff, ignored, ctime, mtime, custom_properties, product_config, control_config, measurement_config, responsetime_config, server_id) FROM stdin;
\.


--
-- Data for Name: eam_alert; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_alert (id, version_col, ctime, fixed, alert_definition_id) FROM stdin;
\.


--
-- Data for Name: eam_alert_action_log; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_alert_action_log (id, "timestamp", detail, alert_id, alert_type, action_id, subject_id) FROM stdin;
\.


--
-- Data for Name: eam_alert_condition; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_alert_condition (id, version_col, "type", required, measurement_id, name, comparator, threshold, option_status, alert_definition_id, trigger_id) FROM stdin;
\.


--
-- Data for Name: eam_alert_condition_log; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_alert_condition_log (id, value, alert_id, condition_id) FROM stdin;
\.


--
-- Data for Name: eam_alert_def_state; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_alert_def_state (alert_definition_id, last_fired) FROM stdin;
0	0
\.


--
-- Data for Name: eam_alert_definition; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_alert_definition (id, version_col, name, ctime, mtime, parent_id, description, priority, active, enabled, frequency_type, count, trange, will_recover, notify_filtered, control_filtered, deleted, escalation_id, resource_id) FROM stdin;
0	0	Resource Type Alert	0	0	\N	\N	0	f	f	0	\N	\N	f	f	f	f	\N	\N
\.


--
-- Data for Name: eam_app_service; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_app_service (id, version_col, service_id, group_id, application_id, isgroup, ctime, mtime, modified_by, fentry_point, service_type_id) FROM stdin;
\.


--
-- Data for Name: eam_app_type_service_type_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_app_type_service_type_map (application_type_id, service_type_id) FROM stdin;
\.


--
-- Data for Name: eam_application; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_application (id, version_col, cid, description, ctime, mtime, modified_by, "location", eng_contact, ops_contact, bus_contact, application_type_id, resource_id) FROM stdin;
\.


--
-- Data for Name: eam_application_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_application_type (id, version_col, name, sort_name, cid, description, ctime, mtime) FROM stdin;
1	0	Generic Application	\N	1	\N	\N	\N
2	0	J2EE Application	\N	2	\N	\N	\N
\.


--
-- Data for Name: eam_audit; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_audit (id, klazz, version_col, start_time, end_time, nature, purpose, importance, original, field, old_val, new_val, message, parent_id, resource_id, subject_id) FROM stdin;
\.


--
-- Data for Name: eam_autoinv_history; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_autoinv_history (id, version_col, group_id, batch_id, entity_type, entity_id, subject, scheduled, date_scheduled, starttime, status, endtime, duration, scanname, scandesc, description, message, config) FROM stdin;
\.


--
-- Data for Name: eam_autoinv_schedule; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_autoinv_schedule (id, version_col, entity_id, entity_type, subject, schedulevaluebytes, nextfiretime, triggername, jobname, job_order_data, scanname, scandesc, config) FROM stdin;
\.


--
-- Data for Name: eam_calendar; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_calendar (id, version_col, name) FROM stdin;
\.


--
-- Data for Name: eam_calendar_ent; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_calendar_ent (id, version_col, calendar_id) FROM stdin;
\.


--
-- Data for Name: eam_calendar_week; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_calendar_week (calendar_week_id, weekday, starttime, endtime) FROM stdin;
\.


--
-- Data for Name: eam_config_props; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_config_props (id, version_col, prefix, propkey, propvalue, default_propvalue, fread_only) FROM stdin;
3	0	\N	CAM_JAAS_PROVIDER	@@@JAASPROVIDER@@@	JDBC	f
4	0	\N	CAM_BASE_URL	http://localhost:7080/	http://localhost:7080/	f
7	0	\N	CAM_SMTP_HOST	@@SMTPHOST@@	@@SMTPHOST@@	f
8	0	\N	CAM_EMAIL_SENDER	hqadmin@localhost	hqadmin@localhost	f
9	0	\N	CAM_HELP_USER	web	web	f
10	0	\N	CAM_HELP_PASSWORD	user	user	f
11	0	\N	CAM_LDAP_NAMING_FACTORY_INITIAL		com.sun.jndi.ldap.LdapCtxFactory	f
12	0	\N	CAM_LDAP_NAMING_PROVIDER_URL		ldap://localhost/	f
13	0	\N	CAM_LDAP_LOGIN_PROPERTY		cn	f
14	0	\N	CAM_LDAP_BASE_DN		o=Hyperic,c=US	f
15	0	\N	CAM_LDAP_BIND_DN			f
16	0	\N	CAM_LDAP_BIND_PW			f
17	0	\N	CAM_LDAP_PROTOCOL	@@@LDAPPROTOCOL@@@		f
18	0	\N	CAM_LDAP_FILTER			f
21	0	\N	CAM_SYSLOG_ACTIONS_ENABLED	false	false	f
23	0	\N	CAM_GUIDE_ENABLED	true	true	f
24	0	\N	CAM_RT_COLLECT_IP_ADDRS	true	true	f
25	0	\N	CAM_DATA_PURGE_RAW	172800000	172800000	f
26	0	\N	CAM_DATA_PURGE_1H	1209600000	1209600000	f
27	0	\N	CAM_DATA_PURGE_6H	2678400000	2678400000	f
28	0	\N	CAM_DATA_PURGE_1D	31536000000	31536000000	f
29	0	\N	CAM_BASELINE_FREQUENCY	259200000	259200000	f
30	0	\N	CAM_BASELINE_DATASET	604800000	604800000	f
31	0	\N	CAM_BASELINE_MINSET	40	40	f
32	0	\N	CAM_DATA_MAINTENANCE	3600000	3600000	f
33	0	\N	DATA_STORE_ALL	true	true	f
34	0	\N	RT_DATA_PURGE	2678400000	2678400000	f
35	0	\N	DATA_REINDEX_NIGHTLY	true	true	f
36	0	\N	ALERT_PURGE	2678400000	2678400000	f
37	0	\N	SNMP_VERSION			f
38	0	\N	SNMP_AUTH_PROTOCOL	MD5		f
39	0	\N	SNMP_AUTH_PASSPHRASE			f
40	0	\N	SNMP_PRIV_PASSPHRASE			f
41	0	\N	SNMP_COMMUNITY	public		f
42	0	\N	SNMP_ENGINE_ID			f
43	0	\N	SNMP_CONTEXT_NAME			f
44	0	\N	SNMP_SECURITY_NAME			f
45	0	\N	SNMP_TRAP_OID			f
46	0	\N	SNMP_ENTERPRISE_OID			f
47	0	\N	SNMP_GENERIC_ID			f
48	0	\N	SNMP_SPECIFIC_ID			f
49	0	\N	SNMP_AGENT_ADDRESS			f
50	0	\N	SNMP_PRIVACY_PROTOCOL			f
51	0	\N	EVENT_LOG_PURGE	2678400000	2678400000	f
52	0	\N	KERBEROS_REALM			f
53	0	\N	KERBEROS_KDC			f
54	0	\N	KERBEROS_DEBUG			f
55	0	\N	HQ-GUID			f
56	0	\N	BATCH_AGGREGATE_WORKERS	10		f
57	0	\N	BATCH_AGGREGATE_BATCHSIZE	1000		f
58	0	\N	BATCH_AGGREGATE_QUEUE	500000		f
59	0	\N	REPORT_STATS_SIZE	1000	1000	f
60	0	\N	AGENT_BUNDLE_REPOSITORY_DIR	hq-agent-bundles		f
61	0	\N	ARC_SERVER_URL			f
62	0	\N	HQ_ALERTS_ENABLED	true	true	f
63	0	\N	HQ_ALERT_NOTIFICATIONS_ENABLED	true	true	f
64	0	\N	HQ_ALERT_THRESHOLD	0	0	f
65	0	\N	HQ_ALERT_THRESHOLD_EMAILS			f
66	0	\N	HQ_HIERARCHICAL_ALERTING_ENABLED	true	true	f
2	0	\N	CAM_SCHEMA_VERSION	3.192	REPLACE_ME	t
1	0	\N	CAM_SERVER_VERSION	4.2.0	REPLACE_ME	t
19	0	\N	CAM_MULTICAST_ADDRESS	227.0.0.1		f
20	0	\N	CAM_MULTICAST_PORT	3030		f
\.


--
-- Data for Name: eam_config_response; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_config_response (id, version_col, product_response, control_response, measurement_response, autoinventory_response, response_time_response, usermanaged, validationerr) FROM stdin;
\.


--
-- Data for Name: eam_control_history; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_control_history (id, version_col, group_id, batch_id, entity_type, entity_id, subject, scheduled, date_scheduled, starttime, status, endtime, description, message, "action", args) FROM stdin;
\.


--
-- Data for Name: eam_control_schedule; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_control_schedule (id, version_col, entity_id, entity_type, subject, schedulevaluebytes, nextfiretime, triggername, jobname, job_order_data, "action") FROM stdin;
\.


--
-- Data for Name: eam_cprop; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_cprop (id, version_col, appdef_id, keyid, value_idx, propvalue) FROM stdin;
\.


--
-- Data for Name: eam_cprop_key; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_cprop_key (id, version_col, appdef_type, appdef_typeid, propkey, description) FROM stdin;
\.


--
-- Data for Name: eam_crispo; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_crispo (id, version_col) FROM stdin;
0	0
2	0
3	0
\.


--
-- Data for Name: eam_crispo_array; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_crispo_array (opt_id, val, idx) FROM stdin;
\.


--
-- Data for Name: eam_crispo_opt; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_crispo_opt (id, version_col, propkey, val, crispo_id) FROM stdin;
2	0	.user.dashboard.default.id	2	3
\.


--
-- Data for Name: eam_criteria; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_criteria (id, version_col, list_index, resource_group_id, klazz, string_prop, date_prop, resource_id_prop, numeric_prop, enum_prop) FROM stdin;
\.


--
-- Data for Name: eam_dash_config; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_dash_config (id, config_type, version_col, name, crispo_id, role_id, user_id) FROM stdin;
0	ROLE	0	Super User Role	0	0	\N
2	ROLE	0	Guest Role	2	2	\N
\.


--
-- Data for Name: eam_error_code; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_error_code (id, version_col, code, description) FROM stdin;
\.


--
-- Data for Name: eam_escalation; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_escalation (id, version_col, name, description, allow_pause, max_wait_time, notify_all, ctime, mtime, frepeat) FROM stdin;
100	0	Default Escalation	This is an Escalation Scheme created by "HQ" that performs no actions	f	300000	f	0	0	f
\.


--
-- Data for Name: eam_escalation_action; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_escalation_action (escalation_id, wait_time, action_id, idx) FROM stdin;
\.


--
-- Data for Name: eam_escalation_state; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_escalation_state (id, version_col, next_action_idx, next_action_time, escalation_id, alert_def_id, alert_id, alert_type, acknowledged_by) FROM stdin;
\.


--
-- Data for Name: eam_event_log; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_event_log (id, detail, "type", "timestamp", resource_id, subject, status, instance_id) FROM stdin;
\.


--
-- Data for Name: eam_exec_strategies; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_exec_strategies (id, version_col, def_id, config_id, partition, type_id) FROM stdin;
\.


--
-- Data for Name: eam_exec_strategy_types; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_exec_strategy_types (id, version_col, type_class) FROM stdin;
\.


--
-- Data for Name: eam_galert_action_log; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_galert_action_log (id, "timestamp", detail, galert_id, alert_type, action_id, subject_id) FROM stdin;
\.


--
-- Data for Name: eam_galert_aux_logs; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_galert_aux_logs (id, version_col, "timestamp", auxtype, description, galert_id, parent, def_id) FROM stdin;
\.


--
-- Data for Name: eam_galert_defs; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_galert_defs (id, version_col, name, descr, severity, enabled, ctime, mtime, deleted, last_fired, group_id, escalation_id) FROM stdin;
\.


--
-- Data for Name: eam_galert_logs; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_galert_logs (id, version_col, "timestamp", fixed, def_id, short_reason, long_reason, partition) FROM stdin;
\.


--
-- Data for Name: eam_gtrigger_types; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_gtrigger_types (id, version_col, type_class) FROM stdin;
\.


--
-- Data for Name: eam_gtriggers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_gtriggers (id, version_col, config_id, type_id, strat_id, lidx) FROM stdin;
\.


--
-- Data for Name: eam_ip; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ip (id, version_col, platform_id, address, netmask, mac_address, ctime, mtime, cid) FROM stdin;
\.


--
-- Data for Name: eam_measurement; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement (id, version_col, instance_id, template_id, mtime, enabled, coll_interval, dsn, resource_id) FROM stdin;
\.


--
-- Data for Name: eam_measurement_bl; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement_bl (id, version_col, measurement_id, compute_time, user_entered, mean, min_expected_val, max_expected_val) FROM stdin;
\.


--
-- Data for Name: eam_measurement_cat; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement_cat (id, version_col, name) FROM stdin;
1	0	AVAILABILITY
2	0	PERFORMANCE
3	0	THROUGHPUT
4	0	UTILIZATION
\.


--
-- Data for Name: eam_measurement_data_1d; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement_data_1d ("timestamp", measurement_id, value, "minvalue", "maxvalue") FROM stdin;
\.


--
-- Data for Name: eam_measurement_data_1h; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement_data_1h ("timestamp", measurement_id, value, "minvalue", "maxvalue") FROM stdin;
\.


--
-- Data for Name: eam_measurement_data_6h; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement_data_6h ("timestamp", measurement_id, value, "minvalue", "maxvalue") FROM stdin;
\.


--
-- Data for Name: eam_measurement_templ; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_measurement_templ (id, version_col, name, alias, units, collection_type, default_on, default_interval, designate, "template", plugin, ctime, mtime, monitorable_type_id, category_id) FROM stdin;
\.


--
-- Data for Name: eam_metric_aux_logs; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_metric_aux_logs (id, version_col, aux_log_id, metric_id, def_id) FROM stdin;
\.


--
-- Data for Name: eam_metric_prob; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_metric_prob (measurement_id, "timestamp", additional, version_col, "type") FROM stdin;
\.


--
-- Data for Name: eam_monitorable_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_monitorable_type (id, version_col, name, appdef_type, plugin) FROM stdin;
\.


--
-- Data for Name: eam_numbers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_numbers (i) FROM stdin;
0
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
\.


--
-- Data for Name: eam_operation; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_operation (id, version_col, name, resource_type_id) FROM stdin;
0	0	createResource	0
1	0	modifyResourceType	0
2	0	addOperation	0
3	0	removeOperation	0
6	0	modifySubject	0
7	0	removeSubject	0
8	0	viewSubject	0
10	0	createSubject	0
11	0	modifyRole	2
12	0	createRole	0
13	0	removeOperation	2
16	0	viewRole	2
24	0	modifyResourceGroup	3
25	0	addRole	3
28	0	viewResourceGroup	3
30	0	removeRole	2
31	0	removeResourceGroup	3
32	0	administerCAM	0
301	0	modifyPlatform	301
302	0	removePlatform	301
303	0	addServer	301
304	0	removeServer	301
305	0	viewPlatform	301
306	0	createServer	303
307	0	modifyServer	303
308	0	removeServer	303
309	0	addService	303
311	0	viewServer	303
312	0	createService	305
313	0	modifyService	305
314	0	removeService	305
315	0	viewService	305
316	0	createApplication	0
317	0	modifyApplication	308
318	0	removeApplication	308
319	0	viewApplication	308
320	0	createPlatform	0
321	0	monitorPlatform	301
322	0	monitorServer	303
323	0	monitorService	305
324	0	monitorApplication	308
325	0	controlPlatform	301
326	0	controlServer	303
327	0	controlService	305
328	0	controlApplication	308
400	0	managePlatformAlerts	301
401	0	manageServerAlerts	303
402	0	manageServiceAlerts	305
403	0	manageApplicationAlerts	308
404	0	manageGroupAlerts	3
412	0	createEscalation	0
413	0	modifyEscalation	0
414	0	removeEscalation	0
\.


--
-- Data for Name: eam_platform; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_platform (id, version_col, fqdn, certdn, cid, description, ctime, mtime, modified_by, "location", comment_text, cpu_count, platform_type_id, config_response_id, agent_id, resource_id) FROM stdin;
\.


--
-- Data for Name: eam_platform_server_type_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_platform_server_type_map (platform_type_id, server_type_id) FROM stdin;
\.


--
-- Data for Name: eam_platform_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_platform_type (id, version_col, name, sort_name, cid, description, ctime, mtime, os, osversion, arch, plugin) FROM stdin;
\.


--
-- Data for Name: eam_plugin; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_plugin (id, version_col, name, path, md5, ctime) FROM stdin;
\.


--
-- Data for Name: eam_principal; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_principal (id, version_col, principal, "password") FROM stdin;
1	0	hqadmin	XfLzwfNQujo/CxxaYX3OCg==
\.


--
-- Data for Name: eam_registered_trigger; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_registered_trigger (id, version_col, frequency, classname, config, alert_definition_id) FROM stdin;
\.


--
-- Data for Name: eam_request_stat; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_request_stat (id, version_col, ipaddr, min, max, total, count, begintime, endtime, svctype, svcreq_id) FROM stdin;
\.


--
-- Data for Name: eam_res_grp_res_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_res_grp_res_map (id, resource_id, resource_group_id, entry_time) FROM stdin;
0	0	0	0
1	1	0	0
2	2	0	0
3	3	0	0
4	4	0	0
5	5	0	0
6	401	0	0
7	501	0	0
8	601	0	0
9	602	0	0
10	603	0	0
11	604	0	0
12	8	1	0
13	6	1	0
14	10	1	0
15	11	1	0
\.


--
-- Data for Name: eam_resource; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_resource (id, version_col, resource_type_id, instance_id, subject_id, proto_id, name, sort_name, fsystem, mtime) FROM stdin;
0	0	0	0	0	0	\N	\N	t	0
1	0	0	1	0	0	\N	\N	t	0
2	0	0	2	0	0	\N	\N	t	0
3	0	0	3	0	0	\N	\N	t	0
4	0	1	0	0	0	\N	\N	t	0
401	0	0	401	0	0	\N	\N	t	0
501	0	0	501	0	0	\N	\N	t	0
601	0	0	601	0	0	\N	\N	t	0
602	0	0	602	0	0	\N	\N	t	0
603	0	0	603	0	0	\N	\N	t	0
604	0	0	604	0	0	\N	\N	t	0
5	0	3	0	0	0	covalentAuthzResourceGroup	COVALENTAUTHZRESOURCEGROUP	t	0
1600	0	604	1	0	0	\N	\N	t	0
1601	0	604	2	0	0	\N	\N	t	0
301	0	0	301	0	0	\N	\N	t	0
303	0	0	303	0	0	\N	\N	t	0
305	0	0	305	0	0	\N	\N	t	0
308	0	0	308	0	0	\N	\N	t	0
6	0	1	1	0	0	\N	\N	t	0
7	0	3	1	1	0	ROOT_RESOURCE_GROUP	ROOT_RESOURCE_GROUP	t	0
8	0	2	0	0	0	\N	\N	t	0
9	0	2	1	0	0	\N	\N	t	0
10	0	1	2	0	0	\N	\N	f	0
11	0	2	2	0	0	\N	\N	f	0
\.


--
-- Data for Name: eam_resource_aux_logs; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_resource_aux_logs (id, version_col, aux_log_id, appdef_type, appdef_id, def_id) FROM stdin;
\.


--
-- Data for Name: eam_resource_edge; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_resource_edge (id, version_col, from_id, to_id, rel_id, distance) FROM stdin;
\.


--
-- Data for Name: eam_resource_group; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_resource_group (id, version_col, description, "location", fsystem, has_or_criteria, grouptype, cluster_id, ctime, mtime, modified_by, resource_prototype, resource_id) FROM stdin;
0	0	\N	\N	t	t	11	-1	0	0	\N	\N	5
1	0	\N	\N	t	t	11	-1	0	0	\N	\N	7
\.


--
-- Data for Name: eam_resource_relation; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_resource_relation (id, version_col, name, is_hier) FROM stdin;
1	0	containment	t
2	0	network	t
\.


--
-- Data for Name: eam_resource_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_resource_type (id, version_col, name, resource_id, fsystem) FROM stdin;
0	0	covalentAuthzRootResourceType	0	f
1	0	covalentAuthzSubject	1	f
2	0	covalentAuthzRole	2	f
3	0	covalentAuthzResourceGroup	3	f
401	0	EscalationScheme	401	f
501	0	HQSystem	501	f
601	0	PlatformPrototype	601	t
602	0	ServerPrototype	602	t
603	0	ServicePrototype	603	t
604	0	ApplicationPrototype	604	t
301	0	covalentEAMPlatform	301	f
303	0	covalentEAMServer	303	f
305	0	covalentEAMService	305	f
308	0	covalentEAMApplication	308	f
\.


--
-- Data for Name: eam_role; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_role (id, version_col, name, sort_name, description, fsystem, resource_id) FROM stdin;
0	0	Super User Role	\N	\N	t	8
1	0	RESOURCE_CREATOR_ROLE	\N	\N	t	9
2	0	Guest Role	\N	\N	f	11
\.


--
-- Data for Name: eam_role_calendar; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_role_calendar (id, version_col, role_id, calendar_id, caltype) FROM stdin;
\.


--
-- Data for Name: eam_role_operation_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_role_operation_map (role_id, operation_id) FROM stdin;
0	0
0	1
0	2
0	3
0	6
0	7
0	8
0	10
0	11
0	12
0	13
0	16
0	24
0	25
0	28
0	301
0	302
0	303
0	305
0	306
0	307
0	308
0	309
0	311
0	312
0	313
0	314
0	315
0	316
0	317
0	318
0	319
0	320
0	30
0	31
0	321
0	322
0	323
0	324
0	325
0	326
0	327
0	328
0	32
0	400
0	401
0	402
0	403
0	404
0	412
0	413
0	414
1	0
2	8
2	16
2	28
2	305
2	311
2	315
2	319
\.


--
-- Data for Name: eam_role_resource_group_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_role_resource_group_map (role_id, resource_group_id) FROM stdin;
0	1
0	0
1	0
\.


--
-- Data for Name: eam_server; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_server (id, version_col, cid, description, ctime, mtime, modified_by, "location", platform_id, autoinventoryidentifier, runtimeautodiscovery, wasautodiscovered, servicesautomanaged, autodiscovery_zombie, installpath, server_type_id, config_response_id, resource_id) FROM stdin;
\.


--
-- Data for Name: eam_server_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_server_type (id, version_col, name, sort_name, cid, description, ctime, mtime, plugin, fvirtual) FROM stdin;
\.


--
-- Data for Name: eam_service; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_service (id, version_col, cid, description, ctime, mtime, modified_by, "location", autodiscovery_zombie, service_rt, enduser_rt, parent_service_id, server_id, autoinventoryidentifier, service_type_id, config_response_id, resource_id) FROM stdin;
\.


--
-- Data for Name: eam_service_dep_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_service_dep_map (id, ctime, mtime, appservice_id, dependent_service_id) FROM stdin;
\.


--
-- Data for Name: eam_service_request; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_service_request (id, version_col, serviceid, url) FROM stdin;
\.


--
-- Data for Name: eam_service_type; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_service_type (id, version_col, name, sort_name, cid, description, ctime, mtime, plugin, finternal, server_type_id) FROM stdin;
\.


--
-- Data for Name: eam_srn; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_srn (instance_id, appdef_type, version_col, srn) FROM stdin;
\.


--
-- Data for Name: eam_stat_errors; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_stat_errors (id, version_col, count, error_id, reqstat_id) FROM stdin;
\.


--
-- Data for Name: eam_subject; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_subject (id, version_col, name, dsn, sort_name, first_name, last_name, email_address, sms_address, phone_number, department, factive, fsystem, html_email, resource_id, pref_crispo_id) FROM stdin;
0	0	admin	covalentAuthzInternalDsn	\N	System	User	\N	\N	\N	Administration	t	t	f	4	\N
1	0	hqadmin	CAM	\N	"HQ"	Administrator	hqadmin@168.23.107	\N	\N	\N	t	t	f	6	\N
2	0	guest	CAM	\N	Guest	User	hqadmin@168.23.107	\N	\N	\N	f	f	f	10	3
\.


--
-- Data for Name: eam_subject_role_map; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_subject_role_map (role_id, subject_id) FROM stdin;
0	1
1	1
2	2
\.


--
-- Data for Name: eam_ui_attach_admin; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_attach_admin (attach_id, category) FROM stdin;
\.


--
-- Data for Name: eam_ui_attach_mast; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_attach_mast (attach_id, category) FROM stdin;
\.


--
-- Data for Name: eam_ui_attach_rsrc; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_attach_rsrc (attach_id, resource_id, category) FROM stdin;
\.


--
-- Data for Name: eam_ui_attachment; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_attachment (id, version_col, attach_time, view_id) FROM stdin;
\.


--
-- Data for Name: eam_ui_plugin; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_plugin (id, version_col, name, plugin_version) FROM stdin;
\.


--
-- Data for Name: eam_ui_view; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_view (id, version_col, path, description, attach_type, ui_plugin_id) FROM stdin;
\.


--
-- Data for Name: eam_ui_view_admin; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_view_admin (view_id) FROM stdin;
\.


--
-- Data for Name: eam_ui_view_masthead; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_view_masthead (view_id) FROM stdin;
\.


--
-- Data for Name: eam_ui_view_resource; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_ui_view_resource (view_id) FROM stdin;
\.


--
-- Data for Name: eam_update_status; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_update_status (id, version_col, report, upmode, ignored) FROM stdin;
\.


--
-- Data for Name: eam_virtual; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY eam_virtual (resource_id, version_col, process_id, physical_id) FROM stdin;
\.


--
-- Data for Name: hq_avail_data_rle; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_avail_data_rle (measurement_id, startime, endtime, availval) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_0d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_0d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_0d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_0d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_1d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_1d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_1d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_1d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_2d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_2d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_2d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_2d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_3d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_3d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_3d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_3d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_4d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_4d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_4d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_4d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_5d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_5d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_5d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_5d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_6d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_6d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_6d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_6d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_7d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_7d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_7d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_7d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_8d_0s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_8d_0s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_8d_1s; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_8d_1s ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: hq_metric_data_compat; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY hq_metric_data_compat ("timestamp", measurement_id, value) FROM stdin;
\.


--
-- Data for Name: qrtz_blob_triggers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_blob_triggers (trigger_name, trigger_group, blob_data) FROM stdin;
\.


--
-- Data for Name: qrtz_calendars; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_calendars (calendar_name, calendar) FROM stdin;
\.


--
-- Data for Name: qrtz_cron_triggers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_cron_triggers (trigger_name, trigger_group, cron_expression, time_zone_id) FROM stdin;
\.


--
-- Data for Name: qrtz_fired_triggers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_fired_triggers (entry_id, trigger_name, trigger_group, instance_name, fired_time, state, is_volatile, job_name, job_group, is_stateful, requests_recovery, priority) FROM stdin;
\.


--
-- Data for Name: qrtz_job_details; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_job_details (job_name, job_group, description, job_class_name, is_durable, is_volatile, is_stateful, requests_recovery, job_data) FROM stdin;
\.


--
-- Data for Name: qrtz_job_listeners; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_job_listeners (job_name, job_group, job_listener) FROM stdin;
\.


--
-- Data for Name: qrtz_locks; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_locks (lock_name) FROM stdin;
TRIGGER_ACCESS
JOB_ACCESS
CALENDAR_ACCESS
STATE_ACCESS
MISFIRE_ACCESS
\.


--
-- Data for Name: qrtz_paused_trigger_grps; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_paused_trigger_grps (trigger_group) FROM stdin;
\.


--
-- Data for Name: qrtz_scheduler_state; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_scheduler_state (instance_name, last_checkin_time, checkin_interval) FROM stdin;
\.


--
-- Data for Name: qrtz_simple_triggers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_simple_triggers (trigger_name, trigger_group, repeat_count, repeat_interval, times_triggered) FROM stdin;
\.


--
-- Data for Name: qrtz_trigger_listeners; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_trigger_listeners (trigger_name, trigger_group, trigger_listener) FROM stdin;
\.


--
-- Data for Name: qrtz_triggers; Type: TABLE DATA; Schema: public; Owner: hqadmin
--

COPY qrtz_triggers (trigger_name, trigger_group, job_name, job_group, is_volatile, description, next_fire_time, prev_fire_time, trigger_state, trigger_type, start_time, end_time, calendar_name, misfire_instr, job_data, priority) FROM stdin;
\.


--
-- Name: eam_action_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_action
    ADD CONSTRAINT eam_action_pkey PRIMARY KEY (id);


--
-- Name: eam_agent_agenttoken_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_agent
    ADD CONSTRAINT eam_agent_agenttoken_key UNIQUE (agenttoken);


--
-- Name: eam_agent_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_agent
    ADD CONSTRAINT eam_agent_pkey PRIMARY KEY (id);


--
-- Name: eam_agent_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_agent_type
    ADD CONSTRAINT eam_agent_type_pkey PRIMARY KEY (id);


--
-- Name: eam_ai_agent_report_agent_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ai_agent_report
    ADD CONSTRAINT eam_ai_agent_report_agent_id_key UNIQUE (agent_id);


--
-- Name: eam_ai_agent_report_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ai_agent_report
    ADD CONSTRAINT eam_ai_agent_report_pkey PRIMARY KEY (id);


--
-- Name: eam_aiq_ip_aiq_platform_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_ip
    ADD CONSTRAINT eam_aiq_ip_aiq_platform_id_key UNIQUE (aiq_platform_id, address);


--
-- Name: eam_aiq_ip_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_ip
    ADD CONSTRAINT eam_aiq_ip_pkey PRIMARY KEY (id);


--
-- Name: eam_aiq_platform_certdn_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_platform
    ADD CONSTRAINT eam_aiq_platform_certdn_key UNIQUE (certdn);


--
-- Name: eam_aiq_platform_fqdn_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_platform
    ADD CONSTRAINT eam_aiq_platform_fqdn_key UNIQUE (fqdn);


--
-- Name: eam_aiq_platform_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_platform
    ADD CONSTRAINT eam_aiq_platform_name_key UNIQUE (name);


--
-- Name: eam_aiq_platform_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_platform
    ADD CONSTRAINT eam_aiq_platform_pkey PRIMARY KEY (id);


--
-- Name: eam_aiq_server_aiq_platform_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_server
    ADD CONSTRAINT eam_aiq_server_aiq_platform_id_key UNIQUE (aiq_platform_id, autoinventoryidentifier);


--
-- Name: eam_aiq_server_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_server
    ADD CONSTRAINT eam_aiq_server_pkey PRIMARY KEY (id);


--
-- Name: eam_aiq_service_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_aiq_service
    ADD CONSTRAINT eam_aiq_service_pkey PRIMARY KEY (id);


--
-- Name: eam_alert_action_log_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_alert_action_log
    ADD CONSTRAINT eam_alert_action_log_pkey PRIMARY KEY (id);


--
-- Name: eam_alert_condition_log_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_alert_condition_log
    ADD CONSTRAINT eam_alert_condition_log_pkey PRIMARY KEY (id);


--
-- Name: eam_alert_condition_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_alert_condition
    ADD CONSTRAINT eam_alert_condition_pkey PRIMARY KEY (id);


--
-- Name: eam_alert_def_state_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_alert_def_state
    ADD CONSTRAINT eam_alert_def_state_pkey PRIMARY KEY (alert_definition_id);


--
-- Name: eam_alert_definition_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_alert_definition
    ADD CONSTRAINT eam_alert_definition_pkey PRIMARY KEY (id);


--
-- Name: eam_alert_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_alert
    ADD CONSTRAINT eam_alert_pkey PRIMARY KEY (id);


--
-- Name: eam_app_service_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_app_service
    ADD CONSTRAINT eam_app_service_pkey PRIMARY KEY (id);


--
-- Name: eam_app_service_service_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_app_service
    ADD CONSTRAINT eam_app_service_service_id_key UNIQUE (service_id, group_id, application_id);


--
-- Name: eam_app_type_service_type_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_app_type_service_type_map
    ADD CONSTRAINT eam_app_type_service_type_map_pkey PRIMARY KEY (service_type_id, application_type_id);


--
-- Name: eam_application_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_application
    ADD CONSTRAINT eam_application_pkey PRIMARY KEY (id);


--
-- Name: eam_application_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_application_type
    ADD CONSTRAINT eam_application_type_pkey PRIMARY KEY (id);


--
-- Name: eam_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_audit
    ADD CONSTRAINT eam_audit_pkey PRIMARY KEY (id);


--
-- Name: eam_autoinv_history_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_autoinv_history
    ADD CONSTRAINT eam_autoinv_history_pkey PRIMARY KEY (id);


--
-- Name: eam_autoinv_schedule_jobname_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_autoinv_schedule
    ADD CONSTRAINT eam_autoinv_schedule_jobname_key UNIQUE (jobname);


--
-- Name: eam_autoinv_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_autoinv_schedule
    ADD CONSTRAINT eam_autoinv_schedule_pkey PRIMARY KEY (id);


--
-- Name: eam_autoinv_schedule_scanname_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_autoinv_schedule
    ADD CONSTRAINT eam_autoinv_schedule_scanname_key UNIQUE (scanname);


--
-- Name: eam_autoinv_schedule_triggername_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_autoinv_schedule
    ADD CONSTRAINT eam_autoinv_schedule_triggername_key UNIQUE (triggername);


--
-- Name: eam_calendar_ent_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_calendar_ent
    ADD CONSTRAINT eam_calendar_ent_pkey PRIMARY KEY (id);


--
-- Name: eam_calendar_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_calendar
    ADD CONSTRAINT eam_calendar_name_key UNIQUE (name);


--
-- Name: eam_calendar_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_calendar
    ADD CONSTRAINT eam_calendar_pkey PRIMARY KEY (id);


--
-- Name: eam_calendar_week_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_calendar_week
    ADD CONSTRAINT eam_calendar_week_pkey PRIMARY KEY (calendar_week_id);


--
-- Name: eam_config_props_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_config_props
    ADD CONSTRAINT eam_config_props_pkey PRIMARY KEY (id);


--
-- Name: eam_config_props_prefix_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_config_props
    ADD CONSTRAINT eam_config_props_prefix_key UNIQUE (prefix, propkey);


--
-- Name: eam_config_response_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_config_response
    ADD CONSTRAINT eam_config_response_pkey PRIMARY KEY (id);


--
-- Name: eam_control_history_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_control_history
    ADD CONSTRAINT eam_control_history_pkey PRIMARY KEY (id);


--
-- Name: eam_control_schedule_jobname_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_control_schedule
    ADD CONSTRAINT eam_control_schedule_jobname_key UNIQUE (jobname);


--
-- Name: eam_control_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_control_schedule
    ADD CONSTRAINT eam_control_schedule_pkey PRIMARY KEY (id);


--
-- Name: eam_control_schedule_triggername_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_control_schedule
    ADD CONSTRAINT eam_control_schedule_triggername_key UNIQUE (triggername);


--
-- Name: eam_cprop_appdef_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_cprop
    ADD CONSTRAINT eam_cprop_appdef_id_key UNIQUE (appdef_id, keyid, value_idx);


--
-- Name: eam_cprop_key_appdef_type_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_cprop_key
    ADD CONSTRAINT eam_cprop_key_appdef_type_key UNIQUE (appdef_type, appdef_typeid, propkey);


--
-- Name: eam_cprop_key_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_cprop_key
    ADD CONSTRAINT eam_cprop_key_pkey PRIMARY KEY (id);


--
-- Name: eam_cprop_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_cprop
    ADD CONSTRAINT eam_cprop_pkey PRIMARY KEY (id);


--
-- Name: eam_crispo_array_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_crispo_array
    ADD CONSTRAINT eam_crispo_array_pkey PRIMARY KEY (opt_id, idx);


--
-- Name: eam_crispo_opt_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_crispo_opt
    ADD CONSTRAINT eam_crispo_opt_pkey PRIMARY KEY (id);


--
-- Name: eam_crispo_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_crispo
    ADD CONSTRAINT eam_crispo_pkey PRIMARY KEY (id);


--
-- Name: eam_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_criteria
    ADD CONSTRAINT eam_criteria_pkey PRIMARY KEY (id);


--
-- Name: eam_dash_config_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_dash_config
    ADD CONSTRAINT eam_dash_config_pkey PRIMARY KEY (id);


--
-- Name: eam_dash_config_role_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_dash_config
    ADD CONSTRAINT eam_dash_config_role_id_key UNIQUE (role_id);


--
-- Name: eam_dash_config_user_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_dash_config
    ADD CONSTRAINT eam_dash_config_user_id_key UNIQUE (user_id);


--
-- Name: eam_error_code_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_error_code
    ADD CONSTRAINT eam_error_code_pkey PRIMARY KEY (id);


--
-- Name: eam_escalation_action_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_escalation_action
    ADD CONSTRAINT eam_escalation_action_pkey PRIMARY KEY (escalation_id, idx);


--
-- Name: eam_escalation_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_escalation
    ADD CONSTRAINT eam_escalation_name_key UNIQUE (name);


--
-- Name: eam_escalation_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_escalation
    ADD CONSTRAINT eam_escalation_pkey PRIMARY KEY (id);


--
-- Name: eam_escalation_state_alert_def_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_escalation_state
    ADD CONSTRAINT eam_escalation_state_alert_def_id_key UNIQUE (alert_def_id, alert_type);


--
-- Name: eam_escalation_state_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_escalation_state
    ADD CONSTRAINT eam_escalation_state_pkey PRIMARY KEY (id);


--
-- Name: eam_event_log_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_event_log
    ADD CONSTRAINT eam_event_log_pkey PRIMARY KEY (id);


--
-- Name: eam_exec_strategies_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_exec_strategies
    ADD CONSTRAINT eam_exec_strategies_pkey PRIMARY KEY (id);


--
-- Name: eam_exec_strategy_types_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_exec_strategy_types
    ADD CONSTRAINT eam_exec_strategy_types_pkey PRIMARY KEY (id);


--
-- Name: eam_galert_action_log_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_galert_action_log
    ADD CONSTRAINT eam_galert_action_log_pkey PRIMARY KEY (id);


--
-- Name: eam_galert_aux_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_galert_aux_logs
    ADD CONSTRAINT eam_galert_aux_logs_pkey PRIMARY KEY (id);


--
-- Name: eam_galert_defs_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_galert_defs
    ADD CONSTRAINT eam_galert_defs_pkey PRIMARY KEY (id);


--
-- Name: eam_galert_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_galert_logs
    ADD CONSTRAINT eam_galert_logs_pkey PRIMARY KEY (id);


--
-- Name: eam_gtrigger_types_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_gtrigger_types
    ADD CONSTRAINT eam_gtrigger_types_pkey PRIMARY KEY (id);


--
-- Name: eam_gtriggers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_gtriggers
    ADD CONSTRAINT eam_gtriggers_pkey PRIMARY KEY (id);


--
-- Name: eam_ip_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ip
    ADD CONSTRAINT eam_ip_pkey PRIMARY KEY (id);


--
-- Name: eam_ip_platform_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ip
    ADD CONSTRAINT eam_ip_platform_id_key UNIQUE (platform_id, address);


--
-- Name: eam_measurement_bl_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_bl
    ADD CONSTRAINT eam_measurement_bl_pkey PRIMARY KEY (id);


--
-- Name: eam_measurement_cat_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_cat
    ADD CONSTRAINT eam_measurement_cat_name_key UNIQUE (name);


--
-- Name: eam_measurement_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_cat
    ADD CONSTRAINT eam_measurement_cat_pkey PRIMARY KEY (id);


--
-- Name: eam_measurement_data_1d_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_data_1d
    ADD CONSTRAINT eam_measurement_data_1d_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: eam_measurement_data_1h_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_data_1h
    ADD CONSTRAINT eam_measurement_data_1h_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: eam_measurement_data_6h_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_data_6h
    ADD CONSTRAINT eam_measurement_data_6h_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: eam_measurement_instance_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement
    ADD CONSTRAINT eam_measurement_instance_id_key UNIQUE (instance_id, template_id);


--
-- Name: eam_measurement_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement
    ADD CONSTRAINT eam_measurement_pkey PRIMARY KEY (id);


--
-- Name: eam_measurement_templ_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_measurement_templ
    ADD CONSTRAINT eam_measurement_templ_pkey PRIMARY KEY (id);


--
-- Name: eam_metric_aux_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_metric_aux_logs
    ADD CONSTRAINT eam_metric_aux_logs_pkey PRIMARY KEY (id);


--
-- Name: eam_metric_prob_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_metric_prob
    ADD CONSTRAINT eam_metric_prob_pkey PRIMARY KEY (measurement_id, "timestamp", additional);


--
-- Name: eam_monitorable_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_monitorable_type
    ADD CONSTRAINT eam_monitorable_type_pkey PRIMARY KEY (id);


--
-- Name: eam_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_numbers
    ADD CONSTRAINT eam_numbers_pkey PRIMARY KEY (i);


--
-- Name: eam_operation_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_operation
    ADD CONSTRAINT eam_operation_name_key UNIQUE (name, resource_type_id);


--
-- Name: eam_operation_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_operation
    ADD CONSTRAINT eam_operation_pkey PRIMARY KEY (id);


--
-- Name: eam_platform_fqdn_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_platform
    ADD CONSTRAINT eam_platform_fqdn_key UNIQUE (fqdn);


--
-- Name: eam_platform_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_platform
    ADD CONSTRAINT eam_platform_pkey PRIMARY KEY (id);


--
-- Name: eam_platform_server_type_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_platform_server_type_map
    ADD CONSTRAINT eam_platform_server_type_map_pkey PRIMARY KEY (server_type_id, platform_type_id);


--
-- Name: eam_platform_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_platform_type
    ADD CONSTRAINT eam_platform_type_pkey PRIMARY KEY (id);


--
-- Name: eam_plugin_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_plugin
    ADD CONSTRAINT eam_plugin_name_key UNIQUE (name);


--
-- Name: eam_plugin_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_plugin
    ADD CONSTRAINT eam_plugin_pkey PRIMARY KEY (id);


--
-- Name: eam_principal_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_principal
    ADD CONSTRAINT eam_principal_pkey PRIMARY KEY (id);


--
-- Name: eam_principal_principal_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_principal
    ADD CONSTRAINT eam_principal_principal_key UNIQUE (principal);


--
-- Name: eam_registered_trigger_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_registered_trigger
    ADD CONSTRAINT eam_registered_trigger_pkey PRIMARY KEY (id);


--
-- Name: eam_request_stat_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_request_stat
    ADD CONSTRAINT eam_request_stat_pkey PRIMARY KEY (id);


--
-- Name: eam_res_grp_res_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_res_grp_res_map
    ADD CONSTRAINT eam_res_grp_res_map_pkey PRIMARY KEY (id);


--
-- Name: eam_res_grp_res_map_resource_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_res_grp_res_map
    ADD CONSTRAINT eam_res_grp_res_map_resource_id_key UNIQUE (resource_id, resource_group_id);


--
-- Name: eam_resource_aux_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_aux_logs
    ADD CONSTRAINT eam_resource_aux_logs_pkey PRIMARY KEY (id);


--
-- Name: eam_resource_edge_from_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_edge
    ADD CONSTRAINT eam_resource_edge_from_id_key UNIQUE (from_id, to_id, rel_id, distance);


--
-- Name: eam_resource_edge_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_edge
    ADD CONSTRAINT eam_resource_edge_pkey PRIMARY KEY (id);


--
-- Name: eam_resource_group_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_group
    ADD CONSTRAINT eam_resource_group_pkey PRIMARY KEY (id);


--
-- Name: eam_resource_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource
    ADD CONSTRAINT eam_resource_pkey PRIMARY KEY (id);


--
-- Name: eam_resource_relation_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_relation
    ADD CONSTRAINT eam_resource_relation_name_key UNIQUE (name);


--
-- Name: eam_resource_relation_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_relation
    ADD CONSTRAINT eam_resource_relation_pkey PRIMARY KEY (id);


--
-- Name: eam_resource_type_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_type
    ADD CONSTRAINT eam_resource_type_name_key UNIQUE (name);


--
-- Name: eam_resource_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_type
    ADD CONSTRAINT eam_resource_type_pkey PRIMARY KEY (id);


--
-- Name: eam_resource_type_resource_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_resource_type
    ADD CONSTRAINT eam_resource_type_resource_id_key UNIQUE (resource_id);


--
-- Name: eam_role_calendar_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_role_calendar
    ADD CONSTRAINT eam_role_calendar_pkey PRIMARY KEY (id);


--
-- Name: eam_role_calendar_role_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_role_calendar
    ADD CONSTRAINT eam_role_calendar_role_id_key UNIQUE (role_id, calendar_id, caltype);


--
-- Name: eam_role_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_role
    ADD CONSTRAINT eam_role_name_key UNIQUE (name);


--
-- Name: eam_role_operation_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_role_operation_map
    ADD CONSTRAINT eam_role_operation_map_pkey PRIMARY KEY (role_id, operation_id);


--
-- Name: eam_role_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_role
    ADD CONSTRAINT eam_role_pkey PRIMARY KEY (id);


--
-- Name: eam_role_resource_group_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_role_resource_group_map
    ADD CONSTRAINT eam_role_resource_group_map_pkey PRIMARY KEY (resource_group_id, role_id);


--
-- Name: eam_server_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_server
    ADD CONSTRAINT eam_server_pkey PRIMARY KEY (id);


--
-- Name: eam_server_platform_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_server
    ADD CONSTRAINT eam_server_platform_id_key UNIQUE (platform_id, autoinventoryidentifier);


--
-- Name: eam_server_type_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_server_type
    ADD CONSTRAINT eam_server_type_name_key UNIQUE (name);


--
-- Name: eam_server_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_server_type
    ADD CONSTRAINT eam_server_type_pkey PRIMARY KEY (id);


--
-- Name: eam_service_dep_map_appservice_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_service_dep_map
    ADD CONSTRAINT eam_service_dep_map_appservice_id_key UNIQUE (appservice_id, dependent_service_id);


--
-- Name: eam_service_dep_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_service_dep_map
    ADD CONSTRAINT eam_service_dep_map_pkey PRIMARY KEY (id);


--
-- Name: eam_service_id_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT eam_service_id_key UNIQUE (id, parent_service_id);


--
-- Name: eam_service_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT eam_service_pkey PRIMARY KEY (id);


--
-- Name: eam_service_request_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_service_request
    ADD CONSTRAINT eam_service_request_pkey PRIMARY KEY (id);


--
-- Name: eam_service_type_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_service_type
    ADD CONSTRAINT eam_service_type_pkey PRIMARY KEY (id);


--
-- Name: eam_srn_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_srn
    ADD CONSTRAINT eam_srn_pkey PRIMARY KEY (instance_id, appdef_type);


--
-- Name: eam_stat_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_stat_errors
    ADD CONSTRAINT eam_stat_errors_pkey PRIMARY KEY (id);


--
-- Name: eam_subject_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_subject
    ADD CONSTRAINT eam_subject_name_key UNIQUE (name, dsn);


--
-- Name: eam_subject_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_subject
    ADD CONSTRAINT eam_subject_pkey PRIMARY KEY (id);


--
-- Name: eam_subject_role_map_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_subject_role_map
    ADD CONSTRAINT eam_subject_role_map_pkey PRIMARY KEY (subject_id, role_id);


--
-- Name: eam_ui_attach_admin_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_attach_admin
    ADD CONSTRAINT eam_ui_attach_admin_pkey PRIMARY KEY (attach_id);


--
-- Name: eam_ui_attach_mast_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_attach_mast
    ADD CONSTRAINT eam_ui_attach_mast_pkey PRIMARY KEY (attach_id);


--
-- Name: eam_ui_attach_rsrc_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_attach_rsrc
    ADD CONSTRAINT eam_ui_attach_rsrc_pkey PRIMARY KEY (attach_id);


--
-- Name: eam_ui_attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_attachment
    ADD CONSTRAINT eam_ui_attachment_pkey PRIMARY KEY (id);


--
-- Name: eam_ui_plugin_name_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_plugin
    ADD CONSTRAINT eam_ui_plugin_name_key UNIQUE (name);


--
-- Name: eam_ui_plugin_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_plugin
    ADD CONSTRAINT eam_ui_plugin_pkey PRIMARY KEY (id);


--
-- Name: eam_ui_view_admin_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_view_admin
    ADD CONSTRAINT eam_ui_view_admin_pkey PRIMARY KEY (view_id);


--
-- Name: eam_ui_view_masthead_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_view_masthead
    ADD CONSTRAINT eam_ui_view_masthead_pkey PRIMARY KEY (view_id);


--
-- Name: eam_ui_view_path_key; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_view
    ADD CONSTRAINT eam_ui_view_path_key UNIQUE (path);


--
-- Name: eam_ui_view_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_view
    ADD CONSTRAINT eam_ui_view_pkey PRIMARY KEY (id);


--
-- Name: eam_ui_view_resource_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_ui_view_resource
    ADD CONSTRAINT eam_ui_view_resource_pkey PRIMARY KEY (view_id);


--
-- Name: eam_update_status_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_update_status
    ADD CONSTRAINT eam_update_status_pkey PRIMARY KEY (id);


--
-- Name: eam_virtual_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY eam_virtual
    ADD CONSTRAINT eam_virtual_pkey PRIMARY KEY (resource_id);


--
-- Name: hq_avail_data_rle_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_avail_data_rle
    ADD CONSTRAINT hq_avail_data_rle_pkey PRIMARY KEY (measurement_id, startime);


--
-- Name: hq_metric_data_0d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_0d_0s
    ADD CONSTRAINT hq_metric_data_0d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_0d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_0d_1s
    ADD CONSTRAINT hq_metric_data_0d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_1d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_1d_0s
    ADD CONSTRAINT hq_metric_data_1d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_1d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_1d_1s
    ADD CONSTRAINT hq_metric_data_1d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_2d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_2d_0s
    ADD CONSTRAINT hq_metric_data_2d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_2d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_2d_1s
    ADD CONSTRAINT hq_metric_data_2d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_3d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_3d_0s
    ADD CONSTRAINT hq_metric_data_3d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_3d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_3d_1s
    ADD CONSTRAINT hq_metric_data_3d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_4d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_4d_0s
    ADD CONSTRAINT hq_metric_data_4d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_4d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_4d_1s
    ADD CONSTRAINT hq_metric_data_4d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_5d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_5d_0s
    ADD CONSTRAINT hq_metric_data_5d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_5d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_5d_1s
    ADD CONSTRAINT hq_metric_data_5d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_6d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_6d_0s
    ADD CONSTRAINT hq_metric_data_6d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_6d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_6d_1s
    ADD CONSTRAINT hq_metric_data_6d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_7d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_7d_0s
    ADD CONSTRAINT hq_metric_data_7d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_7d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_7d_1s
    ADD CONSTRAINT hq_metric_data_7d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_8d_0s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_8d_0s
    ADD CONSTRAINT hq_metric_data_8d_0s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_8d_1s_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_8d_1s
    ADD CONSTRAINT hq_metric_data_8d_1s_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: hq_metric_data_compat_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY hq_metric_data_compat
    ADD CONSTRAINT hq_metric_data_compat_pkey PRIMARY KEY ("timestamp", measurement_id);


--
-- Name: qrtz_blob_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_calendars
    ADD CONSTRAINT qrtz_calendars_pkey PRIMARY KEY (calendar_name);


--
-- Name: qrtz_cron_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_fired_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_fired_triggers
    ADD CONSTRAINT qrtz_fired_triggers_pkey PRIMARY KEY (entry_id);


--
-- Name: qrtz_job_details_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_job_details
    ADD CONSTRAINT qrtz_job_details_pkey PRIMARY KEY (job_name, job_group);


--
-- Name: qrtz_job_listeners_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_job_listeners
    ADD CONSTRAINT qrtz_job_listeners_pkey PRIMARY KEY (job_name, job_group, job_listener);


--
-- Name: qrtz_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_locks
    ADD CONSTRAINT qrtz_locks_pkey PRIMARY KEY (lock_name);


--
-- Name: qrtz_paused_trigger_grps_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_paused_trigger_grps
    ADD CONSTRAINT qrtz_paused_trigger_grps_pkey PRIMARY KEY (trigger_group);


--
-- Name: qrtz_scheduler_state_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_scheduler_state
    ADD CONSTRAINT qrtz_scheduler_state_pkey PRIMARY KEY (instance_name);


--
-- Name: qrtz_simple_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: qrtz_trigger_listeners_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_trigger_listeners
    ADD CONSTRAINT qrtz_trigger_listeners_pkey PRIMARY KEY (trigger_name, trigger_group, trigger_listener);


--
-- Name: qrtz_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: hqadmin; Tablespace: 
--

ALTER TABLE ONLY qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_pkey PRIMARY KEY (trigger_name, trigger_group);


--
-- Name: acknowledged_by_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX acknowledged_by_idx ON eam_escalation_state USING btree (acknowledged_by);


--
-- Name: action_alert_definition_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX action_alert_definition_id_idx ON eam_action USING btree (alert_definition_id);


--
-- Name: action_child_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX action_child_idx ON eam_action USING btree (parent_id);


--
-- Name: agent_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX agent_id_idx ON eam_platform USING btree (agent_id);


--
-- Name: agent_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX agent_type_id_idx ON eam_agent USING btree (agent_type_id);


--
-- Name: ai_hist_scanname_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ai_hist_scanname_idx ON eam_autoinv_history USING btree (scanname);


--
-- Name: ai_schedule_entity_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ai_schedule_entity_idx ON eam_autoinv_schedule USING btree (entity_id, entity_type);


--
-- Name: ai_schedule_nextfiretime_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ai_schedule_nextfiretime_idx ON eam_autoinv_schedule USING btree (nextfiretime);


--
-- Name: aiq_platform_agenttoken_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aiq_platform_agenttoken_idx ON eam_aiq_platform USING btree (agenttoken);


--
-- Name: aiq_server_name; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aiq_server_name ON eam_aiq_server USING btree (name);


--
-- Name: aiq_service_name_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aiq_service_name_idx ON eam_aiq_service USING btree (name);


--
-- Name: aiq_svc_server_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aiq_svc_server_id_idx ON eam_aiq_service USING btree (server_id);


--
-- Name: alert_action_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_action_id_idx ON eam_alert_action_log USING btree (action_id);


--
-- Name: alert_action_log_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_action_log_idx ON eam_alert_action_log USING btree (alert_id);


--
-- Name: alert_action_subj_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_action_subj_id_idx ON eam_alert_action_log USING btree (subject_id);


--
-- Name: alert_alertdefinition_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_alertdefinition_idx ON eam_alert USING btree (alert_definition_id);


--
-- Name: alert_cond_alert_def_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_cond_alert_def_idx ON eam_alert_condition USING btree (alert_definition_id);


--
-- Name: alert_cond_log_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_cond_log_idx ON eam_alert_condition_log USING btree (alert_id);


--
-- Name: alert_cond_trigger_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_cond_trigger_id_idx ON eam_alert_condition USING btree (trigger_id);


--
-- Name: alert_condition_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_condition_id_idx ON eam_alert_condition_log USING btree (condition_id);


--
-- Name: alert_def_child_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_def_child_idx ON eam_alert_definition USING btree (parent_id, priority);


--
-- Name: alert_def_esc_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_def_esc_id_idx ON eam_alert_definition USING btree (escalation_id);


--
-- Name: alert_def_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_def_res_id_idx ON eam_alert_definition USING btree (resource_id);


--
-- Name: alert_def_trigger_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_def_trigger_idx ON eam_registered_trigger USING btree (alert_definition_id);


--
-- Name: alert_time_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX alert_time_idx ON eam_alert USING btree (ctime);


--
-- Name: app_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX app_res_id_idx ON eam_application USING btree (resource_id);


--
-- Name: app_svc_app_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX app_svc_app_id_idx ON eam_app_service USING btree (application_id);


--
-- Name: app_svc_grp_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX app_svc_grp_id_idx ON eam_app_service USING btree (group_id);


--
-- Name: app_svc_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX app_svc_type_id_idx ON eam_app_service USING btree (service_type_id);


--
-- Name: app_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX app_type_id_idx ON eam_application USING btree (application_type_id);


--
-- Name: aux_log_def_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aux_log_def_idx ON eam_galert_aux_logs USING btree (def_id);


--
-- Name: aux_log_galert_id; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aux_log_galert_id ON eam_galert_aux_logs USING btree (galert_id);


--
-- Name: aux_log_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aux_log_id_idx ON eam_metric_aux_logs USING btree (aux_log_id);


--
-- Name: aux_log_metric_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX aux_log_metric_id_idx ON eam_metric_aux_logs USING btree (metric_id);


--
-- Name: avail_rle_endtime_val_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX avail_rle_endtime_val_idx ON hq_avail_data_rle USING btree (endtime, availval);


--
-- Name: calendar_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX calendar_id_idx ON eam_calendar_ent USING btree (calendar_id);


--
-- Name: config_response_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX config_response_id_idx ON eam_platform USING btree (config_response_id);


--
-- Name: cresp_err_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX cresp_err_idx ON eam_config_response USING btree (validationerr);


--
-- Name: crispo_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX crispo_idx ON eam_crispo_opt USING btree (crispo_id);


--
-- Name: criteria_res_grp_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX criteria_res_grp_id_idx ON eam_criteria USING btree (resource_group_id);


--
-- Name: criteria_resource_id_prop_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX criteria_resource_id_prop_idx ON eam_criteria USING btree (resource_id_prop);


--
-- Name: ctl_history_starttime_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ctl_history_starttime_idx ON eam_control_history USING btree (starttime);


--
-- Name: ctl_schedule_entity_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ctl_schedule_entity_idx ON eam_control_schedule USING btree (entity_id, entity_type);


--
-- Name: ctl_schedule_nextfiretime_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ctl_schedule_nextfiretime_idx ON eam_control_schedule USING btree (nextfiretime);


--
-- Name: dash_config_crispo_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX dash_config_crispo_id_idx ON eam_dash_config USING btree (crispo_id);


--
-- Name: dependent_svc_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX dependent_svc_id_idx ON eam_service_dep_map USING btree (dependent_service_id);


--
-- Name: eam_galert_logs_time_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_galert_logs_time_idx ON eam_galert_logs USING btree ("timestamp");


--
-- Name: eam_resource_instance_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_resource_instance_id_idx ON eam_resource USING btree (instance_id);


--
-- Name: eam_resource_owner_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_resource_owner_id_idx ON eam_resource USING btree (subject_id);


--
-- Name: eam_resource_proto_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_resource_proto_idx ON eam_resource USING btree (proto_id);


--
-- Name: eam_resource_to_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_resource_to_id_idx ON eam_resource_edge USING btree (to_id);


--
-- Name: eam_server_type_plugin_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_server_type_plugin_idx ON eam_server_type USING btree (plugin);


--
-- Name: eam_service_aiid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_service_aiid_idx ON eam_service USING btree (server_id, autoinventoryidentifier);


--
-- Name: eam_subject_resource_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX eam_subject_resource_idx ON eam_subject USING btree (resource_id);


--
-- Name: error_code; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX error_code ON eam_error_code USING btree (code);


--
-- Name: esc_action_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX esc_action_id_idx ON eam_escalation_action USING btree (action_id);


--
-- Name: event_log_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX event_log_idx ON eam_event_log USING btree ("timestamp", resource_id);


--
-- Name: event_log_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX event_log_res_id_idx ON eam_event_log USING btree (resource_id);


--
-- Name: exec_strategies_config_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX exec_strategies_config_id_idx ON eam_exec_strategies USING btree (config_id);


--
-- Name: exec_strategies_def_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX exec_strategies_def_id_idx ON eam_exec_strategies USING btree (def_id);


--
-- Name: exec_strategies_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX exec_strategies_type_id_idx ON eam_exec_strategies USING btree (type_id);


--
-- Name: galert_action_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_action_id_idx ON eam_galert_action_log USING btree (action_id);


--
-- Name: galert_action_log_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_action_log_idx ON eam_galert_action_log USING btree (galert_id);


--
-- Name: galert_action_subject_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_action_subject_id_idx ON eam_galert_action_log USING btree (subject_id);


--
-- Name: galert_aux_logs_parent_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_aux_logs_parent_idx ON eam_galert_aux_logs USING btree (parent);


--
-- Name: galert_defs_esc_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_defs_esc_id_idx ON eam_galert_defs USING btree (escalation_id);


--
-- Name: galert_defs_group_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_defs_group_id_idx ON eam_galert_defs USING btree (group_id);


--
-- Name: galert_logs_def_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX galert_logs_def_id_idx ON eam_galert_logs USING btree (def_id);


--
-- Name: group_group_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX group_group_idx ON eam_res_grp_res_map USING btree (resource_group_id);


--
-- Name: group_member_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX group_member_idx ON eam_res_grp_res_map USING btree (resource_id);


--
-- Name: gtriggers_config_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX gtriggers_config_id_idx ON eam_gtriggers USING btree (config_id);


--
-- Name: gtriggers_strat_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX gtriggers_strat_id_idx ON eam_gtriggers USING btree (strat_id);


--
-- Name: gtriggers_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX gtriggers_type_id_idx ON eam_gtriggers USING btree (type_id);


--
-- Name: keyid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX keyid_idx ON eam_cprop USING btree (keyid);


--
-- Name: meas_enabled_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX meas_enabled_idx ON eam_measurement USING btree (enabled);


--
-- Name: meas_res_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX meas_res_idx ON eam_measurement USING btree (resource_id);


--
-- Name: meas_template_id; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX meas_template_id ON eam_measurement USING btree (template_id);


--
-- Name: measurement_data_1d_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX measurement_data_1d_mid_idx ON eam_measurement_data_1d USING btree (measurement_id);


--
-- Name: measurement_data_1h_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX measurement_data_1h_mid_idx ON eam_measurement_data_1h USING btree (measurement_id);


--
-- Name: measurement_data_6h_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX measurement_data_6h_mid_idx ON eam_measurement_data_6h USING btree (measurement_id);


--
-- Name: metric_aux_log_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_aux_log_id_idx ON eam_resource_aux_logs USING btree (aux_log_id);


--
-- Name: metric_aux_log_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_aux_log_idx ON eam_metric_aux_logs USING btree (def_id);


--
-- Name: metric_baseline_calculated_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_baseline_calculated_idx ON eam_measurement_bl USING btree (measurement_id, compute_time);


--
-- Name: metric_data_0d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_0d_0s_mid_idx ON hq_metric_data_0d_0s USING btree (measurement_id);


--
-- Name: metric_data_0d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_0d_1s_mid_idx ON hq_metric_data_0d_1s USING btree (measurement_id);


--
-- Name: metric_data_1d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_1d_0s_mid_idx ON hq_metric_data_1d_0s USING btree (measurement_id);


--
-- Name: metric_data_1d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_1d_1s_mid_idx ON hq_metric_data_1d_1s USING btree (measurement_id);


--
-- Name: metric_data_2d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_2d_0s_mid_idx ON hq_metric_data_2d_0s USING btree (measurement_id);


--
-- Name: metric_data_2d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_2d_1s_mid_idx ON hq_metric_data_2d_1s USING btree (measurement_id);


--
-- Name: metric_data_3d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_3d_0s_mid_idx ON hq_metric_data_3d_0s USING btree (measurement_id);


--
-- Name: metric_data_3d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_3d_1s_mid_idx ON hq_metric_data_3d_1s USING btree (measurement_id);


--
-- Name: metric_data_4d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_4d_0s_mid_idx ON hq_metric_data_4d_0s USING btree (measurement_id);


--
-- Name: metric_data_4d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_4d_1s_mid_idx ON hq_metric_data_4d_1s USING btree (measurement_id);


--
-- Name: metric_data_5d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_5d_0s_mid_idx ON hq_metric_data_5d_0s USING btree (measurement_id);


--
-- Name: metric_data_5d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_5d_1s_mid_idx ON hq_metric_data_5d_1s USING btree (measurement_id);


--
-- Name: metric_data_6d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_6d_0s_mid_idx ON hq_metric_data_6d_0s USING btree (measurement_id);


--
-- Name: metric_data_6d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_6d_1s_mid_idx ON hq_metric_data_6d_1s USING btree (measurement_id);


--
-- Name: metric_data_7d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_7d_0s_mid_idx ON hq_metric_data_7d_0s USING btree (measurement_id);


--
-- Name: metric_data_7d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_7d_1s_mid_idx ON hq_metric_data_7d_1s USING btree (measurement_id);


--
-- Name: metric_data_8d_0s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_8d_0s_mid_idx ON hq_metric_data_8d_0s USING btree (measurement_id);


--
-- Name: metric_data_8d_1s_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_8d_1s_mid_idx ON hq_metric_data_8d_1s USING btree (measurement_id);


--
-- Name: metric_data_compat_mid_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX metric_data_compat_mid_idx ON hq_metric_data_compat USING btree (measurement_id);


--
-- Name: op_res_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX op_res_type_id_idx ON eam_operation USING btree (resource_type_id);


--
-- Name: parent_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX parent_id_idx ON eam_audit USING btree (parent_id);


--
-- Name: parent_service_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX parent_service_id_idx ON eam_service USING btree (parent_service_id);


--
-- Name: platform_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX platform_res_id_idx ON eam_platform USING btree (resource_id);


--
-- Name: platform_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX platform_type_id_idx ON eam_platform USING btree (platform_type_id);


--
-- Name: pref_crispo_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX pref_crispo_id_idx ON eam_subject USING btree (pref_crispo_id);


--
-- Name: rel_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX rel_id_idx ON eam_resource_edge USING btree (rel_id);


--
-- Name: reqstat_idx_begintime; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX reqstat_idx_begintime ON eam_request_stat USING btree (begintime);


--
-- Name: reqstat_idx_endtime; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX reqstat_idx_endtime ON eam_request_stat USING btree (endtime);


--
-- Name: res_grp_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX res_grp_res_id_idx ON eam_resource_group USING btree (resource_id);


--
-- Name: res_proto_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX res_proto_idx ON eam_resource_group USING btree (resource_prototype);


--
-- Name: resource_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX resource_id_idx ON eam_audit USING btree (resource_id);


--
-- Name: role_cal_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX role_cal_id_idx ON eam_role_calendar USING btree (calendar_id);


--
-- Name: role_op_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX role_op_id_idx ON eam_role_operation_map USING btree (operation_id);


--
-- Name: role_res_grp_role_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX role_res_grp_role_id_idx ON eam_role_resource_group_map USING btree (role_id);


--
-- Name: role_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX role_res_id_idx ON eam_role USING btree (resource_id);


--
-- Name: rsrc_aux_log_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX rsrc_aux_log_idx ON eam_resource_aux_logs USING btree (def_id);


--
-- Name: server_config_response_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX server_config_response_id_idx ON eam_server USING btree (config_response_id);


--
-- Name: server_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX server_res_id_idx ON eam_server USING btree (resource_id);


--
-- Name: server_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX server_type_id_idx ON eam_server USING btree (server_type_id);


--
-- Name: service_id; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX service_id ON eam_request_stat USING btree (svcreq_id);


--
-- Name: service_request_svcid; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX service_request_svcid ON eam_service_request USING btree (serviceid);


--
-- Name: service_request_url; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX service_request_url ON eam_service_request USING btree (url);


--
-- Name: service_resource_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX service_resource_id_idx ON eam_service USING btree (resource_id);


--
-- Name: stat_errors_error_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX stat_errors_error_id_idx ON eam_stat_errors USING btree (error_id);


--
-- Name: stat_errors_reqstat; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX stat_errors_reqstat ON eam_stat_errors USING btree (reqstat_id);


--
-- Name: subject_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX subject_id_idx ON eam_audit USING btree (subject_id);


--
-- Name: svc_config_resp_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX svc_config_resp_id_idx ON eam_service USING btree (config_response_id);


--
-- Name: svc_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX svc_type_id_idx ON eam_service USING btree (service_type_id);


--
-- Name: svc_type_server_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX svc_type_server_type_id_idx ON eam_service_type USING btree (server_type_id);


--
-- Name: templ_category_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX templ_category_idx ON eam_measurement_templ USING btree (category_id);


--
-- Name: templ_desig_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX templ_desig_idx ON eam_measurement_templ USING btree (designate);


--
-- Name: templ_monitorable_type_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX templ_monitorable_type_id_idx ON eam_measurement_templ USING btree (monitorable_type_id);


--
-- Name: type_name_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX type_name_idx ON eam_monitorable_type USING btree (name);


--
-- Name: ui_attachment_res_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ui_attachment_res_id_idx ON eam_ui_attach_rsrc USING btree (resource_id);


--
-- Name: ui_attachment_view_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ui_attachment_view_id_idx ON eam_ui_attachment USING btree (view_id);


--
-- Name: ui_plugin_id_idx; Type: INDEX; Schema: public; Owner: hqadmin; Tablespace: 
--

CREATE INDEX ui_plugin_id_idx ON eam_ui_view USING btree (ui_plugin_id);


--
-- Name: eam_fk_qbt_qt; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY qrtz_blob_triggers
    ADD CONSTRAINT eam_fk_qbt_qt FOREIGN KEY (trigger_name, trigger_group) REFERENCES qrtz_triggers(trigger_name, trigger_group);


--
-- Name: eam_fk_qct_qt; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY qrtz_cron_triggers
    ADD CONSTRAINT eam_fk_qct_qt FOREIGN KEY (trigger_name, trigger_group) REFERENCES qrtz_triggers(trigger_name, trigger_group);


--
-- Name: eam_fk_qjl_qjd; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY qrtz_job_listeners
    ADD CONSTRAINT eam_fk_qjl_qjd FOREIGN KEY (job_name, job_group) REFERENCES qrtz_job_details(job_name, job_group) ON DELETE CASCADE;


--
-- Name: eam_fk_qst_qt; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY qrtz_simple_triggers
    ADD CONSTRAINT eam_fk_qst_qt FOREIGN KEY (trigger_name, trigger_group) REFERENCES qrtz_triggers(trigger_name, trigger_group);


--
-- Name: eam_fk_qt_qjd; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY qrtz_triggers
    ADD CONSTRAINT eam_fk_qt_qjd FOREIGN KEY (job_name, job_group) REFERENCES qrtz_job_details(job_name, job_group) ON DELETE CASCADE;


--
-- Name: eam_fk_qtl_qt; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY qrtz_trigger_listeners
    ADD CONSTRAINT eam_fk_qtl_qt FOREIGN KEY (trigger_name, trigger_group) REFERENCES qrtz_triggers(trigger_name, trigger_group) ON DELETE CASCADE;


--
-- Name: fk1877029bb6e3839c; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_measurement_bl
    ADD CONSTRAINT fk1877029bb6e3839c FOREIGN KEY (measurement_id) REFERENCES eam_measurement(id) ON DELETE CASCADE;


--
-- Name: fk1c835366da1b7c9; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_res_grp_res_map
    ADD CONSTRAINT fk1c835366da1b7c9 FOREIGN KEY (resource_group_id) REFERENCES eam_resource_group(id);


--
-- Name: fk1c83536fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_res_grp_res_map
    ADD CONSTRAINT fk1c83536fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fk1ef56c811a5420bd; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_dash_config
    ADD CONSTRAINT fk1ef56c811a5420bd FOREIGN KEY (user_id) REFERENCES eam_subject(id);


--
-- Name: fk1ef56c816364efcd; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_dash_config
    ADD CONSTRAINT fk1ef56c816364efcd FOREIGN KEY (crispo_id) REFERENCES eam_crispo(id);


--
-- Name: fk1ef56c8199d737ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_dash_config
    ADD CONSTRAINT fk1ef56c8199d737ae FOREIGN KEY (role_id) REFERENCES eam_role(id);


--
-- Name: fk253d70712a378d8; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_measurement_templ
    ADD CONSTRAINT fk253d70712a378d8 FOREIGN KEY (category_id) REFERENCES eam_measurement_cat(id);


--
-- Name: fk253d707ef33c225; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_measurement_templ
    ADD CONSTRAINT fk253d707ef33c225 FOREIGN KEY (monitorable_type_id) REFERENCES eam_monitorable_type(id);


--
-- Name: fk2807df20f6253048; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_attachment
    ADD CONSTRAINT fk2807df20f6253048 FOREIGN KEY (view_id) REFERENCES eam_ui_view(id);


--
-- Name: fk320f631499d737ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_subject_role_map
    ADD CONSTRAINT fk320f631499d737ae FOREIGN KEY (role_id) REFERENCES eam_role(id);


--
-- Name: fk320f6314e82fbc; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_subject_role_map
    ADD CONSTRAINT fk320f6314e82fbc FOREIGN KEY (subject_id) REFERENCES eam_subject(id);


--
-- Name: fk36efcad46a3b098; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_criteria
    ADD CONSTRAINT fk36efcad46a3b098 FOREIGN KEY (resource_id_prop) REFERENCES eam_resource(id);


--
-- Name: fk36efcad6da1b7c9; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_criteria
    ADD CONSTRAINT fk36efcad6da1b7c9 FOREIGN KEY (resource_group_id) REFERENCES eam_resource_group(id);


--
-- Name: fk3e0f978ec37f24b8; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_measurement
    ADD CONSTRAINT fk3e0f978ec37f24b8 FOREIGN KEY (template_id) REFERENCES eam_measurement_templ(id);


--
-- Name: fk3e0f978efc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_measurement
    ADD CONSTRAINT fk3e0f978efc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fk423fa3cc1aa4e259; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_action_log
    ADD CONSTRAINT fk423fa3cc1aa4e259 FOREIGN KEY (alert_id) REFERENCES eam_alert(id) ON DELETE CASCADE;


--
-- Name: fk423fa3cc9c76c3bb; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_action_log
    ADD CONSTRAINT fk423fa3cc9c76c3bb FOREIGN KEY (action_id) REFERENCES eam_action(id) ON DELETE CASCADE;


--
-- Name: fk423fa3cce82fbc; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_action_log
    ADD CONSTRAINT fk423fa3cce82fbc FOREIGN KEY (subject_id) REFERENCES eam_subject(id);


--
-- Name: fk4a8354a9b5af9d12; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_registered_trigger
    ADD CONSTRAINT fk4a8354a9b5af9d12 FOREIGN KEY (alert_definition_id) REFERENCES eam_alert_definition(id) ON DELETE CASCADE;


--
-- Name: fk4be3f5b539b1d30d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_platform_server_type_map
    ADD CONSTRAINT fk4be3f5b539b1d30d FOREIGN KEY (server_type_id) REFERENCES eam_server_type(id);


--
-- Name: fk4be3f5b5e3e1026d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_platform_server_type_map
    ADD CONSTRAINT fk4be3f5b5e3e1026d FOREIGN KEY (platform_type_id) REFERENCES eam_platform_type(id);


--
-- Name: fk54ae97741dab49e3; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_gtriggers
    ADD CONSTRAINT fk54ae97741dab49e3 FOREIGN KEY (config_id) REFERENCES eam_crispo(id);


--
-- Name: fk54ae97747d9b78af; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_gtriggers
    ADD CONSTRAINT fk54ae97747d9b78af FOREIGN KEY (strat_id) REFERENCES eam_exec_strategies(id);


--
-- Name: fk54ae9774ce0ff839; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_gtriggers
    ADD CONSTRAINT fk54ae9774ce0ff839 FOREIGN KEY (type_id) REFERENCES eam_gtrigger_types(id);


--
-- Name: fk55818051fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_event_log
    ADD CONSTRAINT fk55818051fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fk5a2c503aaac031cf; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_app_type_service_type_map
    ADD CONSTRAINT fk5a2c503aaac031cf FOREIGN KEY (application_type_id) REFERENCES eam_application_type(id);


--
-- Name: fk5a2c503ab648cf19; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_app_type_service_type_map
    ADD CONSTRAINT fk5a2c503ab648cf19 FOREIGN KEY (service_type_id) REFERENCES eam_service_type(id);


--
-- Name: fk5fd54e62b5f36a31; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_view
    ADD CONSTRAINT fk5fd54e62b5f36a31 FOREIGN KEY (ui_plugin_id) REFERENCES eam_ui_plugin(id);


--
-- Name: fk60c6c4e71bff8500; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_aiq_server
    ADD CONSTRAINT fk60c6c4e71bff8500 FOREIGN KEY (aiq_platform_id) REFERENCES eam_aiq_platform(id) ON DELETE CASCADE;


--
-- Name: fk6406d772d494bca6; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_attach_admin
    ADD CONSTRAINT fk6406d772d494bca6 FOREIGN KEY (attach_id) REFERENCES eam_ui_attachment(id) ON DELETE CASCADE;


--
-- Name: fk64f3daa5029efd7; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_defs
    ADD CONSTRAINT fk64f3daa5029efd7 FOREIGN KEY (escalation_id) REFERENCES eam_escalation(id);


--
-- Name: fk64f3daacce79ab8; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_defs
    ADD CONSTRAINT fk64f3daacce79ab8 FOREIGN KEY (group_id) REFERENCES eam_resource_group(id);


--
-- Name: fk653064b706267a5; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_logs
    ADD CONSTRAINT fk653064b706267a5 FOREIGN KEY (def_id) REFERENCES eam_galert_defs(id);


--
-- Name: fk6c0c122aac031cf; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_application
    ADD CONSTRAINT fk6c0c122aac031cf FOREIGN KEY (application_type_id) REFERENCES eam_application_type(id) ON DELETE CASCADE;


--
-- Name: fk6c0c122fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_application
    ADD CONSTRAINT fk6c0c122fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fk6dbccdbc190495f3; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_group
    ADD CONSTRAINT fk6dbccdbc190495f3 FOREIGN KEY (resource_prototype) REFERENCES eam_resource(id);


--
-- Name: fk6dbccdbcfc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_group
    ADD CONSTRAINT fk6dbccdbcfc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fk6e8f9e9cb6e3839c; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY hq_avail_data_rle
    ADD CONSTRAINT fk6e8f9e9cb6e3839c FOREIGN KEY (measurement_id) REFERENCES eam_measurement(id) ON DELETE CASCADE;


--
-- Name: fk6f2383a8237d366c; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_stat_errors
    ADD CONSTRAINT fk6f2383a8237d366c FOREIGN KEY (error_id) REFERENCES eam_error_code(id) ON DELETE CASCADE;


--
-- Name: fk6f2383a82de89070; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_stat_errors
    ADD CONSTRAINT fk6f2383a82de89070 FOREIGN KEY (reqstat_id) REFERENCES eam_request_stat(id) ON DELETE CASCADE;


--
-- Name: fk7815eb12f6253048; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_view_admin
    ADD CONSTRAINT fk7815eb12f6253048 FOREIGN KEY (view_id) REFERENCES eam_ui_view(id) ON DELETE CASCADE;


--
-- Name: fk7976c8f56796aa86; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ip
    ADD CONSTRAINT fk7976c8f56796aa86 FOREIGN KEY (platform_id) REFERENCES eam_platform(id) ON DELETE CASCADE;


--
-- Name: fk7ac0e15c8b366a94; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource
    ADD CONSTRAINT fk7ac0e15c8b366a94 FOREIGN KEY (proto_id) REFERENCES eam_resource(id);


--
-- Name: fk7ac0e15c9e309b2b; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource
    ADD CONSTRAINT fk7ac0e15c9e309b2b FOREIGN KEY (resource_type_id) REFERENCES eam_resource_type(id);


--
-- Name: fk7ac0e15ce82fbc; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource
    ADD CONSTRAINT fk7ac0e15ce82fbc FOREIGN KEY (subject_id) REFERENCES eam_subject(id);


--
-- Name: fk7d6efc66da1b7c9; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role_resource_group_map
    ADD CONSTRAINT fk7d6efc66da1b7c9 FOREIGN KEY (resource_group_id) REFERENCES eam_resource_group(id);


--
-- Name: fk7d6efc699d737ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role_resource_group_map
    ADD CONSTRAINT fk7d6efc699d737ae FOREIGN KEY (role_id) REFERENCES eam_role(id);


--
-- Name: fk846de1925029efd7; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_escalation_action
    ADD CONSTRAINT fk846de1925029efd7 FOREIGN KEY (escalation_id) REFERENCES eam_escalation(id);


--
-- Name: fk846de1929c76c3bb; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_escalation_action
    ADD CONSTRAINT fk846de1929c76c3bb FOREIGN KEY (action_id) REFERENCES eam_action(id);


--
-- Name: fk84892e98f8214d4d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_calendar_ent
    ADD CONSTRAINT fk84892e98f8214d4d FOREIGN KEY (calendar_id) REFERENCES eam_calendar(id);


--
-- Name: fk859d15ed706267a5; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_aux_logs
    ADD CONSTRAINT fk859d15ed706267a5 FOREIGN KEY (def_id) REFERENCES eam_galert_defs(id);


--
-- Name: fk859d15ed997cfc6; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_aux_logs
    ADD CONSTRAINT fk859d15ed997cfc6 FOREIGN KEY (aux_log_id) REFERENCES eam_galert_aux_logs(id);


--
-- Name: fk8e4d1fe6e3c7cb1; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_subject
    ADD CONSTRAINT fk8e4d1fe6e3c7cb1 FOREIGN KEY (pref_crispo_id) REFERENCES eam_crispo(id);


--
-- Name: fk8e4d1fefc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_subject
    ADD CONSTRAINT fk8e4d1fefc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fk94039bddfc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_virtual
    ADD CONSTRAINT fk94039bddfc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id) ON DELETE CASCADE;


--
-- Name: fk9723a177559691a3; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ai_agent_report
    ADD CONSTRAINT fk9723a177559691a3 FOREIGN KEY (agent_id) REFERENCES eam_agent(id);


--
-- Name: fk975407845029efd7; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_definition
    ADD CONSTRAINT fk975407845029efd7 FOREIGN KEY (escalation_id) REFERENCES eam_escalation(id);


--
-- Name: fk97540784cb32abfe; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_definition
    ADD CONSTRAINT fk97540784cb32abfe FOREIGN KEY (parent_id) REFERENCES eam_alert_definition(id) ON DELETE CASCADE;


--
-- Name: fk97540784fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_definition
    ADD CONSTRAINT fk97540784fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fka416a54bf6253048; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_view_resource
    ADD CONSTRAINT fka416a54bf6253048 FOREIGN KEY (view_id) REFERENCES eam_ui_view(id) ON DELETE CASCADE;


--
-- Name: fkaa7401955029efd7; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_escalation_state
    ADD CONSTRAINT fkaa7401955029efd7 FOREIGN KEY (escalation_id) REFERENCES eam_escalation(id);


--
-- Name: fkaa7401958c8d4d5c; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_escalation_state
    ADD CONSTRAINT fkaa7401958c8d4d5c FOREIGN KEY (acknowledged_by) REFERENCES eam_subject(id);


--
-- Name: fkb0b418f239b1d30d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service_type
    ADD CONSTRAINT fkb0b418f239b1d30d FOREIGN KEY (server_type_id) REFERENCES eam_server_type(id) ON DELETE CASCADE;


--
-- Name: fkb6a961b99e309b2b; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_operation
    ADD CONSTRAINT fkb6a961b99e309b2b FOREIGN KEY (resource_type_id) REFERENCES eam_resource_type(id) ON DELETE CASCADE;


--
-- Name: fkb811e571ea5ff386; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_aiq_service
    ADD CONSTRAINT fkb811e571ea5ff386 FOREIGN KEY (server_id) REFERENCES eam_server(id);


--
-- Name: fkbdab4434642e0910; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service_dep_map
    ADD CONSTRAINT fkbdab4434642e0910 FOREIGN KEY (dependent_service_id) REFERENCES eam_app_service(id);


--
-- Name: fkbdab443476c4c8b1; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service_dep_map
    ADD CONSTRAINT fkbdab443476c4c8b1 FOREIGN KEY (appservice_id) REFERENCES eam_app_service(id) ON DELETE CASCADE;


--
-- Name: fkc161913a6364efcd; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_crispo_opt
    ADD CONSTRAINT fkc161913a6364efcd FOREIGN KEY (crispo_id) REFERENCES eam_crispo(id);


--
-- Name: fkc9583392f6253048; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_view_masthead
    ADD CONSTRAINT fkc9583392f6253048 FOREIGN KEY (view_id) REFERENCES eam_ui_view(id) ON DELETE CASCADE;


--
-- Name: fkca4afc7cd1984a6; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_calendar_week
    ADD CONSTRAINT fkca4afc7cd1984a6 FOREIGN KEY (calendar_week_id) REFERENCES eam_calendar_ent(id);


--
-- Name: fkd0189b04b5af9d12; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_action
    ADD CONSTRAINT fkd0189b04b5af9d12 FOREIGN KEY (alert_definition_id) REFERENCES eam_alert_definition(id) ON DELETE CASCADE;


--
-- Name: fkd0189b04c0bb4c7; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_action
    ADD CONSTRAINT fkd0189b04c0bb4c7 FOREIGN KEY (parent_id) REFERENCES eam_action(id) ON DELETE CASCADE;


--
-- Name: fkd06c1ccb1bff8500; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_aiq_ip
    ADD CONSTRAINT fkd06c1ccb1bff8500 FOREIGN KEY (aiq_platform_id) REFERENCES eam_aiq_platform(id) ON DELETE CASCADE;


--
-- Name: fkd1647e0f1aa4e259; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_condition_log
    ADD CONSTRAINT fkd1647e0f1aa4e259 FOREIGN KEY (alert_id) REFERENCES eam_alert(id) ON DELETE CASCADE;


--
-- Name: fkd1647e0f2eaa2a9f; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_condition_log
    ADD CONSTRAINT fkd1647e0f2eaa2a9f FOREIGN KEY (condition_id) REFERENCES eam_alert_condition(id) ON DELETE CASCADE;


--
-- Name: fkd1cf8e4967a1226e; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_app_service
    ADD CONSTRAINT fkd1cf8e4967a1226e FOREIGN KEY (service_id) REFERENCES eam_service(id) ON DELETE CASCADE;


--
-- Name: fkd1cf8e4999ee4e8e; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_app_service
    ADD CONSTRAINT fkd1cf8e4999ee4e8e FOREIGN KEY (application_id) REFERENCES eam_application(id) ON DELETE CASCADE;


--
-- Name: fkd1cf8e49b648cf19; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_app_service
    ADD CONSTRAINT fkd1cf8e49b648cf19 FOREIGN KEY (service_type_id) REFERENCES eam_service_type(id) ON DELETE CASCADE;


--
-- Name: fkd1cf8e49cce79ab8; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_app_service
    ADD CONSTRAINT fkd1cf8e49cce79ab8 FOREIGN KEY (group_id) REFERENCES eam_resource_group(id);


--
-- Name: fkd1fcb6c04405ae5f; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_edge
    ADD CONSTRAINT fkd1fcb6c04405ae5f FOREIGN KEY (rel_id) REFERENCES eam_resource_relation(id);


--
-- Name: fkd1fcb6c0a2bf2d92; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_edge
    ADD CONSTRAINT fkd1fcb6c0a2bf2d92 FOREIGN KEY (from_id) REFERENCES eam_resource(id) ON DELETE CASCADE;


--
-- Name: fkd1fcb6c0ccc27921; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_edge
    ADD CONSTRAINT fkd1fcb6c0ccc27921 FOREIGN KEY (to_id) REFERENCES eam_resource(id) ON DELETE CASCADE;


--
-- Name: fkd203d83dfc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_resource_type
    ADD CONSTRAINT fkd203d83dfc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fkd703bc5999d737ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role_calendar
    ADD CONSTRAINT fkd703bc5999d737ae FOREIGN KEY (role_id) REFERENCES eam_role(id) ON DELETE CASCADE;


--
-- Name: fkd703bc59f8214d4d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role_calendar
    ADD CONSTRAINT fkd703bc59f8214d4d FOREIGN KEY (calendar_id) REFERENCES eam_calendar(id);


--
-- Name: fkd9f51e52d494bca6; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_attach_mast
    ADD CONSTRAINT fkd9f51e52d494bca6 FOREIGN KEY (attach_id) REFERENCES eam_ui_attachment(id) ON DELETE CASCADE;


--
-- Name: fkd9f7a78fd494bca6; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_attach_rsrc
    ADD CONSTRAINT fkd9f7a78fd494bca6 FOREIGN KEY (attach_id) REFERENCES eam_ui_attachment(id) ON DELETE CASCADE;


--
-- Name: fkd9f7a78ffc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_ui_attach_rsrc
    ADD CONSTRAINT fkd9f7a78ffc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fkdc5c7eb11dab49e3; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_exec_strategies
    ADD CONSTRAINT fkdc5c7eb11dab49e3 FOREIGN KEY (config_id) REFERENCES eam_crispo(id);


--
-- Name: fkdc5c7eb127e934b3; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_exec_strategies
    ADD CONSTRAINT fkdc5c7eb127e934b3 FOREIGN KEY (type_id) REFERENCES eam_exec_strategy_types(id);


--
-- Name: fkdc5c7eb1706267a5; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_exec_strategies
    ADD CONSTRAINT fkdc5c7eb1706267a5 FOREIGN KEY (def_id) REFERENCES eam_galert_defs(id);


--
-- Name: fkdfbea0999d737ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role_operation_map
    ADD CONSTRAINT fkdfbea0999d737ae FOREIGN KEY (role_id) REFERENCES eam_role(id);


--
-- Name: fkdfbea09c848f326; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role_operation_map
    ADD CONSTRAINT fkdfbea09c848f326 FOREIGN KEY (operation_id) REFERENCES eam_operation(id);


--
-- Name: fke20899066993629f; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_aux_logs
    ADD CONSTRAINT fke20899066993629f FOREIGN KEY (parent) REFERENCES eam_galert_aux_logs(id) ON DELETE CASCADE;


--
-- Name: fke2089906706267a5; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_aux_logs
    ADD CONSTRAINT fke2089906706267a5 FOREIGN KEY (def_id) REFERENCES eam_galert_defs(id);


--
-- Name: fke2089906c7d09794; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_aux_logs
    ADD CONSTRAINT fke2089906c7d09794 FOREIGN KEY (galert_id) REFERENCES eam_galert_logs(id) ON DELETE CASCADE;


--
-- Name: fke4028caab5af9d12; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_condition
    ADD CONSTRAINT fke4028caab5af9d12 FOREIGN KEY (alert_definition_id) REFERENCES eam_alert_definition(id) ON DELETE CASCADE;


--
-- Name: fke4028caad448177; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_alert_condition
    ADD CONSTRAINT fke4028caad448177 FOREIGN KEY (trigger_id) REFERENCES eam_registered_trigger(id);


--
-- Name: fke5afd057ccbe6e; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_agent
    ADD CONSTRAINT fke5afd057ccbe6e FOREIGN KEY (agent_type_id) REFERENCES eam_agent_type(id) ON DELETE CASCADE;


--
-- Name: fke5b6292dc81f5938; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_audit
    ADD CONSTRAINT fke5b6292dc81f5938 FOREIGN KEY (parent_id) REFERENCES eam_audit(id) ON DELETE CASCADE;


--
-- Name: fke5b6292de82fbc; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_audit
    ADD CONSTRAINT fke5b6292de82fbc FOREIGN KEY (subject_id) REFERENCES eam_subject(id);


--
-- Name: fke5b6292dfc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_audit
    ADD CONSTRAINT fke5b6292dfc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fke5d04798ccf47f9f; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_cprop
    ADD CONSTRAINT fke5d04798ccf47f9f FOREIGN KEY (keyid) REFERENCES eam_cprop_key(id);


--
-- Name: fke7d70b0b706267a5; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_metric_aux_logs
    ADD CONSTRAINT fke7d70b0b706267a5 FOREIGN KEY (def_id) REFERENCES eam_galert_defs(id);


--
-- Name: fke7d70b0b997cfc6; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_metric_aux_logs
    ADD CONSTRAINT fke7d70b0b997cfc6 FOREIGN KEY (aux_log_id) REFERENCES eam_galert_aux_logs(id);


--
-- Name: fke7d70b0ba1fcb528; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_metric_aux_logs
    ADD CONSTRAINT fke7d70b0ba1fcb528 FOREIGN KEY (metric_id) REFERENCES eam_measurement(id);


--
-- Name: fke8ebbc72154d0f55; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_request_stat
    ADD CONSTRAINT fke8ebbc72154d0f55 FOREIGN KEY (svcreq_id) REFERENCES eam_service_request(id) ON DELETE CASCADE;


--
-- Name: fkee7dcb20ef4e2527; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_crispo_array
    ADD CONSTRAINT fkee7dcb20ef4e2527 FOREIGN KEY (opt_id) REFERENCES eam_crispo_opt(id);


--
-- Name: fkee7e438762b21414; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT fkee7e438762b21414 FOREIGN KEY (config_response_id) REFERENCES eam_config_response(id);


--
-- Name: fkee7e438784174123; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT fkee7e438784174123 FOREIGN KEY (parent_service_id) REFERENCES eam_service(id);


--
-- Name: fkee7e4387b648cf19; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT fkee7e4387b648cf19 FOREIGN KEY (service_type_id) REFERENCES eam_service_type(id) ON DELETE CASCADE;


--
-- Name: fkee7e4387ea5ff386; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT fkee7e4387ea5ff386 FOREIGN KEY (server_id) REFERENCES eam_server(id) ON DELETE CASCADE;


--
-- Name: fkee7e4387fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_service
    ADD CONSTRAINT fkee7e4387fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fkeeeb4c1139b1d30d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_server
    ADD CONSTRAINT fkeeeb4c1139b1d30d FOREIGN KEY (server_type_id) REFERENCES eam_server_type(id) ON DELETE CASCADE;


--
-- Name: fkeeeb4c1162b21414; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_server
    ADD CONSTRAINT fkeeeb4c1162b21414 FOREIGN KEY (config_response_id) REFERENCES eam_config_response(id);


--
-- Name: fkeeeb4c116796aa86; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_server
    ADD CONSTRAINT fkeeeb4c116796aa86 FOREIGN KEY (platform_id) REFERENCES eam_platform(id);


--
-- Name: fkeeeb4c11fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_server
    ADD CONSTRAINT fkeeeb4c11fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fkef4421379c76c3bb; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_action_log
    ADD CONSTRAINT fkef4421379c76c3bb FOREIGN KEY (action_id) REFERENCES eam_action(id);


--
-- Name: fkef442137c7d09794; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_action_log
    ADD CONSTRAINT fkef442137c7d09794 FOREIGN KEY (galert_id) REFERENCES eam_galert_logs(id) ON DELETE CASCADE;


--
-- Name: fkef442137e82fbc; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_galert_action_log
    ADD CONSTRAINT fkef442137e82fbc FOREIGN KEY (subject_id) REFERENCES eam_subject(id);


--
-- Name: fkf6ec7cc4fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_role
    ADD CONSTRAINT fkf6ec7cc4fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: fkfed285c1559691a3; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_platform
    ADD CONSTRAINT fkfed285c1559691a3 FOREIGN KEY (agent_id) REFERENCES eam_agent(id);


--
-- Name: fkfed285c162b21414; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_platform
    ADD CONSTRAINT fkfed285c162b21414 FOREIGN KEY (config_response_id) REFERENCES eam_config_response(id);


--
-- Name: fkfed285c1e3e1026d; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_platform
    ADD CONSTRAINT fkfed285c1e3e1026d FOREIGN KEY (platform_type_id) REFERENCES eam_platform_type(id) ON DELETE CASCADE;


--
-- Name: fkfed285c1fc176ae; Type: FK CONSTRAINT; Schema: public; Owner: hqadmin
--

ALTER TABLE ONLY eam_platform
    ADD CONSTRAINT fkfed285c1fc176ae FOREIGN KEY (resource_id) REFERENCES eam_resource(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: hqadmin
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM hqadmin;
GRANT ALL ON SCHEMA public TO hqadmin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

