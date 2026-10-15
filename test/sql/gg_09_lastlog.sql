-- The last-login history is checked upstream by t/002_lastlog.pl only, which
-- needs Postgres 15, so check here what the adaptation changes: its shared
-- memory on Postgres older than 15, its background worker on the coordinator
-- only, its file removed on segments, the entry db QEs not recorded, the
-- passwords masked in the queries kept, and credcheck.lastlog_query_size = 0.
-- start_ignore
DROP TABLE IF EXISTS ll_entry;
DROP USER IF EXISTS credtest_ll;
DROP EXTENSION IF EXISTS credcheck CASCADE;
-- end_ignore
-- gpexpand copies the files of the coordinator to new segments, so leave the
-- file of the history there, and start from an empty history on the
-- coordinator. Before Postgres 15 the shared memory of the live sessions
-- wasn't counted, and with such a query size the coordinator didn't start.
-- start_ignore
\! psql -At -c "SELECT datadir FROM gp_segment_configuration WHERE content >= 0" postgres | while read d; do touch "$d/credcheck.lastlog"; done
\! psql -At -c "SELECT datadir FROM gp_segment_configuration WHERE content = -1" postgres | while read d; do rm -f "$d/credcheck.lastlog"; done
\! gpconfig -c credcheck.lastlog -v on
\! gpconfig -c credcheck.lastlog_track_query -v on
\! gpconfig -c credcheck.lastlog_query_size -v 262144
\! gpconfig -c credcheck.lastlog_max -v 64
\! sed -i -e '1i local all credtest_ll trust # credcheck test' -e '/ # credcheck test$/d' "$(psql -At -c 'SHOW hba_file' postgres)"
\! gpstop -raq -M fast
-- end_ignore
\c
CREATE EXTENSION credcheck;
CREATE USER credtest_ll SUPERUSER;
-- The session is recorded when its backend exits, after psql has returned
CREATE FUNCTION ll_wait(sessions int) RETURNS void AS $$
BEGIN
	FOR i IN 1..300 LOOP
		EXIT WHEN (SELECT count(*) FROM pg_lastlog
				   WHERE username = 'credtest_ll' AND state = 'disconnected') >= sessions;
		PERFORM pg_sleep(0.1);
	END LOOP;
END $$ LANGUAGE plpgsql;
-- The background worker runs on the coordinator only, and the file of the
-- history was removed on segments
\! psql -At -F ' ' -c "SELECT content, port, datadir FROM gp_segment_configuration WHERE role = 'p' ORDER BY content" postgres | while read c p d; do echo "content $c: $(ps -eo args | grep -c "^postgres: *$p, .*credcheck lastlog flusher") worker, $(ls "$d" | grep -c '^credcheck\.lastlog$') file"; done
SELECT type, state FROM pg_lastlog WHERE pid = pg_backend_pid();
-- The query string holding several statements is kept as a whole, with the
-- password masked whatever credcheck.no_password_logging is
\! PGOPTIONS='-c credcheck.no_password_logging=off' psql -X -q -At -U credtest_ll -d postgres -c "ALTER USER credtest_ll PASSWORD 'Secr3t=Pw1'; SELECT 1"
-- The entry db QE reads the history, but it isn't recorded
SELECT current_user AS superuser \gset
\c - credtest_ll
CREATE TABLE ll_entry AS SELECT username FROM pg_lastlog DISTRIBUTED RANDOMLY;
\c - :superuser
SELECT ll_wait(2);
SELECT state, query, logout_time > login_time AND duration IS NOT NULL AS ended
FROM pg_lastlog WHERE username = 'credtest_ll' ORDER BY login_time;
-- The background worker marks a clean shutdown, and the history is kept
-- start_ignore
\! gpstop -raq -M fast
-- end_ignore
\c
SELECT type FROM pg_lastlog WHERE type <> 'user' ORDER BY login_time DESC LIMIT 2;
SELECT count(*) FROM pg_lastlog WHERE type = 'crash';
SELECT count(*) FROM pg_lastlog WHERE username = 'credtest_ll';
-- No query is kept with credcheck.lastlog_query_size = 0
-- start_ignore
\! gpconfig -c credcheck.lastlog_query_size -v 0
\! gpstop -raq -M fast
-- end_ignore
\c
\! psql -X -q -At -U credtest_ll -d postgres -c "SELECT 1"
SELECT ll_wait(1);
SELECT state, query IS NULL AS no_query FROM pg_lastlog
WHERE username = 'credtest_ll' OR pid = pg_backend_pid() ORDER BY login_time;
-- start_ignore
\! gpconfig -r credcheck.lastlog
\! gpconfig -r credcheck.lastlog_track_query
\! gpconfig -r credcheck.lastlog_query_size
\! gpconfig -r credcheck.lastlog_max
\! sed -i '/ # credcheck test$/d' "$(psql -At -c 'SHOW hba_file' postgres)"
\! gpstop -raq -M fast
\! psql -At -c "SELECT datadir FROM gp_segment_configuration WHERE content = -1" postgres | while read d; do rm -f "$d/credcheck.lastlog"; done
-- end_ignore
\c
DROP TABLE ll_entry;
DROP FUNCTION ll_wait(int);
DROP USER credtest_ll;
DROP EXTENSION credcheck CASCADE;
