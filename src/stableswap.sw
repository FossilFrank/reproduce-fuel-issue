library stableswap;

use std::{
    u128::U128,
    u256::U256,
};

pub fn u128(u: u64) -> U128 {
    U128::from((0, u))
}

pub fn u256(u: u64) -> U256 {
    U256::from((0, 0, 0, u))
}

const ONE_E_9: u64 = 100_000_000;

/// Get LP value for stable curve: x^3*y + x*y^3
/// * `x_coin` - reserves of coin X.
/// * `x_scale` - 10 pow X coin decimals amount.
/// * `y_coin` - reserves of coin Y.
/// * `y_scale` - 10 pow Y coin decimals amount.
pub fn lp_value(x_coin: u64, x_scale: u64, y_coin: u64, y_scale: u64) -> U256 {
    let x_u256 = u256(x_coin);
    let y_u256 = u256(y_coin);
    let u2561e9 = u256(ONE_E_9);

    let x_scale_u256 = u256(x_scale);
    let y_scale_u256 = u256(y_scale);

    let _x = (x_u256 * u2561e9) / x_scale_u256;

    let _y = (y_u256 * u2561e9) / y_scale_u256;

    let _a = _x * _y;

    // ((_x * _x) / 1e18 + (_y * _y) / 1e18)
    let _b = (_x * _x) + (_y * _y);

    _a * _b
}

/// Get coin amount out by passing amount in, returns amount out (we don't take fees into account here).
/// It probably would eat a lot of gas and better to do it offchain (on your frontend or whatever),
/// yet if no other way and need blockchain computation we left it here.
/// * `coin_in` - amount of coin to swap.
/// * `scale_in` - 10 pow by coin decimals you want to swap.
/// * `scale_out` - 10 pow by coin decimals you want to get.
/// * `reserve_in` - reserves of coin to swap coin_in.
/// * `reserve_out` - reserves of coin to get in exchange.
pub fn coin_out(coin_in: u64, scale_in: u64, scale_out: u64, reserve_in: u64, reserve_out: u64) -> u64 {
    let u2561e9 = u256(ONE_E_9);

    let xy = lp_value(reserve_in, scale_in, reserve_out, scale_out);

    let reserve_in_u256 = (u256(reserve_in) * u2561e9) / u256(scale_in);
    let reserve_out_u256 = (u256(reserve_out) * u2561e9) / u256(scale_out);
    let amount_in = (u256(coin_in) * u2561e9) / u256(scale_in);
    let total_reserve = amount_in + reserve_in_u256;
    let y = reserve_out_u256 - get_y(total_reserve, xy, reserve_out_u256);

    let r = (y * u256(scale_out)) / u2561e9;

    r.as_u64().unwrap()
}

/// Get coin amount in by passing amount out, returns amount in (we don't take fees into account here).
/// It probably would eat a lot of gas and better to do it offchain (on your frontend or whatever),
/// yet if no other way and need blockchain computation we left it here.
/// * `coin_out` - amount of coin you want to get.
/// * `scale_in` - 10 pow by coin decimals you want to swap.
/// * `scale_out` - 10 pow by coin decimals you want to get.
/// * `reserve_in` - reserves of coin to swap.
/// * `reserve_out` - reserves of coin to get in exchange.
// pub fn coin_in(coin_out: u64, scale_out: u64, scale_in: u64, reserve_out: u64, reserve_in: u64) -> u64 {
//     let u2561e9 = u256(ONE_E_9);

//     let xy = lp_value(reserve_in, scale_in, reserve_out, scale_out);

//     let reserve_in_u256 = (u256(reserve_in) * u2561e9) / u256(scale_in);

//     let reserve_out_u256 = (u256(reserve_out) * u2561e9) / u256(scale_out);
//     let amount_out = (u256(coin_out) * u2561e9) / u256(scale_out);

//     let total_reserve = reserve_out_u256 - amount_out;
//     let x = get_y(total_reserve, xy, reserve_in_u256) - reserve_in_u256;

//     let r = (x * u256(scale_in)) / u2561e9;

//     r.as_u64().unwrap()
// }

/// Trying to find suitable `y` value.
/// * `x0` - total reserve x (include `coin_in`) with transformed decimals.
/// * `xy` - lp value (see `lp_value` func).
/// * `y` - reserves out with transformed decimals.
#[inline(never)]
fn get_y(x0: U256, xy: U256, y: U256) -> U256 {
    let mut i = 0;
    let mut _y = y;

    let one_u256 = u256(1);

    while (i < 10) {
        let k = f(x0, _y);

        let mut _dy = u256(0);

        if (k < xy) {
            _dy = ((xy - k) / d(x0, _y)) + one_u256;// Round up
            _y = _y + _dy;
        } else {
            let d_tmp = d(x0, _y);
            _dy = (k - xy) / d_tmp;
            log(333);
            _y = _y - _dy;
            log(444);
        };

        if (_dy < one_u256 || _dy == one_u256) {
            return _y
        };

        i = i + 1;
    };

    _y
}

/// Implements x0*y^3 + x0^3*y = x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18
fn f(x0_u256: U256, y_u256: U256) -> U256 {
    // x0*(y*y/1e18*y/1e18)/1e18
    let yy = (y_u256 * y_u256);
    let yyy = (yy * y_u256);

    let a = (x0_u256 * yyy);

    //(x0*x0/1e18*x0/1e18)*y/1e18
    let xx = (x0_u256 * x0_u256);
    let xxx = (xx * x0_u256);
    let b = (xxx * y_u256);

    a + b
}

/// Implements 3 * x0 * y^2 + x0^3 = 3 * x0 * (y * y / 1e8) / 1e8 + (x0 * x0 / 1e8 * x0) / 1e8
fn d(x0_u256: U256, y_u256: U256) -> U256 {
    let three_u256 = u256(3);

    // 3 * x0 * (y * y / 1e8) / 1e8
    let x3 = (three_u256 * x0_u256);
    let yy = (y_u256 * y_u256);
    let xyy3 = (x3 * yy);
    let xx = (x0_u256 * x0_u256);

    // x0 * x0 / 1e8 * x0 / 1e8
    let xxx = (xx * x0_u256);

    xyy3 + xxx
}

// #[test]
// fn test_coin_out() {
//     let out = coin_out(
//         2513058000,
//         1000000,
//         100000000,
//         25582858050757,
//         2558285805075712
//     );
//     assert(out == 251305799999);
// }

#[test]
fn test_coin_out_vise_vera() {
    let out = coin_out(
        251305800000,
        100000000,
        1000000,
        2558285805075701,
        25582858050757
    );
    assert(out == 2513057999);
}

// #[test]
// fn test_get_coin_in() {
//     let in = coin_in(
//         251305800000,
//         100000000,
//         1000000,
//         2558285805075701,
//         25582858050757
//     );
//     assert(in == 2513058000);
// }

// #[test]
// fn test_get_coin_in_vise_versa() {
//     let in = coin_in(
//         2513058000,
//         1000000,
//         100000000,
//         25582858050757,
//         2558285805075701
//     );
//     assert(in == 251305800001);
// }

// #[test]
// fn test_f() {
//     let x0 = u256(10000518365287);
//     let y = u256(2520572000001255);

//     let r = u256::as_u128(u256::div(f(x0, y), u256(1000000000000000000000000)));
//     assert(r == 160149899619106589403934712464197979, 0);

//     let r = u256::as_u128(f(u256::zero(), u256::zero()));
//     assert(r == 0, 1);
// }

// #[test]
// fn test_d() {
//     let x0 = u256(10000518365287);
//     let y = u256(2520572000001255);

//     let z = d(x0, y);
//     let r = u256::as_u128(u256::div(z, u256(100000000)));

//     assert(r == 1906093763356467088703995764640866982, 0);

//     let x0 = u256(5000000000);
//     let y = u256(10000000000000000);

//     let z = d(x0, y);
//     let r = u256::as_u128(u256::div(z, u256(100000000)));

//     assert(r == 15000000000001250000000000000000000, 1);

//     let x0 = u256(1);
//     let y = u256(2);

//     let z = d(x0, y);
//     let r = u256::as_u128(z);
//     assert(r == 13, 2);
// }

// #[test]
// fn test_lp_value_compute() {
//     // 0.3 ^ 3 * 0.5 + 0.5 ^ 3 * 0.3 = 0.051 (12 decimals)
//     let lp_value = lp_value(300000, 1000000, 500000, 1000000);

//     assert(
//         u256::as_u128(lp_value) == 5100000000000000000000000000000,
//         0
//     );

//     lp_value = lp_value(
//         500000899318256,
//         1000000,
//         25000567572582123,
//         1000000000000
//     );

//     lp_value = u256::div(lp_value, u256(1000000000000000000000000));
//     assert(u256::as_u128(lp_value) == 312508781701599715772756132553838833260, 1);
// }
