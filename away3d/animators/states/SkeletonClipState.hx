package away3d.animators.states;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;

import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 *
 */
class SkeletonClipState extends AnimationClipState implements ISkeletonAnimationState
{
	public var currentPose(get, never):SkeletonPose;
	public var nextPose(get, never):SkeletonPose;
	
	private var _rootPos:Vector3D = new Vector3D();
	private var _frames:Vector<SkeletonPose>;
	private var _skeletonClipNode:SkeletonClipNode;
	private var _skeletonPose:SkeletonPose = new SkeletonPose();
	private var _skeletonPoseDirty:Bool = true;
	private var _currentPose:SkeletonPose;
	private var _nextPose:SkeletonPose;
	
	/**
	 * Returns the current skeleton pose frame of animation in the clip based on the internal playhead position.
	 */
	private function get_currentPose():SkeletonPose
	{
		if (_framesDirty)
			updateFrames();
		
		return _currentPose;
	}
	
	/**
	 * Returns the next skeleton pose frame of animation in the clip based on the internal playhead position.
	 */
	private function get_nextPose():SkeletonPose
	{
		if (_framesDirty)
			updateFrames();
		
		return _nextPose;
	}
	
	public function new(animator:IAnimator, skeletonClipNode:SkeletonClipNode)
	{
		super(animator, skeletonClipNode);
		
		_skeletonClipNode = skeletonClipNode;
		_frames = _skeletonClipNode.frames;
	}
	
	/**
	 * Returns the current skeleton pose of the animation in the clip based on the internal playhead position.
	 */
	public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
	{
		if (_skeletonPoseDirty)
			updateSkeletonPose(skeleton);
		
		return _skeletonPose;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		_skeletonPoseDirty = true;
		
		super.updateTime(time);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateFrames():Void
	{
		super.updateFrames();
		
		_currentPose = _frames[_currentFrame];
		
		if (_skeletonClipNode.looping && _nextFrame >= _skeletonClipNode.lastFrame) {
			_nextPose = _frames[0];
			cast(_animator, SkeletonAnimator).dispatchCycleEvent();
		} else
			_nextPose = _frames[_nextFrame];
	}
	
	/**
	 * Updates the output skeleton pose of the node based on the internal playhead position.
	 *
	 * @param skeleton The skeleton used by the animator requesting the ouput pose.
	 */
	private function updateSkeletonPose(skeleton:Skeleton):Void
	{
		_skeletonPoseDirty = false;
		
		if (_skeletonClipNode.totalDuration == 0)
			return;
		
		if (_framesDirty)
			updateFrames();
		
		var currentPose:Vector<JointPose> = _currentPose.jointPoses;
		var nextPose:Vector<JointPose> = _nextPose.jointPoses;
		var numJoints:Int = skeleton.numJoints;
		var p1:Vector3D, p2:Vector3D, s1:Vector3D, s2:Vector3D;
		var pose1:JointPose, pose2:JointPose;
		var endPoses:Vector<JointPose> = _skeletonPose.jointPoses;
		var endPose:JointPose;
		var tr:Vector3D, sc:Vector3D;
		
		// :s
		if (endPoses.length != numJoints)
			endPoses.length = numJoints;
		
		if ((numJoints != currentPose.length) || (numJoints != nextPose.length))
			throw new Error("joint counts don't match!");
		
		for (i in 0...numJoints) {
			if (endPoses[i] == null) endPoses[i] = new JointPose();
			pose1 = currentPose[i];
			pose2 = nextPose[i];
			
			if (i == 0)
				if (_skeletonClipNode.highQuality)
					endPoses[i].orientation.slerp(pose1.orientation, pose2.orientation, _blendWeight)
				else
					endPoses[i].orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);
			else
				endPoses[i].interpolate(pose1, pose2, _blendWeight, _skeletonClipNode.highQuality);
		}
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updatePositionDelta():Void
	{
		_positionDeltaDirty = false;
		
		if (_framesDirty)
			updateFrames();
		
		var p1:Vector3D, p2:Vector3D, p3:Vector3D;
		var totalDelta:Vector3D = _skeletonClipNode.totalDelta;
		
		// jumping back, need to reset position
		if ((_timeDir > 0 && _nextFrame < _oldFrame) || (_timeDir < 0 && _nextFrame > _oldFrame)) {
			_rootPos.x -= totalDelta.x*_timeDir;
			_rootPos.y -= totalDelta.y*_timeDir;
			_rootPos.z -= totalDelta.z*_timeDir;
		}
		
		var dx:Float = _rootPos.x;
		var dy:Float = _rootPos.y;
		var dz:Float = _rootPos.z;
		
		if (_skeletonClipNode.stitchFinalFrame && _nextFrame == _skeletonClipNode.lastFrame) {
			p1 = _frames[0].jointPoses[0].translation;
			p2 = _frames[1].jointPoses[0].translation;
			p3 = _currentPose.jointPoses[0].translation;
			
			_rootPos.x = p3.x + p1.x + _blendWeight*(p2.x - p1.x);
			_rootPos.y = p3.y + p1.y + _blendWeight*(p2.y - p1.y);
			_rootPos.z = p3.z + p1.z + _blendWeight*(p2.z - p1.z);
		} else {
			p1 = _currentPose.jointPoses[0].translation;
			p2 = _frames[_nextFrame].jointPoses[0].translation; //cover the instances where we wrap the pose but still want the final frame translation values
			_rootPos.x = p1.x + _blendWeight*(p2.x - p1.x);
			_rootPos.y = p1.y + _blendWeight*(p2.y - p1.y);
			_rootPos.z = p1.z + _blendWeight*(p2.z - p1.z);
		}
		
		_rootDelta.x = _rootPos.x - dx;
		_rootDelta.y = _rootPos.y - dy;
		_rootDelta.z = _rootPos.z - dz;
		
		_oldFrame = _nextFrame;
	}
}