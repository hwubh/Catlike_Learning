using UnityEngine;
using UnityEngine.Rendering;

public partial class CustomRenderPipeline : RenderPipeline
{
	CameraRenderer renderer = new CameraRenderer();

    //批处理配置
    private bool useDynamicBatching, useGPUInstancing, useLightsPerObject;

    ShadowSettings shadowSettings;

    PostFXSettings postFXSettings;

    //构造函数，初始化管线的一些属性
    public CustomRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, bool useLightsPerObject, 
        ShadowSettings shadowSettings, PostFXSettings postFXSettings)
    {
        this.shadowSettings = shadowSettings;
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        this.useLightsPerObject = useLightsPerObject;
        this.postFXSettings = postFXSettings;
        //配置SRP Batch
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        InitializeForEditor();
    }

    //必须重写Render函数，目前函数内部什么都不执行
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (Camera camera in cameras) 
        {
			renderer.Render(context, camera, useDynamicBatching, useGPUInstancing, useLightsPerObject, shadowSettings, postFXSettings);
		}
    }
}

