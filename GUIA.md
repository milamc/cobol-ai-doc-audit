# Laboratório CardDemo + GnuCOBOL

Ambiente para rodar programas COBOL batch do AWS CardDemo fora do mainframe,
usado como base de verificação para o experimento de documentação com IA.

Testado em Ubuntu 24.04 com GnuCOBOL 3.1.2.

---

## Instalação rápida

```bash
bash setup.sh
```

O script instala o GnuCOBOL, clona o CardDemo, compila os stubs, carrega os
dados e executa o CBACT01C de ponta a ponta.

---

## As cinco armadilhas (todas confirmadas na prática)

### 1. Não use `-free`

O fonte do CardDemo tem numeração de sequência nas colunas 1-6 e indicador de
comentário na coluna 7. Em formato livre, o compilador interpreta os números
como statements e cospe dezenas de erros falsos.

```
cobc -x -free CBACT01C.cbl     # ~16 erros de sintaxe, todos falsos
cobc -x CBACT01C.cbl           # compila limpo
```

### 2. Zoned decimal com sinal sobreposto

Os dados ASCII têm caracteres como `{` no meio dos números:

```
00000000001Y00000001940{00000020200{...
```

Isso **não é corrupção**. É `PIC S9(10)V99` DISPLAY com o sinal sobreposto no
último dígito (`{` = +0). O GnuCOBOL decodifica nativamente — `00000001940{`
é lido como `+0000000194.00`. Ferramentas genéricas de parsing de texto vão
tratar como lixo. Vale conferir sempre contra o copybook.

### 3. VSAM não existe fora do z/OS

O CBACT01C declara `ORGANIZATION IS INDEXED` (KSDS), mas o dado vem como
arquivo plano de 300 bytes. No mainframe isso seria um `IDCAMS REPRO`; aqui é
preciso escrever um carregador. Está em `LOADACCT.cbl`.

### 4. Dependências em Assembler e Language Environment

O `CBACT01C` faz `CALL 'COBDATFT'` — e o COBDATFT é **HLASM**
(`app/asm/COBDATFT.asm`), não COBOL. Também chama `CEE3ABD`, serviço de abend
do IBM Language Environment. Nenhum dos dois compila fora do z/OS.

Sem stub, o programa aborta no meio da execução:

```
libcob: error: module 'COBDATFT' not found
```

Os stubs em `COBDATFT.cbl` e `CEE3ABD.cbl` resolvem. **Importante para o
experimento:** o stub é uma reimplementação sua, não o comportamento original.
Programas que dependem pesadamente de Assembler ficam fora do escopo de
verificação — vale declarar isso explicitamente no artigo.

### 5. DDNAMEs viram variáveis de ambiente

Cada `ASSIGN TO XXXX` precisa de uma variável de ambiente `XXXX` apontando
para um arquivo. Para o CBACT01C: `ACCTFILE`, `OUTFILE`, `ARRYFILE`,
`VBRCFILE`. Faltando qualquer uma, o erro é obscuro. Os módulos dinâmicos
(`.so`) precisam de `COB_LIBRARY_PATH`.

---

## Achado para o artigo: o `IF` sem `ELSE` no CBACT01C

Por volta da linha 236:

```cobol
MOVE   ACCT-CURR-CYC-CREDIT    TO   OUT-ACCT-CURR-CYC-CREDIT.
IF  ACCT-CURR-CYC-DEBIT EQUAL TO ZERO
    MOVE 2525.00         TO   OUT-ACCT-CURR-CYC-DEBIT
END-IF.
```

Dois problemas em quatro linhas:

1. **Constante mágica `2525.00`** sem nenhuma justificativa de negócio.
2. **Não há `ELSE`.** Quando o débito do ciclo é diferente de zero, o campo de
   saída nunca é atribuído e mantém o valor do registro anterior.

E o detalhe que fecha o argumento: **nenhum dos 50 registros de amostra tem
`CURR-CYC-DEBIT` diferente de zero.** O defeito é invisível em qualquer teste
que use os dados que vêm no repositório.

### Reprodução

Alterando o registro 2 para débito de 500,00 e reexecutando, os três registros
de saída trazem o mesmo COMP-3 `\x00\x00\x00\x02RP\x0c`, que decodifica para
**2525,00**. O valor real de 500,00 desapareceu.

Este é o caso de teste ideal para o experimento: pergunte ao modelo o que o
programa faz com `ACCT-CURR-CYC-DEBIT` e classifique a resposta.

- Descreveu como "move o débito para a saída"? → **incorreta**
- Não mencionou o campo? → **omitida**
- Citou o 2525.00 mas não o `ELSE` ausente? → **parcial**
- Apontou o vazamento entre registros? → **correta**

---

## Programas batch disponíveis

| Programa   | Linhas | Observação                                |
|------------|--------|-------------------------------------------|
| CBACT01C   | 430    | Leitura de contas. Bom baseline.          |
| CBTRN02C   | 731    | Postagem de transações. Regra de negócio. |
| CBSTM03A   | 924    | Chama sub-rotina. Atravessa fronteira.    |
| CBSTM03B   | 230    | Sub-rotina do CBSTM03A.                   |

Todos fazem `CALL` externo — verifique as dependências antes de escolher.
Os programas CICS (`CO*`) não rodam em GnuCOBOL; ficam para um segundo artigo.
