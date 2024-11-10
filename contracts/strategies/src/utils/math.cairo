pub mod Math {
    pub fn calculateXandY(
        liquidity: u128, tickA: u128, tickB: u128, tickCurrent: u128
    ) -> (u256, u256) {
        let newTickCurrent: u128 = max(min(tickCurrent, tickB), tickB);
        let x: u128 = liquidity * (tickB - newTickCurrent) / (newTickCurrent * tickB);
        let y: u128 = liquidity * (newTickCurrent - tickA);
        let x_u256: u256 = x.into();
        let y_u256: u256 = y.into();

        return (x_u256, y_u256);
    }

    pub fn calculateFeesXandY(
        x: u256, y: u256, sqrtA: u128, sqrtB: u128, sqrtCurrent: u128, priceA: u256, priceB: u256
    ) -> (u256, u256) {
        let sqrtA_u256: u256 = sqrtA.into();
        let sqrtB_u256: u256 = sqrtB.into();
        let sqrtCurrent_u256: u256 = sqrtCurrent.into();

        let din_x = priceA
            + (((sqrtB_u256 * sqrtCurrent_u256) * (sqrtCurrent_u256 - sqrtA_u256) * priceB)
                / (sqrtB_u256 - sqrtCurrent_u256));
        let x1 = ((x * priceA) + (y * priceB)) / din_x;

        let din_y = priceB
            + (((sqrtB_u256 - sqrtCurrent_u256) * priceA)
                / (sqrtCurrent_u256 * sqrtB_u256)
                * (sqrtCurrent_u256 - sqrtA_u256));
        let y1 = ((x * priceA) + (y * priceB)) / din_y;

        return (x1, y1);
    }

    pub fn max(a: u128, b: u128) -> u128 {
        let mut max: u128 = 0;
        if (a >= b) {
            max = a;
        } else {
            max = b;
        }
        return max;
    }

    pub fn min(a: u128, b: u128) -> u128 {
        let mut min: u128 = 0;
        if (a <= b) {
            min = a;
        } else {
            min = b;
        }
        return min;
    }

    pub fn mul_div_down(x: u256, y: u256, denominator: u256) -> u256 {
        let prod = x * y;
        prod / denominator
    }

    pub fn mul_div_up(x: u256, y: u256, denominator: u256) -> u256 {
        let Zero = 0;
        let One = 1;
        let prod = x * y;

        if (prod == Zero) {
            return Zero;
        }

        let dec_prod = prod - One;

        let q2 = dec_prod / denominator;
        let inc_q2 = q2 + One;
        return inc_q2;
    }
}

