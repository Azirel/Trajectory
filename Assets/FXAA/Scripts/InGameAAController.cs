using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.LWRP;

public class InGameAAController : MonoBehaviour
{
	[SerializeField] protected FXAARendererFeature FXAAController;
	[SerializeField] protected EdgeBlurRendererFeature EdgeBlurController;

	public void SetActiveFXAA(bool value)
	{
		FXAAController.settings.isBlit = value;
	}

	public void SetActiveEdgeBlur(bool value)
	{
		EdgeBlurController.settings.isBlit = value;
	}
}
