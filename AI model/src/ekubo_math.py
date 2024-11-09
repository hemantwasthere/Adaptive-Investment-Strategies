import math

def get_token_order(address1: str, address2: str) -> tuple:
    """
    Compares two token addresses and returns the addresses in the correct order, where token0_address < token1_address.

    Parameters:
    - address1 (str): The first token address (in hexadecimal format).
    - address2 (str): The second token address (in hexadecimal format).

    Returns:
    - tuple: A tuple containing (token0_address, token1_address), where token0_address is the smaller of the two addresses.
    """
    # Convert the hexadecimal addresses to integers
    address1_int = int(address1, 16)
    address2_int = int(address2, 16)
    
    # Compare the integer values and return them in the correct order
    if address1_int < address2_int:
        return (address1, address2)  # address1 is token0_address, address2 is token1_address
    else:
        return (address2, address1)  # address2 is token0_address, address1 is token1_address

def get_pool_fee_touse(pool_fee: float) -> int:
    """
    Calculate the pool fee scaled by 2^128 for blockchain usage.

    Parameters:
    - pool_fee (float): The pool fee as a percentage (e.g., for a 0.3% fee, pass 0.3).

    Returns:
    - int: The pool fee to use, scaled by 2^128.
    """
    return math.floor((pool_fee / 100) * 2**128)

def get_tick_spacing_touse(tick_spacing: float) -> int:
    """
    Calculate the tick spacing to use based on logarithmic operations.

    Parameters:
    - tick_spacing (float): The tick spacing.

    Returns:
    - int: The tick spacing value, calculated and rounded appropriately.
    """
    return math.ceil(math.log(1 + tick_spacing / 100) / math.log(1.000001))

def bool_to_sign(x: int) -> int:
    """
    Convert a boolean or integer (0 or 1) to a sign for arithmetic operations.

    Parameters:
    - x (int): Input integer (0 or 1), where 0 corresponds to positive (+1) and 1 corresponds to negative (-1).

    Returns:
    - int: 1 for positive, -1 for negative.

    Raises:
    - Exception: If the input is not 0 or 1.
    """
    if x == 0:
        return 1
    elif x == 1:
        return -1
    else:
        raise Exception("Invalid input, only 0 or 1 are allowed.")

def price_to_nearest_tick(price: float, tick_spacing_touse: int) -> int:
    """
    Convert a given price to the nearest tick value based on logarithmic calculations.

    Parameters:
    - price (float): The price value to convert.
    - tick_spacing_touse (int, optional): The tick spacing to use

    Returns:
    - int: The nearest tick value.
    """
    return round(int(math.log(price) / math.log(1.000001)) / tick_spacing_touse) * tick_spacing_touse

def price_to_tick(price: float) -> int:
    """
    Convert a given price to the corresponding tick value.

    Parameters:
    - price (float): The price value to convert.

    Returns:
    - int: The corresponding tick value.
    """
    return int(math.log(price) / math.log(1.000001))

def impermanent_loss_absolute(price_ratio: float, sqrt_p, L) -> float:
    """
    Calculate the impermanent loss based on the price ratio between two assets.
    Equation source: https://medium.com/auditless/how-to-calculate-impermanent-loss-full-derivation-803e8b2497b7
    
    Parameters:
    - price_ratio (float): The ratio of the current price to the original price.

    Returns:
    - float: The calculated impermanent loss (a value between 0 and 1).
    """
    sqrt_k = price_ratio**0.5
    k = price_ratio
    return L * sqrt_p * (2*sqrt_k - 1 - k)


def get_liquidity(x, y, sqrt_price, sqrt_lower_bound, sqrt_upper_bound):
    if sqrt_price <= sqrt_lower_bound:
        liquidity = x * sqrt_lower_bound * sqrt_upper_bound / (sqrt_upper_bound - sqrt_lower_bound)
    elif sqrt_price < sqrt_upper_bound:
        liquidity0 = x * sqrt_price * sqrt_upper_bound / (sqrt_upper_bound - sqrt_price)
        liquidity1 =  y / (sqrt_price - sqrt_lower_bound)
        liquidity = min(liquidity0, liquidity1)
    else:
        liquidity = y / (sqrt_upper_bound - sqrt_lower_bound)
    return liquidity

def get_liquidity_from_token1_capital(total_capital_token1_terms, sqrt_price, sqrt_lower_bound, sqrt_upper_bound):
    """
    Calculate liquidity given the capital provided in ETH and the price range.

    Parameters:
    - eth_capital (float): The amount of capital provided in terms of ETH (Token0).
    - sqrt_price (float): The square root of the current price (Token1/Token0).
    - sqrt_lower_bound (float): The square root of the lower bound of the price range.
    - sqrt_upper_bound (float): The square root of the upper bound of the price range.

    Returns:
    - float: The calculated liquidity (L).
    """
    sp = sqrt_price 
    spl = sqrt_lower_bound
    spu = sqrt_upper_bound
    
    y = sp * spu * (sp-spl) / (sp * spu * (sp - spl) + spu - sp) * total_capital_token1_terms
    x = (spu-sp) / (spu - sp + sp * spu * (sp - spl)) * total_capital_token1_terms
    liquidity = get_liquidity(x, y, sqrt_price, sqrt_lower_bound, sqrt_upper_bound)
    
    return liquidity
