# Evaluación del Mini-Taller: QEMU + GDB

Este documento contiene dos bloques de preguntas:


# Parte 1 — Preguntas Iniciales

Estas preguntas son intencionalmente sencillas. Su objetivo es introducir el tema y conocer qué tanto saben los participantes antes de comenzar.

## Pregunta 1

**¿Qué significa depurar un programa?**

A. Cambiar el lenguaje de programación.  
B. Buscar y analizar errores en la ejecución de un programa.  
C. Instalar un sistema operativo.  
D. Convertir código C en Python.

**Respuesta correcta:** B

**Justificación:**  
La depuración consiste en observar y controlar la ejecución de un programa para identificar y comprender errores.

---

## Pregunta 2

**¿Cuál de estas herramientas se utiliza principalmente como depurador?**

A. QEMU  
B. GDB  
C. Git  
D. GCC

**Respuesta correcta:** B

**Justificación:**  
GDB es una herramienta de depuración que permite controlar la ejecución e inspeccionar variables, memoria, registros y otros elementos del programa.

---

## Pregunta 3

**En el contexto de sistemas embebidos, el Target es:**

A. La computadora donde programamos.  
B. El sistema o procesador donde se ejecutará el programa objetivo.  
C. El editor de código.  
D. El repositorio de GitHub.

**Respuesta correcta:** B

**Justificación:**  
El Target es la plataforma objetivo para la cual está diseñado y compilado el programa.

---

## Pregunta 4

**¿Para qué sirve un breakpoint?**

A. Para borrar una función.  
B. Para detener temporalmente la ejecución en un punto determinado.  
C. Para reiniciar el procesador.  
D. Para compilar el programa.

**Respuesta correcta:** B

**Justificación:**  
Un breakpoint permite detener la ejecución en una función o línea específica para inspeccionar el estado del programa.

---

## Pregunta 5

**¿Cuál de estas opciones describe mejor a QEMU?**

A. Es únicamente un compilador de C.  
B. Es una herramienta que puede emular una plataforma o arquitectura objetivo.  
C. Es un editor de texto.  
D. Es un sistema de control de versiones.

**Respuesta correcta:** B

**Justificación:**  
QEMU puede proporcionar un entorno emulado donde se ejecuta software diseñado para una arquitectura objetivo.

---

# Parte 2 — Preguntas Finales

Estas preguntas requieren aplicar los conceptos explicados durante el mini-taller.

## Pregunta 6

**¿Cuál es la diferencia principal entre QEMU y GDB dentro de una sesión de depuración?**

A. QEMU compila el programa y GDB emula el procesador.  
B. QEMU proporciona el entorno Target emulado y GDB controla e inspecciona la ejecución.  
C. Ambos realizan exactamente la misma función.  
D. GDB crea la CPU virtual y QEMU coloca los breakpoints.

**Respuesta correcta:** B

**Justificación:**  
QEMU proporciona la plataforma emulada donde se ejecuta el software, mientras que GDB permite controlar la ejecución, establecer breakpoints e inspeccionar el estado del programa.

---

## Pregunta 7

**¿Cuál es la diferencia técnica entre `gdbstub` y `gdbserver`?**

A. `gdbstub` está integrado en QEMU y puede utilizarse para depuración a bajo nivel, mientras que `gdbserver` se ejecuta dentro de un sistema operativo Target para depurar una aplicación.
B. `gdbserver` está integrado siempre en QEMU y `gdbstub` se instala en Linux.
C. Ambos son exactamente la misma herramienta.
D. `gdbstub` compila el código y `gdbserver` lo ejecuta.

**Respuesta correcta:** A

**Justificación:**  
`gdbstub` forma parte de QEMU y permite interactuar con la CPU emulada. `gdbserver`, en cambio, es un programa que se ejecuta dentro de un sistema operativo Target para controlar un proceso específico.

## Pregunta 8

**¿Cuál es la función principal de la opción `-g` al compilar un programa que será depurado con GDB?**

A. Aumentar la velocidad de ejecución del programa.  
B. Activar automáticamente el `gdbstub` de QEMU.  
C. Incluir información de depuración que relaciona el ejecutable con funciones, variables y líneas del código fuente.  
D. Convertir automáticamente un programa x86_64 en un programa ARM.

**Respuesta correcta:** C

**Justificación:**  
La opción `-g` agrega símbolos de depuración al ejecutable. Estos permiten que GDB relacione las direcciones e instrucciones del programa con nombres de funciones, variables y líneas del código fuente.

---

## Pregunta 9

**Al iniciar QEMU para una sesión de depuración, ¿qué función cumplen las opciones `-s` y `-S`?**

A. `-s` inicia el sistema operativo y `-S` compila el programa.  
B. `-s` habilita el `gdbstub` en el puerto 1234 y `-S` mantiene la CPU detenida hasta que el depurador ordene continuar.  
C. `-s` muestra los registros y `-S` muestra la memoria.  
D. Ambas opciones sirven únicamente para activar la interfaz gráfica de QEMU.

**Respuesta correcta:** B

**Justificación:**  
La opción `-s` habilita el servidor de depuración integrado de QEMU utilizando el puerto TCP 1234 por defecto. La opción `-S` evita que la CPU emulada comience a ejecutar instrucciones hasta que GDB se conecte y ordene continuar.

---

## Pregunta 10

**Si un programa funciona correctamente en QEMU, ¿cuál de las siguientes afirmaciones es correcta?**

A. Se puede garantizar que tendrá exactamente el mismo comportamiento en el hardware físico.  
B. Ya no es necesario realizar ninguna prueba sobre la plataforma real.  
C. QEMU permite validar muchos aspectos del software, pero pueden seguir siendo necesarias pruebas en hardware real para comprobar temporización y periféricos físicos.  
D. El programa solo necesitará pruebas adicionales si fue compilado sin `-g`.

**Respuesta correcta:** C

**Justificación:**  
La emulación permite desarrollar y depurar software sin depender inmediatamente del hardware físico, pero no necesariamente reproduce con exactitud la temporización ni todos los periféricos y comportamientos específicos de la plataforma real.