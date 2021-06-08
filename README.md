Instrucciones de compilación:
Basicamente compila de la misma manera que el ejemplo del video con la diferencia que este programa fue llamado Visor.

En la terminal usar:
make visor
./bin/visor models/"file.obj"

En el makefile se incluyen además los targets "visor4threads" y "visor24threads", ya que quise ver si habia alguna diferencia, pero aparentemente no, ya que probablemente se necesita optimizar el codigo para multithreading. Sería interesante ver como se puede correr el código en multithreading y cómo esto mejora la velocidad de compilación. Si no me equivoco el .obj que más me demoró en compilar fue neptune.obj con un tiempo aprox de 3 segs. (esto en un Ryzen9 3900X)

Supuestos del código:
Se usó el supuesto de que no hay caras de más de 5 lados, sin embargo implementar estos casos no es difícil. 
Basta con agregar su definición a la typeclass Shape, y a las funciones shapeClassifier y createTrianglesFromShape.
Creo que los nombres de las funciones (bien largos en algunos casos) y los comentarios permiten entender bien que se está haciendo en el código.
La experiencia del visor se puede personalizar en los parámetros de la función rotationBucle, su lista de parámetros es:

xiθ yiθ ziθ rxθ ryθ rzθ delay renderx rendery triangleList

donde:
xiθ yiθ ziθ     = es el vector que determina el ángulo inicial de la figura (por defecto 0 0 0)
rxθ ryθ rzθ     = es el vector que determina el cambio en la rotación del ángulo en cada frame (por defecto 0.05 0.5 0.05)
delay           = es el delay en milisegundos para threadDelay (por defecto 120000)
renderx rendery = es el espacio de renderizado (por defecto 80 40)
triangleList    = es la lista de triangulos recibidos de la función asciiRenderListFormat