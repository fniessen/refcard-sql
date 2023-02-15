-- Start of meta-script.

-- Set the SQL*Plus system variable to display commands.
SET ECHO ON

-- ***********************************************************************************
-- *** WARNING: Please update the connection information to match your environment ***
-- ***********************************************************************************

-- Connect to the Oracle database.
CONNECT SYSTEM/secret@ORCL1252

-- Set up a transaction.
SET TRANSACTION NAME 'meta_script_transaction';
SAVEPOINT start_tran;

-- Define the name of the spool file.
SET DEFINE ON
COL SPOOL_FILE NEW_VALUE SPOOL_FILE
SELECT 'execute_scripts-' || USER || '-' ||
       UPPER(SYS_CONTEXT('USERENV', 'DB_NAME')) || '-' ||
       TO_CHAR(sysdate, 'YYYYMMDD-HH24MISS') || '.log'
SPOOL_FILE FROM dual;
SPOOL &SPOOL_FILE.

-- Tell SQL*Plus to exit and rollback the transaction if a SQL error occurs.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

-- Loop through the script files and execute them in order.
PROMPT Running script 1.sql
@1.sql

PROMPT Running script 2.sql
@2.sql

PROMPT Running script 3.sql
@3.sql

-- If all scripts were executed successfully, commit the transaction.
COMMIT;

-- Disconnect from the Oracle database.
DISCONNECT

-- End of meta-script.
