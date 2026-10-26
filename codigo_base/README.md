# Laboratorio Práctico: Despliegue con Canary Releases
### Universidad Icesi — Ingeniería de Software V (Sesión 22)
**Profesor:** Alejandro Muñoz Bravo

Este laboratorio implementa una estrategia de **Canary Release (Lanzamiento Canario)** utilizando el módulo `split_clients` de **Nginx** y **Docker Compose** para mitigación del radio de impacto (*Blast Radius*) basada en telemetría.

---

## 1. Arquitectura del Laboratorio

```
                      [ Peticiones de Usuario ]
                                 │
                                 ▼
                     ┌───────────────────────┐
                     │ Nginx Canary Gateway  │ (:8080)
                     │ (split_clients hash)  │
                     └───────────┬───────────┘
                                 │
             ┌───────────────────┴───────────────────┐
             │ 90% Tráfico                           │ 10% Tráfico (Inicial)
             ▼                                       ▼
   ┌───────────────────┐                   ┌───────────────────┐
   │ Contenedor STABLE │                   │ Contenedor CANARY │
   │ Versión 1.0.0     │                   │ Versión 2.0.0     │
   │ (Puerto 8081)     │                   │ (Puerto 8082)     │
   └───────────────────┘                   └─────────┬─────────┘
                                                     │
                                            [ /api/fault/enable ]
                                            (Simulador de Errores)
```

---

## 2. Instrucciones de Ejecución Paso a Paso

### Paso 1: Iniciar los contenedores
```bash
docker compose up -d --build
docker compose ps
```

### Paso 2: Verificar la distribución porcentual de tráfico
Ejecute el script que envía 100 peticiones simuladas con diversas IPs:
```bash
./test_traffic.sh 100
```
Verifique en el resumen final que aproximadamente el **90%** se atiende por `STABLE` y el **10%** por `CANARY`.

### Paso 3: Simular una degradación en Canary (Inyección de Fallos)
Inyecte un fallo crítico en el contenedor Canary:
```bash
curl -X POST http://localhost:8082/api/fault/enable
```
Vuelva a correr el monitor de tráfico:
```bash
./test_traffic.sh 50
```
**Resultado clave:** Solo el ~10% de los usuarios experimenta errores HTTP 500. El 90% de los usuarios en `STABLE` continúa operando sin afectación (*Blast Radius contenido*).

### Paso 4: Rollback de Emergencia (Evacuación de Tráfico)
Ejecute la orden de evacuación para cortar el tráfico a Canary en caliente:
```bash
./rollback.sh
```
Vuelva a enviar peticiones y confirme que el 100% va a Stable con 0 errores.

### Paso 5: Promoción Progresiva de una Versión Exitosa
Restaure la salud de Canary y simule una promoción progresiva exitosa:
```bash
curl -X POST http://localhost:8082/api/fault/disable
./promote_canary.sh 50   # 50% Stable, 50% Canary
./promote_canary.sh 100  # 100% Canary (Promovido a la nueva Stable)
```

---

## 3. Limpieza del Entorno
```bash
docker compose down
```
