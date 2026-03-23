-- Create an independent stored subprogram that receives a patient's SSN and
-- generates a complete medical report with three sections:
-- 1) prescribed medicines (name and latest administered dose),
-- 2) admission history (admission date, discharge date, diagnosis),
-- 3) the last three rooms where the patient was admitted.

CREATE OR REPLACE PROCEDURE generate_patient_medical_report(p_ssn IN VARCHAR2)
IS
    TYPE t_medicines IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(50);

    TYPE t_admission_rec IS RECORD (
        admission_date DATE,
        discharge_date DATE,
        diagnosis      VARCHAR2(100)
    );

    TYPE t_admissions IS TABLE OF t_admission_rec;
    TYPE t_room_varray IS VARRAY(5) OF NUMBER(6);

    v_medicines   t_medicines;
    v_admissions  t_admissions := t_admissions();
    v_rooms       t_room_varray := t_room_varray();
    v_patient_id  patients.patient_id%TYPE;
    v_name        patients.name%TYPE;
    v_first_name  patients.first_name%TYPE;
    v_idx         medicines.name%TYPE;
BEGIN
    SELECT patient_id, name, first_name
    INTO v_patient_id, v_name, v_first_name
    FROM patients
    WHERE ssn = p_ssn;

    FOR d IN (
        SELECT m.name, am.dose, am.administration_date
        FROM medicines m
        JOIN admission_medicines am ON m.medicine_id = am.medicine_id
        JOIN admissions a ON am.admission_id = a.admission_id
        WHERE a.patient_id = v_patient_id
        ORDER BY am.administration_date DESC, m.name
    ) LOOP
        IF NOT v_medicines.EXISTS(d.name) THEN
            v_medicines(d.name) := d.dose;
        END IF;
    END LOOP;

    FOR a IN (
        SELECT admission_date, discharge_date, diagnosis
        FROM admissions
        WHERE patient_id = v_patient_id
        ORDER BY admission_date
    ) LOOP
        v_admissions.EXTEND;
        v_admissions(v_admissions.COUNT).admission_date := a.admission_date;
        v_admissions(v_admissions.COUNT).discharge_date := a.discharge_date;
        v_admissions(v_admissions.COUNT).diagnosis := a.diagnosis;
    END LOOP;

    FOR r IN (
        SELECT rm.room_number
        FROM admissions a
        JOIN rooms rm ON a.room_id = rm.room_id
        WHERE a.patient_id = v_patient_id
        ORDER BY a.admission_date DESC
        FETCH FIRST 3 ROWS ONLY
    ) LOOP
        v_rooms.EXTEND;
        v_rooms(v_rooms.COUNT) := r.room_number;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Patient: ' || v_name || ' ' || v_first_name);
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('----- Medicine Name - Dose -----');
    v_idx := v_medicines.FIRST;
    IF v_idx IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('  (No medicines recorded)');
    ELSE
        WHILE v_idx IS NOT NULL LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || v_idx || ' - ' || v_medicines(v_idx));
            v_idx := v_medicines.NEXT(v_idx);
        END LOOP;
    END IF;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('----- Admission Date - Discharge Date - Diagnosis -----');
    IF v_admissions.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (No admissions recorded)');
    ELSE
        FOR i IN v_admissions.FIRST .. v_admissions.LAST LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  ' || TO_CHAR(v_admissions(i).admission_date, 'DD.MM.YYYY') || ' - ' ||
                CASE
                    WHEN v_admissions(i).discharge_date IS NULL THEN 'Ongoing'
                    ELSE TO_CHAR(v_admissions(i).discharge_date, 'DD.MM.YYYY')
                END || ' - ' || NVL(v_admissions(i).diagnosis, 'N/A')
            );
        END LOOP;
    END IF;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('----- Rooms -----');
    IF v_rooms.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (No rooms recorded)');
    ELSE
        FOR i IN v_rooms.FIRST .. v_rooms.LAST LOOP
            DBMS_OUTPUT.PUT_LINE('  Room no. ' || v_rooms(i));
        END LOOP;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Patient not found.');
END generate_patient_medical_report;
/

SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Case 1');
    generate_patient_medical_report('6000101012345');
    DBMS_OUTPUT.PUT_LINE('Case 2');
    generate_patient_medical_report('6000101012352');
END;
/
