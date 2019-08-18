using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Text))]
public class SingleToText : MonoBehaviour
{
    public void SetValue(float value)
	{
		GetComponent<Text>().text = value.ToString("##");
	}
}
