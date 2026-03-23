-- Să se creeze o procedură stocată care parcurge toate secțiile spitalului (active 
-- și inactive) și pentru fiecare secție afișează lista medicilor care au avut pacienți 
-- internați în saloanele acelei secții într-un an dat ca parametru. Pentru fiecare 
-- medic se vor afișa: nume, prenume și specializare și numărul de internări. Dacă o 
-- secție nu are internări în anul selectat, se va afișa un mesaj specific.

CREATE OR REPLACE PROCEDURE raport_medici_per_sectie(
  p_an VARCHAR DEFAULT TO_CHAR(SYSDATE, 'YYYY')
) IS
  CURSOR c_medici_sectie (p_id_sectie sectii.id_sectie%TYPE) IS
    SELECT
      a.nume,
      a.prenume,
      m.specializare,
      COUNT(DISTINCT i.id_internare) AS num_internari
    FROM medici m
    JOIN angajati a ON m.id_angajat = a.id_angajat
    JOIN internari i ON m.id_angajat = i.id_medic
    JOIN saloane s ON i.id_salon = s.id_salon
    WHERE s.id_sectie = p_id_sectie
      AND TO_CHAR(i.data_internare, 'YYYY') = p_an
    GROUP BY a.nume, a.prenume, m.specializare
    ORDER BY a.nume, a.prenume;

  c SYS_REFCURSOR;
  v_id_sectie sectii.id_sectie%TYPE;
  v_denumire sectii.denumire%TYPE;
  v_num_medici NUMBER;
BEGIN
  OPEN c FOR 'SELECT id_sectie, denumire
               FROM sectii
               ORDER BY denumire';
  LOOP
    FETCH c INTO v_id_sectie, v_denumire;
    EXIT WHEN c%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Sectia: ' || v_denumire);

    v_num_medici := 0;
    FOR rec_medic IN c_medici_sectie(v_id_sectie) LOOP
      v_num_medici := v_num_medici + 1;
      DBMS_OUTPUT.PUT_LINE('  - ' || rec_medic.nume || ' ' || rec_medic.prenume ||
        ' (' || rec_medic.specializare || ') - ' || rec_medic.num_internari || ' internari');
    END LOOP;

    IF v_num_medici = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Nu exista medici cu internari in anul selectat.');
    END IF;
  END LOOP;
  CLOSE c;

  DBMS_OUTPUT.PUT_LINE('');
END raport_medici_per_sectie;
/

SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Ex 1');
    raport_medici_per_sectie('2025');
    DBMS_OUTPUT.PUT_LINE('Ex 2');
    raport_medici_per_sectie('2026');
END;
/
