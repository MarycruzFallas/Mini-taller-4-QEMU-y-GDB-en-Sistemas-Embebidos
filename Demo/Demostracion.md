# Demo: Depuración de un sistema embebido ARM con QEMU y GDB

Este demo muestra el uso conjunto de **QEMU** y **GNU GDB** para depurar un programa bare-metal escrito en C y ejecutado sobre un procesador ARM Cortex-M3 emulado.

El objetivo es visualizar de forma práctica conceptos como:

- Host y Target.
- Cross-debugging.
- Emulación con QEMU.
- `gdbstub`.
- Breakpoints.
- Ejecución controlada.
- Inspección de variables.
- Inspección de registros.
- Inspección de memoria.
- Modificación de variables durante la ejecución.

---

# 1. Arquitectura del demo

El flujo utilizado es el siguiente:

```text
Host Ubuntu
   │
   ├── GDB Multiarch
   │      │
   │      └── GDB Remote Protocol
   │             localhost:1234
   │
   └── QEMU
          │
          ├── gdbstub
          │
          └── Target ARM Cortex-M3 emulado
                    │
                    └── Programa bare-metal en C
```

En este caso:

- **Host:** computadora con Ubuntu.
- **Target:** ARM Cortex-M3 emulado mediante QEMU.
- **Programa:** máquina de estados de un semáforo.
- **Depurador:** `gdb-multiarch`.
- **Comunicación:** `gdbstub` integrado en QEMU mediante `localhost:1234`.

---

# 2. Funcionamiento del programa

El programa implementa una máquina de estados sencilla para representar un semáforo:

```text
ROJO → VERDE → AMARILLO → ROJO
```

Cada vez que se completa una secuencia y el estado pasa de `AMARILLO` a `ROJO`, se incrementa la variable:

```c
contador_ciclos
```

Durante el demo se utilizará GDB para observar y modificar estos estados mientras el programa está detenido.

---

# 3. Herramientas utilizadas

El demo fue probado en Ubuntu utilizando:

- QEMU System ARM
- GNU Arm Embedded GCC
- GNU GDB Multiarch
- GNU Make

Versiones utilizadas durante la prueba:

```text
QEMU emulator version 10.2.1
arm-none-eabi-gcc 14.2.1
GNU gdb 17.1
GNU Make 4.4.1
```

---

# 4. Instalación de herramientas

## 4.1 Actualizar los repositorios

```bash
sudo apt update
```

Salida esperada:

```text
Se pueden actualizar algunos paquetes.
```

Mientras el comando finalice y regrese al prompt de la terminal, la actualización fue realizada correctamente.

> Si aparece un mensaje indicando que `/var/lib/apt/lists/lock` está siendo utilizado por otro proceso, puede existir una actualización de Ubuntu en ejecución. Se recomienda esperar a que finalice en lugar de eliminar manualmente el archivo de bloqueo.

---

## 4.2 Instalar QEMU para ARM

```bash
sudo apt install qemu-system-arm
```

Verificar la instalación:

```bash
qemu-system-arm --version
```

Salida utilizada durante la prueba:

```text
QEMU emulator version 10.2.1
```

---

## 4.3 Instalar el compilador cruzado ARM

```bash
sudo apt install gcc-arm-none-eabi
```

Verificar:

```bash
arm-none-eabi-gcc --version
```

Salida obtenida durante la prueba:

```text
arm-none-eabi-gcc (...) 14.2.1
```

---

## 4.4 Instalar GDB Multiarch

```bash
sudo apt install gdb-multiarch
```

Verificar:

```bash
gdb-multiarch --version
```

Salida obtenida:

```text
GNU gdb (...) 17.1
```

---

## 4.5 Verificar GNU Make

```bash
make --version
```

Salida obtenida:

```text
GNU Make 4.4.1
```

---

# 5. Verificar la máquina ARM utilizada

El demo utiliza la máquina:

```text
lm3s6965evb
```

Para verificar que esté disponible:

```bash
qemu-system-arm -machine help | grep lm3s
```

Salida obtenida durante la prueba:

```text
lm3s6965evb    Stellaris LM3S6965EVB (Cortex-M3)
lm3s811evb     Stellaris LM3S811EVB (Cortex-M3)
```

Por lo tanto, se utilizará:

```text
lm3s6965evb
```

como Target emulado.

---

# 6. Crear el directorio de trabajo

```bash
mkdir -p ~/demo_qemu_gdb
```

Entrar al directorio:

```bash
cd ~/demo_qemu_gdb
```

Verificar la ubicación:

```bash
pwd
```

Salida esperada:

```text
/home/<usuario>/demo_qemu_gdb
```

---

# 7. Archivos del proyecto

El demo utiliza cuatro archivos fuente/configuración:

```text
demo_qemu_gdb/
├── semaforo.c
├── startup.s
├── linker.ld
└── Makefile
```

Después de compilar se generará:

```text
semaforo.elf
```

---

# 8. Programa principal: `semaforo.c`

Crear el archivo:

```bash
nano semaforo.c
```

Contenido:

```c
typedef enum {
    ESTADO_ROJO = 0,
    ESTADO_VERDE,
    ESTADO_AMARILLO
} EstadoSemaforo;

volatile EstadoSemaforo estado_actual = ESTADO_ROJO;
volatile unsigned int contador_ciclos = 0;

void cambiar_estado(void)
{
    switch (estado_actual)
    {
        case ESTADO_ROJO:
            estado_actual = ESTADO_VERDE;
            break;

        case ESTADO_VERDE:
            estado_actual = ESTADO_AMARILLO;
            break;

        case ESTADO_AMARILLO:
            estado_actual = ESTADO_ROJO;
            contador_ciclos++;
            break;

        default:
            estado_actual = ESTADO_ROJO;
            break;
    }
}

int main(void)
{
    while (1)
    {
        cambiar_estado();

        for (volatile unsigned int i = 0; i < 100000; i++)
        {
        }
    }

    return 0;
}
```

Guardar en `nano`:

```text
Ctrl + O
Enter
Ctrl + X
```

---

# 9. Archivo de arranque: `startup.s`

Como el programa es bare-metal, no existe un sistema operativo que inicialice la ejecución.

Se utiliza un archivo mínimo de arranque para definir el vector inicial y el `Reset_Handler`.

Crear:

```bash
nano startup.s
```

Contenido:

```asm
.syntax unified
.cpu cortex-m3
.thumb

/* Tabla mínima de vectores */
.section .isr_vector, "a", %progbits
.word 0x20010000
.word Reset_Handler

/* Código de arranque */
.section .text.Reset_Handler, "ax", %progbits
.global Reset_Handler
.type Reset_Handler, %function
.thumb_func

Reset_Handler:
    bl main

Loop:
    b Loop

.size Reset_Handler, .-Reset_Handler
```

El valor:

```asm
.word 0x20010000
```

corresponde al valor inicial utilizado para el Stack Pointer.

Después del reset:

```text
Reset_Handler
      │
      └── main()
```

---

# 10. Linker script: `linker.ld`

Crear:

```bash
nano linker.ld
```

Contenido:

```ld
ENTRY(Reset_Handler)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
    .isr_vector :
    {
        KEEP(*(.isr_vector))
    } > FLASH

    .text :
    {
        *(.text*)
        *(.rodata*)
    } > FLASH

    .data :
    {
        *(.data*)
    } > RAM AT > FLASH

    .bss :
    {
        *(.bss*)
        *(COMMON)
    } > RAM
}
```

Este archivo define la distribución utilizada para Flash y RAM y especifica:

```ld
ENTRY(Reset_Handler)
```

como punto de entrada del programa.

---

# 11. Makefile

Crear:

```bash
nano Makefile
```

Contenido:

```makefile
CC = arm-none-eabi-gcc

CFLAGS = -mcpu=cortex-m3 -mthumb -g -O0 -Wall -ffreestanding
LDFLAGS = -T linker.ld -nostdlib

TARGET = semaforo.elf

SOURCES = startup.s semaforo.c

all:
	$(CC) $(CFLAGS) $(SOURCES) $(LDFLAGS) -o $(TARGET)

clean:
	rm -f $(TARGET)
```

> Las líneas de comandos del `Makefile` deben comenzar con una tabulación.

Las opciones principales utilizadas son:

```text
-mcpu=cortex-m3
```

Compila para Cortex-M3.

```text
-mthumb
```

Genera instrucciones Thumb.

```text
-g
```

Incluye información de depuración para GDB.

```text
-O0
```

Desactiva optimizaciones para facilitar el seguimiento del código durante la depuración.

```text
-ffreestanding
```

Indica que el programa se ejecutará en un entorno bare-metal.

```text
-nostdlib
```

Evita utilizar el entorno estándar de ejecución del sistema operativo.

---

# 12. Compilar el proyecto

Ejecutar:

```bash
make
```

El comando utilizado internamente será similar a:

```bash
arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -g -O0 -Wall -ffreestanding startup.s semaforo.c -T linker.ld -nostdlib -o semaforo.elf
```

Si no aparecen errores ni advertencias, se generará:

```text
semaforo.elf
```

---

# 13. Problema encontrado durante la primera compilación

Durante la primera prueba apareció la advertencia:

```text
warning: cannot find entry symbol Reset_Handler; defaulting to 00000008
```

La causa fue que `Reset_Handler` no había sido exportado como símbolo global en `startup.s`.

La corrección consistió en agregar:

```asm
.global Reset_Handler
.thumb_func
```

Después se realizó una compilación limpia:

```bash
make clean
```

y posteriormente:

```bash
make
```

La compilación final terminó correctamente y sin advertencias.

---

# 14. Verificar el ejecutable generado

Comprobar que exista:

```bash
ls -l semaforo.elf
```

Luego verificar su arquitectura:

```bash
file semaforo.elf
```

Salida obtenida durante la prueba:

```text
semaforo.elf: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV),
statically linked, with debug_info, not stripped
```

Los elementos importantes son:

```text
ARM
```

Confirma que el binario fue generado para la arquitectura Target.

```text
with debug_info
```

Confirma que contiene información de depuración.

```text
not stripped
```

Indica que conserva símbolos útiles para GDB.

---

# 15. Ejecutar el Target en QEMU

A partir de este punto se utilizan **dos terminales**.

## Terminal 1 — QEMU

Entrar al directorio:

```bash
cd ~/demo_qemu_gdb
```

Ejecutar:

```bash
qemu-system-arm -M lm3s6965evb -kernel semaforo.elf -s -S -nographic
```

Las opciones importantes son:

### `-M lm3s6965evb`

Selecciona la máquina ARM Cortex-M3 utilizada como Target.

### `-kernel semaforo.elf`

Carga el ejecutable bare-metal.

### `-s`

Activa el `gdbstub` de QEMU utilizando por defecto:

```text
localhost:1234
```

### `-S`

Mantiene la CPU detenida al inicio hasta que GDB ordene continuar.

### `-nographic`

Ejecuta QEMU directamente desde la terminal sin interfaz gráfica.

Después de ejecutar el comando, la terminal puede parecer detenida.

Esto es esperado.

QEMU está esperando la conexión del depurador.

---

# 16. Abrir GDB

## Terminal 2 — GDB

Abrir una segunda terminal:

```bash
cd ~/demo_qemu_gdb
```

Ejecutar:

```bash
gdb-multiarch semaforo.elf
```

Salida esperada:

```text
Reading symbols from semaforo.elf...
(gdb)
```

Esto confirma que GDB cargó el ejecutable y sus símbolos de depuración.

---

# 17. Conectar GDB con QEMU

Dentro de GDB ejecutar:

```gdb
target remote localhost:1234
```

Durante la prueba se obtuvo:

```text
Remote debugging using localhost:1234
Reset_Handler () at startup.s:17
17          bl main
```

Esto confirma que:

1. QEMU tiene activo el `gdbstub`.
2. GDB se conectó correctamente.
3. La CPU emulada está detenida.
4. GDB puede relacionar la ejecución con el código fuente.

---

# 18. Crear un breakpoint

Crear un breakpoint en:

```c
cambiar_estado()
```

Ejecutar:

```gdb
break cambiar_estado
```

Salida obtenida:

```text
Breakpoint 1 at 0x14: file semaforo.c, line 12.
```

Ahora continuar:

```gdb
continue
```

Resultado:

```text
Breakpoint 1, cambiar_estado () at semaforo.c:12
12          switch (estado_actual)
```

El programa se detuvo dentro de la función definida.

---

# 19. Inspeccionar variables

Consultar el estado actual:

```gdb
print estado_actual
```

Durante la prueba se observó:

```text
$1 = ESTADO_VERDE
```

Consultar el contador:

```gdb
print contador_ciclos
```

Resultado:

```text
$2 = 0
```

GDB muestra directamente el nombre simbólico del `enum`:

```text
ESTADO_VERDE
```

en lugar de mostrar únicamente su valor numérico.

---

# 20. Inspeccionar los registros de la CPU

Ejecutar:

```gdb
info registers
```

GDB muestra registros como:

```text
r0
r1
r2
...
sp
lr
pc
xpsr
```

Durante la prueba se observó:

```text
pc    0x14 <cambiar_estado+4>
```

El `pc` corresponde al **Program Counter** y muestra que la ejecución se encuentra dentro de:

```c
cambiar_estado()
```

También se observó el Stack Pointer dentro de RAM:

```text
sp    0x2000ffec
```

---

# 21. Modificar una variable durante la ejecución

Primero consultar el valor actual:

```gdb
print estado_actual
```

Resultado utilizado durante el demo:

```text
$3 = ESTADO_VERDE
```

Modificar el estado directamente desde GDB:

```gdb
set variable estado_actual = ESTADO_AMARILLO
```

Comprobar:

```gdb
print estado_actual
```

Resultado:

```text
$4 = ESTADO_AMARILLO
```

Esto demuestra que GDB no solamente permite observar el programa, sino también modificar su estado mientras está detenido.

---

# 22. Comprobar el efecto de la modificación

Continuar la ejecución:

```gdb
continue
```

Cuando se alcance nuevamente el breakpoint:

```gdb
print estado_actual
```

Resultado obtenido:

```text
$5 = ESTADO_ROJO
```

Consultar:

```gdb
print contador_ciclos
```

Resultado:

```text
$6 = 1
```

Esto demuestra que el cambio realizado desde GDB afectó realmente el comportamiento posterior del programa.

El estado fue modificado manualmente a:

```text
ESTADO_AMARILLO
```

y al continuar la ejecución, el programa realizó:

```text
AMARILLO → ROJO
```

además de ejecutar:

```c
contador_ciclos++;
```

Por eso el contador pasó a:

```text
1
```

---

# 23. Inspeccionar memoria directamente

GDB también permite observar directamente el contenido de una dirección de memoria.

Ejecutar:

```gdb
x/wx &estado_actual
```

La sintaxis significa:

```text
x     → examine
w     → word
x     → formato hexadecimal
```

Durante la prueba se obtuvo:

```text
0x20000000 <estado_actual>: 0x00000000
```

Esto permite relacionar:

```text
Variable en C
      ↓
estado_actual
      ↓
Dirección RAM
      ↓
0x20000000
      ↓
Valor almacenado
      ↓
0x00000000
      ↓
ESTADO_ROJO
```

---

# 24. Flujo resumido del demo

El flujo completo utilizado fue:

```text
1. Compilar el programa para ARM
          ↓
2. Generar semaforo.elf
          ↓
3. Ejecutar QEMU con -s -S
          ↓
4. Abrir GDB
          ↓
5. target remote localhost:1234
          ↓
6. break cambiar_estado
          ↓
7. continue
          ↓
8. print estado_actual
          ↓
9. info registers
          ↓
10. set variable estado_actual = ESTADO_AMARILLO
          ↓
11. continue
          ↓
12. comprobar cambio del comportamiento
          ↓
13. inspeccionar memoria
```

---

# 25. Comandos principales de GDB utilizados

| Comando | Función |
|---|---|
| `target remote localhost:1234` | Conecta GDB con el `gdbstub` de QEMU |
| `break cambiar_estado` | Coloca un breakpoint |
| `continue` | Continúa la ejecución |
| `print estado_actual` | Inspecciona una variable |
| `print contador_ciclos` | Inspecciona el contador |
| `info registers` | Muestra los registros de la CPU |
| `set variable estado_actual = ESTADO_AMARILLO` | Modifica una variable |
| `x/wx &estado_actual` | Examina directamente la memoria |
| `detach` | Desconecta GDB del Target |
| `quit` | Cierra GDB |

---

# 26. Cerrar correctamente la sesión

## Desde GDB

Desconectarse del Target:

```gdb
detach
```

Luego cerrar GDB:

```gdb
quit
```

## Desde QEMU

En la terminal donde se está ejecutando QEMU:

```text
Ctrl + A
```

y después:

```text
X
```

Salida observada:

```text
QEMU: Terminated
```

---

# 27. Resultado del demo

El demo fue probado exitosamente y permitió verificar:

- Ejecución de código bare-metal ARM en QEMU.
- Compilación cruzada desde un Host x86_64.
- Conexión entre GDB y QEMU.
- Uso del `gdbstub`.
- Breakpoints.
- Ejecución controlada.
- Inspección de variables.
- Inspección de registros del Cortex-M3.
- Inspección directa de memoria.
- Modificación de variables durante la ejecución.
- Alteración observable del comportamiento del programa.
- Uso de símbolos de depuración.

El flujo completo QEMU + GDB quedó funcional antes de incorporar los archivos al repositorio.

---

# 28. Idea principal

QEMU y GDB cumplen funciones diferentes pero complementarias:

```text
QEMU
  ↓
Proporciona el Target ARM emulado

GDB
  ↓
Controla e inspecciona la ejecución

QEMU + GDB
  ↓
Entorno de depuración para sistemas embebidos
```

Este entorno permite analizar el comportamiento de firmware bare-metal sin depender inmediatamente de una placa física.