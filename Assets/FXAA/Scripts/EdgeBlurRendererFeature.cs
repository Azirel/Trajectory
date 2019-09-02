using System.Collections.Generic;
using UnityEngine.Serialization;

namespace UnityEngine.Rendering.LWRP
{
	public class EdgeBlurRendererFeature : ScriptableRendererFeature
	{
		[System.Serializable]
		public class EdgeBlurSettings
		{
			public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
			[Range(-50, 0)] public int EventOffset = 0;
			public Material blitMaterial = null;
			public int blitMaterialPassIndex = -1;
			public FilterMode FilterMode = FilterMode.Point;
			[Range(0, 5)] public float Strenght;
			public bool isBlit;
		}

		public EdgeBlurSettings settings = new EdgeBlurSettings();

		EdgeBlurPass blitPass;

		public override void Create()
		{
			settings.blitMaterial.SetFloat("_Strength", settings.Strenght);
			blitPass = new EdgeBlurPass(settings.Event + settings.EventOffset, settings.blitMaterial, settings.blitMaterialPassIndex, settings.FilterMode, name);
#if UNITY_EDITOR
			settings.blitMaterial.EnableKeyword("UNITY_EDITOR");
#else
			settings.blitMaterial.DisableKeyword("UNITY_EDITOR");
#endif
		}

		public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
		{
			if (settings.blitMaterial == null || !settings.isBlit)
				return;
			
			var src = renderer.cameraColorTarget;
			var dest = RenderTargetHandle.CameraTarget;

			blitPass.Setup(src, dest);
			renderer.EnqueuePass(blitPass);
		}
	}
}

