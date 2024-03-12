using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
	CameraRenderer renderer = new CameraRenderer();

    //批处理配置
    private bool useDynamicBatching, useGPUInstancing;

    ShadowSettings shadowSettings;

    //构造函数，初始化管线的一些属性
    public CustomRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, ShadowSettings shadowSettings)
    {
        this.shadowSettings = shadowSettings;
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        //配置SRP Batch
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
    }

    //必须重写Render函数，目前函数内部什么都不执行
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (Camera camera in cameras) 
        {
			renderer.Render(context, camera, useDynamicBatching, useGPUInstancing, shadowSettings);
		}
    }
}

