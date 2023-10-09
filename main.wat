(module
  (memory 1)
  (export "memory" (memory 0))

  (global $pointSize i32 (i32.const 16)) ;; f64, f64
  (global $measureSize i32 (i32.const 16)) ;; i32, i32, f64
  (global $constraintSize i32 (i32.const 4)) ;; i32
  (global $dependentSize i32 (i32.const 20)) ;; i32, i32, i32, f64

  (func $pointCoordinates
    (param $pointsAddr i32) ;; array of {x: f64, y: f64}
    (param $pointIdx i32) ;; index of point
    (result f64 f64) ;; x, y
    (local $pointAddr i32)

    (local.set $pointAddr (i32.add
      (local.get $pointsAddr)
      (i32.mul (local.get $pointIdx) (global.get $pointSize))))

    (return
      (f64.load (local.get $pointAddr))
      (f64.load (i32.add (local.get $pointAddr) (i32.const 8)))))

  (func $pointsDistance
    (param $pointsAddr i32) ;; array of {x: f64, y: f64}
    (param $pointIdx1 i32) ;; index of point 1
    (param $pointIdx2 i32) ;; index of point 2
    (result f64) ;; distance between points
    (local $x1 f64)
    (local $y1 f64)
    (local $x2 f64)
    (local $y2 f64)
    (local $dx f64)
    (local $dy f64)

    (call $pointCoordinates (local.get $pointsAddr) (local.get $pointIdx1))
    local.set $y1 ;; y was returned last, so it's on top
    local.set $x1

    (call $pointCoordinates (local.get $pointsAddr) (local.get $pointIdx2))
    local.set $y2
    local.set $x2

    ;; dx = x2 - x1
    (local.set $dx (f64.sub
      (local.get $x2)
      (local.get $x1)))
    (local.set $dy (f64.sub
      (local.get $y2)
      (local.get $y1)))

    ;; sqrt(dx * dx + dy * dy)
    (return (f64.sqrt (f64.add
      (f64.mul (local.get $dx) (local.get $dx))
      (f64.mul (local.get $dy) (local.get $dy))))))

  (func $addPoint
    (param $array i32)
    (param $arrayLen i32)
    (param $x f64)
    (param $y f64)
    (result i32) ;; new length of array

    (f64.store
      (i32.add
        (i32.add (local.get $array) (i32.mul (local.get $arrayLen) (global.get $pointSize)))
        (i32.const 0)) ;; field offset
      (local.get $x))
    (f64.store
      (i32.add
        (i32.add (local.get $array) (i32.mul (local.get $arrayLen) (global.get $pointSize)))
        (i32.const 8)) ;; field offset
      (local.get $y))

    (return (i32.add (local.get $arrayLen) (i32.const 1))))

  (func $addMeasure
    (param $array i32)
    (param $arrayLen i32)
    (param $pointIdx1 i32)
    (param $pointIdx2 i32)
    (param $distance f64)
    (result i32) ;; new length of array

    (i32.store
      (i32.add
        (i32.add (local.get $array) (i32.mul (local.get $arrayLen) (global.get $measureSize)))
        (i32.const 0)) ;; field offset
      (local.get $pointIdx1))
    (i32.store
      (i32.add
        (i32.add (local.get $array) (i32.mul (local.get $arrayLen) (global.get $measureSize)))
        (i32.const 4)) ;; field offset
      (local.get $pointIdx2))
    (f64.store
      (i32.add
        (i32.add (local.get $array) (i32.mul (local.get $arrayLen) (global.get $measureSize)))
        (i32.const 8)) ;; field offset
      (local.get $distance))

    (return (i32.add (local.get $arrayLen) (i32.const 1))))

  (func $addDependent
    (param $array i32)
    (param $arrayLen i32)
    (param $pointIdx i32)
    (param $neighborIdx i32)
    (param $towardsIdx i32)
    (param $neighborDistance f64)
    (result i32) ;; new length of array
    (local $structAddr i32)

    (local.set $structAddr
      (i32.add (local.get $array)
        (i32.mul (local.get $arrayLen) (global.get $dependentSize))))

    (i32.store
      (i32.add (local.get $structAddr) (i32.const 0))
      (local.get $pointIdx))
    (i32.store
      (i32.add (local.get $structAddr) (i32.const 4))
      (local.get $neighborIdx))
    (i32.store
      (i32.add (local.get $structAddr) (i32.const 8))
      (local.get $towardsIdx))
    (f64.store
      (i32.add (local.get $structAddr) (i32.const 12))
      (local.get $neighborDistance))

    (return (i32.add (local.get $arrayLen) (i32.const 1))))

  (func $updateGradient
    (param $pointsAddr i32)
    (param $gradientsAddr i32)
    (param $measure i32)  ;; address of { pointIdx1: i32, pointIdx2: i32, distance: f64 }
    (result)
    (local $distance f64)
    (local $distanceError f64)
    (local $x1 f64)
    (local $y1 f64)
    (local $x2 f64)
    (local $y2 f64)
    (local $dx f64)
    (local $dy f64)
    (local $gradX f64)
    (local $gradY f64)
    (local $gradAddr i32)

    (call $pointCoordinates (local.get $pointsAddr) (i32.load (i32.add (local.get $measure) (i32.const 0))))
    local.set $y1 ;; y was returned last, so it's on top
    local.set $x1

    (call $pointCoordinates (local.get $pointsAddr) (i32.load (i32.add (local.get $measure) (i32.const 4))))
    local.set $y2
    local.set $x2

    ;; dx = x2 - x1
    (local.set $dx (f64.sub
      (local.get $x2)
      (local.get $x1)))
    (local.set $dy (f64.sub
      (local.get $y2)
      (local.get $y1)))

    ;; sqrt(dx * dx + dy * dy)
    (local.set $distance (f64.sqrt (f64.add
      (f64.mul (local.get $dx) (local.get $dx))
      (f64.mul (local.get $dy) (local.get $dy)))))
    (local.set $distanceError (f64.sub
      (f64.load (i32.add (local.get $measure) (i32.const 8)))
      (local.get $distance)))

    (local.set $gradX (f64.mul
      (local.get $distanceError)
      (f64.div (local.get $dx) (local.get $distance))))
    (local.set $gradY (f64.mul
      (local.get $distanceError)
      (f64.div (local.get $dy) (local.get $distance))))

    ;; update point 2
    (local.set $gradAddr
      (i32.add (local.get $gradientsAddr)
        (i32.mul (global.get $pointSize) (i32.load (i32.add (local.get $measure) (i32.const 4))))))

    (f64.store
      (i32.add (local.get $gradAddr) (i32.const 0)) ;; update x
      (f64.add (f64.load (i32.add (local.get $gradAddr) (i32.const 0)))
        (local.get $gradX)))
    (f64.store
      (i32.add (local.get $gradAddr) (i32.const 8)) ;; update y
      (f64.add (f64.load (i32.add (local.get $gradAddr) (i32.const 8)))
        (local.get $gradY)))

    ;; update point 1, flip gradient
    (local.set $gradAddr
      (i32.add (local.get $gradientsAddr)
        (i32.mul (global.get $pointSize) (i32.load (i32.add (local.get $measure) (i32.const 0))))))
    (local.set $gradX (f64.mul (local.get $gradX) (f64.const -1.0)))
    (local.set $gradY (f64.mul (local.get $gradY) (f64.const -1.0)))

    (f64.store
      (i32.add (local.get $gradAddr) (i32.const 0)) ;; update x
      (f64.add (f64.load (i32.add (local.get $gradAddr) (i32.const 0)))
        (local.get $gradX)))
    (f64.store
      (i32.add (local.get $gradAddr) (i32.const 8)) ;; update y
      (f64.add (f64.load (i32.add (local.get $gradAddr) (i32.const 8)))
        (local.get $gradY)))

    (return))

  (func $updateDependent
    (param $pointsAddr i32)
    (param $dependent i32) ;; address of { point: i32, neighbor: i32, towards: i32, distance: f64 }
    (result)
    (local $pointPosAddr i32) ;; address of currently modified coordinate of point
    (local $neighborPosAddr i32)
    (local $towardsPosAddr i32)
    (local $neighborPos f64)
    (local $posDelta f64)
    (local $fullDistance f64)
    (local $neighborDistance f64)

    (local.set $fullDistance (call $pointsDistance (local.get $pointsAddr)
      (i32.load (i32.add (local.get $dependent) (i32.const 4))) ;; neighborIdx
      (i32.load (i32.add (local.get $dependent) (i32.const 8))) ;; towardsIdx
    ))
    (local.set $neighborDistance (f64.load
      (i32.add (local.get $dependent) (i32.const 12)) ;; neighborDistance
    ))

    (local.set $pointPosAddr (i32.add (local.get $pointsAddr) (i32.mul (global.get $pointSize)
      (i32.load (i32.add (local.get $dependent) (i32.const 0))) ;; pointIdx
    )))
    (local.set $neighborPosAddr (i32.add (local.get $pointsAddr) (i32.mul (global.get $pointSize)
      (i32.load (i32.add (local.get $dependent) (i32.const 4))) ;; neighborIdx
    )))
    (local.set $towardsPosAddr (i32.add (local.get $pointsAddr) (i32.mul (global.get $pointSize)
      (i32.load (i32.add (local.get $dependent) (i32.const 8))) ;; towardsIdx
    )))

    (local.set $neighborPos (f64.load (local.get $neighborPosAddr)))
    (local.set $posDelta (f64.sub (f64.load (local.get $towardsPosAddr)) (local.get $neighborPos)))
    (f64.store (local.get $pointPosAddr) (f64.add
      (local.get $neighborPos)
      (f64.mul
        (local.get $neighborDistance)
        (f64.div (local.get $posDelta) (local.get $fullDistance)))))

    ;; do y coordinate: move all addresses 8 bytes up
    (local.set $pointPosAddr (i32.add (local.get $pointPosAddr) (i32.const 8)))
    (local.set $neighborPosAddr (i32.add (local.get $neighborPosAddr) (i32.const 8)))
    (local.set $towardsPosAddr (i32.add (local.get $towardsPosAddr) (i32.const 8)))

    (local.set $neighborPos (f64.load (local.get $neighborPosAddr)))
    (local.set $posDelta (f64.sub (f64.load (local.get $towardsPosAddr)) (local.get $neighborPos)))
    (f64.store (local.get $pointPosAddr) (f64.add
      (local.get $neighborPos)
      (f64.mul
        (local.get $neighborDistance)
        (f64.div (local.get $posDelta) (local.get $fullDistance)))))

    (return))

  (func $increaseGradient
    (param $gradientsAddr i32) ;; array of {x: f64, y: f64}
    (param $thisPointIdx i32) ;; index of increased gradient
    (param $otherPointIdx i32) ;; index of gradient value to change by
    (result)
    (local $thisGradAddr i32)
    (local $otherGradAddr i32)

    (local.set $thisGradAddr (i32.add (local.get $gradientsAddr) (i32.mul (global.get $pointSize) (local.get $thisPointIdx))))
    (local.set $otherGradAddr (i32.add (local.get $gradientsAddr) (i32.mul (global.get $pointSize) (local.get $otherPointIdx))))

    ;; this = this + other
    (f64.store (local.get $thisGradAddr) (f64.add (f64.load (local.get $thisGradAddr)) (f64.load (local.get $otherGradAddr))))

    ;; do y coordinate: move all addresses 8 bytes up
    (local.set $thisGradAddr (i32.add (local.get $thisGradAddr) (i32.const 8)))
    (local.set $otherGradAddr (i32.add (local.get $otherGradAddr) (i32.const 8)))

    (f64.store (local.get $thisGradAddr) (f64.add (f64.load (local.get $thisGradAddr)) (f64.load (local.get $otherGradAddr))))

    (return))

  (func $increaseNeighborGradient
    (param $gradientsAddr i32) ;; array of {x: f64, y: f64}
    (param $dependent i32) ;; address of { point: i32, neighbor: i32, towards: i32, distance: f64 }
    (result)

    (call $increaseGradient
      (local.get $gradientsAddr)
      (i32.load (i32.add (local.get $dependent) (i32.const 4))) ;; neighborIdx as this
      (i32.load (i32.add (local.get $dependent) (i32.const 0))) ;; pointIdx as other
      )

    (return))

  (func $main
    (result i32) ;; exit code, 0 for success

    ;; points: {f64, f64}[]
    (local $pointsAddr i32)
    (local $pointsLen i32)
    ;; gradients: {f64, f64}[pointsLen]
    (local $gradientsAddr i32)
    ;; measures: {i32, i32, f64}[]
    (local $measuresAddr i32)
    (local $measuresLen i32)
    ;; constraints: i32[]
    (local $constraintsAddr i32)
    (local $constraintsLen i32)
    ;; $dependents: {pointIdx: i32, neighborIdx: i32, towardsIdx: i32, neighborDistance: f64}[]
    (local $dependentsAddr i32)
    (local $dependentsLen i32)

    ;; loop counters
    (local $i i32)
    (local $j i32)
    (local $offset i32)

    ;; optimization parameters
    (local $stepSize f64) ;; by what part of error update the point position

    (local.set $stepSize (f64.const 0.1))

    (local.set $pointsAddr (i32.const 0))
    (local.set $pointsLen (i32.const 0))
    (local.set $gradientsAddr (i32.add (local.get $pointsAddr)
      (i32.mul (global.get $pointSize) (i32.const 20)))) ;; max 20 points
    (local.set $measuresAddr (i32.add (local.get $gradientsAddr)
      (i32.sub (local.get $gradientsAddr) (local.get $pointsAddr)))) ;; gradients[] is same size as points[]
    (local.set $measuresLen (i32.const 0))
    (local.set $constraintsAddr (i32.add (local.get $measuresAddr)
      (i32.mul (global.get $measureSize) (i32.const 40)))) ;; max 40 measures
    (local.set $constraintsLen (i32.const 0))
    (local.set $dependentsAddr (i32.add (local.get $constraintsAddr)
      (i32.mul (global.get $constraintSize (i32.const 20))))) ;; max 20 constraints
    (local.set $dependentsLen (i32.const 0))

    ;; points = { A, B, C, F, G, H, A', B', C', G' }
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 0.0) (f64.const 0.0))) ;; point A
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 0.0) (f64.const 1250.0))) ;; point B
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 900.0) (f64.const 1250.0))) ;; point C
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 1000.0) (f64.const 700.0))) ;; point F roughly
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 1800.0) (f64.const 800.0))) ;; point G
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 1785.0) ;; point H.x
      (f64.sub (f64.const 1252.0) (f64.const 1134.0)))) ;; H.y = AA' = AB - A'B
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 0.0) (f64.sub (f64.const 1252.0) (f64.const 1134.0)))) ;; point A'
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 0.0) (f64.const 1230.0))) ;; point B'
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 880.0) (f64.const 1250.0))) ;; point C'
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 1800.0) (f64.const 780.0))) ;; point G'

    ;; measures
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 1) (i32.const 2) (f64.const 909.0))) ;; BC
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 1) (f64.const 1252.0))) ;; AB
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 8) (f64.const 1543.0))) ;; AC'
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 3) (f64.const 1458.0))) ;; AF
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 9) (f64.const 1961.0))) ;; AG'
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 4) (i32.const 3) (f64.const 590.0))) ;; GF
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 5) (f64.const 1785.0))) ;; AH
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 7) (i32.const 5) (f64.const 2078.0))) ;; B'H
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 3) (i32.const 5) (f64.const 928.0))) ;; FH
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 4) (i32.const 5) (f64.const 714.0))) ;; GH

    ;; constraints = { A.x, A.y, B.x }
    (i32.store (i32.add (local.get $constraintsAddr) (i32.mul (local.get $constraintsLen) (global.get $constraintSize)))
      (i32.const 0)) ;; A.x
    (local.set $constraintsLen (i32.add (local.get $constraintsLen) (i32.const 1)))
    (i32.store (i32.add (local.get $constraintsAddr) (i32.mul (local.get $constraintsLen) (global.get $constraintSize)))
      (i32.const 1)) ;; A.y
    (local.set $constraintsLen (i32.add (local.get $constraintsLen) (i32.const 1)))
    (i32.store (i32.add (local.get $constraintsAddr) (i32.mul (local.get $constraintsLen) (global.get $constraintSize)))
      (i32.const 2)) ;; B.x
    (local.set $constraintsLen (i32.add (local.get $constraintsLen) (i32.const 1)))

    ;; dependents = {
    ;;   A' close to A towards B, 1252-1134 mm away
    ;;   B' close to B towards A, 20 mm away
    ;;   C' close to C towards B, 20 mm away
    ;;   G' close to G towards H, 20 mm away
    ;; }
    (local.set $dependentsLen (call $addDependent (local.get $dependentsAddr) (local.get $dependentsLen)
      (i32.const 6) (i32.const 0) (i32.const 1) (f64.sub (f64.const 1252.0) (f64.const 1134.0)))) ;; A'
    (local.set $dependentsLen (call $addDependent (local.get $dependentsAddr) (local.get $dependentsLen)
      (i32.const 7) (i32.const 1) (i32.const 0) (f64.const 20))) ;; B'
    (local.set $dependentsLen (call $addDependent (local.get $dependentsAddr) (local.get $dependentsLen)
      (i32.const 8) (i32.const 2) (i32.const 1) (f64.const 20))) ;; C'
    (local.set $dependentsLen (call $addDependent (local.get $dependentsAddr) (local.get $dependentsLen)
      (i32.const 9) (i32.const 4) (i32.const 5) (f64.const 20))) ;; G'

    ;; do N times {
    ;;   clear gradients
    ;;   place dependent points
    ;;   foreach measure update gradients
    ;;   foreach dependent add gradient to neighbor
    ;;   foreach constraint clear gradient
    ;;   foreach gradient move point a bit
    ;; }
    (local.set $i (i32.const 0))
    (block $mainLoopBreak (loop $mainLoop

      ;; for (j = 0; j < 2 * pointsLen; j++)
      (local.set $j (i32.const 0))
      (loop $gradientLoop

        ;; *(gradients + j * sizeof(f64)) = 0.0
        (f64.store (i32.add (local.get $gradientsAddr) (i32.mul (local.get $j) (i32.const 8))) (f64.const 0.0))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $gradientLoop (i32.lt_s (local.get $j) (i32.mul (i32.const 2) (local.get $pointsLen)))))

      ;; for (j = 0; j < dependentsLen; j++)
      (local.set $j (i32.const 0))
      (loop $dependentLoop

        (call $updateDependent (local.get $pointsAddr)
          (i32.add (local.get $dependentsAddr) (i32.mul (global.get $dependentSize) (local.get $j))))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $dependentLoop (i32.lt_s (local.get $j) (local.get $dependentsLen))))

      ;; for (j = 0; j < measuresLen; j++)
      (local.set $j (i32.const 0))
      (loop $measureLoop

        (call $updateGradient (local.get $pointsAddr) (local.get $gradientsAddr)
          (i32.add (local.get $measuresAddr) (i32.mul (global.get $measureSize) (local.get $j))))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $measureLoop (i32.lt_s (local.get $j) (local.get $measuresLen))))

      ;; for (j = 0; j < dependentsLen; j++)
      (local.set $j (i32.const 0))
      (loop $dependentLoop

        (call $increaseNeighborGradient (local.get $gradientsAddr)
          (i32.add (local.get $dependentsAddr) (i32.mul (global.get $dependentSize) (local.get $j))))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $dependentLoop (i32.lt_s (local.get $j) (local.get $dependentsLen))))

      ;; for (j = 0; j < constraintsLen; j++)
      (local.set $j (i32.const 0))
      (loop $constraintLoop

        (f64.store
          (i32.add (local.get $gradientsAddr) (i32.mul (i32.const 8) (i32.load
            (i32.add (local.get $constraintsAddr) (i32.mul (global.get $constraintSize) (local.get $j))))))
          (f64.const 0))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $constraintLoop (i32.lt_s (local.get $j) (local.get $constraintsLen))))

      ;; for (j = 0; j < 2 * pointsLen; j++)
      (local.set $j (i32.const 0))
      (loop $updateLoop

        ;; address of processed point coordinate
        (local.set $offset (i32.add (local.get $pointsAddr) (i32.mul (i32.const 8) (local.get $j))))

        (f64.store (local.get $offset) (f64.add (f64.load (local.get $offset))
          (f64.mul (local.get $stepSize)
            (f64.load (i32.add (local.get $offset) (i32.sub (local.get $gradientsAddr) (local.get $pointsAddr)))))))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $updateLoop (i32.lt_s (local.get $j) (i32.mul (i32.const 2) (local.get $pointsLen)))))

      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $mainLoop (i32.lt_s (local.get $i) (i32.const 1000))))) ;; loop while i < 1000; i++

    (return (i32.const 0)))
  (export "main" (func $main))

  (func $testPythagoreanDist
    (result f64)

    ;; &points = 0
    ;; points = {
    ;;   { 0.0, 0.0 },
    ;;   { 3.0, 4.0 },
    ;; }
    (f64.store (i32.const 0) (f64.const 0.0))
    (f64.store (i32.const 8) (f64.const 0.0))
    (f64.store (i32.const 16) (f64.const 3.0))
    (f64.store (i32.const 24) (f64.const 4.0))

    (return (call $pointsDistance
      (i32.const 0)
      (i32.const 0)
      (i32.const 1))))
  (export "testPythagoreanDist" (func $testPythagoreanDist))

  (func $multiVal
    (result i32 i32)
    (return (i32.const 3) (i32.const 5)))

  (func $testMultiVal
    (result i32)
    (return (i32.add (call $multiVal)))) ;; will just be passed as multiple arguments
  (export "testMultiVal" (func $testMultiVal))
)