-- start_matchsubs
-- m/ \(credcheck.c:\d+\)/
-- s/ \(credcheck.c:\d+\)//
-- end_matchsubs
SELECT pg_banned_role_reset();
CREATE USER credtest WITH PASSWORD 'H8Hdre=S2';
-- start_ignore
\! sed -i -e '1i host all credtest samehost md5 # credcheck test' -e '/ # credcheck test$/d' "$(psql -At -c 'SHOW hba_file' postgres)"
\! gpconfig -c credcheck.max_auth_failure -v 3
\! gpstop -u
-- end_ignore
\! PGPASSWORD='J8YuRe=6O' psql -h localhost -U credtest -d postgres -w
\! PGPASSWORD='J8YuRe=6O' psql -h localhost -U credtest -d postgres -w
\! PGPASSWORD='J8YuRe=6O' psql -h localhost -U credtest -d postgres -w
SELECT r.rolname, b.failure_count FROM pg_banned_role() b JOIN pg_roles r ON r.oid = b.roleid;
SELECT pg_banned_role_reset('credtest');
SELECT r.rolname, b.failure_count FROM pg_banned_role() b JOIN pg_roles r ON r.oid = b.roleid;
\! PGPASSWORD='J8YuRe=6O' psql -h localhost -U credtest -d postgres -w
-- start_ignore
\! gpconfig -r credcheck.max_auth_failure
\! sed -i '/ # credcheck test$/d' "$(psql -At -c 'SHOW hba_file' postgres)"
\! gpstop -u
-- end_ignore
SELECT pg_banned_role_reset();
DROP USER credtest;
