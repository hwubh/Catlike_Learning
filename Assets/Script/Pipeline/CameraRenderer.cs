using System;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{
    //存放当前渲染上下文
    private ScriptableRenderContext context;

    //存放摄像机渲染器当前应该渲染的摄像机
    private Camera camera;

    const string bufferName = "Render Camera";

    CullingResults cullingResults;

    CommandBuffer cmd = new CommandBuffer { name = bufferName };

    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    static ShaderTagId litShaderTagId = new ShaderTagId("CustomLit");

    	CommandBuffer buffer = new CommandBuffer {
		name = bufferName
	};

    Lighting lighting = new Lighting();

#if UNITY_EDITOR
#else
	const string SampleName = bufferName;
#endif

    //摄像机渲染器的渲染函数，在当前渲染上下文的基础上渲染当前摄像机
    public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing, ShadowSettings shadowSettings)
    {
        this.context = context;
        this.camera = camera;

#if UNITY_EDITOR
        PrepareBuffer(cmd);
        PrepareForSceneWindow();
        DrawGizmos();
#endif

        if (!Cull(shadowSettings.maxDistance))
        {
            return;
        }

        cmd.BeginSample(SampleName);
        ExecuteBuffer();
        lighting.Setup(context, cullingResults, shadowSettings);
        cmd.EndSample(SampleName);
        SetUp();
        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
        DrawUnsupportedShaders();
        lighting.Cleanup();
        Submit();
    }

    bool Cull(float maxShadowDistance)
    {
        //获取摄像机用于剔除的参数
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            //实际shadowDistance取maxShadowDistance和camera.farClipPlane中较小值
            p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
            cullingResults = context.Cull(ref p);
            return true;
        }

        return false;
    }


    public void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing)
    {
        //决定物体绘制顺序是正交排序还是基于深度排序的配置
        var sortingSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque
        };
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);

        //增加对Lit.shader的绘制支持,index代表本次DrawRenderer中该pass的绘制优先级（0最先绘制）
        drawingSettings.SetShaderPassName(1, litShaderTagId);

        var filteringSetting = new FilteringSettings(RenderQueueRange.opaque, -1, uint.MaxValue);
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSetting);

        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        filteringSetting.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSetting);
    }

    void SetUp()
    {
        context.SetupCameraProperties(camera);
        CameraClearFlags flags = camera.clearFlags;
        cmd.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color, flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);
        cmd.BeginSample(SampleName);
        ExecuteBuffer();
    }

    public void Submit()
    {
        cmd.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }

    private void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
    }

}
