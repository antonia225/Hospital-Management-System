-- Implement row-level DML triggers that enforce exclusive employee subtypes:
-- an employee can be either a doctor or a nurse, but not both.

CREATE OR REPLACE TRIGGER trg_unique_employee_doctor_role
BEFORE INSERT OR UPDATE OF employee_id ON doctors
FOR EACH ROW
DECLARE
  v_exists NUMBER;
BEGIN
  IF INSERTING OR :NEW.employee_id != :OLD.employee_id THEN
    SELECT COUNT(*)
    INTO v_exists
    FROM nurses
    WHERE employee_id = :NEW.employee_id;

    IF v_exists > 0 THEN
      RAISE_APPLICATION_ERROR(
        -20030,
        'ERROR: Employee ID ' || :NEW.employee_id || ' is already registered as nurse.'
      );
    END IF;
  END IF;
END trg_unique_employee_doctor_role;
/

CREATE OR REPLACE TRIGGER trg_unique_employee_nurse_role
BEFORE INSERT OR UPDATE OF employee_id ON nurses
FOR EACH ROW
DECLARE
  v_exists NUMBER;
BEGIN
  IF INSERTING OR :NEW.employee_id != :OLD.employee_id THEN
    SELECT COUNT(*)
    INTO v_exists
    FROM doctors
    WHERE employee_id = :NEW.employee_id;

    IF v_exists > 0 THEN
      RAISE_APPLICATION_ERROR(
        -20031,
        'ERROR: Employee ID ' || :NEW.employee_id || ' is already registered as doctor.'
      );
    END IF;
  END IF;
END trg_unique_employee_nurse_role;
/

SET SERVEROUTPUT ON;
DECLARE
  v_doctor_id NUMBER;
  v_nurse_id NUMBER;
BEGIN
  SELECT NVL(MAX(employee_id), 2000) + 1
  INTO v_doctor_id
  FROM employees;

  v_nurse_id := v_doctor_id + 1;

  DBMS_OUTPUT.PUT_LINE('Test 1: valid doctor');
  INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
  VALUES (
    v_doctor_id,
    'Test',
    'Doctor',
    SYSDATE,
    ADD_MONTHS(SYSDATE, -360),
    '07' || LPAD(v_doctor_id, 8, '0'),
    'test.doctor' || v_doctor_id || '@hospital.com',
    10000
  );

  INSERT INTO doctors (employee_id, specialization, license_code, rank)
  VALUES (v_doctor_id, 'General Medicine', 'PARA' || v_doctor_id, 'resident');

  DBMS_OUTPUT.PUT_LINE('Test 2: same employee as nurse (invalid)');
  BEGIN
    INSERT INTO nurses (employee_id, type, room_id)
    VALUES (v_doctor_id, 'generalist', 101);
    DBMS_OUTPUT.PUT_LINE('ERROR: This should have been blocked.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('CORRECTLY BLOCKED.');
  END;

  DBMS_OUTPUT.PUT_LINE('Test 3: valid nurse');
  INSERT INTO employees (employee_id, name, first_name, hire_date, birth_date, phone, email, salary)
  VALUES (
    v_nurse_id,
    'Test',
    'Nurse',
    SYSDATE,
    ADD_MONTHS(SYSDATE, -300),
    '07' || LPAD(v_nurse_id, 8, '0'),
    'test.nurse' || v_nurse_id || '@hospital.com',
    7000
  );

  INSERT INTO nurses (employee_id, type, room_id)
  VALUES (v_nurse_id, 'medical', 102);

  DBMS_OUTPUT.PUT_LINE('Test 4: same employee as doctor (invalid)');
  BEGIN
    INSERT INTO doctors (employee_id, specialization, license_code, rank)
    VALUES (v_nurse_id, 'Surgery', 'PARA' || v_nurse_id, 'specialist');
    DBMS_OUTPUT.PUT_LINE('ERROR: This should have been blocked.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('CORRECTLY BLOCKED.');
  END;

  ROLLBACK;
END;
/
