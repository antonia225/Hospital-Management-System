-- Create a stored procedure that iterates through all hospital departments
-- (active and inactive). For each department, it prints doctors who treated
-- admitted patients in that department during a given year, along with
-- their specialization and admission count. If a department has no admissions
-- in the selected year, a specific message is shown.

CREATE OR REPLACE PROCEDURE report_doctors_by_department(
  p_year VARCHAR2 DEFAULT TO_CHAR(SYSDATE, 'YYYY')
) IS
  CURSOR c_doctors_for_department(p_department_id departments.department_id%TYPE) IS
    SELECT
      e.name,
      e.first_name,
      d.specialization,
      COUNT(DISTINCT a.admission_id) AS admission_count
    FROM doctors d
    JOIN employees e ON d.employee_id = e.employee_id
    JOIN admissions a ON d.employee_id = a.doctor_id
    JOIN rooms r ON a.room_id = r.room_id
    WHERE r.department_id = p_department_id
      AND TO_CHAR(a.admission_date, 'YYYY') = p_year
    GROUP BY e.name, e.first_name, d.specialization
    ORDER BY e.name, e.first_name;

  c SYS_REFCURSOR;
  v_department_id departments.department_id%TYPE;
  v_department_name departments.name%TYPE;
  v_doctor_count NUMBER;
BEGIN
  OPEN c FOR
    'SELECT department_id, name
     FROM departments
     ORDER BY name';

  LOOP
    FETCH c INTO v_department_id, v_department_name;
    EXIT WHEN c%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Department: ' || v_department_name);

    v_doctor_count := 0;
    FOR rec_doctor IN c_doctors_for_department(v_department_id) LOOP
      v_doctor_count := v_doctor_count + 1;
      DBMS_OUTPUT.PUT_LINE(
        '  - ' || rec_doctor.name || ' ' || rec_doctor.first_name ||
        ' (' || rec_doctor.specialization || ') - ' ||
        rec_doctor.admission_count || ' admissions'
      );
    END LOOP;

    IF v_doctor_count = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No doctors with admissions in the selected year.');
    END IF;
  END LOOP;

  CLOSE c;
  DBMS_OUTPUT.PUT_LINE('');
END report_doctors_by_department;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Case 1');
  report_doctors_by_department('2025');
  DBMS_OUTPUT.PUT_LINE('Case 2');
  report_doctors_by_department('2026');
END;
/
