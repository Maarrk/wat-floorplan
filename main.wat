
(module
  (memory 1)
  (global $pointSize i32 (i32.const 16)) ;; two doubles

  (func $invSqrt
    (param $x f64)
    (result f64)
    (local $y f64)

    ;; evil floating point bit level hacking
    ;; y = MAGIC - (x >> 1)
    (local.set $y
      (f64.reinterpret_i64
        (i64.sub
          (i64.const 0x5FE6EB50C7B537A9)
          (i64.shr_u (i64.reinterpret_f64 (local.get $x)) (i64.const 1)))))

    ;; Newton's algorithm
    ;; y = y * (1.5 - (x * 0.5) * (y * y))
    (local.set $y
      (f64.mul (local.get $y)
        (f64.sub (f64.const 1.5)
          (f64.mul
            (f64.mul (local.get $x) (f64.const 0.5))
            (f64.mul (local.get $y) (local.get $y))))))
    (local.set $y
      (f64.mul (local.get $y)
        (f64.sub (f64.const 1.5)
          (f64.mul
            (f64.mul (local.get $x) (f64.const 0.5))
            (f64.mul (local.get $y) (local.get $y))))))

    (return (local.get $y)))

  (func $main
    (result i32)
    (local $pointsAddr i32) ;; address of first point
    (local $pointsLen i32) ;; amount of points in array

    (local.set $pointsAddr (i32.const 0))
    (local.set $pointsLen (i32.const 0))

    (return (i32.const 0)))

  (export "main" (func $main))
  (export "invSqrt" (func $invSqrt))
)