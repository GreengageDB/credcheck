-- credcheck extension for PostgreSQL
-- Copyright (c) 2024-2026 HexaCluster Corp - All rights reserved.

-- Nothing to do, only library change

-- Greengage: the password history and the banned roles are kept on the
-- coordinator only, the 4.6.0 installation script didn't mark these functions
ALTER FUNCTION pg_password_history() EXECUTE ON MASTER;
ALTER FUNCTION pg_banned_role() EXECUTE ON MASTER;
