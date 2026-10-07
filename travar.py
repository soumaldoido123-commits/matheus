"""Deixa um video de IA com timing de animacao desenhada a mao.

Uso:  python3 travar.py entrada.mp4 saida.mp4 [--trava N] [--lento N]

--trava N  quadros que a pose trava no fim de um movimento (padrao 6, o do
           travar.py original). Use o maior hold da referencia x fps.
--lento N  quadros por desenho no movimento lento (padrao 3). Use 2 para
           sakuga em 1 e 2 (tipo A), que nunca chega a 3.

O que faz, quadro a quadro:
- movimento rapido  -> desenho novo a cada quadro (mantem smears e impactos)
- movimento medio   -> cada desenho segura 2 quadros (animacao em 2)
- movimento lento   -> cada desenho segura 3 quadros (animacao em 3)
- fim de um movimento (o corpo freia e para) -> TRAVA a pose por alguns
  quadros e depois DESTRAVA pulando direto para a posicao certa, entao o
  video nunca atrasa nem perde a sincronia.
A duracao do video nao muda.
"""
import argparse
import json
import subprocess

import numpy as np

TRAVA_QUADROS = 6      # quanto tempo a pose fica travada no fim de cada movimento
LIMIAR_RAPIDO = 0.60   # acima disto (relativo ao maior movimento) = rapido
LIMIAR_LENTO = 0.20    # abaixo disto = lento


def info(path):
    out = subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height,r_frame_rate",
        "-of", "json", path])
    s = json.loads(out)["streams"][0]
    num, den = s["r_frame_rate"].split("/")
    return s["width"], s["height"], f"{num}/{den}"


def ler_quadros(path, w, h):
    raw = subprocess.check_output(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "rawvideo",
         "-pix_fmt", "rgb24", "-"])
    return np.frombuffer(raw, np.uint8).reshape(-1, h, w, 3)


def main(entrada, saida, trava=TRAVA_QUADROS, lento=3):
    w, h, fps = info(entrada)
    q = ler_quadros(entrada, w, h)
    n = len(q)

    cinza = q[:, ::8, ::8].mean(axis=3)
    mov = np.zeros(n)
    mov[1:] = np.abs(np.diff(cinza, axis=0)).mean(axis=(1, 2))
    mov = np.convolve(mov, np.ones(3) / 3, mode="same")
    rel = mov / (mov.max() or 1)

    saida_idx = []
    i = 0
    while i < n:
        fim_de_movimento = (
            0 < i < n - 1 and rel[i - 1] > LIMIAR_RAPIDO * 0.8
            and rel[i] < rel[i - 1] * 0.6)
        if fim_de_movimento:
            seg = trava
        elif rel[i] >= LIMIAR_RAPIDO:
            seg = 1
        elif rel[i] >= LIMIAR_LENTO:
            seg = 2
        else:
            seg = lento
        seg = min(seg, n - i)
        saida_idx += [i] * seg
        i += seg

    enc = subprocess.Popen(
        ["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
         "-s", f"{w}x{h}", "-r", fps, "-i", "-", "-i", entrada,
         "-map", "0:v", "-map", "1:a?", "-c:v", "libx264", "-pix_fmt",
         "yuv420p", "-crf", "16", "-shortest", saida],
        stdin=subprocess.PIPE)
    for k in saida_idx:
        enc.stdin.write(q[k].tobytes())
    enc.stdin.close()
    enc.wait()

    unicos = len(set(saida_idx))
    print(f"{n} quadros -> {unicos} desenhos diferentes "
          f"({n / unicos:.1f} quadros por desenho em media)")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("entrada")
    ap.add_argument("saida")
    ap.add_argument("--trava", type=int, default=TRAVA_QUADROS)
    ap.add_argument("--lento", type=int, default=3)
    a = ap.parse_args()
    main(a.entrada, a.saida, a.trava, a.lento)
