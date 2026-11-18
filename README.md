# Post 9 — Entrada y salida avanzados: puertos, polling e interrupciones

**Estudiante:** Rubio  
**Curso:** Arquitectura de Computadores · Unidad 9 · NASM sobre DOSBox

El laboratorio tiene dos partes. La primera implementa lectura y escritura directa de puertos, polling de estado y combinación de eventos. La segunda instala rutinas para IRQ1, modifica temporalmente el IMR del PIC 8259A y mide intervalos con el contador de ticks del BIOS.

## Entorno y compilación

Los archivos se encuentran en `C:\DOSWork\U9POST` dentro de DOSBox. Para preparar el entorno se monta `C:\DOSWork`, se cambia a `U9POST` y se comprueba NASM con `NASM -v`. Antes de usar el NASM DOS extender puede ejecutarse `CWSDPMI`. Después, `BUILD.BAT` compila todas las fuentes como binarios planos `.COM` usando `NASM -f bin`.

La documentación solicita `LPT1.ASM`, pero Windows reserva los nombres de dispositivo `LPT1` incluso cuando tienen extensión. Por eso, para que el repositorio y la carpeta anfitriona funcionen, la fuente se llama `LPT_1.ASM` y genera `LPT_1.COM`; implementa el mismo ejercicio del puerto paralelo.

## Parte 1 — Acceso directo a puertos

- **TECL.ASM / TECL.COM:** consulta el registro de estado del 8042 en 64h hasta que OBF (bit 0) indica dato disponible, lee el scancode de 60h y lo muestra en hexadecimal. Es una espera sin límite y requiere una tecla.
- **POLL_T.ASM / POLL_T.COM:** realiza la misma consulta con un límite MAX_RETRY. El valor inicial pequeño (5) permite comprobar rápidamente el mensaje de timeout; se puede aumentar para observar la ruta de dato recibido.
- **LPT_1.ASM / LPT_1.COM:** comprueba BUSY# en 379h, escribe el byte 41h en 378h, genera un pulso de STROBE en 37Ah y sondea ACK#. Ambas esperas tienen límite para evitar que el emulador o un periférico ausente dejen el programa bloqueado. Se utiliza DX para los puertos 379h y 37Ah, ya que IN/OUT con puerto inmediato solo codifica una dirección de 8 bits.
- **MULTI_ST.ASM / MULTI_ST.COM:** aísla OBF y BUSY# listo, combina las dos banderas con OR y examina por separado cuál activó la salida. Si LPT1 se reporta listo permanentemente, la espera termina aunque no haya una tecla; se debe describir ese comportamiento como resultado del emulador.

## Parte 2 — ISR y PIC 8259A

- **ISR_KB.ASM / ISR_KB.COM:** guarda el vector INT 09h con INT 21h/3509h, instala el handler con INT 21h/2509h, contabiliza cinco make-codes, envía EOI al PIC y restaura el vector original. El handler solo registra el evento; la salida por pantalla ocurre en el programa principal para no llamar funciones DOS dentro de una interrupción hardware.
- **MASK_KB.ASM / MASK_KB.COM:** guarda el IMR del PIC en 21h, fija el bit 1 para enmascarar IRQ1, espera aproximadamente 55 ticks y restaura el valor original completo. Durante la espera el temporizador sigue habilitado. El tiempo se compara por diferencia de ticks y se detecta el cambio de día del BIOS.
- **ISR_CHAIN.ASM / ISR_CHAIN.COM:** instala un handler que registra las IRQ y luego encadena el handler BIOS con `PUSHF` y llamada lejana. El handler BIOS sigue leyendo el puerto 60h y enviando EOI, por lo que DOS conserva el eco normal del teclado.
- **ISR_TIME.ASM / ISR_TIME.COM:** lee la palabra baja del contador BIOS en 0040h:006Ch para cinco make-codes, guarda las diferencias modulares y las imprime desde el programa principal. La palabra baja se desborda cada 65536 ticks; para intervalos cortos entre teclas, la resta modular conserva el tiempo transcurrido.

## Decisiones técnicas

### 1. Polling sin límite frente a timeout configurable

El polling sin límite de TECL.ASM es aceptable en una demostración controlada en la que el programa sabe que el usuario presionará una tecla, pues la espera forma parte explícita de la interacción. No conviene usarlo cuando el dispositivo puede fallar o cuando el programa debe recuperar el control aunque no llegue ningún dato: en ese escenario POLL_T.ASM necesita terminar con un timeout. El límite evita un bloqueo indefinido, pero si MAX_RETRY se fija en cinco iteraciones, un teclado lento o una respuesta que llega unos instantes después del límite producirá un falso timeout. Además, el contador no mide segundos: cuenta cuántas veces se ejecuta el bucle. Un procesador rápido o una máquina virtual con más ciclos agotará el mismo contador antes que un sistema lento. Para medir tiempo transcurrido es preferible comparar el contador de ticks del BIOS en 0040h:006Ch, porque avanza con el temporizador del sistema y no con el número de vueltas del bucle.

### 2. OR frente a AND al combinar estados

La combinación con OR sirve cuando el programa puede continuar ante el primero de dos eventos: la bandera resultante es distinta de cero si el teclado tiene un dato o si LPT1 está listo. Sin embargo, si el estado del paralelo se mantiene listo en DOSBox, MULTI_ST.ASM sale en la primera iteración aunque el teclado todavía no tenga datos; por ello, la espera combinada deja de esperar realmente por el teclado. Después de salir, el código debe revisar BL y BH por separado, pues el OR solo informa que al menos una condición fue cierta y no identifica cuál. Si el caso de uso requiere que ambos dispositivos estén listos antes de actuar, corresponde una condición AND: esta no se cumple hasta que las dos banderas valen uno simultáneamente. Por ejemplo, sería útil no enviar el carácter a la impresora hasta que el operador haya confirmado la operación con el teclado y el periférico indique disponibilidad. OR significa cualquiera; AND significa ambos.

### 3. Momento de enviar el EOI

El ISR debe confirmar al PIC que terminó el servicio del hardware tan pronto como haya leído el dato necesario y completado el trabajo crítico. Si se demora el EOI hasta después de una impresión por DOS, el PIC conserva la solicitud IRQ1 en estado de servicio durante todo ese procesamiento y puede bloquear solicitudes pendientes de prioridad igual o menor. El EOI temprano libera ese estado del PIC, pero no permite por sí solo que la CPU ejecute otro ISR mientras IF continúa desactivado: la CPU recién acepta interrupciones enmascarables después del IRET, salvo que el handler habilite IF explícitamente. Así se distingue el estado interno del PIC del permiso global de la CPU. En este taller, ISR_TIME.ASM calcula y guarda el intervalo, envía el EOI y luego deja que el programa principal imprima; ISR_KB.ASM también mantiene la salida fuera del ISR en esta implementación. La práctica más segura es hacer mínimo trabajo en el handler y diferir operaciones lentas a la rutina principal.

### 4. Polling frente a interrupción

El polling es sencillo cuando se espera una respuesta durante un intervalo muy corto, conocido y acotado: el programa consulta el registro y puede continuar en cuanto aparezca el dato sin configurar un handler. TECL.ASM muestra el costo del caso general: mientras no llega la tecla, el procesador repite el bucle y no realiza trabajo útil. Ese enfoque resulta inadecuado en un juego, una interfaz o un programa cooperativo que debe animar la pantalla o atender otros dispositivos mientras espera. IRQ1 permite que el flujo principal haga otra tarea y llama al handler cuando el controlador señala el evento, por lo que suele dar una respuesta más oportuna que un bucle que consulta a intervalos. El ISR tiene, a cambio, más complejidad: debe guardar el estado que modifica, leer o encadenar correctamente el dispositivo, enviar EOI y evitar funciones DOS no reentrantes. Para un teclado esporádico, la interrupción ahorra ciclos; para una espera de pocos ciclos, el polling puede ser más simple que instalar y restaurar un ISR.

## Observaciones y resultados

En la ejecución automatizada de DOSBox, `LPT_1.COM` terminó sin bloquearse y mostró `Dato A enviado; ACK recibido.`. Quedan pendientes las pruebas interactivas de lectura de scancode, las cinco pulsaciones en cada ISR y las capturas de pantalla de los diez checkpoints; no se atribuyen resultados a esas pruebas hasta observarlos en DOSBox.

## Evidencias pendientes

El taller solicita al menos dos capturas por checkpoint: 20 capturas en total. Se guardarán en `capturas/` con nombres `P1-CP1-a.png`, `P1-CP1-b.png` … `P1-CP5-b.png` y `P2-CP1-a.png` … `P2-CP5-b.png`. Cada imagen debe mostrar el comando o fuente y el resultado correspondiente del programa.

## Estructura

- Ocho fuentes `.ASM` y ocho binarios `.COM`.
- `BUILD.BAT`: compila todos los ejercicios.
- `docs/`: decisiones técnicas separadas para consulta.
- `capturas/`: evidencias visuales requeridas.
