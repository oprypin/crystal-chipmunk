# Copyright (c) 2013 Scott Lembcke and Howling Moon Software
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


require "./vector"

@[Link("chipmunk")]
lib LibCP
  fun message = cpMessage(condition : UInt8*, file : UInt8*, line : Int32, is_error : Int32, is_hard_error : Int32, message : UInt8*, ...)

  alias HashValue = LibC::SizeT

  alias DataPointer = Void*

  alias CollisionID = UInt32

  struct HashSet
    entries : UInt32
    size : UInt32
    eql : HashSetEqlFunc
    default_value : Void*
    table : Void**
    pooled_bins : Void*
    allocated_buffers : Array
  end

  alias SpatialIndexBBFunc = Void* -> CP::BB

  alias SpatialIndexIteratorFunc = (Void*, Void*) ->

  alias SpatialIndexQueryFunc = (Void*, Void*, CollisionID, Void*) -> CollisionID

  alias SpatialIndexSegmentQueryFunc = (Void*, Void*, Void*) -> Float64

  struct SpatialIndex
    klass : SpatialIndexClass*
    bbfunc : SpatialIndexBBFunc
    static_index : SpatialIndex*
    dynamic_index : SpatialIndex*
  end

  struct SpaceHash
    spatial_index : SpatialIndex
    numcells : Int32
    celldim : Float64
    table : Void**
    handle_set : HashSet*
    pooled_bins : Void*
    pooled_handles : Array*
    allocated_buffers : Array*
    stamp : CP::Space::Timestamp
  end

  fun space_hash_alloc = cpSpaceHashAlloc() : SpaceHash*

  fun space_hash_init = cpSpaceHashInit(hash : SpaceHash*, celldim : Float64, numcells : Int32, bbfunc : SpatialIndexBBFunc, static_index : SpatialIndex*) : SpatialIndex*

  fun space_hash_new = cpSpaceHashNew(celldim : Float64, cells : Int32, bbfunc : SpatialIndexBBFunc, static_index : SpatialIndex*) : SpatialIndex*

  fun space_hash_resize = cpSpaceHashResize(hash : SpaceHash*, celldim : Float64, numcells : Int32)

  struct BBTree
    spatial_index : SpatialIndex
    velocity_func : BBTreeVelocityFunc
    leaves : HashSet*
    root : Void*
    pooled_nodes : Void*
    pooled_pairs : Void*
    allocated_buffers : Array
    stamp : CP::Space::Timestamp
  end

  fun bb_tree_alloc = cpBBTreeAlloc() : BBTree*

  fun bb_tree_init = cpBBTreeInit(tree : BBTree*, bbfunc : SpatialIndexBBFunc, static_index : SpatialIndex*) : SpatialIndex*

  fun bb_tree_new = cpBBTreeNew(bbfunc : SpatialIndexBBFunc, static_index : SpatialIndex*) : SpatialIndex*

  fun bb_tree_optimize = cpBBTreeOptimize(index : SpatialIndex*)

  alias BBTreeVelocityFunc = Void* -> CP::Vect

  fun bb_tree_set_velocity_func = cpBBTreeSetVelocityFunc(index : SpatialIndex*, func : BBTreeVelocityFunc)

  struct Sweep1D
    spatial_index : SpatialIndex
    num : Int32
    max : Int32
    table : Void*
  end

  fun sweep1d_alloc = cpSweep1DAlloc() : Sweep1D*

  fun sweep1d_init = cpSweep1DInit(sweep : Sweep1D*, bbfunc : SpatialIndexBBFunc, static_index : SpatialIndex*) : SpatialIndex*

  fun sweep1d_new = cpSweep1DNew(bbfunc : SpatialIndexBBFunc, static_index : SpatialIndex*) : SpatialIndex*

  alias SpatialIndexDestroyImpl = SpatialIndex* ->

  alias SpatialIndexCountImpl = SpatialIndex* -> Int32

  alias SpatialIndexEachImpl = (SpatialIndex*, SpatialIndexIteratorFunc, Void*) ->

  alias SpatialIndexContainsImpl = (SpatialIndex*, Void*, HashValue) -> Bool

  alias SpatialIndexInsertImpl = (SpatialIndex*, Void*, HashValue) ->

  alias SpatialIndexRemoveImpl = (SpatialIndex*, Void*, HashValue) ->

  alias SpatialIndexReindexImpl = SpatialIndex* ->

  alias SpatialIndexReindexObjectImpl = (SpatialIndex*, Void*, HashValue) ->

  alias SpatialIndexReindexQueryImpl = (SpatialIndex*, SpatialIndexQueryFunc, Void*) ->

  alias SpatialIndexQueryImpl = (SpatialIndex*, Void*, CP::BB, SpatialIndexQueryFunc, Void*) ->

  alias SpatialIndexSegmentQueryImpl = (SpatialIndex*, Void*, CP::Vect, CP::Vect, Float64, SpatialIndexSegmentQueryFunc, Void*) ->

  struct SpatialIndexClass
    destroy : SpatialIndexDestroyImpl
    count : SpatialIndexCountImpl
    each : SpatialIndexEachImpl
    contains : SpatialIndexContainsImpl
    insert : SpatialIndexInsertImpl
    remove : SpatialIndexRemoveImpl
    reindex : SpatialIndexReindexImpl
    reindex_object : SpatialIndexReindexObjectImpl
    reindex_query : SpatialIndexReindexQueryImpl
    query : SpatialIndexQueryImpl
    segment_query : SpatialIndexSegmentQueryImpl
  end

  fun spatial_index_free = cpSpatialIndexFree(index : SpatialIndex*)

  fun spatial_index_collide_static = cpSpatialIndexCollideStatic(dynamic_index : SpatialIndex*, static_index : SpatialIndex*, func : SpatialIndexQueryFunc, data : Void*)

  fun arbiter_get_restitution = cpArbiterGetRestitution(arb : Arbiter*) : Float64

  fun arbiter_set_restitution = cpArbiterSetRestitution(arb : Arbiter*, restitution : Float64)

  fun arbiter_get_friction = cpArbiterGetFriction(arb : Arbiter*) : Float64

  fun arbiter_set_friction = cpArbiterSetFriction(arb : Arbiter*, friction : Float64)

  fun arbiter_get_surface_velocity = cpArbiterGetSurfaceVelocity(arb : Arbiter*) : CP::Vect

  fun arbiter_set_surface_velocity = cpArbiterSetSurfaceVelocity(arb : Arbiter*, vr : CP::Vect)

  fun arbiter_get_user_data = cpArbiterGetUserData(arb : Arbiter*) : DataPointer

  fun arbiter_set_user_data = cpArbiterSetUserData(arb : Arbiter*, user_data : DataPointer)

  fun arbiter_total_impulse = cpArbiterTotalImpulse(arb : Arbiter*) : CP::Vect

  fun arbiter_total_ke = cpArbiterTotalKE(arb : Arbiter*) : Float64

  fun arbiter_ignore = cpArbiterIgnore(arb : Arbiter*) : Bool

  fun arbiter_get_shapes = cpArbiterGetShapes(arb : Arbiter*, a : Shape**, b : Shape**)

  fun arbiter_get_bodies = cpArbiterGetBodies(arb : Arbiter*, a : Body**, b : Body**)

  fun arbiter_get_contact_point_set = cpArbiterGetContactPointSet(arb : Arbiter*) : CP::ContactPointSet

  fun arbiter_set_contact_point_set = cpArbiterSetContactPointSet(arb : Arbiter*, set : CP::ContactPointSet*)

  fun arbiter_is_first_contact = cpArbiterIsFirstContact(arb : Arbiter*) : Bool

  fun arbiter_is_removal = cpArbiterIsRemoval(arb : Arbiter*) : Bool

  fun arbiter_get_count = cpArbiterGetCount(arb : Arbiter*) : Int32

  fun arbiter_get_normal = cpArbiterGetNormal(arb : Arbiter*) : CP::Vect

  fun arbiter_get_point_a = cpArbiterGetPointA(arb : Arbiter*, i : Int32) : CP::Vect

  fun arbiter_get_point_b = cpArbiterGetPointB(arb : Arbiter*, i : Int32) : CP::Vect

  fun arbiter_get_depth = cpArbiterGetDepth(arb : Arbiter*, i : Int32) : Float64

  fun arbiter_call_wildcard_begin_a = cpArbiterCallWildcardBeginA(arb : Arbiter*, space : Space*) : Bool

  fun arbiter_call_wildcard_begin_b = cpArbiterCallWildcardBeginB(arb : Arbiter*, space : Space*) : Bool

  fun arbiter_call_wildcard_pre_solve_a = cpArbiterCallWildcardPreSolveA(arb : Arbiter*, space : Space*) : Bool

  fun arbiter_call_wildcard_pre_solve_b = cpArbiterCallWildcardPreSolveB(arb : Arbiter*, space : Space*) : Bool

  fun arbiter_call_wildcard_post_solve_a = cpArbiterCallWildcardPostSolveA(arb : Arbiter*, space : Space*)

  fun arbiter_call_wildcard_post_solve_b = cpArbiterCallWildcardPostSolveB(arb : Arbiter*, space : Space*)

  fun arbiter_call_wildcard_separate_a = cpArbiterCallWildcardSeparateA(arb : Arbiter*, space : Space*)

  fun arbiter_call_wildcard_separate_b = cpArbiterCallWildcardSeparateB(arb : Arbiter*, space : Space*)

  alias BodyVelocityFunc = (Body*, CP::Vect, Float64, Float64) ->

  alias BodyPositionFunc = (Body*, Float64) ->

  fun body_alloc = cpBodyAlloc() : Body*

  fun body_init = cpBodyInit(body : Body*, mass : Float64, moment : Float64) : Body*

  fun body_new = cpBodyNew(mass : Float64, moment : Float64) : Body*

  fun body_new_kinematic = cpBodyNewKinematic() : Body*

  fun body_new_static = cpBodyNewStatic() : Body*

  fun body_destroy = cpBodyDestroy(body : Body*)

  fun body_free = cpBodyFree(body : Body*)

  fun body_activate = cpBodyActivate(body : Body*)

  fun body_activate_static = cpBodyActivateStatic(body : Body*, filter : Shape*)

  fun body_sleep = cpBodySleep(body : Body*)

  fun body_sleep_with_group = cpBodySleepWithGroup(body : Body*, group : Body*)

  fun body_is_sleeping = cpBodyIsSleeping(body : Body*) : Bool

  fun body_get_type = cpBodyGetType(body : Body*) : CP::Body::Type

  fun body_set_type = cpBodySetType(body : Body*, type : CP::Body::Type)

  fun body_get_space = cpBodyGetSpace(body : Body*) : Space*

  fun body_get_mass = cpBodyGetMass(body : Body*) : Float64

  fun body_set_mass = cpBodySetMass(body : Body*, m : Float64)

  fun body_get_moment = cpBodyGetMoment(body : Body*) : Float64

  fun body_set_moment = cpBodySetMoment(body : Body*, i : Float64)

  fun body_get_position = cpBodyGetPosition(body : Body*) : CP::Vect

  fun body_set_position = cpBodySetPosition(body : Body*, pos : CP::Vect)

  fun body_get_center_of_gravity = cpBodyGetCenterOfGravity(body : Body*) : CP::Vect

  fun body_set_center_of_gravity = cpBodySetCenterOfGravity(body : Body*, cog : CP::Vect)

  fun body_get_velocity = cpBodyGetVelocity(body : Body*) : CP::Vect

  fun body_set_velocity = cpBodySetVelocity(body : Body*, velocity : CP::Vect)

  fun body_get_force = cpBodyGetForce(body : Body*) : CP::Vect

  fun body_set_force = cpBodySetForce(body : Body*, force : CP::Vect)

  fun body_get_angle = cpBodyGetAngle(body : Body*) : Float64

  fun body_set_angle = cpBodySetAngle(body : Body*, a : Float64)

  fun body_get_angular_velocity = cpBodyGetAngularVelocity(body : Body*) : Float64

  fun body_set_angular_velocity = cpBodySetAngularVelocity(body : Body*, angular_velocity : Float64)

  fun body_get_torque = cpBodyGetTorque(body : Body*) : Float64

  fun body_set_torque = cpBodySetTorque(body : Body*, torque : Float64)

  fun body_get_rotation = cpBodyGetRotation(body : Body*) : CP::Vect

  fun body_get_user_data = cpBodyGetUserData(body : Body*) : DataPointer

  fun body_set_user_data = cpBodySetUserData(body : Body*, user_data : DataPointer)

  fun body_set_velocity_update_func = cpBodySetVelocityUpdateFunc(body : Body*, velocity_func : BodyVelocityFunc)

  fun body_set_position_update_func = cpBodySetPositionUpdateFunc(body : Body*, position_func : BodyPositionFunc)

  fun body_update_velocity = cpBodyUpdateVelocity(body : Body*, gravity : CP::Vect, damping : Float64, dt : Float64)

  fun body_update_position = cpBodyUpdatePosition(body : Body*, dt : Float64)

  fun body_local_to_world = cpBodyLocalToWorld(body : Body*, point : CP::Vect) : CP::Vect

  fun body_world_to_local = cpBodyWorldToLocal(body : Body*, point : CP::Vect) : CP::Vect

  fun body_apply_force_at_world_point = cpBodyApplyForceAtWorldPoint(body : Body*, force : CP::Vect, point : CP::Vect)

  fun body_apply_force_at_local_point = cpBodyApplyForceAtLocalPoint(body : Body*, force : CP::Vect, point : CP::Vect)

  fun body_apply_impulse_at_world_point = cpBodyApplyImpulseAtWorldPoint(body : Body*, impulse : CP::Vect, point : CP::Vect)

  fun body_apply_impulse_at_local_point = cpBodyApplyImpulseAtLocalPoint(body : Body*, impulse : CP::Vect, point : CP::Vect)

  fun body_get_velocity_at_world_point = cpBodyGetVelocityAtWorldPoint(body : Body*, point : CP::Vect) : CP::Vect

  fun body_get_velocity_at_local_point = cpBodyGetVelocityAtLocalPoint(body : Body*, point : CP::Vect) : CP::Vect

  fun body_kinetic_energy = cpBodyKineticEnergy(body : Body*) : Float64

  alias BodyShapeIteratorFunc = (Body*, Shape*, Void*) ->

  fun body_each_shape = cpBodyEachShape(body : Body*, func : BodyShapeIteratorFunc, data : Void*)

  alias BodyConstraintIteratorFunc = (Body*, Constraint*, Void*) ->

  fun body_each_constraint = cpBodyEachConstraint(body : Body*, func : BodyConstraintIteratorFunc, data : Void*)

  alias BodyArbiterIteratorFunc = (Body*, Arbiter*, Void*) ->

  fun body_each_arbiter = cpBodyEachArbiter(body : Body*, func : BodyArbiterIteratorFunc, data : Void*)

  fun shape_destroy = cpShapeDestroy(shape : Shape*)

  fun shape_free = cpShapeFree(shape : Shape*)

  fun shape_cache_bb = cpShapeCacheBB(shape : Shape*) : CP::BB

  fun shape_update = cpShapeUpdate(shape : Shape*, transform : CP::Transform) : CP::BB

  fun shape_point_query = cpShapePointQuery(shape : Shape*, p : CP::Vect, out : CP::PointQueryInfo*) : Float64

  fun shape_segment_query = cpShapeSegmentQuery(shape : Shape*, a : CP::Vect, b : CP::Vect, radius : Float64, info : CP::SegmentQueryInfo*) : Bool

  fun shapes_collide = cpShapesCollide(a : Shape*, b : Shape*) : CP::ContactPointSet

  fun shape_get_space = cpShapeGetSpace(shape : Shape*) : Space*

  fun shape_get_body = cpShapeGetBody(shape : Shape*) : Body*

  fun shape_set_body = cpShapeSetBody(shape : Shape*, body : Body*)

  fun shape_get_mass = cpShapeGetMass(shape : Shape*) : Float64

  fun shape_set_mass = cpShapeSetMass(shape : Shape*, mass : Float64)

  fun shape_get_density = cpShapeGetDensity(shape : Shape*) : Float64

  fun shape_set_density = cpShapeSetDensity(shape : Shape*, density : Float64)

  fun shape_get_moment = cpShapeGetMoment(shape : Shape*) : Float64

  fun shape_get_area = cpShapeGetArea(shape : Shape*) : Float64

  fun shape_get_center_of_gravity = cpShapeGetCenterOfGravity(shape : Shape*) : CP::Vect

  fun shape_get_bb = cpShapeGetBB(shape : Shape*) : CP::BB

  fun shape_get_sensor = cpShapeGetSensor(shape : Shape*) : Bool

  fun shape_set_sensor = cpShapeSetSensor(shape : Shape*, sensor : Bool)

  fun shape_get_elasticity = cpShapeGetElasticity(shape : Shape*) : Float64

  fun shape_set_elasticity = cpShapeSetElasticity(shape : Shape*, elasticity : Float64)

  fun shape_get_friction = cpShapeGetFriction(shape : Shape*) : Float64

  fun shape_set_friction = cpShapeSetFriction(shape : Shape*, friction : Float64)

  fun shape_get_surface_velocity = cpShapeGetSurfaceVelocity(shape : Shape*) : CP::Vect

  fun shape_set_surface_velocity = cpShapeSetSurfaceVelocity(shape : Shape*, surface_velocity : CP::Vect)

  fun shape_get_user_data = cpShapeGetUserData(shape : Shape*) : DataPointer

  fun shape_set_user_data = cpShapeSetUserData(shape : Shape*, user_data : DataPointer)

  fun shape_get_collision_type = cpShapeGetCollisionType(shape : Shape*) : CP::CollisionType

  fun shape_set_collision_type = cpShapeSetCollisionType(shape : Shape*, collision_type : CP::CollisionType)

  fun shape_get_filter = cpShapeGetFilter(shape : Shape*) : CP::ShapeFilter

  fun shape_set_filter = cpShapeSetFilter(shape : Shape*, filter : CP::ShapeFilter)

  fun circle_shape_alloc = cpCircleShapeAlloc() : CircleShape*

  fun circle_shape_init = cpCircleShapeInit(circle : CircleShape*, body : Body*, radius : Float64, offset : CP::Vect) : CircleShape*

  fun circle_shape_new = cpCircleShapeNew(body : Body*, radius : Float64, offset : CP::Vect) : Shape*

  fun circle_shape_get_offset = cpCircleShapeGetOffset(shape : Shape*) : CP::Vect

  fun circle_shape_get_radius = cpCircleShapeGetRadius(shape : Shape*) : Float64

  fun segment_shape_alloc = cpSegmentShapeAlloc() : SegmentShape*

  fun segment_shape_init = cpSegmentShapeInit(seg : SegmentShape*, body : Body*, a : CP::Vect, b : CP::Vect, radius : Float64) : SegmentShape*

  fun segment_shape_new = cpSegmentShapeNew(body : Body*, a : CP::Vect, b : CP::Vect, radius : Float64) : Shape*

  fun segment_shape_set_neighbors = cpSegmentShapeSetNeighbors(shape : Shape*, prev : CP::Vect, next_ : CP::Vect)

  fun segment_shape_get_a = cpSegmentShapeGetA(shape : Shape*) : CP::Vect

  fun segment_shape_get_b = cpSegmentShapeGetB(shape : Shape*) : CP::Vect

  fun segment_shape_get_normal = cpSegmentShapeGetNormal(shape : Shape*) : CP::Vect

  fun segment_shape_get_radius = cpSegmentShapeGetRadius(shape : Shape*) : Float64

  fun poly_shape_alloc = cpPolyShapeAlloc() : PolyShape*

  fun poly_shape_init = cpPolyShapeInit(poly : PolyShape*, body : Body*, count : Int32, verts : CP::Vect*, transform : CP::Transform, radius : Float64) : PolyShape*

  fun poly_shape_init_raw = cpPolyShapeInitRaw(poly : PolyShape*, body : Body*, count : Int32, verts : CP::Vect*, radius : Float64) : PolyShape*

  fun poly_shape_new = cpPolyShapeNew(body : Body*, count : Int32, verts : CP::Vect*, transform : CP::Transform, radius : Float64) : Shape*

  fun poly_shape_new_raw = cpPolyShapeNewRaw(body : Body*, count : Int32, verts : CP::Vect*, radius : Float64) : Shape*

  fun box_shape_init = cpBoxShapeInit(poly : PolyShape*, body : Body*, width : Float64, height : Float64, radius : Float64) : PolyShape*

  fun box_shape_init2 = cpBoxShapeInit2(poly : PolyShape*, body : Body*, box : CP::BB, radius : Float64) : PolyShape*

  fun box_shape_new = cpBoxShapeNew(body : Body*, width : Float64, height : Float64, radius : Float64) : Shape*

  fun box_shape_new2 = cpBoxShapeNew2(body : Body*, box : CP::BB, radius : Float64) : Shape*

  fun poly_shape_get_count = cpPolyShapeGetCount(shape : Shape*) : Int32

  fun poly_shape_get_vert = cpPolyShapeGetVert(shape : Shape*, index : Int32) : CP::Vect

  fun poly_shape_get_radius = cpPolyShapeGetRadius(shape : Shape*) : Float64

  alias ConstraintPreSolveFunc = (Constraint*, Space*) ->

  alias ConstraintPostSolveFunc = (Constraint*, Space*) ->

  fun constraint_destroy = cpConstraintDestroy(constraint : Constraint*)

  fun constraint_free = cpConstraintFree(constraint : Constraint*)

  fun constraint_get_space = cpConstraintGetSpace(constraint : Constraint*) : Space*

  fun constraint_get_body_a = cpConstraintGetBodyA(constraint : Constraint*) : Body*

  fun constraint_get_body_b = cpConstraintGetBodyB(constraint : Constraint*) : Body*

  fun constraint_get_max_force = cpConstraintGetMaxForce(constraint : Constraint*) : Float64

  fun constraint_set_max_force = cpConstraintSetMaxForce(constraint : Constraint*, max_force : Float64)

  fun constraint_get_error_bias = cpConstraintGetErrorBias(constraint : Constraint*) : Float64

  fun constraint_set_error_bias = cpConstraintSetErrorBias(constraint : Constraint*, error_bias : Float64)

  fun constraint_get_max_bias = cpConstraintGetMaxBias(constraint : Constraint*) : Float64

  fun constraint_set_max_bias = cpConstraintSetMaxBias(constraint : Constraint*, max_bias : Float64)

  fun constraint_get_collide_bodies = cpConstraintGetCollideBodies(constraint : Constraint*) : Bool

  fun constraint_set_collide_bodies = cpConstraintSetCollideBodies(constraint : Constraint*, collide_bodies : Bool)

  fun constraint_get_pre_solve_func = cpConstraintGetPreSolveFunc(constraint : Constraint*) : ConstraintPreSolveFunc

  fun constraint_set_pre_solve_func = cpConstraintSetPreSolveFunc(constraint : Constraint*, pre_solve_func : ConstraintPreSolveFunc)

  fun constraint_get_post_solve_func = cpConstraintGetPostSolveFunc(constraint : Constraint*) : ConstraintPostSolveFunc

  fun constraint_set_post_solve_func = cpConstraintSetPostSolveFunc(constraint : Constraint*, post_solve_func : ConstraintPostSolveFunc)

  fun constraint_get_user_data = cpConstraintGetUserData(constraint : Constraint*) : DataPointer

  fun constraint_set_user_data = cpConstraintSetUserData(constraint : Constraint*, user_data : DataPointer)

  fun constraint_get_impulse = cpConstraintGetImpulse(constraint : Constraint*) : Float64

  fun constraint_is_pin_joint = cpConstraintIsPinJoint(constraint : Constraint*) : Bool

  fun pin_joint_alloc = cpPinJointAlloc() : PinJoint*

  fun pin_joint_init = cpPinJointInit(joint : PinJoint*, a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect) : PinJoint*

  fun pin_joint_new = cpPinJointNew(a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect) : Constraint*

  fun pin_joint_get_anchor_a = cpPinJointGetAnchorA(constraint : Constraint*) : CP::Vect

  fun pin_joint_set_anchor_a = cpPinJointSetAnchorA(constraint : Constraint*, anchor_a : CP::Vect)

  fun pin_joint_get_anchor_b = cpPinJointGetAnchorB(constraint : Constraint*) : CP::Vect

  fun pin_joint_set_anchor_b = cpPinJointSetAnchorB(constraint : Constraint*, anchor_b : CP::Vect)

  fun pin_joint_get_dist = cpPinJointGetDist(constraint : Constraint*) : Float64

  fun pin_joint_set_dist = cpPinJointSetDist(constraint : Constraint*, dist : Float64)

  fun constraint_is_slide_joint = cpConstraintIsSlideJoint(constraint : Constraint*) : Bool

  fun slide_joint_alloc = cpSlideJointAlloc() : SlideJoint*

  fun slide_joint_init = cpSlideJointInit(joint : SlideJoint*, a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect, min : Float64, max : Float64) : SlideJoint*

  fun slide_joint_new = cpSlideJointNew(a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect, min : Float64, max : Float64) : Constraint*

  fun slide_joint_get_anchor_a = cpSlideJointGetAnchorA(constraint : Constraint*) : CP::Vect

  fun slide_joint_set_anchor_a = cpSlideJointSetAnchorA(constraint : Constraint*, anchor_a : CP::Vect)

  fun slide_joint_get_anchor_b = cpSlideJointGetAnchorB(constraint : Constraint*) : CP::Vect

  fun slide_joint_set_anchor_b = cpSlideJointSetAnchorB(constraint : Constraint*, anchor_b : CP::Vect)

  fun slide_joint_get_min = cpSlideJointGetMin(constraint : Constraint*) : Float64

  fun slide_joint_set_min = cpSlideJointSetMin(constraint : Constraint*, min : Float64)

  fun slide_joint_get_max = cpSlideJointGetMax(constraint : Constraint*) : Float64

  fun slide_joint_set_max = cpSlideJointSetMax(constraint : Constraint*, max : Float64)

  fun constraint_is_pivot_joint = cpConstraintIsPivotJoint(constraint : Constraint*) : Bool

  fun pivot_joint_alloc = cpPivotJointAlloc() : PivotJoint*

  fun pivot_joint_init = cpPivotJointInit(joint : PivotJoint*, a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect) : PivotJoint*

  fun pivot_joint_new = cpPivotJointNew(a : Body*, b : Body*, pivot : CP::Vect) : Constraint*

  fun pivot_joint_new2 = cpPivotJointNew2(a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect) : Constraint*

  fun pivot_joint_get_anchor_a = cpPivotJointGetAnchorA(constraint : Constraint*) : CP::Vect

  fun pivot_joint_set_anchor_a = cpPivotJointSetAnchorA(constraint : Constraint*, anchor_a : CP::Vect)

  fun pivot_joint_get_anchor_b = cpPivotJointGetAnchorB(constraint : Constraint*) : CP::Vect

  fun pivot_joint_set_anchor_b = cpPivotJointSetAnchorB(constraint : Constraint*, anchor_b : CP::Vect)

  fun constraint_is_groove_joint = cpConstraintIsGrooveJoint(constraint : Constraint*) : Bool

  fun groove_joint_alloc = cpGrooveJointAlloc() : GrooveJoint*

  fun groove_joint_init = cpGrooveJointInit(joint : GrooveJoint*, a : Body*, b : Body*, groove_a : CP::Vect, groove_b : CP::Vect, anchor_b : CP::Vect) : GrooveJoint*

  fun groove_joint_new = cpGrooveJointNew(a : Body*, b : Body*, groove_a : CP::Vect, groove_b : CP::Vect, anchor_b : CP::Vect) : Constraint*

  fun groove_joint_get_groove_a = cpGrooveJointGetGrooveA(constraint : Constraint*) : CP::Vect

  fun groove_joint_set_groove_a = cpGrooveJointSetGrooveA(constraint : Constraint*, groove_a : CP::Vect)

  fun groove_joint_get_groove_b = cpGrooveJointGetGrooveB(constraint : Constraint*) : CP::Vect

  fun groove_joint_set_groove_b = cpGrooveJointSetGrooveB(constraint : Constraint*, groove_b : CP::Vect)

  fun groove_joint_get_anchor_b = cpGrooveJointGetAnchorB(constraint : Constraint*) : CP::Vect

  fun groove_joint_set_anchor_b = cpGrooveJointSetAnchorB(constraint : Constraint*, anchor_b : CP::Vect)

  fun constraint_is_damped_spring = cpConstraintIsDampedSpring(constraint : Constraint*) : Bool

  alias DampedSpringForceFunc = (Constraint*, Float64) -> Float64

  fun damped_spring_alloc = cpDampedSpringAlloc() : DampedSpring*

  fun damped_spring_init = cpDampedSpringInit(joint : DampedSpring*, a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect, rest_length : Float64, stiffness : Float64, damping : Float64) : DampedSpring*

  fun damped_spring_new = cpDampedSpringNew(a : Body*, b : Body*, anchor_a : CP::Vect, anchor_b : CP::Vect, rest_length : Float64, stiffness : Float64, damping : Float64) : Constraint*

  fun damped_spring_get_anchor_a = cpDampedSpringGetAnchorA(constraint : Constraint*) : CP::Vect

  fun damped_spring_set_anchor_a = cpDampedSpringSetAnchorA(constraint : Constraint*, anchor_a : CP::Vect)

  fun damped_spring_get_anchor_b = cpDampedSpringGetAnchorB(constraint : Constraint*) : CP::Vect

  fun damped_spring_set_anchor_b = cpDampedSpringSetAnchorB(constraint : Constraint*, anchor_b : CP::Vect)

  fun damped_spring_get_rest_length = cpDampedSpringGetRestLength(constraint : Constraint*) : Float64

  fun damped_spring_set_rest_length = cpDampedSpringSetRestLength(constraint : Constraint*, rest_length : Float64)

  fun damped_spring_get_stiffness = cpDampedSpringGetStiffness(constraint : Constraint*) : Float64

  fun damped_spring_set_stiffness = cpDampedSpringSetStiffness(constraint : Constraint*, stiffness : Float64)

  fun damped_spring_get_damping = cpDampedSpringGetDamping(constraint : Constraint*) : Float64

  fun damped_spring_set_damping = cpDampedSpringSetDamping(constraint : Constraint*, damping : Float64)

  fun damped_spring_get_spring_force_func = cpDampedSpringGetSpringForceFunc(constraint : Constraint*) : DampedSpringForceFunc

  fun damped_spring_set_spring_force_func = cpDampedSpringSetSpringForceFunc(constraint : Constraint*, spring_force_func : DampedSpringForceFunc)

  fun constraint_is_damped_rotary_spring = cpConstraintIsDampedRotarySpring(constraint : Constraint*) : Bool

  alias DampedRotarySpringTorqueFunc = (Constraint*, Float64) -> Float64

  fun damped_rotary_spring_alloc = cpDampedRotarySpringAlloc() : DampedRotarySpring*

  fun damped_rotary_spring_init = cpDampedRotarySpringInit(joint : DampedRotarySpring*, a : Body*, b : Body*, rest_angle : Float64, stiffness : Float64, damping : Float64) : DampedRotarySpring*

  fun damped_rotary_spring_new = cpDampedRotarySpringNew(a : Body*, b : Body*, rest_angle : Float64, stiffness : Float64, damping : Float64) : Constraint*

  fun damped_rotary_spring_get_rest_angle = cpDampedRotarySpringGetRestAngle(constraint : Constraint*) : Float64

  fun damped_rotary_spring_set_rest_angle = cpDampedRotarySpringSetRestAngle(constraint : Constraint*, rest_angle : Float64)

  fun damped_rotary_spring_get_stiffness = cpDampedRotarySpringGetStiffness(constraint : Constraint*) : Float64

  fun damped_rotary_spring_set_stiffness = cpDampedRotarySpringSetStiffness(constraint : Constraint*, stiffness : Float64)

  fun damped_rotary_spring_get_damping = cpDampedRotarySpringGetDamping(constraint : Constraint*) : Float64

  fun damped_rotary_spring_set_damping = cpDampedRotarySpringSetDamping(constraint : Constraint*, damping : Float64)

  fun damped_rotary_spring_get_spring_torque_func = cpDampedRotarySpringGetSpringTorqueFunc(constraint : Constraint*) : DampedRotarySpringTorqueFunc

  fun damped_rotary_spring_set_spring_torque_func = cpDampedRotarySpringSetSpringTorqueFunc(constraint : Constraint*, spring_torque_func : DampedRotarySpringTorqueFunc)

  fun constraint_is_rotary_limit_joint = cpConstraintIsRotaryLimitJoint(constraint : Constraint*) : Bool

  fun rotary_limit_joint_alloc = cpRotaryLimitJointAlloc() : RotaryLimitJoint*

  fun rotary_limit_joint_init = cpRotaryLimitJointInit(joint : RotaryLimitJoint*, a : Body*, b : Body*, min : Float64, max : Float64) : RotaryLimitJoint*

  fun rotary_limit_joint_new = cpRotaryLimitJointNew(a : Body*, b : Body*, min : Float64, max : Float64) : Constraint*

  fun rotary_limit_joint_get_min = cpRotaryLimitJointGetMin(constraint : Constraint*) : Float64

  fun rotary_limit_joint_set_min = cpRotaryLimitJointSetMin(constraint : Constraint*, min : Float64)

  fun rotary_limit_joint_get_max = cpRotaryLimitJointGetMax(constraint : Constraint*) : Float64

  fun rotary_limit_joint_set_max = cpRotaryLimitJointSetMax(constraint : Constraint*, max : Float64)

  fun constraint_is_ratchet_joint = cpConstraintIsRatchetJoint(constraint : Constraint*) : Bool

  fun ratchet_joint_alloc = cpRatchetJointAlloc() : RatchetJoint*

  fun ratchet_joint_init = cpRatchetJointInit(joint : RatchetJoint*, a : Body*, b : Body*, phase : Float64, ratchet : Float64) : RatchetJoint*

  fun ratchet_joint_new = cpRatchetJointNew(a : Body*, b : Body*, phase : Float64, ratchet : Float64) : Constraint*

  fun ratchet_joint_get_angle = cpRatchetJointGetAngle(constraint : Constraint*) : Float64

  fun ratchet_joint_set_angle = cpRatchetJointSetAngle(constraint : Constraint*, angle : Float64)

  fun ratchet_joint_get_phase = cpRatchetJointGetPhase(constraint : Constraint*) : Float64

  fun ratchet_joint_set_phase = cpRatchetJointSetPhase(constraint : Constraint*, phase : Float64)

  fun ratchet_joint_get_ratchet = cpRatchetJointGetRatchet(constraint : Constraint*) : Float64

  fun ratchet_joint_set_ratchet = cpRatchetJointSetRatchet(constraint : Constraint*, ratchet : Float64)

  fun constraint_is_gear_joint = cpConstraintIsGearJoint(constraint : Constraint*) : Bool

  fun gear_joint_alloc = cpGearJointAlloc() : GearJoint*

  fun gear_joint_init = cpGearJointInit(joint : GearJoint*, a : Body*, b : Body*, phase : Float64, ratio : Float64) : GearJoint*

  fun gear_joint_new = cpGearJointNew(a : Body*, b : Body*, phase : Float64, ratio : Float64) : Constraint*

  fun gear_joint_get_phase = cpGearJointGetPhase(constraint : Constraint*) : Float64

  fun gear_joint_set_phase = cpGearJointSetPhase(constraint : Constraint*, phase : Float64)

  fun gear_joint_get_ratio = cpGearJointGetRatio(constraint : Constraint*) : Float64

  fun gear_joint_set_ratio = cpGearJointSetRatio(constraint : Constraint*, ratio : Float64)

  fun constraint_is_simple_motor = cpConstraintIsSimpleMotor(constraint : Constraint*) : Bool

  fun simple_motor_alloc = cpSimpleMotorAlloc() : SimpleMotor*

  fun simple_motor_init = cpSimpleMotorInit(joint : SimpleMotor*, a : Body*, b : Body*, rate : Float64) : SimpleMotor*

  fun simple_motor_new = cpSimpleMotorNew(a : Body*, b : Body*, rate : Float64) : Constraint*

  fun simple_motor_get_rate = cpSimpleMotorGetRate(constraint : Constraint*) : Float64

  fun simple_motor_set_rate = cpSimpleMotorSetRate(constraint : Constraint*, rate : Float64)

  alias CollisionBeginFunc = (Arbiter*, Space*, DataPointer) -> Bool

  alias CollisionPreSolveFunc = (Arbiter*, Space*, DataPointer) -> Bool

  alias CollisionPostSolveFunc = (Arbiter*, Space*, DataPointer) ->

  alias CollisionSeparateFunc = (Arbiter*, Space*, DataPointer) ->

  struct CollisionHandler
    type_a : CP::CollisionType
    type_b : CP::CollisionType
    begin_func : CollisionBeginFunc
    pre_solve_func : CollisionPreSolveFunc
    post_solve_func : CollisionPostSolveFunc
    separate_func : CollisionSeparateFunc
    user_data : DataPointer
  end

  fun space_alloc = cpSpaceAlloc() : Space*

  fun space_init = cpSpaceInit(space : Space*) : Space*

  fun space_new = cpSpaceNew() : Space*

  fun space_destroy = cpSpaceDestroy(space : Space*)

  fun space_free = cpSpaceFree(space : Space*)

  fun space_get_iterations = cpSpaceGetIterations(space : Space*) : Int32

  fun space_set_iterations = cpSpaceSetIterations(space : Space*, iterations : Int32)

  fun space_get_gravity = cpSpaceGetGravity(space : Space*) : CP::Vect

  fun space_set_gravity = cpSpaceSetGravity(space : Space*, gravity : CP::Vect)

  fun space_get_damping = cpSpaceGetDamping(space : Space*) : Float64

  fun space_set_damping = cpSpaceSetDamping(space : Space*, damping : Float64)

  fun space_get_idle_speed_threshold = cpSpaceGetIdleSpeedThreshold(space : Space*) : Float64

  fun space_set_idle_speed_threshold = cpSpaceSetIdleSpeedThreshold(space : Space*, idle_speed_threshold : Float64)

  fun space_get_sleep_time_threshold = cpSpaceGetSleepTimeThreshold(space : Space*) : Float64

  fun space_set_sleep_time_threshold = cpSpaceSetSleepTimeThreshold(space : Space*, sleep_time_threshold : Float64)

  fun space_get_collision_slop = cpSpaceGetCollisionSlop(space : Space*) : Float64

  fun space_set_collision_slop = cpSpaceSetCollisionSlop(space : Space*, collision_slop : Float64)

  fun space_get_collision_bias = cpSpaceGetCollisionBias(space : Space*) : Float64

  fun space_set_collision_bias = cpSpaceSetCollisionBias(space : Space*, collision_bias : Float64)

  fun space_get_collision_persistence = cpSpaceGetCollisionPersistence(space : Space*) : CP::Space::Timestamp

  fun space_set_collision_persistence = cpSpaceSetCollisionPersistence(space : Space*, collision_persistence : CP::Space::Timestamp)

  fun space_get_user_data = cpSpaceGetUserData(space : Space*) : DataPointer

  fun space_set_user_data = cpSpaceSetUserData(space : Space*, user_data : DataPointer)

  fun space_get_static_body = cpSpaceGetStaticBody(space : Space*) : Body*

  fun space_get_current_time_step = cpSpaceGetCurrentTimeStep(space : Space*) : Float64

  fun space_is_locked = cpSpaceIsLocked(space : Space*) : Bool

  fun space_add_default_collision_handler = cpSpaceAddDefaultCollisionHandler(space : Space*) : CollisionHandler*

  fun space_add_collision_handler = cpSpaceAddCollisionHandler(space : Space*, a : CP::CollisionType, b : CP::CollisionType) : CollisionHandler*

  fun space_add_wildcard_handler = cpSpaceAddWildcardHandler(space : Space*, type : CP::CollisionType) : CollisionHandler*

  fun space_add_shape = cpSpaceAddShape(space : Space*, shape : Shape*) : Shape*

  fun space_add_body = cpSpaceAddBody(space : Space*, body : Body*) : Body*

  fun space_add_constraint = cpSpaceAddConstraint(space : Space*, constraint : Constraint*) : Constraint*

  fun space_remove_shape = cpSpaceRemoveShape(space : Space*, shape : Shape*)

  fun space_remove_body = cpSpaceRemoveBody(space : Space*, body : Body*)

  fun space_remove_constraint = cpSpaceRemoveConstraint(space : Space*, constraint : Constraint*)

  fun space_contains_shape = cpSpaceContainsShape(space : Space*, shape : Shape*) : Bool

  fun space_contains_body = cpSpaceContainsBody(space : Space*, body : Body*) : Bool

  fun space_contains_constraint = cpSpaceContainsConstraint(space : Space*, constraint : Constraint*) : Bool

  alias PostStepFunc = (Space*, Void*, Void*) ->

  fun space_add_post_step_callback = cpSpaceAddPostStepCallback(space : Space*, func : PostStepFunc, key : Void*, data : Void*) : Bool

  alias SpacePointQueryFunc = (Shape*, CP::Vect, Float64, CP::Vect, Void*) ->

  fun space_point_query = cpSpacePointQuery(space : Space*, point : CP::Vect, max_distance : Float64, filter : CP::ShapeFilter, func : SpacePointQueryFunc, data : Void*)

  fun space_point_query_nearest = cpSpacePointQueryNearest(space : Space*, point : CP::Vect, max_distance : Float64, filter : CP::ShapeFilter, out : CP::PointQueryInfo*) : Shape*

  alias SpaceSegmentQueryFunc = (Shape*, CP::Vect, CP::Vect, Float64, Void*) ->

  fun space_segment_query = cpSpaceSegmentQuery(space : Space*, start : CP::Vect, end_ : CP::Vect, radius : Float64, filter : CP::ShapeFilter, func : SpaceSegmentQueryFunc, data : Void*)

  fun space_segment_query_first = cpSpaceSegmentQueryFirst(space : Space*, start : CP::Vect, end_ : CP::Vect, radius : Float64, filter : CP::ShapeFilter, out : CP::SegmentQueryInfo*) : Shape*

  alias SpaceBBQueryFunc = (Shape*, Void*) ->

  fun space_bb_query = cpSpaceBBQuery(space : Space*, bb : CP::BB, filter : CP::ShapeFilter, func : SpaceBBQueryFunc, data : Void*)

  alias SpaceShapeQueryFunc = (Shape*, CP::ContactPointSet*, Void*) ->

  fun space_shape_query = cpSpaceShapeQuery(space : Space*, shape : Shape*, func : SpaceShapeQueryFunc, data : Void*) : Bool

  alias SpaceBodyIteratorFunc = (Body*, Void*) ->

  fun space_each_body = cpSpaceEachBody(space : Space*, func : SpaceBodyIteratorFunc, data : Void*)

  alias SpaceShapeIteratorFunc = (Shape*, Void*) ->

  fun space_each_shape = cpSpaceEachShape(space : Space*, func : SpaceShapeIteratorFunc, data : Void*)

  alias SpaceConstraintIteratorFunc = (Constraint*, Void*) ->

  fun space_each_constraint = cpSpaceEachConstraint(space : Space*, func : SpaceConstraintIteratorFunc, data : Void*)

  fun space_reindex_static = cpSpaceReindexStatic(space : Space*)

  fun space_reindex_shape = cpSpaceReindexShape(space : Space*, shape : Shape*)

  fun space_reindex_shapes_for_body = cpSpaceReindexShapesForBody(space : Space*, body : Body*)

  fun space_use_spatial_hash = cpSpaceUseSpatialHash(space : Space*, dim : Float64, count : Int32)

  @[Raises]
  fun space_step = cpSpaceStep(space : Space*, dt : Float64)

  alias SpaceDebugDrawCircleImpl = (CP::Vect, Float64, Float64, CP::Space::DebugDraw::Color, CP::Space::DebugDraw::Color, DataPointer) ->

  alias SpaceDebugDrawSegmentImpl = (CP::Vect, CP::Vect, CP::Space::DebugDraw::Color, DataPointer) ->

  alias SpaceDebugDrawFatSegmentImpl = (CP::Vect, CP::Vect, Float64, CP::Space::DebugDraw::Color, CP::Space::DebugDraw::Color, DataPointer) ->

  alias SpaceDebugDrawPolygonImpl = (Int32, CP::Vect*, Float64, CP::Space::DebugDraw::Color, CP::Space::DebugDraw::Color, DataPointer) ->

  alias SpaceDebugDrawDotImpl = (Float64, CP::Vect, CP::Space::DebugDraw::Color, DataPointer) ->

  alias SpaceDebugDrawColorForShapeImpl = (Shape*, DataPointer) -> CP::Space::DebugDraw::Color

  struct SpaceDebugDrawOptions
    draw_circle : SpaceDebugDrawCircleImpl
    draw_segment : SpaceDebugDrawSegmentImpl
    draw_fat_segment : SpaceDebugDrawFatSegmentImpl
    draw_polygon : SpaceDebugDrawPolygonImpl
    draw_dot : SpaceDebugDrawDotImpl
    flags : CP::Space::DebugDraw::Flags
    shape_outline_color : CP::Space::DebugDraw::Color
    color_for_shape : SpaceDebugDrawColorForShapeImpl
    constraint_color : CP::Space::DebugDraw::Color
    collision_point_color : CP::Space::DebugDraw::Color
    data : DataPointer
  end

  fun space_debug_draw = cpSpaceDebugDraw(space : Space*, options : SpaceDebugDrawOptions*)

  VERSION_MAJOR = 7

  VERSION_MINOR = 0

  VERSION_RELEASE = 1

  fun moment_for_circle = cpMomentForCircle(m : Float64, r1 : Float64, r2 : Float64, offset : CP::Vect) : Float64

  fun area_for_circle = cpAreaForCircle(r1 : Float64, r2 : Float64) : Float64

  fun moment_for_segment = cpMomentForSegment(m : Float64, a : CP::Vect, b : CP::Vect, radius : Float64) : Float64

  fun area_for_segment = cpAreaForSegment(a : CP::Vect, b : CP::Vect, radius : Float64) : Float64

  fun moment_for_poly = cpMomentForPoly(m : Float64, count : Int32, verts : CP::Vect*, offset : CP::Vect, radius : Float64) : Float64

  fun area_for_poly = cpAreaForPoly(count : Int32, verts : CP::Vect*, radius : Float64) : Float64

  fun centroid_for_poly = cpCentroidForPoly(count : Int32, verts : CP::Vect*) : CP::Vect

  fun moment_for_box = cpMomentForBox(m : Float64, width : Float64, height : Float64) : Float64

  fun moment_for_box2 = cpMomentForBox2(m : Float64, box : CP::BB) : Float64

  fun convex_hull = cpConvexHull(count : Int32, verts : CP::Vect*, result : CP::Vect*, first : Int32*, tol : Float64) : Int32

  struct Array
    num : Int32
    max : Int32
    arr : Void**
  end

  alias HashSetEqlFunc = (Void*, Void*) -> Bool

  alias HashSetTransFunc = (Void*, Void*) -> Void*

  struct BodySleeping
    root : Body*
    next_ : Body*
    idle_time : Float64
  end

  struct Body
    velocity_func : BodyVelocityFunc
    position_func : BodyPositionFunc
    m : Float64
    m_inv : Float64
    i : Float64
    i_inv : Float64
    cog : CP::Vect
    p : CP::Vect
    v : CP::Vect
    f : CP::Vect
    a : Float64
    w : Float64
    t : Float64
    transform : CP::Transform
    user_data : DataPointer
    v_bias : CP::Vect
    w_bias : Float64
    space : Space*
    shape_list : Shape*
    arbiter_list : Arbiter*
    constraint_list : Constraint*
    sleeping : BodySleeping
  end

  enum ArbiterState
    FIRST_COLLISION
    NORMAL
    IGNORE
    CACHED
    INVALIDATED
  end

  struct ArbiterThread
    next_ : Arbiter*
    prev : Arbiter*
  end

  struct Contact
    r1 : CP::Vect
    r2 : CP::Vect
    n_mass : Float64
    t_mass : Float64
    bounce : Float64
    jn_acc : Float64
    jt_acc : Float64
    j_bias : Float64
    bias : Float64
    hash : HashValue
  end

  struct CollisionInfo
    a : Shape*
    b : Shape*
    id : CollisionID
    n : CP::Vect
    count : Int32
    arr : Contact*
  end

  struct Arbiter
    e : Float64
    u : Float64
    surface_vr : CP::Vect
    data : DataPointer
    a : Shape*
    b : Shape*
    body_a : Body*
    body_b : Body*
    thread_a : ArbiterThread
    thread_b : ArbiterThread
    count : Int32
    contacts : Contact*
    n : CP::Vect
    handler : CollisionHandler*
    handler_a : CollisionHandler*
    handler_b : CollisionHandler*
    swapped : Bool
    stamp : CP::Space::Timestamp
    state : ArbiterState
  end

  struct ShapeMassInfo
    m : Float64
    i : Float64
    cog : CP::Vect
    area : Float64
  end

  enum ShapeType
    CIRCLE_SHAPE
    SEGMENT_SHAPE
    POLY_SHAPE
    NUM_SHAPES
  end

  alias ShapeCacheDataImpl = (Shape*, CP::Transform) -> CP::BB

  alias ShapeDestroyImpl = Shape* ->

  alias ShapePointQueryImpl = (Shape*, CP::Vect, CP::PointQueryInfo*) ->

  alias ShapeSegmentQueryImpl = (Shape*, CP::Vect, CP::Vect, Float64, CP::SegmentQueryInfo*) ->

  struct ShapeClass
    type : ShapeType
    cache_data : ShapeCacheDataImpl
    destroy : ShapeDestroyImpl
    point_query : ShapePointQueryImpl
    segment_query : ShapeSegmentQueryImpl
  end

  struct Shape
    klass : ShapeClass*
    space : Space*
    body : Body*
    mass_info : ShapeMassInfo
    bb : CP::BB
    sensor : Bool
    e : Float64
    u : Float64
    surface_v : CP::Vect
    user_data : DataPointer
    type : CP::CollisionType
    filter : CP::ShapeFilter
    next_ : Shape*
    prev : Shape*
    hashid : HashValue
  end

  struct CircleShape
    shape : Shape
    c : CP::Vect
    tc : CP::Vect
    r : Float64
  end

  struct SegmentShape
    shape : Shape
    a : CP::Vect
    b : CP::Vect
    n : CP::Vect
    ta : CP::Vect
    tb : CP::Vect
    tn : CP::Vect
    r : Float64
    a_tangent : CP::Vect
    b_tangent : CP::Vect
  end

  struct SplittingPlane
    v0 : CP::Vect
    n : CP::Vect
  end

  struct PolyShape
    shape : Shape
    r : Float64
    count : Int32
    planes : SplittingPlane*
    _planes : SplittingPlane[12]
  end

  alias ConstraintPreStepImpl = (Constraint*, Float64) ->

  alias ConstraintApplyCachedImpulseImpl = (Constraint*, Float64) ->

  alias ConstraintApplyImpulseImpl = (Constraint*, Float64) ->

  alias ConstraintGetImpulseImpl = Constraint* -> Float64

  struct ConstraintClass
    pre_step : ConstraintPreStepImpl
    apply_cached_impulse : ConstraintApplyCachedImpulseImpl
    apply_impulse : ConstraintApplyImpulseImpl
    get_impulse : ConstraintGetImpulseImpl
  end

  struct Constraint
    klass : ConstraintClass*
    space : Space*
    a : Body*
    b : Body*
    next_a : Constraint*
    next_b : Constraint*
    max_force : Float64
    error_bias : Float64
    max_bias : Float64
    collide_bodies : Bool
    pre_solve : ConstraintPreSolveFunc
    post_solve : ConstraintPostSolveFunc
    user_data : DataPointer
  end

  struct PinJoint
    constraint : Constraint
    anchor_a : CP::Vect
    anchor_b : CP::Vect
    dist : Float64
    r1 : CP::Vect
    r2 : CP::Vect
    n : CP::Vect
    n_mass : Float64
    jn_acc : Float64
    bias : Float64
  end

  struct SlideJoint
    constraint : Constraint
    anchor_a : CP::Vect
    anchor_b : CP::Vect
    min : Float64
    max : Float64
    r1 : CP::Vect
    r2 : CP::Vect
    n : CP::Vect
    n_mass : Float64
    jn_acc : Float64
    bias : Float64
  end

  struct PivotJoint
    constraint : Constraint
    anchor_a : CP::Vect
    anchor_b : CP::Vect
    r1 : CP::Vect
    r2 : CP::Vect
    k : CP::Mat2x2
    j_acc : CP::Vect
    bias : CP::Vect
  end

  struct GrooveJoint
    constraint : Constraint
    grv_n : CP::Vect
    grv_a : CP::Vect
    grv_b : CP::Vect
    anchor_b : CP::Vect
    grv_tn : CP::Vect
    clamp : Float64
    r1 : CP::Vect
    r2 : CP::Vect
    k : CP::Mat2x2
    j_acc : CP::Vect
    bias : CP::Vect
  end

  struct DampedSpring
    constraint : Constraint
    anchor_a : CP::Vect
    anchor_b : CP::Vect
    rest_length : Float64
    stiffness : Float64
    damping : Float64
    spring_force_func : DampedSpringForceFunc
    target_vrn : Float64
    v_coef : Float64
    r1 : CP::Vect
    r2 : CP::Vect
    n_mass : Float64
    n : CP::Vect
    j_acc : Float64
  end

  struct DampedRotarySpring
    constraint : Constraint
    rest_angle : Float64
    stiffness : Float64
    damping : Float64
    spring_torque_func : DampedRotarySpringTorqueFunc
    target_wrn : Float64
    w_coef : Float64
    i_sum : Float64
    j_acc : Float64
  end

  struct RotaryLimitJoint
    constraint : Constraint
    min : Float64
    max : Float64
    i_sum : Float64
    bias : Float64
    j_acc : Float64
  end

  struct RatchetJoint
    constraint : Constraint
    angle : Float64
    phase : Float64
    ratchet : Float64
    i_sum : Float64
    bias : Float64
    j_acc : Float64
  end

  struct GearJoint
    constraint : Constraint
    phase : Float64
    ratio : Float64
    ratio_inv : Float64
    i_sum : Float64
    bias : Float64
    j_acc : Float64
  end

  struct SimpleMotor
    constraint : Constraint
    rate : Float64
    i_sum : Float64
    j_acc : Float64
  end

  struct Space
    iterations : Int32
    gravity : CP::Vect
    damping : Float64
    idle_speed_threshold : Float64
    sleep_time_threshold : Float64
    collision_slop : Float64
    collision_bias : Float64
    collision_persistence : CP::Space::Timestamp
    user_data : DataPointer
    stamp : CP::Space::Timestamp
    curr_dt : Float64
    dynamic_bodies : Array*
    static_bodies : Array*
    roused_bodies : Array*
    sleeping_components : Array*
    shape_id_counter : HashValue
    static_shapes : SpatialIndex*
    dynamic_shapes : SpatialIndex*
    constraints : Array*
    arbiters : Array*
    contact_buffers_head : Void*
    cached_arbiters : HashSet*
    pooled_arbiters : Array*
    allocated_buffers : Array*
    locked : UInt32
    uses_wildcards : Bool
    collision_handlers : HashSet*
    default_handler : CollisionHandler
    skip_post_step : Bool
    post_step_callbacks : Array*
    static_body : Body*
    _static_body : Body
  end

  struct PostStepCallback
    func : PostStepFunc
    key : Void*
    data : Void*
  end

  fun circle_shape_set_radius = cpCircleShapeSetRadius(shape : Shape*, radius : Float64)

  fun circle_shape_set_offset = cpCircleShapeSetOffset(shape : Shape*, offset : CP::Vect)

  fun segment_shape_set_endpoints = cpSegmentShapeSetEndpoints(shape : Shape*, a : CP::Vect, b : CP::Vect)

  fun segment_shape_set_radius = cpSegmentShapeSetRadius(shape : Shape*, radius : Float64)

  fun poly_shape_set_verts = cpPolyShapeSetVerts(shape : Shape*, count : Int32, verts : CP::Vect*, transform : CP::Transform)

  fun poly_shape_set_radius = cpPolyShapeSetRadius(shape : Shape*, radius : Float64)

  struct PointQueryContext
    point : CP::Vect
    max_distance : Float64
    filter : CP::ShapeFilter
    func : SpacePointQueryFunc
  end

  fun hasty_space_new = cpHastySpaceNew : Space*

  fun hasty_space_free = cpHastySpaceFree(space : Space*)

  fun hasty_space_set_threads = cpHastySpaceSetThreads(space : Space*, threads : UInt32)

  fun hasty_space_get_threads = cpHastySpaceGetThreads(space : Space*) : UInt32

  @[Raises]
  fun hasty_space_step = cpHastySpaceStep(space : Space*, dt : Float64)
end
