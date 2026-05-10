module OgImage
  class IndexPage < Base
    LOGO_PATH = Rails.root.join("app", "assets", "images", "landing", "header", "stardance-logo.png").to_s
    STREAK_PATH = Rails.root.join("app", "assets", "images", "landing", "how-this-works", "colorful-streak.png").to_s

    def initialize(title: nil, subtitle: nil)
      super()
      @title = title
      @subtitle = subtitle
    end

    def render
      create_stardance_canvas
      place_streak
      place_logo
      draw_title if @title.present?
      draw_subtitle if @subtitle.present?
    end

    private

    def place_streak
      return unless File.exist?(STREAK_PATH)

      place_image(
        STREAK_PATH,
        x: -100, y: -80,
        width: 900, height: 500,
        gravity: "NorthWest",
        cover: false
      )
    end

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

    def draw_title
      draw_glowing_text(
        @title,
        x: 0,
        y: 20,
        size: 120,
        color: "#fffcf4",
        glow_color: "#ebb7ff",
        gravity: "Center",
        glow_radius: 12,
        glow_opacity: 0.4,
        font: title_font_name
      )
    end

    def draw_subtitle
      draw_text(
        @subtitle,
        x: 0,
        y: 100,
        size: 38,
        color: "#95dbff",
        gravity: "Center"
      )
    end
  end
end
