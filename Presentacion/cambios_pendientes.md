# Cambios finales de la presentación

## Diapositiva 12 — Arquitectura de la Demo Técnica

```text
Laptop Ubuntu (Host)
│
├── QEMU
│   └── Raspberry Pi 3B emulada
│       └── Linux ARM64
│           └── GStreamer
│               └── RTP/H.264
│
├── Red virtual QEMU
│   └── Host = 10.0.2.2
│
├── socat
│   └── puente UDP :5000
│
└── Docker
    └── vigilante
        └── recibe + decodifica + mide FPS
```

Texto corto:
- QEMU emula una Raspberry Pi 3B.
- GStreamer corre dentro del Guest ARM64.
- El stream cruza la red virtual de QEMU.
- `socat` lo reenvía al contenedor `vigilante`.
- `vigilante` valida recepción y FPS.

Eliminar de esta diapositiva: `semaforo_rpi`, `gdbserver` y `localhost:2345`.

## Diapositiva 13 — Flujo práctico

```text
1. Emular      → arrancar Raspberry Pi 3B con QEMU
2. Verificar   → Linux ARM64 + red + GStreamer
3. Preparar    → levantar Docker y dejar vigilante activo
4. Conectar    → QEMU → Host → socat → Docker
5. Transmitir  → RTP/H.264 desde la Raspberry emulada
6. Validar     → FPS y dropped=0 en vigilante
```

Frase final:
> Un Target ARM emulado puede ejecutar software real y comunicarse con otros entornos aislados dentro del mismo Host.

## Diapositiva 15

Cambiar “Poder Absoluto” por **Alta observabilidad**.

Texto:
> QEMU + GDB aumentan la observabilidad y permiten desarrollar, probar y depurar software antes de validar sobre hardware físico.
