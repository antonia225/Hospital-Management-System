-- Să se creeze un subprogram stocat independent care primește ca parametru CNP-ul unui 
-- pacient și generează un raport medical complet. Subprogramul identifică pacientul pe 
-- baza CNP-ului și afișează numele acestuia, apoi construiește raportul cu trei secțiuni: 
-- lista medicamentelor prescrise (denumirea și ultima doză administrată, iar dacă în ultima 
-- zi există mai multe administrări se ia prima găsită), istoricul internărilor (data internării, 
-- data externării și diagnosticul) și ultimele trei saloane în care pacientul a fost internat 
-- (numărul salonului). La apelul subprogramului cu un CNP valid, se afișează integral raportul 
-- pacientului într-un format clar, ușor de urmărit.

CREATE OR REPLACE PROCEDURE raport_medical_pacient(p_cnp IN VARCHAR2)
IS
    TYPE t_medicamente IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(50);
    TYPE t_internare_rec IS RECORD (
        data_internare  DATE,        
        data_externare  DATE,
        diagnostic      VARCHAR2(100)
    );
    TYPE t_internari IS TABLE OF t_internare_rec;
    TYPE t_salon_varray IS VARRAY(5) OF NUMBER(6);
    
    v_medicamente   t_medicamente;
    v_internari     t_internari := t_internari();
    v_saloane       t_salon_varray := t_salon_varray();
    v_pacient_id    pacienti.id_pacient%TYPE;
    v_nume          pacienti.nume%TYPE;
    v_prenume       pacienti.prenume%TYPE;
    v_idx           medicamente.denumire%TYPE;
    v_cnp           pacienti.cnp%TYPE := p_cnp;
BEGIN
    SELECT id_pacient, nume, prenume 
    INTO v_pacient_id, v_nume, v_prenume
    FROM pacienti
    WHERE cnp = v_cnp;

    FOR d IN (
        SELECT m.denumire, im.doza, im.data_administrare
        FROM medicamente m JOIN internari_medicamente im ON (m.id_medicament = im.id_medicament)
            JOIN internari i ON (im.id_internare = i.id_internare)
        WHERE i.id_pacient = v_pacient_id
        ORDER BY im.data_administrare DESC, m.denumire
    ) LOOP
        IF NOT v_medicamente.EXISTS(d.denumire) THEN
            v_medicamente(d.denumire) := d.doza;
        END IF;
    END LOOP;

    FOR i IN (
        SELECT data_internare, data_externare, diagnostic
        FROM internari
        WHERE id_pacient = v_pacient_id
        ORDER BY data_internare
    ) LOOP
        v_internari.EXTEND;
        v_internari(v_internari.COUNT).data_internare := i.data_internare;
        v_internari(v_internari.COUNT).data_externare := i.data_externare;
        v_internari(v_internari.COUNT).diagnostic := i.diagnostic;
    END LOOP;

    FOR s IN (
        SELECT s.NR_SALON
        FROM INTERNARi i JOIN SALOANE s ON (i.id_salon = s.ID_SALON)
        WHERE i.id_pacient = v_pacient_id
        ORDER BY i.data_internare DESC
        FETCH FIRST 3 ROWS ONLY
    ) LOOP
        v_saloane.EXTEND;
        v_saloane(v_saloane.COUNT) := s.nr_salon;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Pacient: ' || v_nume || ' ' || v_prenume);
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('----- Denumire medicament - Doza -----');
    v_idx := v_medicamente.FIRST;
    IF v_idx IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('  (Nu exista medicamente inregistrate)');
    ELSE
        WHILE v_idx IS NOT NULL LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || v_idx || ' - ' || v_medicamente(v_idx));
            v_idx := v_medicamente.NEXT(v_idx);
        END LOOP;
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('----- Data Internare - Data Externare - Diagnostic -----');
    IF v_internari.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (Nu exista internari inregistrate)');
    ELSE
        FOR i IN v_internari.FIRST .. v_internari.LAST LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || 
                TO_CHAR(v_internari(i).data_internare, 'DD.MM.YYYY') || ' - ' ||
                CASE WHEN v_internari(i).data_externare IS NULL THEN 'In curs' 
                     ELSE TO_CHAR(v_internari(i).data_externare, 'DD.MM.YYYY') END || ' - ' ||
                NVL(v_internari(i).diagnostic, 'N/A'));
        END LOOP;
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('----- Saloane -----');
    IF v_saloane.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (Nu exista saloane inregistrate)');
    ELSE
        FOR i IN v_saloane.FIRST .. v_saloane.LAST LOOP
            DBMS_OUTPUT.PUT_LINE('  Salon nr. ' || v_saloane(i));
        END LOOP;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('Nu exista acest pacient.');
END raport_medical_pacient;
/

SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Ex 1');
    raport_medical_pacient('6000101012345');
    DBMS_OUTPUT.PUT_LINE('Ex 2');
    raport_medical_pacient('6000101012352');
END;
/
