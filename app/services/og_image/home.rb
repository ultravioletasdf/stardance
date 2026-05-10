module OgImage
  class Home < Base
    PREVIEWS = {
      "default" => -> { new }
    }.freeze

    LOGO_PATH = Rails.root.join("app", "assets", "images", "landing", "header", "stardance-logo.png").to_s
    STAR_PATH = Rails.root.join("app", "assets", "images", "landing", "hero", "star-character.png").to_s
    EARTH_PATH = Rails.root.join("app", "assets", "images", "landing", "hero", "earth.png").to_s
    STREAK_PATH = Rails.root.join("app", "assets", "images", "landing", "how-this-works", "colorful-streak.png").to_s

    def render
      create_stardance_canvas
      place_streak
      draw_text_scrim
      place_earth
      place_star_character
      place_logo
      draw_tagline
      draw_subtitle
    end

    private

    def place_streak
      return unless File.exist?(STREAK_PATH)

      place_image(
        STREAK_PATH,
        x: -60, y: -60,
        width: 800, height: 450,
        gravity: "NorthWest",
        cover: false
      )
    end

    def draw_text_scrim
      r, g, b = hex_to_rgb("#08061e")
      h_ramp = Vips::Image.identity(bands: 1).resize(WIDTH / 256.0, vscale: 1.0)
      h_ramp = h_ramp.linear(-1.0, 255.0)
      h_ramp = h_ramp.resize(1, vscale: HEIGHT.to_f)

      v_ramp = Vips::Image.identity(bands: 1).resize(1, vscale: HEIGHT / 256.0)
      v_ramp = v_ramp.linear(-1.0, 255.0)
      v_ramp = v_ramp.resize(WIDTH.to_f, vscale: 1.0)

      diag = ((h_ramp + v_ramp) / 2.0 * 0.55).cast(:uchar)

      scrim = solid_rgba(WIDTH, HEIGHT, r, g, b).extract_band(0, n: 3).bandjoin(diag).copy(interpretation: :srgb)
      @image = image.composite(scrim, :over, x: [ 0 ], y: [ 0 ])
    end

    def place_earth
      return unless File.exist?(EARTH_PATH)

      place_image(
        EARTH_PATH,
        x: -50, y: -70,
        width: 280, height: 280,
        gravity: "SouthWest",
        cover: false
      )
    end

    def place_star_character
      return unless File.exist?(STAR_PATH)

      place_image(
        STAR_PATH,
        x: 80, y: 80,
        width: 280, height: 280,
        gravity: "NorthEast",
        cover: false
      )
    end

    def place_logo
      return unless File.exist?(LOGO_PATH)

      place_image(
        LOGO_PATH,
        x: 80, y: 80,
        width: 420, height: 120,
        gravity: "NorthWest",
        cover: false
      )
    end

    def draw_tagline
      draw_soft_shadow("Make projects. Get prizes.", x: 80, y: 280, size: 72, font: title_font_name, radius: 8, opacity: 0.6)
      draw_glowing_text(
        "Make projects. Get prizes.",
        x: 80,
        y: 280,
        size: 72,
        color: "#fffcf4",
        glow_color: "#ebb7ff",
        glow_radius: 10,
        glow_opacity: 0.4,
        font: title_font_name
      )
    end

    def draw_subtitle
      draw_soft_shadow("A free summer program for teens 13-18. By Hack Club.", x: 80, y: 380, size: 30, radius: 4, opacity: 0.5)
      draw_text(
        "A free summer program for teens 13-18. By Hack Club.",
        x: 80,
        y: 380,
        size: 30,
        color: "#95dbff"
      )
    end
  end
end
