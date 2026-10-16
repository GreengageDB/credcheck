-- pg_check_password() takes the password as an ordinary argument, so its
-- literals must be masked in the log as the PASSWORD clause is
-- start_ignore
DROP EXTENSION IF EXISTS credcheck CASCADE;
-- end_ignore
CREATE EXTENSION credcheck;
-- GPORCA logs its fallback for the function at LOG level
SET optimizer = off;
SET log_statement = 'all';
SET client_min_messages = LOG;
SELECT pg_check_password('credtest', 'H8Hdre=S2');
SELECT public.pg_check_password ( username := 'credtest',
  password := E'H8\\Hdre=S2' ) AS checked;
SELECT pg_check_password('credtest', $pwd$H8Hdre=S2$pwd$),
  'not a password' AS note;
-- fail, the password is too short, but it's still masked in the log
SET credcheck.password_min_length = 12;
SELECT pg_check_password('credtest', 'H8Hdre=S2');
RESET client_min_messages;
RESET log_statement;
RESET credcheck.password_min_length;
RESET optimizer;
DROP EXTENSION credcheck CASCADE;
