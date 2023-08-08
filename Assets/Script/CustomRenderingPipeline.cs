using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
	CameraRenderer renderer = new CameraRenderer();

    //必须重写Render函数，目前函数内部什么都不执行
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (Camera camera in cameras) 
        {
			renderer.Render(context, camera);
		}
    }
}

