-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION credcheck UPDATE TO '6.0.0'" to load this file. \quit

----
-- Record an authentication failure reported from outside PostgreSQL, for
-- environments where a connection pooler (e.g. PgBouncer with auth_query)
-- verifies the password itself so the failure never reaches the backend's
-- ClientAuthentication hook. credcheck applies the same credcheck.max_auth_failure
-- threshold and shared ban state as for direct connections. Returns the new
-- failure count for the role.
----
CREATE FUNCTION credcheck_record_auth_failure( IN username name )
RETURNS integer
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT VOLATILE;

----
-- Return true when a role is currently banned. Intended to be called from the
-- pooler's auth_query function so a banned role can be refused at the edge.
----
CREATE FUNCTION credcheck_is_banned( IN username name )
RETURNS boolean
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE;

-- record_auth_failure can ban any role, so keep it off PUBLIC: the operator
-- GRANTs EXECUTE to the trusted reporting role only (e.g. the fail2ban DB user).
REVOKE ALL ON FUNCTION credcheck_record_auth_failure(name) FROM PUBLIC;
-- is_banned only reads state; the operator GRANTs it to the pooler auth_query role.
REVOKE ALL ON FUNCTION credcheck_is_banned(name) FROM PUBLIC;

----
-- lastlog: utmp/wtmp-like login history. The data is kept in shared memory
-- and a memory-mapped file managed by the C code; this only exposes it.
----
CREATE FUNCTION credcheck_lastlog (
	OUT type        text,
	OUT username    text,
	OUT pid         integer,
	OUT client_addr text,
	OUT client_port integer,
	OUT login_time  timestamp with time zone,
	OUT logout_time timestamp with time zone,
	OUT duration    interval,
	OUT state       text,
	OUT query       text
)
RETURNS SETOF record
AS 'MODULE_PATHNAME', 'credcheck_lastlog'
LANGUAGE C VOLATILE EXECUTE ON MASTER;

CREATE VIEW pg_lastlog AS
  SELECT * FROM credcheck_lastlog();

REVOKE ALL ON FUNCTION credcheck_lastlog() FROM PUBLIC;
REVOKE ALL ON pg_lastlog FROM PUBLIC;
-- Greengage: pg_read_all_stats appeared in Postgres 10. The function is
-- called with the privileges of the user of the view, so grant it too.
DO $$ BEGIN
    IF setting::int >= 100000 FROM pg_settings WHERE name = 'server_version_num' THEN
        GRANT EXECUTE ON FUNCTION credcheck_lastlog() TO pg_read_all_stats;
        GRANT SELECT ON pg_lastlog TO pg_read_all_stats;
    END IF;
END; $$;

REVOKE ALL ON FUNCTION pg_password_history() FROM PUBLIC;
REVOKE ALL ON pg_password_history FROM PUBLIC;
-- Greengage: pg_read_all_stats appeared in Postgres 10, only superusers can
-- see the password history before. The function is called with the
-- privileges of the user of the view, so grant it too.
DO $$ BEGIN
    IF setting::int >= 100000 FROM pg_settings WHERE name = 'server_version_num' THEN
        GRANT EXECUTE ON FUNCTION pg_password_history() TO pg_read_all_stats;
        GRANT SELECT ON pg_password_history TO pg_read_all_stats;
    END IF;
END; $$;
