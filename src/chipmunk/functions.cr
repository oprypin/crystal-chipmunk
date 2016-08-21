module CP
  extend self

  def moment_for_circle(m : Number, r1 : Number, r2 : Number, offset : Vect) : Float64
    LibCP.moment_for_circle(m, r1, r2, offset)
  end

  def area_for_circle(r1 : Number, r2 : Number) : Float64
    LibCP.area_for_circle(r1, r2)
  end

  def moment_for_segment(m : Number, a : Vect, b : Vect, radius : Number) : Float64
    LibCP.moment_for_segment(m, a, b, radius)
  end

  def area_for_segment(a : Vect, b : Vect, radius : Number) : Float64
    LibCP.area_for_segment(a, b, radius)
  end

  def moment_for_poly(m : Number, verts : Array(Vect)|Slice(Vect), offset : Vect, radius : Number) : Float64
    LibCP.moment_for_poly(m, verts.size, verts, offset, radius)
  end

  def area_for_poly(verts : Array(Vect)|Slice(Vect), radius : Number) : Float64
    LibCP.area_for_poly(verts.size, verts, radius)
  end

  def centroid_for_poly(verts : Array(Vect)|Slice(Vect)) : Vect
    LibCP.centroid_for_poly(verts.size, verts)
  end

  def moment_for_box(m : Number, width : Number, height : Number) : Float64
    LibCP.moment_for_box(m, width, height)
  end

  def moment_for_box(m : Number, box : BB) : Float64
    LibCP.moment_for_box2(m, box)
  end

  def convex_hull(verts : Array(Vect)|Slice(Vect), tol : Number) : {Slice(Vect), Int32}
    result = Slice(Vect).new(verts.size)
    LibCP.convex_hull(verts.size, verts, result, out first, tol)
    {result, first}
  end

  def lerp(f1 : Number, f2 : Number, t : Number) : Number
    (f1 * (1.0 - t)) + (f2 * t)
  end

  def lerpconst(f1 : Number, f2 : Number, d : Number) : Number
    f1 + (f2 - f1).clamp(-d, d)
  end

  def spatial_index_destroy(index : SpatialIndex*)
    if (klass = index.value.klass)
      klass.value.destroy.call(index)
    end
  end

  def spatial_index_count(index : SpatialIndex*) : Int32
    index.value.klass.value.count.call(index)
  end

  def spatial_index_each(index : SpatialIndex*, func : SpatialIndexIteratorFunc, data : Void*)
    index.value.klass.value.each.call(index, func, data)
  end

  def spatial_index_contains(index : SpatialIndex*, obj : Void*, hashid : HashValue) : Bool
    index.value.klass.value.contains.call(index, obj, hashid)
  end

  def spatial_index_insert(index : SpatialIndex*, obj : Void*, hashid : HashValue)
    index.value.klass.value.insert.call(index, obj, hashid)
  end

  def spatial_index_remove(index : SpatialIndex*, obj : Void*, hashid : HashValue)
    index.value.klass.value.remove.call(index, obj, hashid)
  end

  def spatial_index_reindex(index : SpatialIndex*)
    index.value.klass.value.reindex.call(index)
  end

  def spatial_index_reindex_object(index : SpatialIndex*, obj : Void*, hashid : HashValue)
    index.value.klass.value.reindex_object.call(index, obj, hashid)
  end

  def spatial_index_query(index : SpatialIndex*, obj : Void*, bb : BB, func : SpatialIndexQueryFunc, data : Void*)
    index.value.klass.value.query.call(index, obj, bb, func, data)
  end

  def spatial_index_segment_query(index : SpatialIndex*, obj : Void*, a : Vect, b : Vect, t_exit : Float64, func : SpatialIndexSegmentQueryFunc, data : Void*)
    index.value.klass.value.segment_query.call(index, obj, a, b, t_exit, func, data)
  end

  def spatial_index_reindex_query(index : SpatialIndex*, func : SpatialIndexQueryFunc, data : Void*)
    index.value.klass.value.reindex_query.call(index, func, data)
  end
end
