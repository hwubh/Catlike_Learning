using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

//���ڰѳ����еĹ�Դ��Ϣͨ��cpu���ݸ�gpu
public class Lighting
{
    private const string bufferName = "Lighting";
    //������Դ����
    private const int maxDirLightCount = 4;

    //��ȡCBUFFER�ж�Ӧ�������Ƶ�Id��CBUFFER�Ϳ��Կ���Shader��ȫ�ֱ�����
    private static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount"),
        dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors"),
        dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections"),
        dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");

    private static Vector4[] dirLightColors = new Vector4[maxDirLightCount],
    dirLightDirections = new Vector4[maxDirLightCount],
    dirLightShadowData = new Vector4[maxDirLightCount];

    private CommandBuffer buffer = new CommandBuffer()
    {
        name = bufferName
    };

    //��Ҫʹ�õ�CullingResults�µĹ�Դ��Ϣ
    private CullingResults cullingResults;

    Shadows shadows = new Shadows();

    //�������context����ע��CmmandBufferָ�cullingResults���ڻ�ȡ��ǰ��Ч�Ĺ�Դ��Ϣ
    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
    {
        //�洢���ֶη���ʹ��
        this.cullingResults = cullingResults;
        //���ڴ��ݹ�Դ���ݵ�GPU����һ���̣����ǿ����ò���CommandBuffer�µ�ָ���ʵ�õ���buffer.SetGlobalVector������������Ȼʹ����������Debug
        buffer.BeginSample(bufferName);
        shadows.Setup(context, cullingResults, shadowSettings);
        // SetupDirectionalLight();
        //����cullingResults�µ���Ч��Դ
        SetupLights();
        shadows.Render();
        buffer.EndSample(bufferName);
        //�ٴ���������ֻ���ύCommandBuffer��Context��ָ������У�ֻ�еȵ�context.Submit()�Ż���������ִ��ָ��
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    //����Vector4�����еĵ�������
    //������visibleLight�����ref�ؼ��֣���ֹcopy����VisibleLight�ṹ�壨�ýṹ��ռ�ܴ�
    void SetupDirectionalLight(int index, ref VisibleLight visibleLight)
    {
        //VisibleLight.finalColorΪ��Դ��ɫ��ʵ���ǹ�Դ��ɫ*��Դǿ�ȣ�����Ĭ�ϲ���������ɫ�ռ䣬��Ҫ��Graphics.lightsUseLinearIntensity����Ϊtrue��
        dirLightColors[index] = visibleLight.finalColor;
        //��Դ����Ϊ��ԴlocalToWorldMatrix�ĵ����У�����Ҳ��Ҫȡ��
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);
    }

    void SetupLights()
    {
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        //ѭ����������Vector����
        int dirLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight visibleLight = visibleLights[i];

            //ֻ���÷����Դ
            if (visibleLight.lightType == LightType.Directional)
            {
                //���������е�����Դ������
                SetupDirectionalLight(dirLightCount++, ref visibleLight);
                if (dirLightCount >= maxDirLightCount)
                {
                    //��󲻳���4�������Դ
                    break;
                }
            }
        }

        //���ݵ�ǰ��Ч��Դ������Դ��ɫVector���顢��Դ����Vector���顣
        buffer.SetGlobalInt(dirLightCountId, visibleLights.Length);
        buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
        buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
    }

    public void Cleanup()
    {
        shadows.Cleanup();
    }
}
