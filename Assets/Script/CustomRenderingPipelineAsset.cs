using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Custom Render Pipeline")]
public class CustomRenderPipelineAsset : RenderPipelineAsset
{
    //重写创建实际RenderPipeline的函数
    protected override RenderPipeline CreatePipeline()
    {
		return new CustomRenderPipeline();
    }
}
