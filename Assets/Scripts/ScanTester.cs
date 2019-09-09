using DG.Tweening;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScanTester : MonoBehaviour
{
	[SerializeField] protected Material ScannerMaterial;
	[SerializeField] protected string MaterialRadiusPropertyName;
	[SerializeField] protected float From;
	[SerializeField] protected float To;
	[SerializeField] protected float Duration;
	[SerializeField] protected Transform LeftCameraEye;
	[SerializeField] protected Transform RightCameraEye;

	[ContextMenu("LaunchScanWave")]
	public void LaunchScanWave()
	{
		var currentValue = From;
		DOTween.KillAll();
		var a = DOTween.To(
			getter: () => currentValue,
			setter: (value) =>
			{
				currentValue = value;
				ScannerMaterial.SetFloat(MaterialRadiusPropertyName, currentValue);
			},
			endValue: To, duration: Duration);
	}

	protected void Update()
	{
		ScannerMaterial.SetVector("_WorldSpaceLeftScannerPos", LeftCameraEye.position);
		ScannerMaterial.SetVector("_WorldSpaceRightScannerPos", RightCameraEye.position);
		if (Input.GetKeyDown(KeyCode.Space) || OVRInput.GetDown(OVRInput.Button.PrimaryIndexTrigger, OVRInput.Controller.RTouch))
			LaunchScanWave();
	}
}
