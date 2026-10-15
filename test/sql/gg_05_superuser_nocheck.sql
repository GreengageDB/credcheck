-- No CREATE/ALTER ROLE check at all must be done for a superuser when
-- credcheck.superuser_nocheck is enabled
-- start_ignore
DROP USER IF EXISTS credtest;
DROP USER IF EXISTS shrt;
DROP EXTENSION IF EXISTS credcheck CASCADE;
-- end_ignore
CREATE EXTENSION credcheck;
SET credcheck.password_min_upper = 4;
SET credcheck.username_min_length = 5;
-- fail, the password has not enough upper case characters
CREATE USER credtest PASSWORD 'DummY2';
-- fail, the username is too short
CREATE USER shrt;
SET credcheck.superuser_nocheck = on;
-- no error
CREATE USER credtest PASSWORD 'DummY2';
ALTER USER credtest PASSWORD 'DummY3';
CREATE USER shrt;
SET credcheck.disallow_change_password = on;
ALTER USER credtest PASSWORD 'DummY4';
RESET credcheck.disallow_change_password;
RESET credcheck.superuser_nocheck;
-- fail, the checks are back
ALTER USER credtest PASSWORD 'DummY5';
RESET credcheck.password_min_upper;
RESET credcheck.username_min_length;
DROP USER credtest;
DROP USER shrt;
