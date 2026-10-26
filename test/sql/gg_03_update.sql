-- Update from 4.6.0, the version shipped with Greengage 6X, where the
-- functions returning the password history and the banned roles were not
-- executed on the coordinator
DROP EXTENSION credcheck;
CREATE EXTENSION credcheck VERSION '4.6.0';
SELECT proname, proexeclocation IN ('m', 'c') AS on_coordinator FROM pg_proc
  WHERE proname IN ('pg_password_history', 'pg_banned_role') ORDER BY proname;
ALTER EXTENSION credcheck UPDATE;
SELECT extversion = (SELECT default_version FROM pg_available_extensions
  WHERE name = 'credcheck') AS updated FROM pg_extension WHERE extname = 'credcheck';
SELECT proname, proexeclocation IN ('m', 'c') AS on_coordinator FROM pg_proc
  WHERE proname IN ('pg_password_history', 'pg_banned_role') ORDER BY proname;
-- The updated extension has the same objects as a freshly created one, with
-- the same privileges and execution locations
CREATE TEMP VIEW cc_objects AS
  SELECT pg_describe_object(classid, objid, objsubid)
      || coalesce(' ' || (SELECT coalesce(proacl::text, '') || ' '
                              || proexeclocation FROM pg_proc
                          WHERE classid = 'pg_proc'::regclass AND oid = objid), '')
      || coalesce(' ' || (SELECT coalesce(relacl::text, '') FROM pg_class
                          WHERE classid = 'pg_class'::regclass AND oid = objid), '')
      AS obj
  FROM pg_depend
  WHERE refclassid = 'pg_extension'::regclass AND deptype = 'e'
    AND refobjid = (SELECT oid FROM pg_extension WHERE extname = 'credcheck');
CREATE TEMP TABLE cc_updated AS SELECT obj FROM cc_objects DISTRIBUTED RANDOMLY;
DROP EXTENSION credcheck;
CREATE EXTENSION credcheck;
(SELECT obj FROM cc_updated EXCEPT SELECT obj FROM cc_objects)
UNION ALL
(SELECT obj FROM cc_objects EXCEPT SELECT obj FROM cc_updated);
DROP TABLE cc_updated;
DROP VIEW cc_objects;
-- and works
DROP EXTENSION credcheck;
CREATE EXTENSION credcheck VERSION '4.6.0';
ALTER EXTENSION credcheck UPDATE;
SET credcheck.password_reuse_history = 1;
CREATE USER cc_update WITH PASSWORD 'H8Hdre=S2';
SELECT rolename FROM pg_password_history WHERE rolename = 'cc_update';
SELECT count(*) FROM pg_banned_role;
DROP USER cc_update;
RESET credcheck.password_reuse_history;
