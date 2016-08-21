# :nodoc:
macro _cp_if_overridden(name, cls = nil, &block)
  {% cls = cls ? cls.resolve : @type %}
  {% if cls.superclass != Reference %}
    {% if cls.methods.any? { |meth| meth.name == name.id } %}
      {{yield}}
    {% else %}
      _cp_if_overridden({{name}}, {{cls.superclass}}) {{block}}
    {% end %}
  {% end %}
end
