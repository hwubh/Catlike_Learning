using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

//���ڰѳ����еĹ�Դ��Ϣͨ��cpu���ݸ�gpu
public class Lighting
{
    private const string bufferName = "Lighting";
    //������Դ����
    private const int maxDirLightCount = 4, maxOtherLightCount = 64;

    static int
        otherLightCountId = Shader.PropertyToID("_OtherLightCount"),
        otherLightColorsId = Shader.PropertyToID("_OtherLightColors"),
        otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions"),
        otherLightDirectionsId = Shader.PropertyToID("_OtherLightDirections"),
        otherLightSpotAnglesId = Shader.PropertyToID("_OtherLightSpotAngles"),
        otherLightShadowDataId = Shader.PropertyToID("_OtherLightShadowData");

    static Vector4[]
        otherLightColors = new Vector4[maxOtherLightCount],
        otherLightPositions = new Vector4[maxOtherLightCount],
        otherLightDirections = new Vector4[maxOtherLightCount],
        otherLightSpotAngles = new Vector4[maxOtherLightCount],
        otherLightShadowData = new Vector4[maxOtherLightCount];

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
    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings, bool useLightsPerObject)
    {
        //�洢���ֶη���ʹ��
        this.cullingResults = cullingResults;
        //���ڴ��ݹ�Դ���ݵ�GPU����һ���̣����ǿ����ò���CommandBuffer�µ�ָ���ʵ�õ���buffer.SetGlobalVector������������Ȼʹ����������Debug
        buffer.BeginSample(bufferName);
        shadows.Setup(context, cullingResults, shadowSettings);
        //����cullingResults�µ���Ч��Դ
        SetupLights(useLightsPerObject);
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

    void SetupPointLight(int index, ref VisibleLight visibleLight)
    {
        otherLightColors[index] = visibleLight.finalColor;
        Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
        position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
        otherLightPositions[index] = position;
        otherLightSpotAngles[index] = new Vector4(0f, 1f);
        Light light = visibleLight.light;
        otherLightShadowData[index] = shadows.ReserveOtherShadows(light, index);
    }

    void SetupSpotLight(int index, ref VisibleLight visibleLight)
    {
        otherLightColors[index] = visibleLight.finalColor;
        Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
        position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
        otherLightPositions[index] = position;
        otherLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);

        Light light = visibleLight.light;
        float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.innerSpotAngle);
        float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * visibleLight.spotAngle);
        float angleRangeInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
        otherLightSpotAngles[index] = new Vector4(angleRangeInv, -outerCos * angleRangeInv);
        otherLightShadowData[index] = shadows.ReserveOtherShadows(light, index);
    }

    static string lightsPerObjectKeyword = "_LIGHTS_PER_OBJECT";
    void SetupLights(bool useLightsPerObject)
    {
        NativeArray<int> indexMap = useLightsPerObject ? cullingResults.GetLightIndexMap(Allocator.Temp) : default;
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        //ѭ����������Vector����
        int dirLightCount = 0, otherLightCount = 0;
        int i;
        for (i = 0; i < visibleLights.Length; i++)
        {
            int newIndex = -1;
            VisibleLight visibleLight = visibleLights[i];

            //���ݹ�Դ���ͽ�������
            switch (visibleLight.lightType)
            {
                case LightType.Directional:
                    if (dirLightCount < maxDirLightCount)
                    {
                        SetupDirectionalLight(dirLightCount++, ref visibleLight);
                    }
                    break;
                case LightType.Point:
                    if (otherLightCount < maxOtherLightCount)
                    {
                        newIndex = otherLightCount;
                        SetupPointLight(otherLightCount++, ref visibleLight);
                    }
                    break;
                case LightType.Spot:
                    if (otherLightCount < maxOtherLightCount)
                    {
                        newIndex = otherLightCount;
                        SetupSpotLight(otherLightCount++, ref visibleLight);
                    }
                    break;
            }
            if (useLightsPerObject)
            {
                indexMap[i] = newIndex;
            }
        }

        if (useLightsPerObject)
        {
            for (; i < indexMap.Length; i++)
            {
                indexMap[i] = -1;
            }
            cullingResults.SetLightIndexMap(indexMap);
            indexMap.Dispose();
            Shader.EnableKeyword(lightsPerObjectKeyword);
        }
        else
        {
            Shader.DisableKeyword(lightsPerObjectKeyword);
        }

        if (dirLightCount > 0)
        {
            buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
            buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
            buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
        }

        buffer.SetGlobalInt(otherLightCountId, otherLightCount);
        if (otherLightCount > 0)
        {
            buffer.SetGlobalVectorArray(otherLightColorsId, otherLightColors);
            buffer.SetGlobalVectorArray(otherLightPositionsId, otherLightPositions);
            buffer.SetGlobalVectorArray(otherLightDirectionsId, otherLightDirections);
            buffer.SetGlobalVectorArray(otherLightSpotAnglesId, otherLightSpotAngles);
            buffer.SetGlobalVectorArray(otherLightShadowDataId, otherLightShadowData);
        }
    }

    public void Cleanup()
    {
        shadows.Cleanup();
    }
}
