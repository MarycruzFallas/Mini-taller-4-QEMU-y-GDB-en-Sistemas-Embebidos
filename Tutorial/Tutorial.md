# Tutorial guiado: Diagnóstico de un sistema de acceso con QEMU y GDB

## Introducción

En este tutorial se utilizarán **QEMU** y **GNU GDB** para depurar un pequeño sistema embebido de control de acceso ejecutado sobre un procesador ARM Cortex-M3 emulado.

El sistema recibe tres intentos de PIN:

```text
1111
2222
1234
```

El PIN correcto es:

```text
1234
```

El sistema debería permitir hasta tres intentos antes de bloquearse.

Sin embargo, existe un problema en el programa.

La misión del estudiante será utilizar GDB para observar la ejecución, identificar por qué el sistema no se comporta como se espera, localizar la causa y corregirla.

> **Importante:** no revise buscando directamente el error. La idea es encontrarlo siguiendo la ejecución con GDB.

---

# 1. Herramientas necesarias

Para realizar el tutorial se necesitan:

- Ubuntu
- QEMU System ARM
- GNU Arm Embedded GCC
- GNU GDB Multiarch
- GNU Make

Estas herramientas fueron instaladas y verificadas previamente durante el demo.

Se puede comprobar que QEMU reconoce la máquina utilizada con:

```bash
qemu-system-arm -machine help | grep lm3s
```

Durante nuestra prueba obtuvimos:

```text
lm3s6965evb    Stellaris LM3S6965EVB (Cortex-M3)
lm3s811evb     Stellaris LM3S811EVB (Cortex-M3)
```

En este tutorial utilizaremos:

```text
lm3s6965evb
```

---

# 2. Crear la carpeta de trabajo

Abrir una terminal de Ubuntu.

Crear una carpeta exclusiva para el tutorial:

```bash
mkdir -p ~/tutorial_qemu_gdb
```

Entrar a la carpeta:

```bash
cd ~/tutorial_qemu_gdb
```

Comprobar la ubicación actual:

```bash
pwd
```

La salida debe ser similar a:

```text
/home/<usuario>/tutorial_qemu_gdb
```

En nuestra prueba se obtuvo:

```text
/home/marycruz/tutorial_qemu_gdb
```

---

# 3. Crear el programa `acceso.c`

Crear el archivo:

```bash
nano acceso.c
```

Se abrirá el editor `nano`.

Pegar exactamente el siguiente código:

```c
#define MAX_INTENTOS 2

typedef enum {
    ESPERANDO_PIN = 0,
    ACCESO_CONCEDIDO,
    ACCESO_DENEGADO,
    SISTEMA_BLOQUEADO
} EstadoSistema;

volatile EstadoSistema estado_sistema = ESPERANDO_PIN;
volatile unsigned int intentos_fallidos = 0;

const unsigned int PIN_CORRECTO = 1234;

void verificar_pin(unsigned int pin_ingresado)
{
    if (estado_sistema == SISTEMA_BLOQUEADO)
    {
        return;
    }

    if (pin_ingresado == PIN_CORRECTO)
    {
        estado_sistema = ACCESO_CONCEDIDO;
        intentos_fallidos = 0;
    }
    else
    {
        estado_sistema = ACCESO_DENEGADO;
        intentos_fallidos++;

        if (intentos_fallidos >= MAX_INTENTOS)
        {
            estado_sistema = SISTEMA_BLOQUEADO;
        }
    }
}

int main(void)
{
    unsigned int intentos[] = {
        1111,
        2222,
        1234
    };

    for (unsigned int i = 0; i < 3; i++)
    {
        verificar_pin(intentos[i]);

        if (estado_sistema == SISTEMA_BLOQUEADO)
        {
            break;
        }

        estado_sistema = ESPERANDO_PIN;
    }

    while (1)
    {
    }

    return 0;
}
```

Guardar el archivo:

```text
Ctrl + O
```

Presionar:

```text
Enter
```

Salir de `nano`:

```text
Ctrl + X
```

Verificar que el archivo exista:

```bash
ls
```

Salida esperada:

```text
acceso.c
```

---

# 4. Crear el archivo de arranque `startup.s`

Crear:

```bash
nano startup.s
```

Pegar:

```asm
.syntax unified
.cpu cortex-m3
.thumb

.section .isr_vector, "a", %progbits
.word 0x20010000
.word Reset_Handler

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

Guardar:

```text
Ctrl + O
Enter
Ctrl + X
```

Verificar:

```bash
ls
```

Ahora deben aparecer:

```text
acceso.c
startup.s
```

---

# 5. Crear el linker script `linker.ld`

Crear:

```bash
nano linker.ld
```

Pegar:

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

Guardar:

```text
Ctrl + O
Enter
Ctrl + X
```

Verificar:

```bash
ls
```

Ahora deben aparecer:

```text
acceso.c
linker.ld
startup.s
```

---

# 6. Crear el `Makefile`

Crear:

```bash
nano Makefile
```

Pegar:

```makefile
CC = arm-none-eabi-gcc

CFLAGS = -mcpu=cortex-m3 -mthumb -g -O0 -Wall -ffreestanding
LDFLAGS = -T linker.ld -nostdlib

TARGET = acceso.elf

SOURCES = startup.s acceso.c

all:
	$(CC) $(CFLAGS) $(SOURCES) $(LDFLAGS) -o $(TARGET)

clean:
	rm -f $(TARGET)
```

> **Importante:** las líneas debajo de `all:` y `clean:` deben comenzar con una **tabulación**, no con espacios.

Guardar:

```text
Ctrl + O
Enter
Ctrl + X
```

Verificar:

```bash
ls
```

Deben aparecer:

```text
Makefile
acceso.c
linker.ld
startup.s
```

---

# 7. Compilar el programa

Ejecutar:

```bash
make
```

Durante nuestra prueba se ejecutó:

```text
arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -g -O0 -Wall -ffreestanding startup.s acceso.c -T linker.ld -nostdlib -o acceso.elf
```

La compilación debe terminar sin errores.

Ahora verificar que `acceso.elf` fue creado:

```bash
ls -l acceso.elf
```

Después comprobar el tipo de ejecutable:

```bash
file acceso.elf
```

Durante nuestra prueba se obtuvo una salida similar a:

```text
acceso.elf: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, with debug_info, not stripped
```

Los datos importantes son:

```text
ARM
with debug_info
not stripped
```

Esto confirma que:

- el programa fue compilado para ARM;
- contiene información de depuración;
- conserva los símbolos que utilizará GDB.

---

# 8. Iniciar QEMU

A partir de aquí se necesitan **dos terminales**.

## Terminal 1 — QEMU

Abrir una segunda terminal y entrar al directorio:

```bash
cd ~/tutorial_qemu_gdb
```

Ejecutar:

```bash
qemu-system-arm -M lm3s6965evb -kernel acceso.elf -s -S -nographic
```

Después de ejecutar el comando puede parecer que la terminal quedó congelada.

Esto es normal.

Las opciones principales son:

```text
-s
```

Activa el `gdbstub` de QEMU en:

```text
localhost:1234
```

y:

```text
-S
```

mantiene detenida la CPU emulada hasta que GDB ordene continuar.

**No cerrar esta terminal.**

---

# 9. Abrir GDB

## Terminal 2 — GDB

Abrir otra terminal.

Entrar al directorio:

```bash
cd ~/tutorial_qemu_gdb
```

Ejecutar:

```bash
gdb-multiarch acceso.elf
```

Durante nuestra prueba apareció:

```text
Reading symbols from acceso.elf...
(gdb)
```

Esto significa que GDB cargó el programa y sus símbolos.

---

# 10. Conectar GDB con QEMU

En:

```text
(gdb)
```

ejecutar:

```gdb
target remote localhost:1234
```

Durante nuestra prueba apareció:

```text
Remote debugging using localhost:1234
Reset_Handler () at startup.s:15
15          bl main
```

Esto confirma que:

- GDB está conectado al `gdbstub`;
- QEMU está ejecutando el Target ARM;
- la CPU está detenida;
- GDB reconoce el código fuente.

---

# 11. Crear un breakpoint

Queremos observar cada intento de PIN.

Crear un breakpoint en:

```c
verificar_pin()
```

Ejecutar:

```gdb
break verificar_pin
```

Durante nuestra prueba apareció algo similar a:

```text
Breakpoint 1 at 0x...: file acceso.c, line 17.
```

Ahora continuar:

```gdb
continue
```

GDB debe detenerse en la primera llamada:

```text
Breakpoint 1, verificar_pin (pin_ingresado=1111) at acceso.c:17
```

El primer PIN que está siendo probado es:

```text
1111
```

---

# 12. Inspeccionar el primer intento

Consultar el PIN:

```gdb
print pin_ingresado
```

Durante nuestra prueba:

```text
$1 = 1111
```

Consultar el contador:

```gdb
print intentos_fallidos
```

Resultado:

```text
$2 = 0
```

Antes de procesar el primer intento tenemos:

```text
pin_ingresado = 1111
intentos_fallidos = 0
```

---

# 13. Avanzar dentro de `verificar_pin()`

Ahora utilizaremos:

```gdb
next
```

Ejecutar:

```gdb
next
```

Volver a ejecutar:

```gdb
next
```

Durante nuestra prueba llegamos a:

```c
if (pin_ingresado == PIN_CORRECTO)
```

En este momento todavía observábamos:

```text
intentos_fallidos = 0
estado_sistema = ESPERANDO_PIN
```

Ahora ejecutar nuevamente:

```gdb
next
```

Como:

```text
1111 != 1234
```

GDB entra al bloque correspondiente al PIN incorrecto.

Debe aparecer una línea similar a:

```c
estado_sistema = ACCESO_DENEGADO;
```

---

# 14. Procesar el primer PIN incorrecto

Ejecutar:

```gdb
next
```

Ahora GDB debe quedar antes de:

```c
intentos_fallidos++;
```

Ejecutar:

```gdb
next
```

Consultar:

```gdb
print intentos_fallidos
```

Resultado:

```text
1
```

Consultar:

```gdb
print estado_sistema
```

Resultado:

```text
ACCESO_DENEGADO
```

Después del primer intento tenemos:

```text
pin = 1111
intentos_fallidos = 1
estado_sistema = ACCESO_DENEGADO
```

GDB debe encontrarse cerca de:

```c
if (intentos_fallidos >= MAX_INTENTOS)
```

---

# 15. Continuar al segundo intento

Ejecutar:

```gdb
continue
```

GDB vuelve a detenerse en:

```c
verificar_pin()
```

pero ahora debe mostrar:

```text
pin_ingresado=2222
```

Consultar:

```gdb
print pin_ingresado
```

Resultado:

```text
2222
```

Consultar:

```gdb
print intentos_fallidos
```

Resultado:

```text
1
```

Ahora sabemos que:

```text
Segundo intento = 2222
Fallos acumulados = 1
```

---

# 16. Seguir el segundo intento paso a paso

Ejecutar:

```gdb
next
```

Luego:

```gdb
next
```

Luego:

```gdb
next
```

Avanzar hasta llegar nuevamente a:

```c
intentos_fallidos++;
```

En este momento sabemos que antes de incrementar:

```text
intentos_fallidos = 1
```

Ejecutar:

```gdb
next
```

Consultar:

```gdb
print intentos_fallidos
```

Resultado:

```text
2
```

Consultar:

```gdb
print estado_sistema
```

Resultado:

```text
ACCESO_DENEGADO
```

Ahora tenemos:

```text
pin = 2222
intentos_fallidos = 2
estado_sistema = ACCESO_DENEGADO
```

GDB debe estar cerca de:

```c
if (intentos_fallidos >= MAX_INTENTOS)
```

---

# 17. Observar qué ocurre con dos fallos

Ejecutar:

```gdb
next
```

Durante nuestra prueba GDB entró al bloque donde aparece:

```c
estado_sistema = SISTEMA_BLOQUEADO;
```

Antes de ejecutar esa asignación consultamos:

```gdb
print estado_sistema
```

y todavía aparecía:

```text
ACCESO_DENEGADO
```

También intentamos consultar:

```gdb
print MAX_INTENTOS
```

GDB respondió:

```text
No symbol "MAX_INTENTOS" in current context.
```

Esto no significa que el programa esté mal compilado.

`MAX_INTENTOS` está definido mediante una macro del preprocesador:

```c
#define MAX_INTENTOS ...
```

y por eso no se comporta como una variable normal que GDB pueda consultar con `print`.

Ahora ejecutar:

```gdb
next
```

Consultar:

```gdb
print estado_sistema
```

Durante nuestra prueba apareció:

```text
SISTEMA_BLOQUEADO
```

Por lo tanto, el sistema quedó bloqueado después de dos fallos.

---

# 18. Comprobar qué ocurre con el tercer PIN

Ejecutar:

```gdb
continue
```

Durante nuestra prueba apareció:

```text
Continuando.
```

pero GDB **no volvió a detenerse en `verificar_pin()`**.

Eso indica que el tercer PIN:

```text
1234
```

nunca fue procesado.

Hasta ahora observamos:

```text
1111
 ↓
fallo 1

2222
 ↓
fallo 2

SISTEMA_BLOQUEADO

1234
 ↓
nunca se procesa
```

---

# 19. Recuperar el control de GDB

Como el programa queda ejecutándose en un ciclo infinito, presionar:

```text
Ctrl + C
```

Durante nuestra prueba apareció:

```text
Program received signal SIGINT, Interrupt.
main () at acceso.c:59
59      while (1)
```

Esto también confirma que el programa ya llegó al:

```c
while (1)
{
}
```

del final de `main()`.

---

# 20. Buscar la causa del comportamiento

Ahora que ya conocemos el síntoma, revisar el comienzo del código fuente desde GDB.

Ejecutar:

```gdb
list 1,20
```

GDB mostrará las primeras líneas de `acceso.c`.

Entre ellas aparece:

```c
#define MAX_INTENTOS 2
```

Ahora podemos relacionar lo observado durante la depuración.

Después del segundo fallo:

```text
intentos_fallidos = 2
```

y el código evalúa:

```c
if (intentos_fallidos >= MAX_INTENTOS)
```

Con la configuración actual:

```text
2 >= 2
```

es verdadero.

Por eso el sistema ejecuta:

```c
estado_sistema = SISTEMA_BLOQUEADO;
```

antes de llegar al tercer PIN.

---

# 21. Corregir el programa

Primero salir de GDB.

Ejecutar:

```gdb
quit
```

Si GDB pregunta si desea terminar o salir de la sesión, responder:

```text
y
```

Ahora volvemos a una terminal normal similar a:

```text
usuario@equipo:~/tutorial_qemu_gdb$
```

Abrir nuevamente el programa:

```bash
nano acceso.c
```

Buscar esta línea:

```c
#define MAX_INTENTOS 2
```

Cambiar únicamente el valor:

```c
#define MAX_INTENTOS 3
```

No modificar ninguna otra parte del programa.

Guardar:

```text
Ctrl + O
```

Presionar:

```text
Enter
```

Salir:

```text
Ctrl + X
```

---

# 22. Recompilar la versión corregida

Eliminar el ejecutable anterior:

```bash
make clean
```

Durante nuestra prueba apareció:

```text
rm -f acceso.elf
```

Ahora recompilar:

```bash
make
```

Debe volver a ejecutarse un comando similar a:

```text
arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -g -O0 -Wall -ffreestanding startup.s acceso.c -T linker.ld -nostdlib -o acceso.elf
```

La compilación debe finalizar sin errores.

---

# 23. Cerrar la instancia anterior de QEMU

La instancia de QEMU que estaba abierta todavía tiene cargada la versión anterior de `acceso.elf`.

Ir a la **Terminal 1**, donde está QEMU.

Presionar:

```text
Ctrl + A
```

y luego:

```text
X
```

Durante nuestra prueba apareció:

```text
QEMU: Terminated
```

Ahora ya podemos cargar el ejecutable corregido.

---

# 24. Iniciar QEMU nuevamente

En la misma terminal:

```bash
cd ~/tutorial_qemu_gdb
```

Ejecutar nuevamente:

```bash
qemu-system-arm -M lm3s6965evb -kernel acceso.elf -s -S -nographic
```

La terminal volverá a quedar esperando la conexión de GDB.

---

# 25. Abrir GDB nuevamente

En otra terminal:

```bash
cd ~/tutorial_qemu_gdb
```

Ejecutar:

```bash
gdb-multiarch acceso.elf
```

Cuando aparezca:

```text
(gdb)
```

conectar con QEMU:

```gdb
target remote localhost:1234
```

Debe aparecer nuevamente algo similar a:

```text
Remote debugging using localhost:1234
Reset_Handler () at startup.s:15
```

---

# 26. Volver a colocar el breakpoint

Ejecutar:

```gdb
break verificar_pin
```

Luego:

```gdb
continue
```

Debe detenerse en:

```text
pin_ingresado=1111
```

Este es el primer intento.

---

# 27. Validar que ahora existen tres intentos

Ejecutar:

```gdb
continue
```

Debe detenerse nuevamente con:

```text
pin_ingresado=2222
```

Ejecutar otra vez:

```gdb
continue
```

Ahora debe aparecer:

```text
pin_ingresado=1234
```

En nuestra prueba esto ocurrió correctamente.

La secuencia ahora es:

```text
1111
2222
1234
```

Esto confirma que el sistema **ya no se bloqueó después del segundo intento**.

---

# 28. Comprobar el PIN correcto paso a paso

Ahora estamos dentro de:

```c
verificar_pin(1234)
```

Ejecutar:

```gdb
next
```

Durante nuestra prueba llegamos a:

```c
if (pin_ingresado == PIN_CORRECTO)
```

Consultar, si se desea:

```gdb
print estado_sistema
```

En este momento todavía puede aparecer:

```text
ESPERANDO_PIN
```

También:

```gdb
print intentos_fallidos
```

puede mostrar:

```text
2
```

Esto es normal porque todavía no se ha ejecutado la rama del PIN correcto.

---

# 29. Confirmar `ACCESO_CONCEDIDO`

Ejecutar otro:

```gdb
next
```

GDB llegará a:

```c
estado_sistema = ACCESO_CONCEDIDO;
```

Todavía está detenido **antes** de ejecutar esa línea.

Ejecutar:

```gdb
next
```

Ahora consultar:

```gdb
print estado_sistema
```

Durante nuestra prueba apareció:

```text
ACCESO_CONCEDIDO
```

Esto confirma que:

```text
1234 == PIN_CORRECTO
```

y el acceso fue concedido.

---

# 30. Comprobar el reinicio del contador

Después de conceder acceso, la siguiente instrucción es:

```c
intentos_fallidos = 0;
```

Antes de ejecutarla todavía observamos:

```text
intentos_fallidos = 2
```

Ejecutar:

```gdb
next
```

Luego consultar:

```gdb
print intentos_fallidos
```

Durante nuestra prueba obtuvimos:

```text
0
```

La corrección quedó completamente validada.

El comportamiento final es:

```text
1111
 ↓
fallo 1

2222
 ↓
fallo 2

1234
 ↓
ACCESO_CONCEDIDO
 ↓
intentos_fallidos = 0
```

---

# 31. Comparación del comportamiento

## Antes de corregir

```text
1111
 ↓
intentos_fallidos = 1

2222
 ↓
intentos_fallidos = 2
 ↓
SISTEMA_BLOQUEADO

1234
 ↓
NO SE PROCESA
```

## Después de corregir

```text
1111
 ↓
intentos_fallidos = 1

2222
 ↓
intentos_fallidos = 2

1234
 ↓
ACCESO_CONCEDIDO
 ↓
intentos_fallidos = 0
```

---

# 32. Cerrar correctamente GDB

Al terminar el tutorial, si el programa está ejecutándose y no aparece:

```text
(gdb)
```

presionar:

```text
Ctrl + C
```

Cuando vuelva a aparecer:

```text
(gdb)
```

desconectarse del Target:

```gdb
detach
```

Luego cerrar GDB:

```gdb
quit
```

Si GDB solicita confirmación, responder:

```text
y
```

---

# 33. Cerrar QEMU

Ir a la terminal donde se está ejecutando QEMU.

Presionar:

```text
Ctrl + A
```

y después:

```text
X
```

Debe aparecer:

```text
QEMU: Terminated
```

Con esto termina correctamente la sesión del tutorial.

---

# 34. Comandos utilizados durante el tutorial

| Comando | Función |
|---|---|
| `pwd` | Mostrar el directorio actual |
| `ls` | Mostrar los archivos |
| `nano acceso.c` | Crear o editar el programa |
| `nano startup.s` | Crear el archivo de arranque |
| `nano linker.ld` | Crear el linker script |
| `nano Makefile` | Crear el archivo de compilación |
| `make` | Compilar |
| `make clean` | Eliminar el ELF anterior |
| `file acceso.elf` | Verificar el ejecutable ARM |
| `gdb-multiarch acceso.elf` | Abrir el ejecutable en GDB |
| `target remote localhost:1234` | Conectar GDB con QEMU |
| `break verificar_pin` | Crear un breakpoint |
| `continue` | Continuar la ejecución |
| `next` | Ejecutar la siguiente línea |
| `print pin_ingresado` | Consultar el PIN actual |
| `print intentos_fallidos` | Consultar el contador |
| `print estado_sistema` | Consultar el estado del sistema |
| `list 1,20` | Mostrar las primeras líneas del código |
| `Ctrl + C` | Interrumpir la ejecución |
| `detach` | Desconectar GDB del Target |
| `quit` | Salir de GDB |

---

# 35. ¿Qué se aprendió?

Durante este tutorial se utilizó GDB para seguir el comportamiento real de un programa ejecutado sobre un Target ARM emulado.

El proceso seguido fue:

```text
Ejecutar el sistema
        ↓
Detectar comportamiento incorrecto
        ↓
Colocar breakpoint
        ↓
Observar primer intento
        ↓
Observar segundo intento
        ↓
Detectar bloqueo
        ↓
Comprobar que el tercer PIN no se procesa
        ↓
Revisar el código
        ↓
Encontrar la configuración incorrecta
        ↓
Corregir
        ↓
Recompilar
        ↓
Volver a ejecutar
        ↓
Validar el tercer intento
        ↓
Confirmar ACCESO_CONCEDIDO
```

La actividad muestra cómo un depurador permite encontrar la causa de un problema observando la evolución del programa en lugar de limitarse únicamente a leer el código fuente.

---

# 36. Solución del ejercicio

> **No consultar esta sección hasta haber realizado la investigación con GDB.**

La causa se encuentra en:

```c
#define MAX_INTENTOS 2
```

El sistema debía permitir tres intentos, por lo que la configuración correcta es:

```c
#define MAX_INTENTOS 3
```

Con el valor incorrecto:

```text
intentos_fallidos = 2
MAX_INTENTOS = 2
```

la condición:

```c
if (intentos_fallidos >= MAX_INTENTOS)
```

se cumple después del segundo fallo.

Entonces se ejecuta:

```c
estado_sistema = SISTEMA_BLOQUEADO;
```

y el `main()` sale del ciclo antes de llegar al tercer PIN.

Con:

```c
#define MAX_INTENTOS 3
```

los dos primeros intentos pueden fallar y el tercer PIN:

```text
1234
```

sí llega a procesarse, produciendo:

```text
ACCESO_CONCEDIDO
```

y reiniciando:

```text
intentos_fallidos = 0
```