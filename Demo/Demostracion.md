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

## Qué mostrar en clase

Terminal 1 — QEMU:
- `uname -m`
- `ip a`
- `gst-launch-1.0 --version`
- explicar Host, Guest y Target.

Terminal 2 — `socat`:
- explicar el puente `10.0.2.2:5000 → vigilante:5000`.

Terminal 3 — Docker:
- `docker compose ps`
- mostrar FPS de `vigilante`
- recalcar que `emisor` Docker está detenido y el stream viene de QEMU.

## Cierre

Guest:

```bash
sudo poweroff
```

Host:

```bash
docker compose down
```

La demo quedó validada con el flujo:

```text
QEMU → Raspberry Pi 3B → Linux ARM64 → GStreamer → RTP/UDP → Host → socat → Docker → vigilante
```
