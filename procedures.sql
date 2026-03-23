-- Implement a procedure that receives an admission ID and a proposed discharge date
-- and verifies whether the patient's discharge is allowed. Validation is performed
-- with a single SQL query using admission, patient, coordinating doctor, and room data.
-- The procedure raises dedicated exceptions for: incomplete medication plans,
-- ICU discharge restrictions (minimum 3 days), and inactive linked entities.
-- If all checks pass, it updates the admission with the discharge date and status.

CREATE OR REPLACE PROCEDURE finalize_discharge(
  p_admission_id admissions.admission_id%TYPE,
  p_discharge_date DATE
) IS
  ex_incomplete_medication EXCEPTION;
  ex_icu_discharge_restricted EXCEPTION;
  ex_inactive_entity EXCEPTION;

  v_room_type VARCHAR2(20);
  v_admission_date DATE;
  v_inactive_entity_count NUMBER;
  v_incomplete_med_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_inactive_entity_count
  FROM admissions i
  JOIN patients p ON i.patient_id = p.patient_id
  JOIN doctors d ON i.doctor_id = d.employee_id
  JOIN rooms r ON i.room_id = r.room_id
  WHERE i.admission_id = p_admission_id
    AND (p.active = 'N' OR d.active = 'N' OR r.active = 'N');

  IF v_inactive_entity_count > 0 THEN
    RAISE ex_inactive_entity;
  END IF;

  SELECT COUNT(*)
  INTO v_incomplete_med_count
  FROM admission_medicines
  WHERE admission_id = p_admission_id
    AND (administration_date + duration_days - 1) > p_discharge_date;

  IF v_incomplete_med_count > 0 THEN
    RAISE ex_incomplete_medication;
  END IF;

  SELECT rt.name, i.admission_date
  INTO v_room_type, v_admission_date
  FROM admissions i
  JOIN rooms r ON i.room_id = r.room_id
  JOIN room_types rt ON r.type = rt.type_id
  WHERE i.admission_id = p_admission_id;

  IF p_discharge_date IS NULL THEN
    RAISE_APPLICATION_ERROR(-20007, 'Discharge date is required.');
  END IF;

  IF p_discharge_date < v_admission_date THEN
    RAISE_APPLICATION_ERROR(-20008, 'Discharge date cannot be before admission date.');
  END IF;

  IF UPPER(v_room_type) = 'ICU' AND (p_discharge_date - v_admission_date) < 3 THEN
    RAISE ex_icu_discharge_restricted;
  END IF;

  UPDATE admissions
  SET discharge_date = p_discharge_date,
      discharge_status = 'recovered'
  WHERE admission_id = p_admission_id;

  DBMS_OUTPUT.PUT_LINE('SUCCESS: Discharge completed for admission ' || p_admission_id);

EXCEPTION
  WHEN ex_incomplete_medication THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: There are incomplete medication plans at the proposed discharge date.');
  WHEN ex_icu_discharge_restricted THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: ICU patients must remain admitted for at least 3 days.');
  WHEN ex_inactive_entity THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: One linked entity (patient/doctor/room) is inactive.');
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Admission ' || p_admission_id || ' does not exist.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END finalize_discharge;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Case 1: Valid discharge');
  finalize_discharge(4001, TO_DATE('2025-12-28','YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 2: Incomplete medication plan');
  UPDATE admissions SET discharge_date = NULL, discharge_status = NULL
  WHERE admission_id = 4001;
  finalize_discharge(4001, TO_DATE('2025-12-27','YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 3: ICU discharge restriction');
  UPDATE admissions SET discharge_date = NULL, discharge_status = NULL
  WHERE admission_id = 4004;
  finalize_discharge(4004, TO_DATE('2025-12-12','YYYY-MM-DD'));
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 4: Inactive entity');
  UPDATE patients SET active = 'N', inactive_date = SYSDATE
  WHERE patient_id = 3001;
  finalize_discharge(4001, TO_DATE('2025-12-28','YYYY-MM-DD'));

  UPDATE patients SET active = 'Y', inactive_date = NULL
  WHERE patient_id = 3001;
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 5: Non-existent admission');
  finalize_discharge(99999, TO_DATE('2025-12-28','YYYY-MM-DD'));

  ROLLBACK;
END;
/
