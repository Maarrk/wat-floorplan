(module
  (memory 1)
  (global $pointSize i32 (i32.const 16)) ;; f64, f64
  (global $measureSize i32 (i32.const 16)) ;; i32, i32, f64
  (global $constraintSize i32 (i32.const 4)) ;; i32

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

    ;; x1 = points[pointIdx1];
    (local.set $x1 (f64.load
      (i32.add (local.get $pointsAddr)
        (i32.mul (local.get $pointIdx1) (global.get $pointSize)))))
    (local.set $y1 (f64.load
      (i32.add (local.get $pointsAddr)
        (i32.add (i32.const 8) ;; sizeof double
          (i32.mul (local.get $pointIdx1) (global.get $pointSize))))))
    (local.set $x2 (f64.load
      (i32.add (local.get $pointsAddr)
        (i32.mul (local.get $pointIdx2) (global.get $pointSize)))))
    (local.set $y2 (f64.load
      (i32.add (local.get $pointsAddr)
        (i32.add (i32.const 8) ;; sizeof double
          (i32.mul (local.get $pointIdx2) (global.get $pointSize))))))

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

  (func $main
    (result i32) ;; exit code, 0 for success
    ;; points: {f64, f64}[]
    (local $pointsAddr i32)
    (local $pointsLen i32)
    ;; gradiends: {f64, f64}[#points]
    (local $gradientsAddr i32)
    ;; measures: {i32, i32, f64}[]
    (local $measuresAddr i32)
    (local $measuresLen i32)
    ;; constraints: i32[]
    (local $constraintsAddr i32)
    (local $constraintsLen i32)

    (local.set $pointsAddr (i32.const 0))
    (local.set $pointsLen (i32.const 0))
    (local.set $gradientsAddr (i32.add (local.get $pointsAddr)
      (i32.mul (global.get $pointSize) (i32.const 20)))) ;; max 20 points
    (local.set $measuresAddr (i32.add (local.get $gradientsAddr)
      (i32.sub (local.get $gradientsAddr) (local.get $pointsAddr)))) ;; gradients[] is same size as points[]
    (local.set $measuresLen (i32.const 0))
    (local.set $constraintsAddr (i32.add (local.get $measuresAddr)
      (i32.mul (global.get $measureSize) (i32.const 40)))) ;; max 40 measurements
    (local.set $constraintsLen (i32.const 0))

    ;; points = { A, H, F }
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 0.0) (f64.const 0.0))) ;; point A
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 1785.0) ;; point H.x
      (f64.sub (f64.const 1252.0) (f64.const 1134.0)))) ;; H.y = AA' = AB - A'B
    (local.set $pointsLen (call $addPoint (local.get $pointsAddr) (local.get $pointsLen)
      (f64.const 1000.0) (f64.const 700.0))) ;; point F roughly

    ;; measures = {
    ;;   { AH: 1785 },
    ;;   { AF: 1458 },
    ;;   { FH:  928 },
    ;; }
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 1) (f64.const 1785.0)))
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 0) (i32.const 2) (f64.const 1458.0)))
    (local.set $measuresLen (call $addMeasure (local.get $measuresAddr) (local.get $measuresLen)
      (i32.const 1) (i32.const 2) (f64.const 928.0)))

    ;; constraints = { A.x, A.y, H.y }
    (i32.store (i32.add (local.get $constraintsAddr) (i32.mul (local.get $constraintsLen) (global.get $constraintSize)))
      (i32.const 0)) ;; A.x
    (i32.store (i32.add (local.get $constraintsAddr) (i32.mul (local.get $constraintsLen) (global.get $constraintSize)))
      (i32.const 1)) ;; A.y
    (i32.store (i32.add (local.get $constraintsAddr) (i32.mul (local.get $constraintsLen) (global.get $constraintSize)))
      (i32.const 3)) ;; H.y
    (local.set $constraintsLen (i32.const 3))

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

)