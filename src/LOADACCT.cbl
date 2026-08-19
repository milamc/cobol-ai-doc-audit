      *****************************************************************
      * LOADACCT - Carrega arquivo sequencial ASCII em arquivo
      *            INDEXED, substituindo o IDCAMS REPRO do mainframe.
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOADACCT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FLAT-FILE ASSIGN TO FLATIN
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS FLAT-STATUS.

           SELECT IDX-FILE  ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS RANDOM
                  RECORD KEY   IS IDX-ACCT-ID
                  FILE STATUS  IS IDX-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  FLAT-FILE.
       01  FLAT-REC.
           05  FLAT-ACCT-ID    PIC X(11).
           05  FILLER          PIC X(289).

       FD  IDX-FILE.
       01  IDX-REC.
           05  IDX-ACCT-ID     PIC X(11).
           05  FILLER          PIC X(289).

       WORKING-STORAGE SECTION.
       01  FLAT-STATUS         PIC XX VALUE SPACES.
       01  IDX-STATUS          PIC XX VALUE SPACES.
       01  WS-EOF              PIC X  VALUE 'N'.
       01  WS-COUNT            PIC 9(5) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-PARA.
           OPEN INPUT FLAT-FILE
           IF FLAT-STATUS NOT = '00'
              DISPLAY 'ERRO ABRINDO FLAT: ' FLAT-STATUS
              STOP RUN
           END-IF

           OPEN OUTPUT IDX-FILE
           IF IDX-STATUS NOT = '00'
              DISPLAY 'ERRO ABRINDO INDEXED: ' IDX-STATUS
              STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
              READ FLAT-FILE
                 AT END
                    MOVE 'Y' TO WS-EOF
                 NOT AT END
                    MOVE FLAT-REC TO IDX-REC
                    WRITE IDX-REC
                    IF IDX-STATUS NOT = '00'
                       DISPLAY 'ERRO GRAVANDO: ' IDX-STATUS
                              ' CHAVE: ' FLAT-ACCT-ID
                    ELSE
                       ADD 1 TO WS-COUNT
                    END-IF
              END-READ
           END-PERFORM

           CLOSE FLAT-FILE
           CLOSE IDX-FILE
           DISPLAY 'REGISTROS CARREGADOS: ' WS-COUNT
           STOP RUN.
