# Copyright (c) 2016 Oleh Prypin <oleh@pryp.in>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# :nodoc:
macro _cp_if_defined(name, cls = nil, &block)
  {% cls = cls ? cls.resolve : @type %}
  {% if cls != Reference %}
    {% if cls.methods.any? { |meth| meth.name == name.id } %}
      {{yield}}
    {% else %}
      _cp_if_defined({{name}}, {{cls.superclass}}) {{block}}
    {% end %}
  {% end %}
end

# :nodoc:
macro _cp_if_overridden(name, cls = nil, &block)
  {% cls = cls ? cls.resolve : @type %}
  {% if cls != Reference %}
    {% if cls.methods.any? { |meth| meth.name == name.id } %}
      _cp_if_defined({{name}}, {{cls.superclass}}) {{block}}
    {% else %}
      _cp_if_overridden({{name}}, {{cls.superclass}}) {{block}}
    {% end %}
  {% end %}
end

# :nodoc:
macro _cp_gather(name, f)
  {% typ = name.type %}
  {% name = name.var.id %}

  {{f}}

  def {% if f.receiver %}{{f.receiver}}.{% end %}{{name}}({{f.args.splat}}) : Array({{typ}})
    result = [] of {{typ}}
    {{f.name}}({{f.args.map(&.internal_name).splat}}) do |item|
      result << item
    end
    result
  end
end


# :nodoc:
macro _cp_extract(from)
  {% for c in from.resolve.constants %}
    # :nodoc:
    {{c}} = {{from}}::{{c}}
  {% end %}
end
