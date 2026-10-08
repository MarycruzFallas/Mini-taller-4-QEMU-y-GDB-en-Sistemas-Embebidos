# Tutorial: Depuración con `pdb`
## Sistema de control de acceso visual

## Objetivo

Aplicar un flujo de depuración utilizando `pdb`, el depurador integrado de Python, para identificar y corregir errores en un sistema de control de acceso basado en detección de color.

El programa simula un panel visual con tres posibles estados:

- **Verde** → Acceso permitido.
- **Rojo** → Acceso denegado.
- **Amarillo** → Revisión.

El código contiene dos errores intencionales. Durante el tutorial se utilizarán breakpoints, inspección de variables y ejecución controlada para localizar la causa de cada fallo.

---

## Requisitos

Para realizar el tutorial se necesita:

- Python 3
- OpenCV
- NumPy
- `pdb`, incluido en la biblioteca estándar de Python

Verificar Python:

```bash
python3 --version
```

Verificar OpenCV:

```bash
python3 -c "import cv2; print(cv2.__version__)"
```

Verificar NumPy:

```bash
python3 -c "import numpy; print(numpy.__version__)"
```

---

## Archivo utilizado

El ejercicio utiliza:

```text
control_acceso_vision.py
```

Para ejecutarlo:

```bash
python3 control_acceso_vision.py
```

---

# 1. Observar el problema

Ejecutar el programa sin modificarlo:

```bash
python3 control_acceso_vision.py
```

La ejecución inicial debe mostrar:

```text
Resultado final: 1/4 pruebas correctas
```

Los resultados son similares a:

```text
Tarjeta rechazada
Esperado: ACCESO DENEGADO
Resultado: ACCESO PERMITIDO

Tarjeta autorizada
Esperado: ACCESO PERMITIDO
Resultado: ACCESO DENEGADO

Validación pendiente
Esperado: REVISIÓN
Resultado: REVISIÓN

Tarjeta autorizada + ruido
Esperado: ACCESO PERMITIDO
Resultado: ACCESO DENEGADO
```

A partir de esta salida se puede observar que rojo y verde parecen estar intercambiados, mientras que amarillo funciona correctamente.

En lugar de modificar el código inmediatamente, se utilizará el depurador para determinar qué está ocurriendo.

---

# 2. Agregar un breakpoint

Abrir el archivo:

```bash
nano control_acceso_vision.py
```

Dentro de la función:

```python
analizar_panel()
```

buscar:

```python
hsv = cv2.cvtColor(imagen, cv2.COLOR_BGR2HSV)
```

y agregar debajo:

```python
breakpoint()
```

Debe quedar:

```python
hsv = cv2.cvtColor(imagen, cv2.COLOR_BGR2HSV)

breakpoint()
```

Guardar el archivo y ejecutar nuevamente:

```bash
python3 control_acceso_vision.py
```

El programa se detendrá y aparecerá el prompt:

```text
(Pdb)
```

A partir de este momento es posible inspeccionar el estado interno del programa.

---

# 3. Inspeccionar la señal roja

La primera pausa corresponde al caso donde la señal roja está activa.

En `pdb`, ejecutar:

```text
p hsv[60, 50]
```

Resultado esperado:

```text
array([  0, 255, 220], dtype=uint8)
```

El primer valor corresponde al componente **Hue**:

```text
Hue = 0
```

Ahora listar el código cercano:

```text
l
```

El rango configurado para rojo es:

```python
rango_rojo_bajo = np.array([35, 100, 100])
rango_rojo_alto = np.array([85, 255, 255])
```

Sin embargo, el píxel rojo inspeccionado tiene:

```text
Hue = 0
```

Por lo tanto, el rojo real no se encuentra dentro del rango configurado para rojo.

---

# 4. Inspeccionar la señal verde

Continuar la ejecución:

```text
c
```

El programa llegará a la segunda imagen.

Inspeccionar ahora el centro de la señal verde:

```text
p hsv[150, 50]
```

Resultado esperado:

```text
array([ 60, 255, 200], dtype=uint8)
```

Por tanto:

```text
Hue = 60
```

El rango configurado para verde es:

```python
rango_verde_bajo = np.array([0, 100, 100])
rango_verde_alto = np.array([10, 255, 255])
```

El valor:

```text
Hue = 60
```

tampoco pertenece al rango configurado para verde.

---

# 5. Bug 1: rangos HSV intercambiados

Las inspecciones permiten determinar que los rangos HSV correspondientes a rojo y verde se encuentran intercambiados.

Los valores correctos son:

```python
rango_rojo_bajo = np.array([0, 100, 100])
rango_rojo_alto = np.array([10, 255, 255])

rango_verde_bajo = np.array([35, 100, 100])
rango_verde_alto = np.array([85, 255, 255])
```

Salir del depurador:

```text
q
```

Abrir nuevamente el archivo:

```bash
nano control_acceso_vision.py
```

Corregir los rangos y eliminar temporalmente:

```python
breakpoint()
```

Ejecutar:

```bash
python3 control_acceso_vision.py
```

El resultado ahora debe ser:

```text
Resultado final: 3/4 pruebas correctas
```

Los tres primeros casos funcionan correctamente.

Sin embargo, todavía falla:

```text
Tarjeta autorizada + ruido
```

Esto indica que existe un segundo problema.

---

# 6. Investigar el segundo error

Agregar nuevamente:

```python
breakpoint()
```

después de:

```python
hsv = cv2.cvtColor(imagen, cv2.COLOR_BGR2HSV)
```

Ejecutar:

```bash
python3 control_acceso_vision.py
```

El programa se detendrá cuatro veces, una por cada caso de prueba.

Utilizar:

```text
c
```

tres veces para avanzar hasta la cuarta pausa.

Esta corresponde al caso:

```text
Tarjeta autorizada + ruido
```

---

# 7. Inspeccionar los conteos de píxeles

Utilizar `list` para localizar la sección donde se calculan las máscaras y los conteos:

```text
l 84,110
```

En esta sección se encuentran:

```python
pixeles_rojo
pixeles_verde
pixeles_amarillo
```

Avanzar hasta después de realizar los conteos:

```text
until 100
```

Luego inspeccionar los valores:

```text
p pixeles_rojo, pixeles_verde, pixeles_amarillo
```

Resultado esperado:

```text
(3, 2453, 0)
```

Es decir:

```text
Rojo     = 3 píxeles
Verde    = 2453 píxeles
Amarillo = 0 píxeles
```

La señal dominante es claramente verde.

Sin embargo, el programa devuelve:

```text
ACCESO DENEGADO
```

---

# 8. Bug 2: lógica de decisión incorrecta

La lógica original del programa es:

```python
if pixeles_rojo > 0:
    return "ACCESO DENEGADO", pixeles_rojo

elif pixeles_verde > 0:
    return "ACCESO PERMITIDO", pixeles_verde

elif pixeles_amarillo > 0:
    return "REVISIÓN", pixeles_amarillo

else:
    return "SEÑAL DESCONOCIDA", 0
```

El problema es que se selecciona el primer color que tenga al menos un píxel.

Por esta razón, únicamente:

```text
3 píxeles rojos
```

son suficientes para devolver:

```text
ACCESO DENEGADO
```

aunque existan:

```text
2453 píxeles verdes
```

El sistema debería seleccionar el color dominante.

---

# 9. Corregir la lógica de decisión

Salir de `pdb`:

```text
q
```

Abrir el archivo:

```bash
nano control_acceso_vision.py
```

Reemplazar la lógica anterior por:

```python
conteos = {
    "ACCESO DENEGADO": pixeles_rojo,
    "ACCESO PERMITIDO": pixeles_verde,
    "REVISIÓN": pixeles_amarillo,
}

resultado = max(conteos, key=conteos.get)

if conteos[resultado] == 0:
    return "SEÑAL DESCONOCIDA", 0

return resultado, conteos[resultado]
```

Ahora se selecciona el estado asociado con la mayor cantidad de píxeles detectados.

Eliminar nuevamente:

```python
breakpoint()
```

---

# 10. Verificación final

Ejecutar:

```bash
python3 control_acceso_vision.py
```

El resultado final debe ser:

```text
Resultado final: 4/4 pruebas correctas
```

Los cuatro casos deben funcionar correctamente:

```text
Tarjeta rechazada           → ACCESO DENEGADO
Tarjeta autorizada          → ACCESO PERMITIDO
Validación pendiente        → REVISIÓN
Tarjeta autorizada + ruido  → ACCESO PERMITIDO
```

Con esto se confirma que ambos errores fueron identificados y corregidos correctamente.

---

# Comandos utilizados en `pdb`

| Comando | Función |
|---|---|
| `breakpoint()` | Detiene la ejecución y abre `pdb` |
| `p expresión` | Evalúa e imprime una variable o expresión |
| `l` | Muestra el código alrededor de la posición actual |
| `l inicio,fin` | Muestra un rango específico del código |
| `n` | Ejecuta la siguiente línea |
| `s` | Entra dentro de una función |
| `c` | Continúa hasta el siguiente breakpoint |
| `until línea` | Continúa hasta alcanzar una línea posterior |
| `q` | Sale del depurador |

---

# Relación entre `pdb` y GDB

Aunque este ejercicio utiliza `pdb`, el flujo de trabajo es similar al utilizado con GDB durante la depuración de software embebido.

| Acción | `pdb` | GDB |
|---|---|---|
| Crear breakpoint | `breakpoint()` / `b` | `break` |
| Siguiente línea | `n` | `next` |
| Entrar a función | `s` | `step` |
| Inspeccionar variable | `p` | `print` |
| Continuar ejecución | `c` | `continue` |
| Listar código | `l` | `list` |
| Salir | `q` | `quit` |

El proceso general puede representarse como:

```text
Observar el fallo
        ↓
Detener la ejecución
        ↓
Inspeccionar el estado del programa
        ↓
Avanzar de forma controlada
        ↓
Formular una hipótesis
        ↓
Corregir el código
        ↓
Ejecutar nuevamente
        ↓
Validar el resultado
```

La herramienta utilizada puede cambiar, pero el razonamiento de depuración se mantiene.

---

# Resultado

Durante el tutorial se identificaron dos errores:

1. Los rangos HSV de las señales roja y verde estaban intercambiados.
2. La lógica de decisión seleccionaba el primer color detectado en lugar del color dominante.

Después de realizar ambas correcciones, el sistema alcanza:

```text
4/4 pruebas correctas
```

Este ejercicio permite practicar un flujo estructurado de depuración: observar, detener, inspeccionar, formular una hipótesis, corregir y validar.

---

## Referencia

La estructura pedagógica de este ejercicio fue adaptada a partir del enfoque de depuración presentado en el mini-taller de David Leitón sobre depuradores y emuladores. El ejemplo, contexto, código y flujo de control de acceso fueron modificados para este tutorial.
