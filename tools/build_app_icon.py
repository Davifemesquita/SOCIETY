#!/usr/bin/env python3
"""Monta assets/icon/society.ico com os PNGs gerados por tools/build_app_icon.gd (ICO com PNG dentro)."""
import pathlib, struct
pasta = pathlib.Path(__file__).resolve().parent.parent / "assets" / "icon"
tamanhos = [16, 32, 48, 64, 128, 256]
imagens = [(lado, (pasta / f"society_{lado}.png").read_bytes()) for lado in tamanhos]
cabecalho = struct.pack("<HHH", 0, 1, len(imagens))
diretorio = b""
deslocamento = 6 + 16 * len(imagens)
dados = b""
for lado, png in imagens:
    diretorio += struct.pack("<BBBBHHII", lado % 256, lado % 256, 0, 0, 1, 32, len(png), deslocamento + len(dados))
    dados += png
(pasta / "society.ico").write_bytes(cabecalho + diretorio + dados)
print("society.ico:", len(imagens), "tamanhos")
