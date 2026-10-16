-- The last-login history shows who connected from where, so only a superuser,
-- or a member of pg_read_all_stats on Postgres 10 and later, can see it
-- start_matchsubs
-- m/permission denied for view /
-- s/permission denied for view /permission denied for relation /
-- end_matchsubs
-- start_ignore
DROP USER IF EXISTS credtest_reader;
DROP EXTENSION IF EXISTS credcheck CASCADE;
-- end_ignore
CREATE EXTENSION credcheck;
CREATE USER credtest_reader;
SET ROLE credtest_reader;
-- fail, the view and the function are not granted to PUBLIC
SELECT count(*) FROM pg_lastlog;
SELECT count(*) FROM credcheck_lastlog();
RESET ROLE;
-- A member of pg_read_all_stats can read the view on Postgres 10 and later,
-- which have this role. credcheck.lastlog is disabled here, so the query
-- fails after the privilege checks of the view and of the function.
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
		PERFORM count(*) FROM pg_lastlog;
		can_see := true;
	EXCEPTION
		WHEN insufficient_privilege THEN
			can_see := false;
		WHEN object_not_in_prerequisite_state THEN
			can_see := true;
	END;
	EXECUTE 'RESET ROLE';
	IF can_see = has_read_all_stats THEN
		RAISE NOTICE 'PASS';
	ELSE
		RAISE NOTICE 'FAIL: credtest_reader can see the last-login history: %', can_see;
	END IF;
END $$;
DROP USER credtest_reader;
DROP EXTENSION credcheck CASCADE;
