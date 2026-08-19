      *****************************************************************
      * STUB de COBDATFT (original em Assembler HLASM z/OS).
      * Reimplementa a formatacao de data em COBOL para permitir
      * execucao fora do mainframe. TIPO 2 = YYYY-MM-DD.
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDATFT.
       DATA DIVISION.
       LINKAGE SECTION.
       COPY CODATECN.
       PROCEDURE DIVISION USING CODATECN-REC.
       MAIN-PARA.
           MOVE CODATECN-INP-DATE (1:20) TO CODATECN-0UT-DATE (1:20)
           GOBACK.
