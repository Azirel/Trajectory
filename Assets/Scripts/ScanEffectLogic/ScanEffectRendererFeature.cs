using System.Collections.Generic;
using UnityEngine.Serialization;

namespace UnityEngine.Rendering.LWRP
{
	public class ScanEffectRendererFeature : ScriptableRendererFeature
	{
		[System.Serializable]
		public class ScanEffectSettings
		{
			public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
			[Range(-50, 0)] public int EventOffset = 0;
			public Material Material = null;
			public int BlitMaterialPassIndex = -1;
			public FilterMode FilterMode = FilterMode.Point;
			public bool isBlit;
		}

		public ScanEffectSettings settings = new ScanEffectSettings();

		ScanEffectPass blitPass;

		public override void Create()
		{
			blitPass = new ScanEffectPass(settings.Event + settings.EventOffset, settings.Material, settings.BlitMaterialPassIndex, settings.FilterMode, name);
#if UNITY_EDITOR
			settings.Material.EnableKeyword("UNITY_EDITOR");
#else
			settings.Material.DisableKeyword("UNITY_EDITOR");
#endif
		}

		public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
		{
			if (settings.Material == null || !settings.isBlit)
				return;
			
			var src = renderer.cameraColorTarget;
			var dest = RenderTargetHandle.CameraTarget;

			blitPass.Setup(src, dest);
			renderer.EnqueuePass(blitPass);
		}
	}
}

