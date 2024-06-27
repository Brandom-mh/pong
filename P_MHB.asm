title "PingPong"
.model small
.386
.stack 64
;Equipo 2
;Gomez Garcia Luis David
;Santos Carranza Alexis
;Martinez Hernandez Brandom 
.data
    ; Datos de la pelota
    posX db 36  ; Posición X inicial (columna)
    posY db 12   ; Posición Y inicial (fila)
    dirX db 1    ; Dirección X (1: derecha, -1: izquierda)
    dirY db 1    ; Dirección Y (1: abajo, -1: arriba)
    ballChar db '8'
    emptyChar db ' '

    ; Datos de la barra inferior
    pos_col db 40       ; Posición inicial de la columna
    pos_ren db 23       ; Posición inicial del renglón (parte inferior)
    bar_char db 219     ; Caracter para la barra
    bar_width equ 30    ; Ancho de la barra (10)

    ; Datos de la barra superior
    top_bar_col db 40   ; Posición inicial de la columna
    top_bar_ren db 1    ; Posición inicial del renglón (parte superior)
    top_bar_char db 219 ; Caracter para la barra superior

    ; Variables para los marcadores de puntos
    jugador_superior db 0   ; Contador de puntos del jugador superior
    jugador_inferior db 0   ; Contador de puntos del jugador inferior
    marcador_char db '.'

    ; Obstáculos
    obstaculo1_col db 20 ; Columna del obstáculo 1
    obstaculo1_ren db 10; Renglón del obstáculo 1
    obstaculo2_col db 60 ; Columna del obstáculo 2
    obstaculo2_ren db 10 ; Renglón del obstáculo 2
    obstaculo_char db 219 ; Carácter del obstáculo

   ; Mensajes para los jugadores
    jugador1_msg db 'Fin del juego.', 0
    jugador2_msg db 'Fin del juego.', 0

    ; Mensaje de fin de juego
    game_over_msg db 'Fin del juego$', 0

    ; Estado del juego
    game_state db 0    ; 0: Pausado, 1: En ejecución


.code
main:
    mov ax, @data
    mov ds, ax
    mov es, ax
    mov ax, 03h   ;Prepara la BIOS para una llamada a interrupcion 
    int 10h       ;Interrupcion para la BIOS, depende del valor de AX
    call hide_cursor
    call draw_obstaculos  ; Dibuja los obstáculos
    call draw_ball
    call draw_bar
    call draw_top_bar

wait_for_start:
    call check_keyboard
    cmp game_state, 1
    jne wait_for_start ;Si GS no es 1

animation_loop:
    call clear_screen
    call update_position
    call draw_ball
    call draw_bar
    call draw_top_bar
    call draw_obstaculos  ; Asegura que los obstáculos se vuelvan a dibujar
    call draw_score

    call delay
    call check_keyboard


    ; Verificar si algún jugador ha llegado a 10 puntos
    mov al, jugador_superior
    cmp al, 10
    jge end_game
    mov al, jugador_inferior
    cmp al, 10
    jge end_game

    jmp animation_loop

end_game:
    ; Limpiar la pantalla
    call clear_screen

    ; Mostrar mensaje de fin de juego centrado en la pantalla
    mov ah, 02h           ; Función de mover el cursor
    mov dl, 35            ; Columna (aproximadamente centrada)
    mov dh, 12            ; Fila (aproximadamente centrada)
    mov bh, 0             ; Página de video
    int 10h
    lea dx, game_over_msg ; Cargar dirección del mensaje "Fin del juego"
    mov ah, 09h           ; Función para escribir carácter y atributo
    int 21h

    ; Esperar una tecla para salir
    mov ah, 00h
    int 16h
    jmp salir

clear_ball:
    mov ah, 02h           ; Función de mover el cursor
    mov dl, [posX]        ; Columna
    mov dh, [posY]        ; Fila
    mov bh, 0             ; Página de video
    int 10h
    mov ah, 09h           ; Función de escribir carácter y atributo
    mov al, [emptyChar]   ; Caracter de espacio vacío
    mov bl, 07h           ; Atributo de color (gris claro)
    mov cx, 1             ; Número de veces que se imprime el caracter
    int 10h
    ret
update_position:
    call clear_ball  ; Llama a la función que borra la posición actual de la pelota

    ; Actualizar X
    mov al, [posX]  ; Carga la posición X actual de la pelota en el registro al
    add al, [dirX]  ; Suma la dirección X a la posición X

    cmp al, 79
    jle .check_left  ; Si al <= 79, salta a .check_left
    mov al, 78       ; Si al > 79, establece al en 78 (límite derecho)
    mov [dirX], -1   ; Cambia la dirección X a -1 (izquierda)
    jmp .done_x

.check_left:
    cmp al, 0
    jge .done_x  ; Si al >= 0, salta a .done_x
    mov al, 1    ; Si al < 0, establece al en 1 (límite izquierdo)
    mov [dirX], 1  ; Cambia la dirección X a 1 (derecha)
.done_x:
    mov [posX], al  ; Guarda la nueva posición X

    ; Actualizar Y
    mov al, [posY]  ; Carga la posición Y actual de la pelota en el registro al
    add al, [dirY]  ; Suma la dirección Y a la posición Y
    cmp al, 25
    jge .reset_position  ; Si al >= 25, reinicia la posición
    cmp al, -1
    jle .reset_position  ; Si al <= -1, reinicia la posición

    ; Comprobar colisiones superiores e inferiores antes de actualizar posY
    cmp al, [pos_ren]
    jne .check_top_collision  ; Si al no es igual a pos_ren, salta a .check_top_collision

    ; Comprobación de colisión con la barra inferior
    mov bl, [pos_col]
    mov bh, [pos_col]
    add bh, bar_width 
    cmp [posX], bl
    jb .check_top_collision  ; Si [posX] < bl, salta a .check_top_collision
    cmp [posX], bh
    ja .check_top_collision  ; Si [posX] > bh, salta a .check_top_collision
    neg [dirY]  ; Invertir dirección de Y
    jmp .done_y

.check_top_collision:
    cmp al, 24
    jle .check_top  ; Si al <= 24, salta a .check_top
    mov al, 23      ; Si al > 24, establece al en 23 (límite inferior)
    neg [dirY]      ; Invertir dirección de Y
    jmp .done_y

.check_top:
    cmp al, [top_bar_ren]
    jne .done_y  ; Si al no es igual a top_bar_ren, salta a .done_y
    ; Comprobación de colisión con la barra superior
    mov bl, [top_bar_col]
    mov bh, [top_bar_col]
    add bh, bar_width
    cmp [posX], bl
    jb .no_top_bar_collision  ; Si [posX] < bl, salta a .no_top_bar_collision
    cmp [posX], bh
    ja .no_top_bar_collision  ; Si [posX] > bh, salta a .no_top_bar_collision
    neg [dirY]  ; Invertir dirección de Y

.no_top_bar_collision:
.done_y:
    ; Actualizar la posición Y después de comprobar colisiones
    mov [posY], al

    ; Comprobación de colisión con los obstáculos
    cmp al, 10  ; Comprueba si la posición Y de la pelota es igual a 10 (obstáculo en renglón 10)
    je .check_obstacle_collision
    cmp al, 11  ; Comprueba si la posición Y de la pelota es igual a 11 (obstáculo en renglón 11)
    je .check_obstacle_collision
    jmp .check_bottom_collision  ; Continuar a verificar colisiones en la parte inferior

.check_obstacle_collision:
    cmp [posX], 20  ; Comprueba si la posición X de la pelota es igual a 20 (obstáculo en columna 20)
    jl .check_next_obstacle
    cmp [posX], 22  ; Comprueba si la posición X de la pelota es menor que 22 (obstáculo en columna 20 y 21)
    jg .check_next_obstacle
    neg [dirY]  ; Invertir dirección de Y
    jmp .done_y_obstacle

.check_next_obstacle:
    cmp [posX], 60  ; Comprueba si la posición X de la pelota es igual a 60 (obstáculo en columna 60)
    jl .done_y_obstacle
    cmp [posX], 62  ; Comprueba si la posición X de la pelota es menor que 62 (obstáculo en columna 60 y 61)
    jg .done_y_obstacle
    neg [dirY]  ; Invertir dirección de Y
    jmp .done_y_obstacle

    ; Agregar detección de colisiones desde la parte inferior
.check_bottom_collision:
    cmp al, 9  ; Comprueba si la posición Y de la pelota es igual a 9 (justo debajo del obstáculo en renglón 10)
    je .check_bottom_collision_y9
    cmp al, 10  ; Comprueba si la posición Y de la pelota es igual a 10 (justo debajo del obstáculo en renglón 11)
    je .check_bottom_collision_y10
    jmp .done_y_obstacle

.check_bottom_collision_y9:
    cmp [posX], 20  ; Comprueba si la posición X de la pelota es igual a 20 (obstáculo en columna 20)
    jl .check_next_bottom_obstacle
    cmp [posX], 22  ; Comprueba si la posición X de la pelota es menor que 22 (obstáculo en columna 20 y 21)
    jg .check_next_bottom_obstacle
    neg [dirY]  ; Invertir dirección de Y
    jmp .done_y_obstacle

.check_next_bottom_obstacle:
    cmp [posX], 60  ; Comprueba si la posición X de la pelota es igual a 60 (obstáculo en columna 60)
    jl .done_y_obstacle
    cmp [posX], 62  ; Comprueba si la posición X de la pelota es menor que 62 (obstáculo en columna 60 y 61)
    jg .done_y_obstacle
    neg [dirY]  ; Invertir dirección de Y
    jmp .done_y_obstacle

.check_bottom_collision_y10:
    cmp [posX], 20  ; Comprueba si la posición X de la pelota es igual a 20 (obstáculo en columna 20)
    jl .check_next_bottom_obstacle_y10
    cmp [posX], 22  ; Comprueba si la posición X de la pelota es menor que 22 (obstáculo en columna 20 y 21)
    jg .check_next_bottom_obstacle_y10
    neg [dirY]  ; Invertir dirección de Y
    jmp .done_y_obstacle

.check_next_bottom_obstacle_y10:
    cmp [posX], 60  ; Comprueba si la posición X de la pelota es igual a 60 (obstáculo en columna 60)
    jl .done_y_obstacle
    cmp [posX], 62  ; Comprueba si la posición X de la pelota es menor que 62 (obstáculo en columna 60 y 61)
    jg .done_y_obstacle
    neg [dirY]  ; Invertir dirección de Y

.done_y_obstacle:
    mov [posY], al  ; Guarda la nueva posición Y

    ; Actualizar marcador si la pelota llega a la parte superior o inferior
    cmp al, 0
    je .punto_superior  ; Si al == 0, llama a .punto_superior
    cmp al, 24
    je .punto_inferior  ; Si al == 24, llama a .punto_inferior
    ret

.punto_superior:
    cmp jugador_superior, 10
    jge .reset_position  ; Si jugador_superior >= 10, reinicia la posición
    inc jugador_superior  ; Incrementa el marcador del jugador superior
    call draw_score
    call reset_position_after_point
    ret

.punto_inferior:
    cmp jugador_inferior, 10
    jge .reset_position  ; Si jugador_inferior >= 10, reinicia la posición
    inc jugador_inferior  ; Incrementa el marcador del jugador inferior
    call draw_score
    call reset_position_after_point
    ret

.reset_position:
    mov [posX], 40  ; Reinicia la posición X de la pelota al centro
    mov [posY], 12  ; Reinicia la posición Y de la pelota al centro
    ret

draw_ball:
    mov ah, 02h           ; Función de mover el cursor
    mov dl, [posX]        ; Columna
    mov dh, [posY]        ; Fila
    mov bh, 0             ; Página de video
    int 10h
    mov ah, 09h           ; Función de escribir carácter y atributo
    mov al, [ballChar]    ; Caracter de la pelota
    mov bl, 0Eh           ; Atributo de color (amarillo claro)
    mov cx, 1             ; Número de veces que se imprime el caracter
    int 10h
    ret

draw_score:
    ; Dibujar marcador superior
    mov ah, 02h           ; Función de mover el cursor
    mov dl, 12            ; Columna
    mov dh, 0             ; Fila
    mov bh, 0             ; Página de video
    int 10h
    mov ah, 09h           ; Función de escribir carácter y atributo
    mov al, marcador_char ; Carácter del marcador
    mov bl, 0Fh           ; Atributo de color (blanco sobre negro)
    mov cl, jugador_superior
    int 10h

    ; Dibujar marcador inferior
    mov ah, 02h           ; Función de mover el cursor
    mov dl, 12            ; Columna
    mov dh, 24            ; Fila
    mov bh, 0             ; Página de video
    int 10h
    mov ah, 09h           ; Función de escribir carácter y atributo
    mov al, marcador_char ; Carácter del marcador
    mov bl, 0Fh           ; Atributo de color (blanco sobre negro)
    mov cl, jugador_inferior
    int 10h
    ret

reset_position_after_point:
    ; Función para reiniciar la posición de la pelota y continuar el juego
    mov [posX], 40
    mov [posY], 12
    ret

print_string:
    ; Función para imprimir una cadena de caracteres
.next_char:
    lodsb ;Carga un byte en un segmento de datos
    cmp al, 0
    je .done
    mov ah, 0Eh
    int 10h
    jmp .next_char
.done:
    ret

draw_fixed_elements:
    ; Mostrar "Jugador 1" en una posición fija
    mov ah, 02h           ; Función de mover el cursor
    mov dl, 0             ; Columna
    mov dh, 0             ; Fila
    mov bh, 0             ; Página de video
    int 10h
    lea dx, jugador1_msg  ; Cargar dirección del mensaje "|Fin del juego|."
    call print_string

    ; Mostrar "Jugador 2" en una posición fija
    mov ah, 02h           ; Función de mover el cursor
    mov dl, 0             ; Columna
    mov dh, 24            ; Fila
    mov bh, 0             ; Página de video
    int 10h
    lea dx, jugador2_msg  ; Cargar dirección del mensaje "|Fin del juego|."
    call print_string
    ret

delay:
    ; Aumentamos el retraso para reducir la velocidad de la pelota por cada loop
    mov cx, 0FFFFh
.delay_loop1:
    loop .delay_loop1
    mov cx, 0FFFFh
.delay_loop2:
    loop .delay_loop2
    mov cx, 0FFFFh
.delay_loop3:
    loop .delay_loop3
    ret

hide_cursor:
    mov ah, 01h     ; Función 01h - Ocultar cursor
    mov cx, 0100h   ; Ocultar el cursor
    int 10h         ; Llamada a la interrupción del BIOS
    ret

check_keyboard:
    mov ah, 01h         ; Comprueba si una tecla está disponible
    int 16h
    jz no_key_pressed   ; Si no hay tecla, salta a no_key_pressed

    mov ah, 00h   ;espera que se precione una tecla
    int 16h       ;Interactuar con el teclado
    cmp ah, 4Bh         ; Tecla de flecha izquierda
    je mover_izquierda
    cmp ah, 4Dh         ; Tecla de flecha derecha
    je mover_derecha
    cmp ah, 1Eh         ; Tecla 'A'
    je mover_izquierda_superior
    cmp ah, 20h         ; Tecla 'D'
    je mover_derecha_superior
    cmp ah, 1Fh         ; Tecla 'S'
    je toggle_pause     ; Cambiar estado del juego con la tecla 'p'

no_key_pressed:
    ret

toggle_pause:
    cmp game_state, 1
    jne resume_game     ; Si el juego está pausado, reanudarlo
    mov game_state, 0   ; Si el juego está en ejecución, pausarlo
    jmp wait_for_start  ; Esperar una tecla antes de continuar

resume_game:
    mov game_state, 1   ; Si el juego está pausado, reanudarlo
    jmp wait_for_start  ; Esperar una tecla antes de continuar


mover_izquierda:
    call clear_bar   ; Borrar la barra en la posición anterior
    dec pos_col      ; Disminuir la columna
    cmp pos_col, 0
    jl limite_izquierdo
    jmp actualizar_barra

limite_izquierdo:
    inc pos_col     ; Si excede el límite, revertir el cambio
    jmp actualizar_barra

mover_derecha:
    call clear_bar   ; Borrar la barra en la posición anterior
    mov al, pos_col
    add al, bar_width
    cmp al, 79
    jg limite_derecho
    inc pos_col
    jmp actualizar_barra

limite_derecho:
    jmp actualizar_barra

mover_izquierda_superior:
    call clear_top_bar   ; Borrar la barra superior en la posición anterior
    dec top_bar_col      ; Disminuir la columna de la barra superior
    cmp top_bar_col, 0
    jl limite_izquierdo_superior
    jmp actualizar_barra_superior

limite_izquierdo_superior:
    inc top_bar_col     ; Si excede el límite, revertir el cambio
    jmp actualizar_barra_superior

mover_derecha_superior:
    call clear_top_bar   ; Borrar la barra superior en la posición anterior
    mov al, top_bar_col
    add al, bar_width
    cmp al, 79
    jg limite_derecho_superior
    inc top_bar_col
    jmp actualizar_barra_superior

limite_derecho_superior:
    jmp actualizar_barra_superior

actualizar_barra:
    ret

actualizar_barra_superior:
    ret
clear_bar:
    mov dl, pos_col
    mov dh, pos_ren
    mov ah, 02h
    mov bh, 00h
    int 10h
    mov ah, 09h
    mov al, emptyChar
    mov bl, 00001111b   ; Color blanco sobre fondo negro
    mov cx, bar_width
    int 10h
    ret

draw_bar:
    mov dl, pos_col
    mov dh, pos_ren
    mov ah, 02h ; prepara llamada a interrupcion
    mov bh, 00h 
    int 10h
    mov ah, 09h
    mov al, bar_char
    mov bl, 00001111b   ; Color blanco sobre fondo negro
    mov cx, bar_width
    int 10h
    ret

clear_top_bar:
    mov dl, top_bar_col
    mov dh, top_bar_ren
    mov ah, 02h
    mov bh, 00h
    int 10h
    mov ah, 09h
    mov al, emptyChar
    mov bl, 00001111b   ; Color blanco sobre fondo negro
    mov cx, bar_width
    int 10h
    ret

draw_top_bar:
    mov dl, top_bar_col
    mov dh, top_bar_ren
    mov ah, 02h
    mov bh, 00h
    int 10h
    mov ah, 09h
    mov al, top_bar_char
    mov bl, 00001111b   ; Color blanco sobre fondo negro
    mov cx, bar_width
    int 10h
    ret

clear_screen:
    mov ax, 0600h   ; Función 06h - scroll window up (desplazar ventana hacia arriba)
    mov bh, 07h     ; Color del fondo (negro)
    mov cx, 0       ; Número de líneas a desplazar
    mov dx, 184fh   ; Esquina superior izquierda de la ventana (0, 0)
    int 10h         ; Llamada a la interrupción del BIOS
    ret

draw_obstaculos:
    ; Dibuja los dos obstáculos
    call draw_obstaculo1
    call draw_obstaculo2
    ret

draw_obstaculo1:
    ; Dibuja el obstáculo 1 (2x2)
    mov cx, 2
    mov dl, [obstaculo1_col]
    mov dh, [obstaculo1_ren]
.draw_loop1_row:
    push cx
    mov cx, 2
.draw_loop1_col:
    mov ah, 02h   ;Coloca el cursor en pantalla
    mov bh, 00h   ; Pagina de video
    int 10h       ;Prepara la BIOS
    mov ah, 09h   ;Imprime en pantalla
    mov al, obstaculo_char
    mov bl, 00001111b   ; Color blanco sobre fondo negro
    mov cx, 1
    int 10h
    inc dl
    loop .draw_loop1_col
    pop cx
    loop .draw_loop1_row
    ret

draw_obstaculo2:
    ; Dibuja el obstáculo 2 (2x2)
    mov cx, 2
    mov dl, [obstaculo2_col]
    mov dh, [obstaculo2_ren]
.draw_loop2_row:
    push cx
    mov cx, 2
.draw_loop2_col:
    mov ah, 02h
    mov bh, 00h
    int 10h
    mov ah, 09h
    mov al, obstaculo_char
    mov bl, 00001111b   ; Color blanco sobre fondo negro
    mov cx, 1
    int 10h
    inc dl
    loop .draw_loop2_col
    pop cx
    ;inc dh
    loop .draw_loop2_row
    ret
salir:
    mov ah, 01h     ; Función 01h - Mostrar cursor
    mov cx, 0107h   ; Mostrar el cursor con parpadeo
    int 10h         ; Llamada a la interrupción del BIOS
    mov ax, 4C00h   ; Función 4Ch - Salir del programa
    int 21h         ; Llamada a la interrupción del DOS

end main