import hsluv


def rgb(c):
    c = c.lower()
    return [int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)]


class Util:
    @staticmethod
    def blend(foreground, alpha, background):
        if isinstance(alpha, str):
            alpha = int(alpha, 16) / 255.0
        bg = rgb(background)
        fg = rgb(foreground)

        def blend_channel(i):
            ret = alpha * fg[i] + (1 - alpha) * bg[i]
            return int(min(max(0, ret), 255) + 0.5)

        return f"#{blend_channel(0):02x}{blend_channel(1):02x}{blend_channel(2):02x}"

    @staticmethod
    def brighten(color, lightness_amount=0.05, saturation_amount=0.2):
        hsl = hsluv.hex_to_hsluv(color)
        hsl[2] = min(hsl[2] + (lightness_amount * 100), 100)
        hsl[1] = min(hsl[1] + (saturation_amount * 100), 100)
        return hsluv.hsluv_to_hex(hsl)
