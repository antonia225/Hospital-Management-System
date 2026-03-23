-- Create a schema-level DDL trigger that blocks DROP commands for protected
-- application tables to prevent accidental or unauthorized data loss.

CREATE OR REPLACE TRIGGER trg_protect_drop_tables
BEFORE DROP ON SCHEMA
DECLARE
  v_table_name VARCHAR2(50);
BEGIN
  v_table_name := UPPER(ora_dict_obj_name);

  IF v_table_name IN (
    'BLOOD_GROUPS',
    'ROOM_TYPES',
    'PATIENTS',
    'DEPARTMENTS',
    'ROOMS',
    'EMPLOYEES',
    'DOCTORS',
    'NURSES',
    'ADMISSIONS',
    'ADMISSION_MEDICINES',
    'MEDICINES'
  ) THEN
    RAISE_APPLICATION_ERROR(
      -20200,
      'ACCESS DENIED: Table ' || v_table_name || ' cannot be dropped.'
    );
  END IF;
END trg_protect_drop_tables;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Test 1: Create temporary test table');
  EXECUTE IMMEDIATE 'CREATE TABLE test_temp_drop (id NUMBER, description VARCHAR2(50))';
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Table test_temp_drop created.');
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 2: Drop unprotected temporary table (SUCCESS)');
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE test_temp_drop';
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Table test_temp_drop was dropped (unprotected).');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
  END;
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 3: Attempt to drop PATIENTS (BLOCKED)');
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE patients';
    DBMS_OUTPUT.PUT_LINE('ERROR: DROP should not have been allowed.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('CORRECTLY BLOCKED: ' || SQLERRM);
  END;
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- To actually drop protected tables (for example, during a full reset),
-- temporarily disable this trigger:
--
-- ALTER TRIGGER trg_protect_drop_tables DISABLE;
--
-- DROP TABLE admission_medicines CASCADE CONSTRAINTS;
-- DROP TABLE admissions CASCADE CONSTRAINTS;
-- DROP TABLE nurses CASCADE CONSTRAINTS;
-- DROP TABLE doctors CASCADE CONSTRAINTS;
-- ...
--
-- ALTER TRIGGER trg_protect_drop_tables ENABLE;
