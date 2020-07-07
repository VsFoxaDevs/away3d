package away3d.animators.data;

import away3d.core.math.*;

import openfl.geom.*;
import openfl.Vector;

/**
 * Contains transformation data for a skeleton joint, used for skeleton animation.
 *
 * @see away3d.animation.data.Skeleton
 * @see away3d.animation.data.SkeletonJoint
 *
 * todo: support (nonuniform) scale
 */
class JointPose
{
	/**
	 * The name of the joint to which the pose is associated
	 */
	public var name:String; // intention is that this should be used only at load time, not in the main loop
	
	/**
	 * The rotation of the pose stored as a quaternion
	 */
	public var orientation:Quaternion = new Quaternion();
	
	/**
	 * The translation of the pose
	 */
	public var translation:Vector3D = new Vector3D();
	
	/**
	 * The scale of the pose
	 */
	public var scale:Vector3D = new Vector3D(1, 1, 1);
	
	public function new(?matrix:Matrix3D)
	{
		if (matrix != null) {
			var components:Vector<Vector3D> = matrix.decompose(QUATERNION);
			
			translation.copyFrom(components[0]);
			
			if (!Math.isNaN(components[1].x)) {
				orientation.x = components[1].x;
				orientation.y = components[1].y;
				orientation.z = components[1].z;
				orientation.w = components[1].w;
			}
			
			scale.copyFrom(components[2]);
		}
   	}
	
	/**
	 * Converts the transformation to a Matrix3D representation.
	 *
	 * @param target An optional target matrix to store the transformation. If not provided, it will create a new instance.
	 * @return The transformation matrix of the pose.
	 */
	public function toMatrix3D(target:Matrix3D = null):Matrix3D
	{
		if (target == null)
			target = new Matrix3D();
		
		orientation.toMatrix3D(target);
		target.appendTranslation(translation.x, translation.y, translation.z);
		target.appendScale(scale.x, scale.y, scale.z);
		return target;
	}
	
	/**
	 * Copies the transformation data from a source pose object into the existing pose object.
	 *
	 * @param pose The source pose to copy from.
	 */
	public function copyFrom(pose:JointPose):Void
	{
		var or:Quaternion = pose.orientation;
		var tr:Vector3D = pose.translation;
		var sr:Vector3D = pose.scale;
		orientation.x = or.x;
		orientation.y = or.y;
		orientation.z = or.z;
		orientation.w = or.w;
		translation.x = tr.x;
		translation.y = tr.y;
		translation.z = tr.z;
		scale.x = sr.x;
		scale.y = sr.y;
		scale.z = sr.z;
	}
	
	/**
	 * Fills this pose with values between the given start and end poses.
	 * 
	 * @param pose1 The first pose to interpolate.
	 * @param pose2 The second pose to interpolate.
	 * @param blendWeight The interpolation weight, a value between 0 and 1.
	 * @param highQuality Determines whether to use SLERP equations (true) or
	 * LERP equations (false) in the calculation of the resulting orientation.
	 * Defaults to false.
	 */
	public function interpolate(pose1:JointPose, pose2:JointPose, blendWeight:Float, ?highQuality:Bool = false):Void
	{
		var p1:Vector3D = pose1.translation;
		var p2:Vector3D = pose2.translation;
		var s1:Vector3D = pose1.scale;
		var s2:Vector3D = pose2.scale;
		
		if (highQuality)
			orientation.slerp(pose1.orientation, pose2.orientation, blendWeight)
		else
			orientation.lerp(pose1.orientation, pose2.orientation, blendWeight);
		
		translation.x = p1.x + blendWeight*(p2.x - p1.x);
		translation.y = p1.y + blendWeight*(p2.y - p1.y);
		translation.z = p1.z + blendWeight*(p2.z - p1.z);
		
		scale.x = s1.x + blendWeight*(s2.x - s1.x);
		scale.y = s1.y + blendWeight*(s2.y - s1.y);
		scale.z = s1.z + blendWeight*(s2.z - s1.z);
	}
}