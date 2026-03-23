-- Create a package for admission and medication management.
-- The package defines complex data types, utility functions, and procedures
-- to register admissions, record medications, and display full admission details.

CREATE OR REPLACE PACKAGE pkg_medical_management AS
  TYPE t_admission_details IS RECORD (
    admission_id        admissions.admission_id%TYPE,
    patient_name        patients.name%TYPE,
    patient_first_name  patients.first_name%TYPE,
    doctor_name         employees.name%TYPE,
    doctor_first_name   employees.first_name%TYPE,
    room_number         rooms.room_number%TYPE,
    admission_date      admissions.admission_date%TYPE,
    discharge_date      admissions.discharge_date%TYPE,
    diagnosis           admissions.diagnosis%TYPE
  );

  TYPE t_medicine_rec IS RECORD (
    medicine_name       medicines.name%TYPE,
    dose                admission_medicines.dose%TYPE,
    administration_date admission_medicines.administration_date%TYPE
  );

  TYPE t_administered_medicines IS TABLE OF t_medicine_rec;

  FUNCTION check_bed_availability(
    p_room_id rooms.room_id%TYPE,
    p_admission_date DATE
  ) RETURN NUMBER;

  FUNCTION calculate_admission_duration(
    p_admission_id admissions.admission_id%TYPE
  ) RETURN NUMBER;

  PROCEDURE register_new_admission(
    p_admission_id admissions.admission_id%TYPE,
    p_patient_id patients.patient_id%TYPE,
    p_doctor_id doctors.employee_id%TYPE,
    p_room_id rooms.room_id%TYPE,
    p_admission_date DATE,
    p_diagnosis VARCHAR2
  );

  PROCEDURE add_admission_medicine(
    p_admission_id admissions.admission_id%TYPE,
    p_medicine_id medicines.medicine_id%TYPE,
    p_dose VARCHAR2,
    p_frequency VARCHAR2,
    p_administration_date DATE,
    p_duration_days NUMBER
  );

  PROCEDURE show_admission_details(
    p_admission_id admissions.admission_id%TYPE
  );
END pkg_medical_management;
/

CREATE OR REPLACE PACKAGE BODY pkg_medical_management AS

  FUNCTION check_bed_availability(
    p_room_id rooms.room_id%TYPE,
    p_admission_date DATE
  ) RETURN NUMBER IS
    v_bed_count NUMBER;
    v_occupied_beds NUMBER;
  BEGIN
    SELECT bed_count
    INTO v_bed_count
    FROM rooms
    WHERE room_id = p_room_id
      AND active = 'Y';

    SELECT COUNT(*)
    INTO v_occupied_beds
    FROM admissions
    WHERE room_id = p_room_id
      AND admission_date <= p_admission_date
      AND (discharge_date IS NULL OR discharge_date >= p_admission_date);

    RETURN v_bed_count - v_occupied_beds;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20310, 'Room does not exist or is inactive: ' || p_room_id);
  END check_bed_availability;

  FUNCTION calculate_admission_duration(
    p_admission_id admissions.admission_id%TYPE
  ) RETURN NUMBER IS
    v_admission_date DATE;
    v_discharge_date DATE;
  BEGIN
    SELECT admission_date, discharge_date
    INTO v_admission_date, v_discharge_date
    FROM admissions
    WHERE admission_id = p_admission_id;

    IF v_discharge_date IS NULL THEN
      RETURN TRUNC(SYSDATE - v_admission_date);
    END IF;

    RETURN TRUNC(v_discharge_date - v_admission_date);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END calculate_admission_duration;

  PROCEDURE register_new_admission(
    p_admission_id admissions.admission_id%TYPE,
    p_patient_id patients.patient_id%TYPE,
    p_doctor_id doctors.employee_id%TYPE,
    p_room_id rooms.room_id%TYPE,
    p_admission_date DATE,
    p_diagnosis VARCHAR2
  ) IS
  BEGIN
    INSERT INTO admissions (
      admission_id,
      patient_id,
      doctor_id,
      room_id,
      admission_date,
      diagnosis
    ) VALUES (
      p_admission_id,
      p_patient_id,
      p_doctor_id,
      p_room_id,
      p_admission_date,
      p_diagnosis
    );

    DBMS_OUTPUT.PUT_LINE('SUCCESS: Admission registered with ID ' || p_admission_id);
  END register_new_admission;

  PROCEDURE add_admission_medicine(
    p_admission_id admissions.admission_id%TYPE,
    p_medicine_id medicines.medicine_id%TYPE,
    p_dose VARCHAR2,
    p_frequency VARCHAR2,
    p_administration_date DATE,
    p_duration_days NUMBER
  ) IS
  BEGIN
    INSERT INTO admission_medicines (
      admission_id,
      medicine_id,
      dose,
      frequency,
      administration_date,
      duration_days
    ) VALUES (
      p_admission_id,
      p_medicine_id,
      p_dose,
      p_frequency,
      p_administration_date,
      p_duration_days
    );

    DBMS_OUTPUT.PUT_LINE('SUCCESS: Medicine added to admission ' || p_admission_id);
  END add_admission_medicine;

  PROCEDURE show_admission_details(
    p_admission_id admissions.admission_id%TYPE
  ) IS
    v_details t_admission_details;
    v_medicines t_administered_medicines := t_administered_medicines();
    v_duration NUMBER;
  BEGIN
    SELECT
      a.admission_id,
      p.name,
      p.first_name,
      e.name,
      e.first_name,
      r.room_number,
      a.admission_date,
      a.discharge_date,
      a.diagnosis
    INTO v_details
    FROM admissions a
    JOIN patients p ON a.patient_id = p.patient_id
    JOIN doctors d ON a.doctor_id = d.employee_id
    JOIN employees e ON d.employee_id = e.employee_id
    JOIN rooms r ON a.room_id = r.room_id
    WHERE a.admission_id = p_admission_id;

    FOR rec IN (
      SELECT m.name, am.dose, am.administration_date
      FROM admission_medicines am
      JOIN medicines m ON am.medicine_id = m.medicine_id
      WHERE am.admission_id = p_admission_id
      ORDER BY am.administration_date
    ) LOOP
      v_medicines.EXTEND;
      v_medicines(v_medicines.COUNT).medicine_name := rec.name;
      v_medicines(v_medicines.COUNT).dose := rec.dose;
      v_medicines(v_medicines.COUNT).administration_date := rec.administration_date;
    END LOOP;

    v_duration := calculate_admission_duration(p_admission_id);

    DBMS_OUTPUT.PUT_LINE('ADMISSION REPORT #' || v_details.admission_id);
    DBMS_OUTPUT.PUT_LINE('Patient: ' || v_details.patient_name || ' ' || v_details.patient_first_name);
    DBMS_OUTPUT.PUT_LINE('Coordinating doctor: ' || v_details.doctor_name || ' ' || v_details.doctor_first_name);
    DBMS_OUTPUT.PUT_LINE('Room: ' || v_details.room_number);
    DBMS_OUTPUT.PUT_LINE('Admission date: ' || TO_CHAR(v_details.admission_date, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Discharge date: ' ||
      CASE
        WHEN v_details.discharge_date IS NULL THEN 'Ongoing'
        ELSE TO_CHAR(v_details.discharge_date, 'DD-MON-YYYY')
      END);
    DBMS_OUTPUT.PUT_LINE('Duration: ' || v_duration || ' days');
    DBMS_OUTPUT.PUT_LINE('Diagnosis: ' || NVL(v_details.diagnosis, 'N/A'));

    DBMS_OUTPUT.PUT_LINE('--- Administered medicines ---');
    IF v_medicines.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('  (No medicines)');
    ELSE
      FOR i IN v_medicines.FIRST .. v_medicines.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(
          '  ' || v_medicines(i).medicine_name ||
          ' - ' || v_medicines(i).dose ||
          ' (from ' || TO_CHAR(v_medicines(i).administration_date, 'DD-MON-YYYY') || ')'
        );
      END LOOP;
    END IF;
  END show_admission_details;
END pkg_medical_management;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Test 1: Check bed availability');
  DBMS_OUTPUT.PUT_LINE(
    'Available beds in room 101: ' ||
    pkg_medical_management.check_bed_availability(101, SYSDATE)
  );
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 2: Calculate admission duration');
  DBMS_OUTPUT.PUT_LINE(
    'Admission 4001 duration: ' ||
    pkg_medical_management.calculate_admission_duration(4001) || ' days'
  );
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 3: Register new admission');
  pkg_medical_management.register_new_admission(
    p_admission_id => 4006,
    p_patient_id => 3001,
    p_doctor_id => 2001,
    p_room_id => 101,
    p_admission_date => SYSDATE,
    p_diagnosis => 'Routine checkup'
  );
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 4: Add medicine');
  pkg_medical_management.add_admission_medicine(
    p_admission_id => 4006,
    p_medicine_id => 1001,
    p_dose => '500 mg',
    p_frequency => '2 times/day',
    p_administration_date => SYSDATE,
    p_duration_days => 5
  );
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 5: Show complete admission details');
  pkg_medical_management.show_admission_details(4006);
  DBMS_OUTPUT.PUT_LINE('');

  DBMS_OUTPUT.PUT_LINE('Test 6: Show existing admission with medicines');
  pkg_medical_management.show_admission_details(4001);

  ROLLBACK;
END;
/
