using UnityEngine;
using UnityEngine.Rendering;

public class CameraRenderer
{
    //存放当前渲染上下文
    private ScriptableRenderContext context;

    //存放摄像机渲染器当前应该渲染的摄像机
    private Camera camera;

    const string bufferName = "Render Camera";

    CullingResults cullingResults;

    CommandBuffer cmd = new CommandBuffer {name = bufferName};

    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");

    //摄像机渲染器的渲染函数，在当前渲染上下文的基础上渲染当前摄像机
    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;

        if (!Cull())
        {
            return;
        }

        SetUp();
        DrawVisibleGeometry();
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

    public void DrawVisibleGeometry()
    {
        //决定物体绘制顺序是正交排序还是基于深度排序的配置
        var sortingSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque
        };
        var drawingSetting = new DrawingSettings(unlitShaderTagId, sortingSettings);
        var filteringSetting = new FilteringSettings(RenderQueueRange.all, -1, uint.MaxValue);
        context.DrawRenderers(cullingResults, ref drawingSetting, ref filteringSetting);
        context.DrawSkybox(camera);
    }

    void SetUp()
    {
        cmd.BeginSample(bufferName); 
        context.SetupCameraProperties(camera);
        cmd.ClearRenderTarget(RTClearFlags.All, Color.clear, 1.0f, 0);
        ExecuteBuffer();
    }

    public void Submit()
    {
        cmd.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();
    }

    private void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
    }

}
