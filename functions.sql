-- Să se definească o funcție care primește ca parametru numele de familie al unui pacient 
-- și identifică medicul care a supravegheat cea mai recentă internare a acestuia. Funcția 
-- va returna numele complet și gradul medicului responsabil, obținute printr-o singură 
-- comandă SQL care folosește trei tabele relevante din baza de date. Se vor trata toate 
-- situațiile posibile, inclusiv cazul în care nu există pacientul sau nu are internări 
-- (NO_DATA_FOUND), respectiv cazul în care există mai mulți pacienți cu același nume 
-- (TOO_MANY_ROWS). Funcția va fi apelată în mod demonstrativ astfel încât să fie evidențiat 
-- atât un caz de succes, cât și fiecare tip de excepție tratată.

CREATE OR REPLACE FUNCTION get_medic_ultima_internare(
  p_nume_pacient VARCHAR2
) RETURN VARCHAR2 IS
  v_medic_info VARCHAR2(200);
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM pacienti WHERE UPPER(nume) = UPPER(p_nume_pacient);
  IF v_cnt > 1 THEN
    RAISE TOO_MANY_ROWS;
  END IF;

  SELECT (
    SELECT a.nume || ' ' || a.prenume 
    FROM angajati a 
    WHERE a.id_angajat = m.id_angajat) || ' - ' || m.grad
  INTO v_medic_info
  FROM pacienti p
  JOIN internari i ON p.id_pacient = i.id_pacient
  JOIN medici m ON i.id_medic = m.id_angajat
  WHERE UPPER(p.nume) = UPPER(p_nume_pacient)
  ORDER BY i.data_internare DESC
  FETCH FIRST 1 ROW ONLY;
  
  RETURN v_medic_info;
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'EROARE: Pacient inexistent sau fara internari';
  WHEN TOO_MANY_ROWS THEN
    RETURN 'EROARE: Exista mai multi pacienti cu numele ' || p_nume_pacient;
  WHEN OTHERS THEN
    RETURN 'EROARE: ' || SQLERRM;
END get_medic_ultima_internare;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Ex 1: Pacient valid cu internari');
  DBMS_OUTPUT.PUT_LINE(get_medic_ultima_internare('Iacob'));
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 2: NO_DATA_FOUND - pacient inexistent');
  DBMS_OUTPUT.PUT_LINE(get_medic_ultima_internare('NumeInexistent'));
  DBMS_OUTPUT.PUT_LINE('');
  
  INSERT INTO pacienti (id_pacient, nume, prenume, cnp, data_nasterii, adresa, telefon, email, grupa_sange)
  VALUES (3006, 'Iacob', 'Maria', '2950606234567', TO_DATE('1995-06-06','YYYY-MM-DD'), 
          'Str. Test 1', '0722000006', 'maria.iacob@example.com', 2);
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('Ex 3: TOO_MANY_ROWS - mai multi pacienti cu acelasi nume');
  DBMS_OUTPUT.PUT_LINE(get_medic_ultima_internare('Iacob'));
  DBMS_OUTPUT.PUT_LINE('');
  
  DELETE FROM pacienti WHERE id_pacient = 3006;
  COMMIT;
END;
/
