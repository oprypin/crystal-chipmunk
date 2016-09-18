require "./demo"

{% for cls in Demo.all_subclasses %}
  {% if cls.subclasses.empty? %}
    window = SF::RenderWindow.new(
      SF::VideoMode.new(990, 750), "",
      settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
    )
    window.vertical_sync_enabled = true
    window.title = {{cls}}::TITLE

    {{cls}}.new(window).run
  {% end %}
{% end %}
