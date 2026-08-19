#!/usr/bin/env bash
# =====================================================================
# Ambiente CardDemo + GnuCOBOL — testado em Ubuntu 24.04 / GnuCOBOL 3.1.2
# Uso:  bash setup.sh
# =====================================================================
set -e

LAB="${LAB:-$HOME/cobol-lab}"
mkdir -p "$LAB"/{bin,data,src}
cd "$LAB"

#echo ">>> 1/5 Instalando GnuCOBOL"
#if ! command -v cobc >/dev/null 2>&1; then
##  sudo apt-get update -qq
#  sudo apt-get install -y gnucobol
#fi
#cobc --version | head -1

echo ">>> 2/5 Clonando CardDemo"
[ -d carddemo ] || git clone --depth 1 \
  https://github.com/aws-samples/aws-mainframe-modernization-carddemo.git carddemo

CD_APP="$LAB/carddemo/app"

echo ">>> 3/5 Compilando stubs (substituem Assembler/LE do z/OS)"
# COBDATFT: o original é HLASM (app/asm/COBDATFT.asm) e não roda fora do z/OS.
cobc -m src/COBDATFT.cbl -I "$CD_APP/cpy" -o bin/COBDATFT.so
cobc -m src/CEE3ABD.cbl                   -o bin/CEE3ABD.so

echo ">>> 4/5 Compilando carregador e programa alvo"
# ATENÇÃO: NÃO usar -free. O fonte tem numeração nas colunas 1-6 (formato fixo).
cobc -x src/LOADACCT.cbl              -o bin/LOADACCT
cobc -x "$CD_APP/cbl/CBACT01C.cbl" -I "$CD_APP/cpy" -o bin/CBACT01C

echo ">>> 5/5 Carregando dados no arquivo INDEXED (equivale ao IDCAMS REPRO)"
export FLATIN="$CD_APP/data/ASCII/acctdata.txt"
export ACCTFILE="$LAB/data/ACCTFILE"
rm -f "$LAB/data/ACCTFILE"*
./bin/LOADACCT

echo
echo ">>> Execução de teste"
export COB_LIBRARY_PATH="$LAB/bin"
export OUTFILE="$LAB/data/OUTFILE.txt"
export ARRYFILE="$LAB/data/ARRYFILE.txt"
export VBRCFILE="$LAB/data/VBRCFILE.txt"
./bin/CBACT01C | tail -3

echo
echo "OK. Ambiente pronto em: $LAB"
echo "Para rodar de novo, exporte as variáveis acima e chame ./bin/CBACT01C"
