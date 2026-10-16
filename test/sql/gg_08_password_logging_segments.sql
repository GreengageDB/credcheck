-- The segments log the statements dispatched by the coordinator, so the
-- password must be masked there too. Without log_statement the coordinator
-- logs the statement only after it has been dispatched.
-- start_matchsubs
-- m/^LOG:  duration: \d+\.\d+ ms/
-- s/^LOG:  duration: \d+\.\d+ ms/LOG:  duration: X ms/
-- end_matchsubs
-- start_ignore
DROP USER IF EXISTS credtest;
-- end_ignore
SET log_statement = 'none';
SET log_min_duration_statement = 0;
SET client_min_messages = LOG;
CREATE USER credtest PASSWORD 'H8Hdre=S2';
RESET client_min_messages;
RESET log_min_duration_statement;
RESET log_statement;
DROP USER credtest;
