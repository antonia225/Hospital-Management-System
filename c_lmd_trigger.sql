-- Create a statement-level DML trigger on ADMISSIONS that reports the impact of
-- INSERT/UPDATE/DELETE operations on room occupancy and department distribution.
-- The report includes affected row count, involved rooms, occupancy rate,
-- and warnings for rooms approaching maximum capacity.

CREATE OR REPLACE TRIGGER trg_admission_statistics
AFTER INSERT OR UPDATE OR DELETE ON admissions
DECLARE
  v_operation_type VARCHAR2(10);
  v_affected_rows NUMBER;
  v_involved_rooms NUMBER;
  v_total_patients NUMBER;
  v_total_capacity NUMBER;
BEGIN
  v_affected_rows := SQL%ROWCOUNT;

  IF INSERTING THEN
    v_operation_type := 'INSERT';
  ELSIF UPDATING THEN
    v_operation_type := 'UPDATE';
  ELSIF DELETING THEN
    v_operation_type := 'DELETE';
  END IF;

  SELECT COUNT(DISTINCT room_id)
  INTO v_involved_rooms
  FROM admissions
  WHERE discharge_date IS NULL;

  SELECT COUNT(*)
  INTO v_total_patients
  FROM admissions
  WHERE discharge_date IS NULL;

  SELECT NVL(SUM(bed_count), 0)
  INTO v_total_capacity
  FROM rooms
  WHERE active = 'Y';

  DBMS_OUTPUT.PUT_LINE('ADMISSION REPORT - ' || v_operation_type);
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Rows modified: ' || v_affected_rows);
  DBMS_OUTPUT.PUT_LINE('Rooms involved: ' || v_involved_rooms);

  IF v_total_capacity = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Occupancy rate: N/A');
  ELSE
    DBMS_OUTPUT.PUT_LINE(
      'Occupancy rate: ' || ROUND((v_total_patients / v_total_capacity) * 100, 1) || '%'
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('');

  FOR rec IN (
    SELECT
      r.room_id,
      ROUND((COUNT(a.admission_id) / r.bed_count) * 100, 1) AS occupancy_pct
    FROM rooms r
    LEFT JOIN admissions a ON r.room_id = a.room_id
    WHERE r.active = 'Y'
      AND a.discharge_date IS NULL
    GROUP BY r.room_id, r.bed_count
    HAVING COUNT(a.admission_id) >= r.bed_count * 0.8
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Room ' || rec.room_id || ': ' || rec.occupancy_pct || '%');
  END LOOP;
END trg_admission_statistics;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Case 1: INSERT - add new admission');
  INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, diagnosis)
  VALUES (9001, 3001, 2001, 101, SYSDATE, 'Post-operative monitoring');
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 2: INSERT - multiple admissions');
  INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, diagnosis)
  VALUES (9002, 3002, 2002, 101, SYSDATE, 'Pneumonia treatment');
  INSERT INTO admissions (admission_id, patient_id, doctor_id, room_id, admission_date, diagnosis)
  VALUES (9003, 3003, 2003, 102, SYSDATE, 'Cardiovascular recovery');
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 3: UPDATE - diagnosis change');
  UPDATE admissions
  SET diagnosis = 'Post-operative monitoring (stable condition)'
  WHERE admission_id = 9001;
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 4: DELETE - patient discharge');
  DELETE FROM admissions WHERE admission_id = 9001;
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Case 5: DELETE - multiple discharges');
  DELETE FROM admissions WHERE admission_id IN (9002, 9003);

  ROLLBACK;
END;
/
