# Evaluación del Mini-Taller: QEMU + GDB

Este documento contiene dos bloques de preguntas:


# Parte 1 — Rompehielo y reflexión inicial

Estas preguntas se realizan de forma abierta al inicio del mini-taller. Su objetivo es partir de la experiencia previa de los participantes y llevarlos a reflexionar sobre la diferencia entre simulación y emulación.

## Pregunta 1

**¿Qué herramientas de simulación han usado?**

La idea es que los participantes mencionen herramientas que ya conozcan o hayan utilizado durante la carrera.

---

## Pregunta 2

**¿Qué estaban simulando con ellas?**

Esta pregunta busca que identifiquen qué parte del sistema representaban con esas herramientas: circuitos, sistemas de control, procesadores, hardware digital, redes u otros sistemas.

---

## Pregunta 3

**¿Eso es lo mismo que emular hardware?**

No se responde inmediatamente. La intención es generar la duda y utilizarla como transición hacia el tema principal del mini-taller.

### Transición

> **Hoy vamos a ver por qué no.**

A continuación se muestra una demostración práctica: un juego antiguo ejecutándose dentro de QEMU.

La idea es que, a partir de esta experiencia, se introduzca la diferencia entre simulación y emulación y se analice qué está haciendo QEMU para permitir que software diseñado para otra plataforma pueda ejecutarse en la computadora actual.

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
