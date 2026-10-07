"""Controle de aceite de uma geracao do Wan (rode no arquivo BRUTO, antes da pos).

Uso:  python3 aceite.py gerado.mp4 [--desde S] [--precisa S] [--hold-max S]
                         [--piso-min X] [--ref ref.mp4]

--desde S    ignora os primeiros S segundos (ex.: o trecho da referencia,
             quando a geracao e uma extensao do video de referencia)
--precisa S  quantos segundos vivos voce precisa (ex.: 15)
--hold-max S maior trecho identico aceito (padrao 0,2 s). Para referencias
             com holds longos (Aqua 0,27 s) use o maior hold da referencia
             + 1 quadro, sem contar pontas de loop e pausa intencional.
--piso-min X piso de energia exigido (padrao 0,15). Rode o aceite na propria
             referencia: se ela reprovar (sala de aula: piso 0,09 no close
             parado; Aqua: pausa de 1 s), use um valor um pouco abaixo do
             piso dela fora da pausa (sala 0,08; Aqua 0,2).
--ref V      (so informativo) mede tambem a referencia e imprime: desenhos/s
             e maior hold dela, a razao de energia por segundo geracao/ref
             e a sugestao de pos de cadencia (nenhuma / grade / regerar).

Mesma medida do metric.py (cinza 160x90, janelas de 0,5 s, energia
normalizada pelo pico do video). Regras, calibradas nas 6 geracoes medidas
(boas fa5/0ca: piso 0,29/0,19, hold 0,13/0,10 s; ruins: piso 0,01-0,10):
  1. corta o rabo morto na 1a de 2 janelas seguidas abaixo de 0,10
  2. no trecho que sobra: hold identico mais longo <= 0,2 s
                          piso de energia (janelas completas) >= 0,15
                          duracao viva >= --precisa
"""
import argparse, json, subprocess
import numpy as np

ap = argparse.ArgumentParser()
ap.add_argument("video")
ap.add_argument("--desde", type=float, default=0.0)
ap.add_argument("--precisa", type=float, default=0.0)
ap.add_argument("--hold-max", type=float, default=0.2)
ap.add_argument("--piso-min", type=float, default=0.15)
ap.add_argument("--ref", default=None)
a = ap.parse_args()


def medir(path):
    st = json.loads(subprocess.check_output(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
         "stream=r_frame_rate", "-of", "json", path]))["streams"][0]
    nu, de = st["r_frame_rate"].split("/")
    f = float(nu) / float(de)
    rw = subprocess.check_output(
        ["ffmpeg", "-v", "error", "-i", path, "-vf", "scale=160:90",
         "-f", "rawvideo", "-pix_fmt", "gray", "-"])
    qq = np.frombuffer(rw, np.uint8).reshape(-1, 90, 160).astype(float)
    return f, np.abs(np.diff(qq, axis=0)).mean(axis=(1, 2))


def piso_de(dd, f):
    w = max(1, int(round(f / 2)))
    ee = [dd[i:i + w].sum() for i in range(0, len(dd), w) if len(dd[i:i + w]) == w]
    return min(ee) / (max(ee) or 1) if ee else 0.0


def maior_hold(dd):
    m = r = 1
    for x in dd:
        r = r + 1 if x < 1.0 else 1
        m = max(m, r)
    return m

s = json.loads(subprocess.check_output(
    ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
     "stream=r_frame_rate", "-of", "json", a.video]))["streams"][0]
num, den = s["r_frame_rate"].split("/")
fps = float(num) / float(den)
w, h = 160, 90
raw = subprocess.check_output(
    ["ffmpeg", "-v", "error", "-i", a.video, "-vf", f"scale={w}:{h}",
     "-f", "rawvideo", "-pix_fmt", "gray", "-"])
q = np.frombuffer(raw, np.uint8).reshape(-1, h, w).astype(float)
d = np.abs(np.diff(q, axis=0)).mean(axis=(1, 2))   # d[i] = quadro i -> i+1
n = len(q)
win = max(1, int(round(fps / 2)))
e = np.array([d[i:i + win].sum() for i in range(0, len(d), win)])
completa = np.array([len(d[i:i + win]) == win for i in range(0, len(d), win)])
e = e / (e.max() or 1)

j0 = int(np.ceil(a.desde * fps / win))           # 1a janela analisada
corte_j = None
for j in range(j0, len(e)):
    if not completa[j]:
        break
    prox_baixa = (j + 1 < len(e) and completa[j + 1] and e[j + 1] < 0.10) \
        or (j + 1 >= len(e) or not completa[j + 1])
    if e[j] < 0.10 and prox_baixa:
        corte_j = j
        break
fim_q = corte_j * win if corte_j is not None else n - 1
ini_q = int(round(a.desde * fps))

# hold identico mais longo dentro de [ini_q, fim_q]
maior = r = 1
for x in d[ini_q:fim_q]:
    r = r + 1 if x < 1.0 else 1
    maior = max(maior, r)
jj = [j for j in range(j0, corte_j if corte_j is not None else len(e)) if completa[j]]
piso = float(e[jj].min()) if jj else 0.0
vivo = (fim_q - ini_q) / fps
desenhos = 1 + int((d[ini_q:fim_q] >= 1.0).sum())

ok_hold = maior / fps <= a.hold_max + 1e-9
ok_piso = piso >= a.piso_min - 1e-9
ok_dur = vivo >= a.precisa
print(json.dumps({
    "energia_por_meio_segundo": [round(float(x), 2) for x in e],
    "corte_s": round(fim_q / fps, 2) if corte_j is not None else None,
    "segundos_vivos": round(vivo, 2),
    "hold_identico_max_s": round(maior / fps, 2),
    "piso": round(piso, 2),
    "desenhos_por_s (so informativo)": round(desenhos / vivo, 1) if vivo else 0,
}, ensure_ascii=False))
print(("ACEITA" if ok_hold and ok_piso and ok_dur else "REGERE")
      + f"  hold {'ok' if ok_hold else 'FALHOU'}"
      + f" | piso {'ok' if ok_piso else 'FALHOU'}"
      + f" | duracao {'ok' if ok_dur else 'FALHOU'}")
if corte_j is not None:
    print(f"corte o rabo: ffmpeg ... -t {fim_q / fps:.2f} ...")
if a.ref:
    rfps, rd = medir(a.ref)
    r_des = (1 + int((rd >= 1.0).sum())) / (len(rd) / rfps)
    g_des = desenhos / vivo if vivo else 0
    r_e = rd.sum() / (len(rd) / rfps)
    g_e = d[ini_q:fim_q].sum() / vivo if vivo else 0
    razao = g_des / r_des if r_des else 0
    if razao > 1.3:
        sug = "geracao mais lisa que a referencia: aplique a pos de grade do tipo"
    elif razao < 0.75:
        sug = "geracao com menos desenhos que a referencia: a pos nao resolve, regere"
    else:
        sug = "cadencia ja parecida com a referencia: nao aplique pos de cadencia"
    print(json.dumps({
        "ref_desenhos_por_s": round(r_des, 1),
        "ref_hold_identico_max_s": round(maior_hold(rd) / rfps, 2),
        "ref_piso": round(piso_de(rd, rfps), 2),
        "razao_desenhos_ger_ref": round(razao, 2),
        "razao_energia_por_s_ger_ref (tela inteira, so informativo)":
            round(g_e / r_e, 2) if r_e else None,
    }, ensure_ascii=False))
    print("sugestao de pos:", sug)
