using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForceApllier : MonoBehaviour
{
	public Vector3 ForceVector;
	public Rigidbody BodyApplyForceTo;
	public ForceMode ForceMode;
	public Vector3 ResetPosition;


	[ContextMenu("Apply")]
	public void Apply()
	{
		BodyApplyForceTo?.AddForce(ForceVector, ForceMode);
	}

	[ContextMenu("ResetBodyPosition")]
	public void ResetBodyPosition()
	{
		BodyApplyForceTo.Sleep();
		BodyApplyForceTo.position = ResetPosition;
	}

}
