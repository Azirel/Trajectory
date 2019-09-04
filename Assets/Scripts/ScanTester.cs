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
	[SerializeField] Transform Camera;

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
		if (Input.GetKeyDown(KeyCode.Space))
			LaunchScanWave();
		ScannerMaterial.SetVector("_WorldSpaceScannerPos", Camera.position);
	}
}
