# Demo técnica: Raspberry Pi 3B emulada con QEMU + GStreamer + Docker

Esta demo reemplaza la demostración bare-metal anterior. El objetivo es mostrar una Raspberry Pi 3B emulada con QEMU que ejecuta Linux ARM64 y transmite un flujo RTP/H.264 hacia un contenedor Docker receptor.

## Arquitectura

```text
Laptop Ubuntu (Host)
│
├── QEMU
│   └── Raspberry Pi 3B emulada
│       ├── Debian / Raspberry Pi OS Bullseye ARM64
│       ├── usb0: 10.0.2.15
│       └── GStreamer → H.264 → RTP/UDP
│
├── Red virtual QEMU
│   └── Host visto desde Guest: 10.0.2.2
│
├── socat
│   └── puente UDP :5000
│
└── Docker
    └── vigilante
        └── recibe + decodifica + mide FPS
```

Validado durante la prueba:
- Raspberry Pi 3B emulada arrancó correctamente.
- Linux ARM64 operativo.
- Red Guest→Host funcional.
- GStreamer 1.18.4 instalado.
- RTP/H.264 llegó al Host.
- `socat` reenvió el tráfico a `vigilante`.
- `vigilante` mostró `dropped: 0` y promedio cercano a 29 FPS.

## Preparación de la imagen

```bash
wget -O raspios_bullseye_2022.img.xz https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64-lite.img.xz
unxz raspios_bullseye_2022.img.xz
```

Extraer kernel y DTB:

```bash
mkdir -p bootbull
sudo mount -o loop,ro,offset=$((8192*512)) raspios_bullseye_2022.img bootbull
cp bootbull/kernel8.img kernel8-bullseye.img
cp bootbull/bcm2710-rpi-3-b.dtb bcm2710-rpi-3-b-bullseye.dtb
gzip -dc kernel8-bullseye.img > kernel8-bullseye-uncompressed.img
sudo umount bootbull
```

Crear copia de trabajo y ampliar:

```bash
cp raspios_bullseye_2022.img raspios_bullseye_qemu.img
qemu-img resize -f raw raspios_bullseye_qemu.img 4G
sudo losetup --find --partscan --show raspios_bullseye_qemu.img
```

Usar el `/dev/loopX` devuelto:

```bash
sudo growpart /dev/loopX 2
sudo resize2fs /dev/loopXp2
sudo losetup -d /dev/loopX
```

Crear usuario:

```bash
sudo mkdir -p /mnt/rpi-boot
sudo mount -o loop,offset=$((8192*512)) raspios_bullseye_qemu.img /mnt/rpi-boot
printf 'pi:%s
' "$(openssl passwd -6 raspberry)" | sudo tee /mnt/rpi-boot/userconf >/dev/null
sudo umount /mnt/rpi-boot
```

Credenciales: `pi / raspberry`.

## Arranque de QEMU

```bash
qemu-system-aarch64   -M raspi3b   -cpu cortex-a53   -m 1G   -smp 4   -kernel kernel8-bullseye-uncompressed.img   -dtb bcm2710-rpi-3-b-bullseye.dtb   -sd raspios_bullseye_qemu.img   -append "console=ttyAMA0,115200 root=PARTUUID=0ee3e8a8-02 rootfstype=ext4 fsck.repair=yes rootwait rw"   -netdev user,id=net0   -device usb-net,netdev=net0   -nographic
```

Dentro del Guest:

```bash
ip a
ping -c 3 10.0.2.2
```

## Repositorios Bullseye

```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo nano /etc/apt/sources.list
```

Contenido:

```text
deb http://archive.debian.org/debian bullseye main contrib non-free
deb http://archive.debian.org/debian bullseye-updates main contrib non-free
deb http://archive.debian.org/debian-security bullseye-security main contrib non-free
```

Luego:

```bash
sudo apt update
sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
gst-launch-1.0 --version
```

## Receptor Docker

En Host:

```bash
cd ~/Project_1_Embebidos
docker compose up --build
docker compose stop emisor
docker compose ps
```

Obtener IP del receptor:

```bash
CID=$(docker compose ps -q vigilante)
VIGILANTE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID")
echo "$VIGILANTE_IP"
```

## Puente UDP

```bash
socat -v UDP4-RECVFROM:5000,fork UDP4-SENDTO:${VIGILANTE_IP}:5000
```

## Emisor dentro de Raspberry emulada

```bash
gst-launch-1.0 -v   videotestsrc is-live=true pattern=ball !   video/x-raw,width=1280,height=720,framerate=30/1 !   x264enc tune=zerolatency bitrate=2000 speed-preset=veryfast key-int-max=30 !   h264parse !   rtph264pay pt=96 config-interval=1 !   udpsink host=10.0.2.2 port=5000 sync=false
```

# Ejecución de la demostración en clase

Esta sección contiene únicamente los pasos que deben ejecutarse durante la demostración en vivo.

La preparación de la imagen de Raspberry Pi, instalación de dependencias, configuración de repositorios y creación del usuario se realizan previamente y no forman parte de la ejecución en clase.

La demostración utiliza tres terminales en el Host Ubuntu:

- Terminal 1: Docker / contenedor `vigilante`.
- Terminal 2: QEMU / Raspberry Pi 3B emulada.
- Terminal 3: puente UDP con `socat`.

---

## 1. Levantar el receptor Docker

En una terminal del Host Ubuntu:

```bash
cd ~/Project_1_Embebidos
docker compose up -d vigilante
docker compose ps
```

Verificar que el servicio `vigilante` aparezca en estado activo.

El contenedor `vigilante` funciona como receptor del stream de video.

Durante esta demostración no se utiliza el emisor Docker, debido a que el emisor será la Raspberry Pi emulada con QEMU.

Para visualizar los datos recibidos:

```bash
docker compose logs -f vigilante
```

Mantener esta terminal abierta.

---

## 2. Arrancar la Raspberry Pi 3B emulada

Abrir una segunda terminal en el Host Ubuntu:

```bash
cd ~/Mini-taller-4-QEMU-y-GDB-en-Sistemas-Embebidos
./Demo/run_qemu_rpi.sh
```

Esperar hasta que el sistema termine de arrancar.

Cuando aparezca el login:

```text
raspberrypi login:
```

Ingresar:

```text
pi
```

Contraseña:

```text
raspberry
```

Al finalizar el login debe aparecer un prompt similar a:

```text
pi@raspberrypi:~ $
```

A partir de este punto, los siguientes comandos se ejecutan dentro del Guest emulado.

---

## 3. Verificar la arquitectura del Guest

Dentro de la Raspberry Pi emulada:

```bash
uname -m
```

Salida esperada:

```text
aarch64
```

Esto permite verificar que el sistema ejecutado dentro de QEMU utiliza arquitectura ARM64, aunque el Host físico utiliza arquitectura x86-64.

---

## 4. Verificar la interfaz de red virtual

Dentro del Guest:

```bash
ip a
```

Buscar la interfaz:

```text
usb0
```

La dirección esperada es:

```text
10.0.2.15/24
```

Esto corresponde a la interfaz de red virtual de la Raspberry Pi emulada.

---

## 5. Verificar comunicación Guest → Host

Dentro del Guest:

```bash
ping -c 3 10.0.2.2
```

Salida esperada:

```text
3 packets transmitted
3 received
0% packet loss
```

Dentro de esta configuración de red de QEMU:

```text
Guest Raspberry Pi → 10.0.2.15
Host Ubuntu        → 10.0.2.2
```

Este paso verifica que la Raspberry Pi emulada puede comunicarse correctamente con el Host Ubuntu.

---

## 6. Crear el puente UDP hacia Docker

Abrir una tercera terminal en el Host Ubuntu:

```bash
cd ~/Mini-taller-4-QEMU-y-GDB-en-Sistemas-Embebidos
./Demo/bridge_udp.sh
```

El script obtiene automáticamente la dirección IP actual del contenedor `vigilante` y ejecuta el puente UDP mediante `socat`.

Debe mostrarse una salida similar a:

```text
vigilante=172.19.0.2:5000
```

La dirección exacta del contenedor puede cambiar entre ejecuciones.

El flujo en este punto es:

```text
Raspberry Pi emulada
        |
        | RTP/UDP
        v
10.0.2.2:5000
Host Ubuntu
        |
        | socat
        v
Docker vigilante:5000
```

Mantener esta terminal abierta.

---

## 7. Iniciar el emisor GStreamer en la Raspberry Pi emulada

Volver a la terminal de QEMU.

Dentro del Guest ejecutar:

```bash
gst-launch-1.0 -v \
  videotestsrc is-live=true pattern=ball ! \
  video/x-raw,width=1280,height=720,framerate=30/1 ! \
  x264enc tune=zerolatency bitrate=2000 speed-preset=veryfast key-int-max=30 ! \
  h264parse ! \
  rtph264pay pt=96 config-interval=1 ! \
  udpsink host=10.0.2.2 port=5000 sync=false
```

Este pipeline realiza las siguientes operaciones:

```text
videotestsrc
      |
      v
Video 1280x720 @ 30 FPS
      |
      v
Codificación H.264
      |
      v
Encapsulado RTP
      |
      v
Transmisión UDP
      |
      v
10.0.2.2:5000
```

La Raspberry Pi emulada funciona ahora como el emisor del sistema.

---

## 8. Verificar recepción en Docker

Volver a la terminal donde se están mostrando los logs de `vigilante`.

Se deben observar estadísticas del stream recibido.

Durante las pruebas realizadas se obtuvo un comportamiento similar a:

```text
rendered: ...
dropped: 0
average: ~29 FPS
```

Esto confirma que el video generado dentro de la Raspberry Pi ARM64 emulada:

```text
Raspberry Pi emulada
        |
        v
GStreamer
        |
        v
H.264 sobre RTP/UDP
        |
        v
Red virtual de QEMU
        |
        v
Host Ubuntu
        |
        v
socat
        |
        v
Docker vigilante
```

fue recibido y decodificado correctamente.

La fuente fue configurada para transmitir a 30 FPS y durante la validación se obtuvo un promedio cercano a 29 FPS, sin frames descartados.

El objetivo de esta prueba no es realizar un benchmark exacto de una Raspberry Pi física, sino validar la comunicación e integración entre un sistema ARM emulado y servicios ejecutándose en el Host.

---

# Cierre de la demostración

## 9. Detener GStreamer

En la terminal de la Raspberry Pi emulada:

```text
Ctrl + C
```

---

## 10. Apagar el Guest

Dentro de la Raspberry Pi emulada:

```bash
sudo poweroff
```

Esperar hasta que QEMU finalice correctamente.

---

## 11. Detener `socat`

En la terminal donde se ejecutó:

```bash
./Demo/bridge_udp.sh
```

presionar:

```text
Ctrl + C
```

---

## 12. Detener Docker

En el Host Ubuntu:

```bash
cd ~/Project_1_Embebidos
docker compose down
```

---

# Flujo completo validado

La demostración implementa el siguiente recorrido:

```text
Laptop Ubuntu
    |
    v
QEMU
    |
    v
Raspberry Pi 3B emulada
ARM64 / Debian Bullseye
    |
    v
GStreamer
    |
    v
H.264 + RTP/UDP
    |
    v
Red virtual de QEMU
    |
    v
Host Ubuntu
    |
    v
socat
    |
    v
Docker
    |
    v
vigilante
    |
    v
Recepción + decodificación + medición de FPS
```

Resultados observados durante la validación:

```text
Comunicación Guest → Host: funcional
Stream RTP/H.264: recibido correctamente
Frames descartados: 0
FPS promedio: aproximadamente 29 FPS
```
