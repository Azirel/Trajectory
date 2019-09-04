using TMPro;
using UnityEngine;

public class TestTouchInput : MonoBehaviour
{
	public OVRInput.Controller Controller;
	public OVRInput.Axis2D Axis;
	public TextMeshProUGUI Output;

	void Update()
	{
		Output.text = OVRInput.Get(Axis, Controller).ToString();
	}
}
