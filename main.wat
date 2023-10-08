(module
  (memory 1)
  (global $pointSize i32 (i32.const 16)) ;; two doubles

  (func $pointsDistance
    (param $pointsAddr i32)
    (param $pointIdx1 i32)
    (param $pointIdx2 i32)
    (result f64)
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

  (func $main
    (result i32)
    (local $pointsAddr i32) ;; address of first point
    (local $pointsLen i32) ;; amount of points in array

    (local.set $pointsAddr (i32.const 0))
    (local.set $pointsLen (i32.const 0))

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