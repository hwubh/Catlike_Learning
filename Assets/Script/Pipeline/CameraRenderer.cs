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

    Lighting lighting = new Lighting();

#if UNITY_EDITOR
#else
	const string SampleName = bufferName;
#endif

    //摄像机渲染器的渲染函数，在当前渲染上下文的基础上渲染当前摄像机
    public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing)
    {
        this.context = context;
        this.camera = camera;

#if UNITY_EDITOR
        PrepareBuffer(cmd);
        PrepareForSceneWindow();
        DrawGizmos();
#endif

        if (!Cull())
        {
            return;
        }

        SetUp();
        lighting.Setup(context, cullingResults);
        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
        DrawUnsupportedShaders();
        Submit();
    }

    bool Cull()
    {
        //获取摄像机用于剔除的参数
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
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
