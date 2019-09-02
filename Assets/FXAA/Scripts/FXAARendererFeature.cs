using System.Collections.Generic;
using UnityEngine.Serialization;

namespace UnityEngine.Rendering.LWRP
{
	public class FXAARendererFeature : ScriptableRendererFeature
	{
		[System.Serializable]
		public class FXAASettings
		{
			public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
			[Range(-50, 0)] public int EventOffset = 0;
			public Material blitMaterial = null;
			public int blitMaterialPassIndex = -1;
			public FilterMode FilterMode = FilterMode.Point;
			public bool isBlit;
		}

		public FXAASettings settings = new FXAASettings();

		FXAAPass blitPass;

		public override void Create()
		{
			var passIndex = settings.blitMaterial != null ? settings.blitMaterial.passCount - 1 : 1;
			settings.blitMaterialPassIndex = Mathf.Clamp(settings.blitMaterialPassIndex, -1, passIndex);
			blitPass = new FXAAPass(settings.Event + settings.EventOffset, settings.blitMaterial, settings.blitMaterialPassIndex, settings.FilterMode, name);
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

