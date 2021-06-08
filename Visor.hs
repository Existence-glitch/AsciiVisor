import System.IO (readFile)
import System.Environment
import AsciiRender
import Control.Concurrent
import Data.List
import Data.Array(Array,(!))
import Data.Array.IArray(listArray)

          -- Figure [Vertex 1] ...... [Vertex n]
data Shape = Triangle' Vec3 Vec3 Vec3 Color |
             Rectangle Vec3 Vec3 Vec3 Vec3 | 
             Pentagon Vec3 Vec3 Vec3 Vec3 Vec3
             deriving (Show)

--Función que entrega el vector que representa al centro de la Bounding Box
boundingBoxCenter :: [[Float]] -> Vec3
boundingBoxCenter vertexList = (promX, promY, promZ)
    where
    xs = [coordUnzipper(getIndexes vertex [0])| vertex <- vertexList]
    ys = [coordUnzipper(getIndexes vertex [1])| vertex <- vertexList]
    zs = [coordUnzipper(getIndexes vertex [2])| vertex <- vertexList]
    maxX = maximum xs
    maxY = maximum ys
    maxZ = maximum zs
    minX = minimum xs
    minY = minimum ys
    minZ = minimum zs
    promX = (maxX+minX)/2
    promY = (maxY+minY)/2
    promZ = (maxZ+minZ)/2

--Función que recibe el vector centro de la Bounding Box y calcula la transformación necesaria que se le debe aplicar a cada vector para centrar la figura en el origen.
boundingBoxCenterDistanceToOrigin :: Vec3 -> Vec3
boundingBoxCenterDistanceToOrigin (centerX, centerY, centerZ) = (xDistanceto0, yDistanceto0, zDistanceto0)
    where
    xDistanceto0 = 0-centerX
    yDistanceto0 = 0-centerY
    zDistanceto0 = 0-centerZ

--Función que recibe la lista de vectores centrados y entrega el vector más alejado del origen encontrado en la lista.
farthestVectorfromOrigin :: [[Float]] -> Vec3
farthestVectorfromOrigin vertexListCentered = (farthestX, farthestY, farthestZ)
    where
    xs = [coordUnzipper(getIndexes vertex [0])| vertex <- vertexListCentered]
    ys = [coordUnzipper(getIndexes vertex [1])| vertex <- vertexListCentered]
    zs = [coordUnzipper(getIndexes vertex [2])| vertex <- vertexListCentered]
    maxX = maximum xs
    maxY = maximum ys
    maxZ = maximum zs
    minX = minimum xs
    minY = minimum ys
    minZ = minimum zs
    farthestX = if (minimum [(1-maxX),(1+minX)] == (1-maxX)) then maxX else minX
    farthestY = if (minimum [(1-maxY),(1+minY)] == (1-maxY)) then maxY else minY
    farthestZ = if (minimum [(1-maxZ),(1+minZ)] == (1-maxZ)) then maxZ else minZ

--Función que recibe un vector y la lista de coordenadas (vértice), para aplicar la transformación del vector al vértice.
moveVertex :: Vec3 -> [Float] -> [Float]
moveVertex (xDistanceto0,yDistanceto0,zDistanceto0) [x,y,z] = [x+xDistanceto0,y+yDistanceto0,z+zDistanceto0]

--Función que escala un vértice por (1/(2*mag)), recibiendo el vector más alejado del origen y un vértice.
scaleVertex :: Vec3 -> [Float] -> [Float]
scaleVertex (farthestX, farthestY, farthestZ) [x,y,z] = [scaledX, scaledY, scaledZ]
    where
    magFarthestVector = mag (farthestX, farthestY, farthestZ)
    scaledX = x*(1/(2*magFarthestVector))
    scaledY = y*(1/(2*magFarthestVector))
    scaledZ = z*(1/(2*magFarthestVector))

getIndexes :: [a] -> [Int] -> [a]
getIndexes xs is = let
    arr = listArray (0, length xs-1) xs
    in map (arr!) is

stringListToFloat :: [[String]] -> [[Float]]
stringListToFloat stringList = let
    convertedList = [[(read c :: Float)  | c <- coord] | coord <- stringList]
    in convertedList

stringListToInt :: [[String]] -> [[Int]]
stringListToInt stringList = let
    convertedList = [[((read c :: Int)-1)  | c <- coord] | coord <- stringList]
    in convertedList

tuplifyCoordinates :: [Float] -> Vec3
tuplifyCoordinates [x,y,z] = (x,y,z)

coordUnzipper :: [Float] -> Float
coordUnzipper [x] = x

vectorUnzipper :: [Vec3] -> Vec3
vectorUnzipper [(x,y,z)] = (x,y,z)

--Función que permite parsear strings hasta la aparición de cierto caracter deseado.
takeUntil :: String -> String -> String
takeUntil [] [] = []
takeUntil xs [] = []
takeUntil [] ys = []
takeUntil xs (y:ys) = if isPrefixOf xs (y:ys)
                      then []
                      else y:(takeUntil xs (tail (y:ys)))

--Función que clasifica una cara en una figura del tipo Shape, de acuerdo a la cantidad de lados que esta tenga.
shapeClassifier :: [Vec3] -> Shape
shapeClassifier face
    |(length face == 3) = Triangle' v1 v2 v3 Norm
    |(length face == 4) = Rectangle v1 v2 v3 v4
    |(length face == 5) = Pentagon v1 v2 v3 v4 v5
    where 
    v1 = (vectorUnzipper(getIndexes face [0]))
    v2 = (vectorUnzipper(getIndexes face [1]))
    v3 = (vectorUnzipper(getIndexes face [2]))
    v4 = (vectorUnzipper(getIndexes face [3]))
    v5 = (vectorUnzipper(getIndexes face [4]))

--Función que transforma figuras a triángulos.
createTrianglesfromShape :: Shape -> [Triangle]
createTrianglesfromShape (Triangle' v1 v2 v3 Norm) = [Triangle v1 v2 v3 Norm]
createTrianglesfromShape (Rectangle v1 v2 v3 v4)   = [(Triangle v1 v2 v3 Norm), (Triangle v1 v3 v4 Norm)]
createTrianglesfromShape (Pentagon v1 v2 v3 v4 v5) = [(Triangle v1 v2 v5 Norm), (Triangle v2 v3 v5 Norm), (Triangle v3 v4 v5 Norm)]

--Función que rota un triángulo en los 3 ejes.
rotateTriangle :: Float -> Float -> Float -> Triangle -> Triangle
rotateTriangle xθ yθ zθ (Triangle v1 v2 v3 Norm) = (Triangle (rotatedV1) (rotatedV2) (rotatedV3) Norm)
    where
    rotatedV1 = rotateZ zθ (rotateY yθ (rotateX xθ v1))
    rotatedV2 = rotateZ zθ (rotateY yθ (rotateX xθ v2))
    rotatedV3 = rotateZ zθ (rotateY yθ (rotateX xθ v3))

--Función que aplica la transformación (0.5+x, 0.5-y, z) a cada vector de un triángulo.
transformateTriangle :: Triangle -> Triangle
transformateTriangle (Triangle (x1,y1,z1) (x2,y2,z2) (x3,y3,z3) Norm) = (Triangle (0.5+x1, 0.5-y1, z1) (0.5+x2, 0.5-y2, z2) (0.5+x3, 0.5-y3, z3) Norm)

--Función que parsea las lineas del archivo .obj que nos interesan.
asciiParser :: [Char] -> [Char] -> [[String]]
asciiParser linetype content = let
    --[[String]] Lista de lineas donde cada linea posee una lista de coordenadas en formato String
    coordList = map tail (map words (filter (isPrefixOf linetype) (lines content)))
    --Filtrar la lista de modo que se lea las coordenadas correctamente (transforma "x/n" a "x")
    filteredCoordList = [[(takeUntil "/" c)  | c <- coord] | coord <- coordList]
    in filteredCoordList

--Función que transforma el contenido del archivo a leer a la lista de triangulos pedida por render.
asciiRenderListFormat :: [Char] -> [Triangle]
asciiRenderListFormat content = let
    --[[Float]] Lista de vértices donde cada vértice tiene su lista de coordenadas.
    vertexList         = stringListToFloat (asciiParser "v " content)
    --[[Int]] Lista de caras donde cada cara tiene su lista de índices.
    facesList          = stringListToInt (asciiParser "f " content)
    --(Vec3) Vector que posee las coordenadas del centro de la Bounding Box.
    centerVector       = boundingBoxCenter vertexList
    --(Vec3) Vector que debe aplicarse a todos los vértices para centrar la figura.
    moveToOrigin       = boundingBoxCenterDistanceToOrigin centerVector
    --[[Float]] Lista de vértices centrados.
    vertexListCentered = [moveVertex moveToOrigin vertex | vertex <- vertexList]
    --Vec3 Vector mas alejado del origen encontrado en la lista de vértices centrados.
    farthestVector     = farthestVectorfromOrigin vertexListCentered
    --[Vec3] Lista de vértices centrados escalados.
    vertexListScaled   = [tuplifyCoordinates (scaleVertex farthestVector vertex) | vertex <- vertexListCentered]
    --[[Vec3]] Lista de caras donde cada cara tiene su lista de vértices y cada vértice es una tupla de tipo Vec3.
    facesVertexTuples  = [getIndexes vertexListScaled face | face <- facesList]
    --[Shape] Lista de figuras clasificadas (sin convertir a triángulos).
    shapesList         = [shapeClassifier (face) | face <- facesVertexTuples]
    --[[Triangle]] Lista de figuras donde cada figura tiene su lista de triángulos.
    shapesTriangleList = [createTrianglesfromShape shape | shape <- shapesList]
    --[Triangle] Lista de triángulos en formato para entregar a render.
    triangleList       = concat shapesTriangleList
    in triangleList

--Bucle recursivo infinito que rota y printea cada frame de la figura en la terminal.
rotationBucle :: Float -> Float -> Float -> Float -> Float -> Float -> Int -> Int -> Int -> [Triangle] -> IO ()
rotationBucle xiθ yiθ ziθ rxθ ryθ rzθ delay renderx rendery triangleList = do
    let rotatedTransformedTriangleList = [transformateTriangle (rotateTriangle xiθ yiθ ziθ triangle) | triangle <- triangleList]
    putStrLn "\x1b[H"
    putStrLn $ render renderx rendery rotatedTransformedTriangleList
    threadDelay delay
    rotationBucle (xiθ+rxθ) (yiθ+ryθ) (ziθ+rzθ) rxθ ryθ rzθ delay renderx rendery triangleList

main = do
    args <- getArgs
    content <- readFile (head args)
    rotationBucle 0 0 0 0.05 0.5 0.05 120000 80 40 (asciiRenderListFormat content)
