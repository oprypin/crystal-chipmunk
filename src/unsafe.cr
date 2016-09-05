require "./chipmunk"

module CP
  class CircleShape < Shape
    def radius=(radius : Number)
      LibCP.circle_shape_set_radius(self, radius)
    end

    def offset=(offset : Vect)
      LibCP.circle_shape_set_offset(self, offset)
    end
  end

  class SegmentShape < Shape
    def set_endpoints(a : Vect, b : Vect)
      LibCP.segment_shape_set_endpoints(self, a, b)
    end

    def radius=(radius : Number)
      LibCP.segment_shape_set_radius(self, radius)
    end
  end

  class PolyShape < Shape
    def set_verts(verts : Array(Vect)|Slice(Vect), transform : Transform = Transform::IDENTITY)
      LibCP.poly_shape_set_verts(self, verts.size, verts, transform)
    end

    def radius=(radius : Number)
      LibCP.poly_shape_set_radius(self, radius)
    end
  end
end
