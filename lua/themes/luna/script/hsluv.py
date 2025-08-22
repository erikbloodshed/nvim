import math

m = [
    [3.240969941904521, -1.537383177570093, -0.498610760293],
    [-0.96924363628087, 1.87596750150772, 0.041555057407175],
    [0.055630079696993, -0.20397695888897, 1.056971514242878],
]

minv = [
    [0.41239079926595, 0.35758433938387, 0.18048078840183],
    [0.21263900587151, 0.71516867876775, 0.072192315360733],
    [0.019330818715591, 0.11919477979462, 0.95053215224966],
]

refY = 1.0
refU = 0.19783000664283
refV = 0.46831999493879
kappa = 903.2962962
epsilon = 0.0088564516
hex_chars = "0123456789abcdef"


def length_of_ray_until_intersect(theta: float, line: dict) -> float:
    return line["intercept"] / (math.sin(theta) - line["slope"] * math.cos(theta))


def dot_product(a: list, b: list) -> float:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def from_linear(c: float) -> float:
    if c <= 0.0031308:
        return 12.92 * c
    return 1.055 * (c**0.416666666666666685) - 0.055


def to_linear(c: float) -> float:
    if c > 0.04045:
        return ((c + 0.055) / 1.055) ** 2.4
    return c / 12.92


def get_bounds(L: float) -> list:
    result = []
    sub1 = ((L + 16) ** 3) / 1560896
    sub2 = sub1 if sub1 > epsilon else L / kappa

    for i in range(3):
        m1, m2, m3 = m[i]
        for t in [0, 1]:
            top1 = (284517 * m1 - 94839 * m3) * sub2
            top2 = (838422 * m3 + 769860 * m2 + 731718 * m1) * L * sub2 - 769860 * t * L
            bottom = (632260 * m3 - 126452 * m2) * sub2 + 126452 * t
            result.append({"slope": top1 / bottom, "intercept": top2 / bottom})
    return result


def max_safe_chroma_for_lh(L: float, h: float) -> float:
    hrad = h / 360 * math.pi * 2
    bounds = get_bounds(L)
    min_val = float("inf")
    for bound in bounds:
        length = length_of_ray_until_intersect(hrad, bound)
        if length >= 0:
            min_val = min(min_val, length)
    return min_val


def xyz_to_rgb(tuple: list) -> list:
    return [
        from_linear(dot_product(m[0], tuple)),
        from_linear(dot_product(m[1], tuple)),
        from_linear(dot_product(m[2], tuple)),
    ]


def rgb_to_xyz(tuple: list) -> list:
    rgbl = [to_linear(tuple[0]), to_linear(tuple[1]), to_linear(tuple[2])]
    return [
        dot_product(minv[0], rgbl),
        dot_product(minv[1], rgbl),
        dot_product(minv[2], rgbl),
    ]


def y_to_l(Y: float) -> float:
    if Y <= epsilon:
        return Y / refY * kappa
    return 116 * ((Y / refY) ** 0.333333333333333315) - 16


def l_to_y(L: float) -> float:
    if L <= 8:
        return refY * L / kappa
    return refY * (((L + 16) / 116) ** 3)


def xyz_to_luv(tuple: list) -> list:
    X, Y, Z = tuple
    divider = X + 15 * Y + 3 * Z
    varU = 4 * X / divider if divider != 0 else 0
    varV = 9 * Y / divider if divider != 0 else 0
    L = y_to_l(Y)
    if L == 0:
        return [0, 0, 0]
    return [L, 13 * L * (varU - refU), 13 * L * (varV - refV)]


def luv_to_xyz(tuple: list) -> list:
    L, U, V = tuple
    if L == 0:
        return [0, 0, 0]
    varU = U / (13 * L) + refU
    varV = V / (13 * L) + refV
    Y = l_to_y(L)
    X = 0 - (9 * Y * varU) / ((varU - 4) * varV - varU * varV)
    return [X, Y, (9 * Y - 15 * varV * Y - varV * X) / (3 * varV)]


def luv_to_lch(tuple: list) -> list:
    L, U, V = tuple
    C = math.sqrt(U * U + V * V)
    if C < 0.00000001:
        H = 0
    else:
        H = math.atan2(V, U) * 180.0 / math.pi
        if H < 0:
            H = 360 + H
    return [L, C, H]


def lch_to_luv(tuple: list) -> list:
    L, C, H = tuple
    Hrad = H / 360.0 * 2 * math.pi
    return [L, math.cos(Hrad) * C, math.sin(Hrad) * C]


def hsluv_to_lch(tuple: list) -> list:
    H, S, L = tuple
    if L > 99.9999999:
        return [100, 0, H]
    if L < 0.00000001:
        return [0, 0, H]
    return [L, max_safe_chroma_for_lh(L, H) / 100 * S, H]


def lch_to_hsluv(tuple: list) -> list:
    L, C, H = tuple
    max_chroma = max_safe_chroma_for_lh(L, H)
    if L > 99.9999999:
        return [H, 0, 100]
    if L < 0.00000001:
        return [H, 0, 0]
    return [H, C / max_chroma * 100, L]


def rgb_to_hex(tuple: list) -> str:
    h = "#"
    for i in range(3):
        c = int(tuple[i] * 255 + 0.5)
        digit2 = c % 16
        digit1 = (c - digit2) // 16
        h += hex_chars[digit1] + hex_chars[digit2]
    return h


def hex_to_rgb(hex: str) -> list:
    hex = hex.lower()
    ret = []
    for i in range(3):
        char1 = hex[i * 2 + 1]
        char2 = hex[i * 2 + 2]
        digit1 = hex_chars.index(char1)
        digit2 = hex_chars.index(char2)
        ret.append((digit1 * 16 + digit2) / 255.0)
    return ret


def lch_to_rgb(tuple: list) -> list:
    return xyz_to_rgb(luv_to_xyz(lch_to_luv(tuple)))


def rgb_to_lch(tuple: list) -> list:
    return luv_to_lch(xyz_to_luv(rgb_to_xyz(tuple)))


def hsluv_to_rgb(tuple: list) -> list:
    return lch_to_rgb(hsluv_to_lch(tuple))


def rgb_to_hsluv(tuple: list) -> list:
    return lch_to_hsluv(rgb_to_lch(tuple))


def hsluv_to_hex(tuple: list) -> str:
    return rgb_to_hex(hsluv_to_rgb(tuple))


def hex_to_hsluv(s: str) -> list:
    return rgb_to_hsluv(hex_to_rgb(s))
