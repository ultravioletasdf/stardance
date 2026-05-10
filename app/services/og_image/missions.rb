module OgImage
  class Missions < Base
    PREVIEWS = {
      "default" => -> { new(sample_mission) },
      "with_description" => -> { new(sample_mission(description: "Build a collection of micro-games inspired by WarioWare. Each game should last 5 seconds or less and chain together into a frantic sequence.")) },
      "long_name" => -> { new(sample_mission(name: "Build Your Own Programming Language From Scratch")) }
    }.freeze

    LOGO_PATH = Rails.root.join("app", "assets", "images", "landing", "header", "stardance-logo.png").to_s
    STAR_PATH = Rails.root.join("app", "assets", "images", "landing", "hero", "star-character.png").to_s
    STREAK_PATH = Rails.root.join("app", "assets", "images", "landing", "done-before", "star-bg.png").to_s

    class << self
      def sample_mission(name: "Wario-Ware Clone", description: nil, banner: nil, icon: nil)
        OpenStruct.new(
          name: name,
          description: description || "Create a fast-paced collection of micro-games that chain together.",
          banner: banner,
          icon: icon
        )
      end
    end

    def initialize(mission)
      @mission = mission
      super()
    end

    def render
      if @mission.banner&.attached?
        download_attachment(@mission.banner) || render_designed
      else
        render_designed
      end
    end

    private

    def render_designed
      create_stardance_canvas
      place_streak
      draw_text_scrim
      place_logo
      place_icon_or_star
      draw_mission_label
      draw_mission_name
      draw_description
    end

    def place_streak
      return unless File.exist?(STREAK_PATH)

      place_image(
        STREAK_PATH,
        x: -50, y: -40,
        width: 700, height: 400,
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
      v_ramp = v_ramp.resize(WIDTH.to_f, vscale: 1.0)

      diag = (h_ramp + v_ramp) / 2.0
      diag = (diag * 0.85).cast(:uchar)

      scrim = solid_rgba(WIDTH, HEIGHT, r, g, b).extract_band(0, n: 3).bandjoin(diag).copy(interpretation: :srgb)
      @image = image.composite(scrim, :over, x: [ 0 ], y: [ 0 ])
    end

    def place_logo
      return unless File.exist?(LOGO_PATH)

      place_image(
        LOGO_PATH,
        x: 70, y: 55,
        width: 240, height: 68,
        gravity: "NorthWest",
        cover: false
      )
    end

    def place_icon_or_star
      if @mission.respond_to?(:icon) && @mission.icon.respond_to?(:attached?) && @mission.icon.attached?
        place_image(
          @mission.icon,
          x: 80, y: 80,
          width: 300, height: 300,
          gravity: "NorthEast",
          rounded: true,
          radius: 24
        )
      elsif File.exist?(STAR_PATH)
        place_image(
          STAR_PATH,
          x: 80, y: 100,
          width: 260, height: 260,
          gravity: "NorthEast",
          cover: false
        )
      end
    end

    def draw_mission_label
      draw_soft_shadow("MISSION", x: 70, y: 170, size: 24, radius: 4, opacity: 0.7)
      draw_text("MISSION", x: 70, y: 170, size: 24, color: "#81ffff")
    end

    def draw_mission_name
      lines = wrap_text(@mission.name, 20).take(3)
      spacing = (64 * 1.3).to_i
      lines.each_with_index do |line, i|
        draw_soft_shadow(line, x: 70, y: 210 + (i * spacing), size: 64, font: title_font_name, radius: 8, opacity: 0.7)
      end

      @name_lines = draw_glowing_multiline_text(
        @mission.name,
        x: 70,
        y: 210,
        size: 64,
        color: "#fffcf4",
        glow_color: "#ebb7ff",
        max_chars: 20,
        max_lines: 3,
        glow_radius: 8,
        glow_opacity: 0.35,
        font: title_font_name
      )
    end

    def draw_description
      desc = @mission.respond_to?(:description) ? @mission.description : nil
      return unless desc.present?

      start_y = 210 + (@name_lines * 64 * 1.3).to_i + 15
      lines = wrap_text(desc, 42).take(2)
      lines.each_with_index do |line, i|
        ly = start_y + (i * (28 * 1.3).to_i)
        draw_soft_shadow(line, x: 70, y: ly, size: 28, radius: 4, opacity: 0.5)
      end
      draw_multiline_text(
        desc,
        x: 70,
        y: start_y,
        size: 28,
        color: "#c9c9c9",
        max_chars: 42,
        max_lines: 2,
        line_height: 1.3
      )
    end

    def download_attachment(attachment)
      data = attachment.download
      @image = Vips::Image.new_from_buffer(data, "")
      @image = resize_image(@image, WIDTH, HEIGHT, cover: true)
      @image
    rescue StandardError => e
      Rails.logger.warn("OgImage::Missions: Failed to use banner: #{e.message}")
      nil
    end
  end
end
