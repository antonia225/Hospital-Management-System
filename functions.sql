-- Define a function that receives a patient last name and returns the doctor who
-- supervised that patient's most recent admission. The function uses one SQL query
-- joining three relevant tables and handles all edge cases:
-- no matching patient/admission (NO_DATA_FOUND) and duplicate patient names
-- (TOO_MANY_ROWS).

CREATE OR REPLACE FUNCTION get_latest_admission_doctor(
  p_patient_name VARCHAR2
) RETURN VARCHAR2 IS
  v_doctor_info VARCHAR2(200);
  v_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM patients
  WHERE UPPER(name) = UPPER(p_patient_name);

  IF v_count > 1 THEN
    RAISE TOO_MANY_ROWS;
  END IF;

  SELECT (
    SELECT e.name || ' ' || e.first_name
    FROM employees e
    WHERE e.employee_id = d.employee_id
  ) || ' - ' || d.rank
  INTO v_doctor_info
  FROM patients p
  JOIN admissions a ON p.patient_id = a.patient_id
  JOIN doctors d ON a.doctor_id = d.employee_id
  WHERE UPPER(p.name) = UPPER(p_patient_name)
  ORDER BY a.admission_date DESC
  FETCH FIRST 1 ROW ONLY;

  RETURN v_doctor_info;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'ERROR: Patient not found or no admissions available.';
  WHEN TOO_MANY_ROWS THEN
    RETURN 'ERROR: Multiple patients found with last name ' || p_patient_name;
  WHEN OTHERS THEN
    RETURN 'ERROR: ' || SQLERRM;
END get_latest_admission_doctor;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Case 1: Valid patient with admissions');
  DBMS_OUTPUT.PUT_LINE(get_latest_admission_doctor('Iacob'));
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 2: NO_DATA_FOUND - non-existent patient');
  DBMS_OUTPUT.PUT_LINE(get_latest_admission_doctor('MissingName'));
  DBMS_OUTPUT.PUT_LINE('');

  INSERT INTO patients (patient_id, name, first_name, ssn, birth_date, address, phone, email, blood_group)
  VALUES (
    3006,
    'Iacob',
    'Maria',
    '2950606234567',
    TO_DATE('1995-06-06', 'YYYY-MM-DD'),
    'Test Street 1',
    '0722000006',
    'maria.iacob@example.com',
    2
  );
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Case 3: TOO_MANY_ROWS - duplicate patient last name');
  DBMS_OUTPUT.PUT_LINE(get_latest_admission_doctor('Iacob'));
  DBMS_OUTPUT.PUT_LINE('');
  
  COMMIT;
END;
/
