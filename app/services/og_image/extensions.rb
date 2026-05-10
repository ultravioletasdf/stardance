module OgImage
  class Extensions < Base
    PREVIEWS = {
      "default" => -> { new }
    }.freeze

    LOGO_PATH = Rails.root.join("app", "assets", "images", "landing", "header", "stardance-logo.png").to_s
    STAR_PATH = Rails.root.join("app", "assets", "images", "landing", "hero", "star-character.png").to_s

    def render
      create_stardance_canvas
      place_logo
      place_star
      draw_tagline
      draw_subtitle
    end

    private

    def place_logo
      return unless File.exist?(LOGO_PATH)

      place_image(
        LOGO_PATH,
        x: 70, y: 60,
        width: 280, height: 80,
        gravity: "NorthWest",
        cover: false
      )
    end

    def place_star
      return unless File.exist?(STAR_PATH)

      place_image(
        STAR_PATH,
        x: 60, y: 60,
        width: 220, height: 220,
        gravity: "SouthEast",
        cover: false
      )
    end

    def draw_tagline
      draw_glowing_text(
        "Browser extensions",
        x: 70,
        y: 220,
        size: 72,
        color: "#fffcf4",
        glow_color: "#95dbff",
        glow_radius: 8,
        glow_opacity: 0.35,
        font: title_font_name
      )
      draw_glowing_text(
        "from the community.",
        x: 70,
        y: 310,
        size: 72,
        color: "#fffcf4",
        glow_color: "#95dbff",
        glow_radius: 8,
        glow_opacity: 0.35,
        font: title_font_name
      )
    end

    def draw_subtitle
      draw_text(
        "Tools built by teens, for teens.",
        x: 70,
        y: 420,
        size: 30,
        color: "#ebb7ff"
      )
    end
  end
end
