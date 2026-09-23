# Mini-Taller 4: QEMU y GDB en Sistemas Embebidos

Mini-taller desarrollado para el curso **Taller de Sistemas Embebidos** de la Escuela de Ingeniería Electrónica del Instituto Tecnológico de Costa Rica.

## Descripción

Este repositorio contiene el material correspondiente al mini-taller sobre **depuración y emulación de sistemas embebidos utilizando QEMU y GDB**.

Durante el mini-taller se estudia cómo utilizar QEMU para ejecutar un sistema ARM emulado y cómo conectarse a dicho sistema mediante GNU GDB para controlar e inspeccionar la ejecución de programas embebidos.

Entre los conceptos abordados se encuentran:

- Host y Target.
- Cross-debugging.
- Remote debugging.
- Emulación con QEMU.
- Depuración con GNU GDB.
- `gdbstub` y `gdbserver`.
- Breakpoints.
- Ejecución paso a paso.
- Inspección de variables.
- Inspección de registros.
- Inspección de memoria.
- Modificación del estado de un programa durante la ejecución.

---

## Objetivos

### Objetivo general

Comprender el uso conjunto de **QEMU y GDB** como herramientas para la depuración de software en sistemas embebidos.

### Objetivos específicos

- Comprender la diferencia entre el Host y el Target.
- Introducir el concepto de cross-debugging.
- Ejecutar software ARM bare-metal mediante QEMU.
- Conectar GNU GDB con el `gdbstub` de QEMU.
- Utilizar breakpoints y ejecución paso a paso.
- Inspeccionar variables, registros y memoria.
- Analizar y diagnosticar errores de software utilizando un depurador.

---

## Estructura del repositorio

El repositorio se encuentra organizado de la siguiente manera:

```text
Mini-taller-4-QEMU-y-GDB-en-Sistemas-Embebidos/
│
├── Demo/
│   └── Demostración práctica del uso de QEMU y GDB.
│
├── Tutorial/
│   └── Tutorial guiado de diagnóstico de un sistema embebido.
│
├── Presentacion/
│   └── Presentación utilizada durante el mini-taller.
│
├── Evaluacion/
│   └── Preguntas iniciales y finales de evaluación.
│
├── Referencias/
│   └── Fuentes y documentación técnica utilizadas.
│
└── README.md
```

---

## Demo

La carpeta `Demo/` contiene una demostración práctica donde se ejecuta un programa bare-metal para un **ARM Cortex-M3** utilizando QEMU.

Mediante GDB se realizan operaciones como:

- Conexión al Target emulado.
- Creación de breakpoints.
- Inspección de variables.
- Inspección de registros.
- Inspección de memoria.
- Modificación de variables durante la ejecución.

El procedimiento completo se encuentra documentado dentro del `README.md` de la carpeta `Demo/`.

---

## Tutorial

La carpeta `Tutorial/` contiene una actividad práctica en la que el estudiante debe diagnosticar un problema en un sistema de control de acceso mediante PIN.

El objetivo es utilizar GDB para:

1. Observar el comportamiento incorrecto del sistema.
2. Seguir la ejecución paso a paso.
3. Inspeccionar variables.
4. Identificar la causa del problema.
5. Corregir el código.
6. Recompilar el programa.
7. Verificar que la solución funciona correctamente.

El procedimiento completo se encuentra documentado dentro del `README.md` de la carpeta `Tutorial/`.

---

## Herramientas utilizadas

Para las actividades prácticas se utilizaron las siguientes herramientas:

- **QEMU System ARM**
- **GNU GDB Multiarch**
- **GNU Arm Embedded GCC**
- **GNU Make**
- **Ubuntu**

El Target utilizado durante las pruebas fue:

```text
Stellaris LM3S6965EVB
ARM Cortex-M3
```

---

## Flujo general de depuración

```text
Código C
   │
   ▼
Compilación cruzada para ARM
   │
   ▼
Ejecutable ELF
   │
   ▼
QEMU
(Target ARM emulado)
   │
   │ GDB Remote Protocol
   ▼
GNU GDB
(Host)
```

QEMU proporciona el entorno donde se ejecuta el software del Target, mientras que GDB permite controlar e inspeccionar la ejecución.

---

## Requisitos

Para reproducir las actividades prácticas se requiere un sistema Linux con las siguientes herramientas instaladas:

```bash
sudo apt update
sudo apt install qemu-system-arm
sudo apt install gcc-arm-none-eabi
sudo apt install gdb-multiarch
```

GNU Make puede verificarse mediante:

```bash
make --version
```

---

## Evaluación

El mini-taller incluye dos grupos de preguntas:

- **Evaluación inicial:** preguntas introductorias utilizadas para conocer el conocimiento previo de los participantes.
- **Evaluación final:** preguntas orientadas a comprobar la comprensión de los conceptos y herramientas utilizadas durante el mini-taller.

Estas preguntas se encuentran en:

```text
Evaluacion/preguntas.md
```

---

## Referencias

Las principales fuentes utilizadas corresponden a documentación oficial de:

- QEMU.
- GNU GDB.
- Arm.
- AMD/Xilinx.

Las referencias completas utilizadas para desarrollar el mini-taller se encuentran en:

```text
Referencias/referencias.md
```

---

## Autor

**Marycruz Fallas Barquero**  
Instituto Tecnológico de Costa Rica  
Escuela de Ingeniería Electrónica  
Curso: Taller de Sistemas Embebidos
