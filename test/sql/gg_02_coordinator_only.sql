-- In Greengage, the password history and the banned roles are kept in the
-- shared memory of the coordinator only.
SET credcheck.password_reuse_history = 2;
CREATE USER cc_coord1 WITH PASSWORD 'H8Hdre=S2';
CREATE USER cc_coord2 WITH PASSWORD 'J8YuRe=6O';
CREATE TABLE cc_roles (u name) DISTRIBUTED BY (u);
INSERT INTO cc_roles VALUES ('cc_coord1'), ('cc_coord2'), ('cc_coord3');
SELECT rolename, count(*) FROM pg_password_history
  WHERE rolename LIKE 'cc_coord%' GROUP BY rolename ORDER BY rolename;
-- The history and the banned roles can't be changed on segments
SELECT pg_password_history_reset(u) FROM cc_roles;
SELECT pg_password_history_timestamp(u, now()) FROM cc_roles;
SELECT pg_banned_role_reset(u) FROM cc_roles;
-- They can be executed on the coordinator
SELECT pg_password_history_reset('cc_coord1');
SELECT rolename, count(*) FROM pg_password_history
  WHERE rolename LIKE 'cc_coord%' GROUP BY rolename ORDER BY rolename;
DROP TABLE cc_roles;
DROP USER cc_coord1;
DROP USER cc_coord2;
RESET credcheck.password_reuse_history;
