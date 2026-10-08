# Mini-Taller 4: QEMU y GDB en Sistemas Embebidos

Mini-taller del curso **Taller de Sistemas Embebidos** del Instituto Tecnológico de Costa Rica.

## Descripción

El mini-taller estudia simulación vs. emulación, la arquitectura interna de QEMU y conceptos de depuración con GDB.

La demo técnica utiliza una **Raspberry Pi 3B emulada con QEMU**, ejecutando Linux ARM64 y GStreamer. El Guest transmite un stream RTP/H.264 hacia el Host y, mediante `socat`, el flujo llega a un contenedor Docker `vigilante`, que lo decodifica y mide FPS.

## Arquitectura de la demo

```text
QEMU
  ↓
Raspberry Pi 3B
  ↓
Linux ARM64
  ↓
GStreamer
  ↓
RTP/H.264
  ↓
Host Ubuntu
  ↓
socat
  ↓
Docker
  ↓
vigilante
```

## Estructura

```text
Demo/
  Demostracion.md
  run_qemu_rpi.sh
  bridge_udp.sh

Tutorial/
Presentacion/
Evaluacion/
Referencias/
README.md
```

## Demo

La documentación completa y reproducible está en:

```text
Demo/Demostracion.md
```

La demo fue probada con:
- Raspberry Pi 3B emulada.
- Debian/Raspberry Pi OS Bullseye ARM64.
- GStreamer 1.18.4.
- Red virtual QEMU.
- Docker.
- `socat`.
- recepción RTP/H.264 con `dropped: 0`.

## Tutorial

La carpeta `Tutorial/` contiene la actividad guiada de depuración. Esta sección se está adaptando a un formato más gráfico y participativo.

## Presentación

La presentación cubre:
- simulación vs. emulación;
- por qué emular;
- QEMU;
- CPU emulada y TCG;
- memoria, buses, I/O y red;
- Host, Guest y Target;
- GDB;
- `gdbstub` vs. `gdbserver`;
- demo técnica;
- aplicaciones y limitaciones.

## Autor

**Marycruz Fallas Barquero**  
Instituto Tecnológico de Costa Rica  
Escuela de Ingeniería Electrónica  
Curso: Taller de Sistemas Embebidos
