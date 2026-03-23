-- Să se creeze un trigger LMD la nivel de comandă care se declanșează la orice 
-- operațiune de inserare, modificare sau ștergere asupra tabelului INTERNARI și 
-- urmărește impactul acestor schimbări asupra ocupării saloanelor și a distribuției 
-- pacienților pe secții. După fiecare comandă executată, trigger-ul va calcula și 
-- va afișa un raport sintetic cu numărul de rânduri afectate, saloanele implicate 
-- în modificare, gradul de ocupare al fiecărui salon și repartizarea pe secții. În 
-- plus, raportul va include alerte pentru saloanele care se apropie de capacitatea 
-- maximă, astfel încât situațiile de supraaglomerare să fie observate imediat.

CREATE OR REPLACE TRIGGER trg_statistici_internari
AFTER INSERT OR UPDATE OR DELETE ON internari
DECLARE
  v_tip_operatie VARCHAR2(10);
  v_numar_randuri NUMBER;
  v_saloane_afectate NUMBER;
  v_total_pacienti NUMBER;
  v_total_capacitate NUMBER;
BEGIN
  v_numar_randuri := SQL%ROWCOUNT;
  
  IF INSERTING THEN
    v_tip_operatie := 'INSERT';
  ELSIF UPDATING THEN
    v_tip_operatie := 'UPDATE';
  ELSIF DELETING THEN
    v_tip_operatie := 'DELETE';
  END IF;
  
  SELECT COUNT(DISTINCT id_salon)
  INTO v_saloane_afectate
  FROM internari
  WHERE data_externare IS NULL;
  
  SELECT COUNT(*)
  INTO v_total_pacienti
  FROM internari
  WHERE data_externare IS NULL;

  SELECT NVL(SUM(nr_paturi), 0)
  INTO v_total_capacitate
  FROM saloane
  WHERE activ = 'Y';
  
  DBMS_OUTPUT.PUT_LINE('RAPORT INTERNARI - ' || v_tip_operatie);
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Randuri modificate: ' || v_numar_randuri);
  DBMS_OUTPUT.PUT_LINE('Saloane implicate: ' || v_saloane_afectate);
  IF v_total_capacitate = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Grad ocupare: N/A');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Grad ocupare: ' || ROUND((v_total_pacienti/v_total_capacitate)*100, 1) || '%');
  END IF;
  DBMS_OUTPUT.PUT_LINE('');

  FOR rec IN (
    SELECT s.id_salon,
        ROUND((COUNT(i.id_internare)/s.nr_paturi)*100, 1) AS procent_ocupare
    FROM saloane s
    LEFT JOIN internari i ON s.id_salon = i.id_salon
    WHERE s.activ = 'Y'
    AND i.data_externare IS NULL
    GROUP BY s.id_salon, s.nr_paturi
    HAVING COUNT(i.id_internare) >= s.nr_paturi * 0.8
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Salon ' || rec.id_salon || ': ' || rec.procent_ocupare || '%)');
  END LOOP;
END trg_statistici_internari;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Ex 1: INSERT - adăugare internare nouă');
  INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, diagnostic)
  VALUES (9001, 3001, 2001, 101, SYSDATE, 'Monitorizare post-operatorie');
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 2: INSERT - mai multe internări simultan');
  INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, diagnostic)
  VALUES (9002, 3002, 2002, 101, SYSDATE, 'Tratament pneumonie');
  INSERT INTO internari (id_internare, id_pacient, id_medic, id_salon, data_internare, diagnostic)
  VALUES (9003, 3003, 2003, 102, SYSDATE, 'Recuperare cardiovasculară');
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 3: UPDATE - modificare diagnostic');
  UPDATE internari 
  SET diagnostic = 'Monitorizare post-operatorie (stare stabilă)'
  WHERE id_internare = 9001;
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 4: DELETE - externare pacient');
  DELETE FROM internari WHERE id_internare = 9001;
  DBMS_OUTPUT.PUT_LINE('');
  
  DBMS_OUTPUT.PUT_LINE('Ex 5: DELETE - externare multiplă');
  DELETE FROM internari WHERE id_internare IN (9002, 9003);
  
  ROLLBACK;
END;
/
