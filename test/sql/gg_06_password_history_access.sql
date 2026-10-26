-- The password history holds the hashes of the passwords of all roles, so
-- only a superuser, or a member of pg_read_all_stats on Postgres 10 and
-- later, can see it
-- start_matchsubs
-- m/permission denied for view /
-- s/permission denied for view /permission denied for relation /
-- m/only superuser or a member of pg_read_all_stats can /
-- s/only superuser or a member of pg_read_all_stats can /only superuser can /
-- end_matchsubs
-- start_ignore
DROP USER IF EXISTS credtest;
DROP USER IF EXISTS credtest_reader;
DROP EXTENSION IF EXISTS credcheck CASCADE;
-- end_ignore
CREATE EXTENSION credcheck;
SELECT pg_password_history_reset();
SET credcheck.password_reuse_history = 2;
CREATE USER credtest WITH PASSWORD 'H8Hdre=S2';
CREATE USER credtest_reader;
-- success, a superuser can see the password history
SELECT rolename FROM pg_password_history WHERE rolename = 'credtest';
SET ROLE credtest_reader;
-- fail, the view and the function are not granted to PUBLIC
SELECT rolename FROM pg_password_history WHERE rolename = 'credtest';
SELECT rolename FROM pg_password_history() WHERE rolename = 'credtest';
RESET ROLE;
GRANT SELECT ON pg_password_history TO credtest_reader;
GRANT EXECUTE ON FUNCTION pg_password_history() TO credtest_reader;
SET ROLE credtest_reader;
-- fail, only a superuser can see the password history, even if the view is granted
SELECT rolename FROM pg_password_history WHERE rolename = 'credtest';
SELECT rolename FROM pg_password_history() WHERE rolename = 'credtest';
RESET ROLE;
REVOKE SELECT ON pg_password_history FROM credtest_reader;
REVOKE EXECUTE ON FUNCTION pg_password_history() FROM credtest_reader;
-- A member of pg_read_all_stats can see the password history through the
-- view on Postgres 10 and later, which have this role
DO $$
DECLARE
	has_read_all_stats boolean :=
		current_setting('server_version_num')::int >= 100000;
	can_see boolean;
BEGIN
	IF has_read_all_stats THEN
		EXECUTE 'GRANT pg_read_all_stats TO credtest_reader';
	END IF;
	EXECUTE 'SET ROLE credtest_reader';
	BEGIN
		PERFORM rolename FROM pg_password_history WHERE rolename = 'credtest';
		can_see := true;
	EXCEPTION WHEN insufficient_privilege THEN
		can_see := false;
	END;
	EXECUTE 'RESET ROLE';
	IF can_see = has_read_all_stats THEN
		RAISE NOTICE 'PASS';
	ELSE
		RAISE NOTICE 'FAIL: credtest_reader can see the password history: %', can_see;
	END IF;
END $$;
SELECT pg_password_history_reset();
DROP USER credtest_reader;
DROP USER credtest;
DROP EXTENSION credcheck CASCADE;
