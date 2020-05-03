require "./demo/run"
require "./demos/*"

FONT = SF::Font.from_file("../examples/resources/font/Cantarell-Regular.otf")

window = SF::RenderWindow.new(
  SF::VideoMode.new(990, 750), "",
  settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
)
window.vertical_sync_enabled = true

def reset_view(window)
  view = SF::View.new(SF.float_rect(0, 0, window.size.x, window.size.y))
  window.view = view
  view
end

cache = SF::Texture.new

{% begin %}
demo_count = 0
{% for cls in Demo.all_subclasses %}
  {% if cls.subclasses.empty? %}
    demo_count += 1
    %demos{cls} = {{cls}}.new(window)
  {% end %}
{% end %}

grid_size = (demo_count**0.5).ceil.to_i

damaged = true

while window.open?
  while event = window.poll_event
    case event
    when SF::Event::Closed
      window.close()
    when SF::Event::KeyPressed
      if event.code == SF::Keyboard::Escape
        window.close()
      end
    when SF::Event::Resized
      damaged = true
    when SF::Event::MouseButtonPressed
      i = 0
      {% for cls in Demo.all_subclasses %}
        {% if cls.subclasses.empty? %}
          y, x = i.divmod grid_size

          if (
            window.size.x * x / grid_size <= event.x < window.size.x * (x + 1) / grid_size &&
            window.size.y * y / grid_size <= event.y < window.size.y * (y + 1) / grid_size
          )
            reset_view(window)
            if event.button == SF::Mouse::Left
              window.title = "#{{{cls}}::TITLE} - #{Demo::TITLE unless Demo::TITLE == {{cls}}::TITLE}"
              %demos{cls}.run
            else
              %demos{cls} = {{cls}}.new(window)
            end
            damaged = true
            next
          end

          i += 1
        {% end %}
      {% end %}
    end
  end

  if damaged
    window.title = Demo::TITLE
    view = reset_view(window)
    window.clear

    rect = SF::RectangleShape.new(window.size)
    text = SF::Text.new("", FONT, window.size.x // 12)
    text.outline_thickness = 3

    i = 0
    {% for cls in Demo.all_subclasses %}
      {% if cls.subclasses.empty? %}
        y, x = i.divmod grid_size

        margin = 0.003
        view.viewport = SF.float_rect(x.to_f/grid_size + margin, y.to_f/grid_size + margin,
                                      1.0/grid_size - margin*2, 1.0/grid_size - margin*2)
        window.view = view

        color = CP::Space::DebugDraw.color_for_hash({{cls.stringify}}.hash, intensity: 0.22)
        rect.fill_color = SF::Color.new((color.r*255).to_u8, (color.g*255).to_u8, (color.b*255).to_u8)
        window.draw rect

        %demos{cls}.rescale
        %demos{cls}.draw

        text.string = {{cls}}::TITLE
        text.origin = {text.local_bounds.width / 2, 0}
        text.position = {window.size.x / 2, 10}
        window.draw text

        i += 1
      {% end %}
    {% end %}

    reset_view(window)

    text = SF::Text.new("Click to select a demo. Right click to reset.", FONT, 18)
    text.origin = {text.local_bounds.width, text.local_bounds.height}
    text.position = window.size - {10, 10}
    window.draw text

    cache.create(window.size.x, window.size.y)
    cache.update(window)

    damaged = false
  end

  window.draw SF::Sprite.new(cache)
  window.display()
end

{% end %}
