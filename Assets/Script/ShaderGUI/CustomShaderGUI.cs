using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class CustomShaderGUI : ShaderGUI
{
    //�洢��ǰ�۵���ǩ״̬
    private bool showPresets;

    private MaterialEditor editor;
    //��ǰѡ�е�material��������ʽ����Ϊ���ǿ���ͬʱ��ѡ���ʹ��ͬһShader�Ĳ��ʽ��б༭��
    private Object[] materials;
    private MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        EditorGUI.BeginChangeCheck();
        //���Ȼ��Ʋ���Inspector��ԭ�����е�GUI��������ʵ�Properties��
        base.OnGUI(materialEditor, properties);
        //��editor��material��properties�洢���ֶ���
        editor = materialEditor;
        materials = materialEditor.targets;
        this.properties = properties;

        BakedEmission();

        //����һ�п���
        EditorGUILayout.Space();
        //�����۵���ǩ
        showPresets = EditorGUILayout.Foldout(showPresets, "Presets", true);
        if (showPresets)
        {
            //���Ƹ�����ȾģʽԤ��ֵ�İ�ť
            OpaquePreset();
            ClipPreset();
            FadePreset();
            TransparentPreset();
        }
        if (EditorGUI.EndChangeCheck())
        {
            SetShadowCasterPass();
            CopyLightMappingProperties();
        }
    }

    void BakedEmission()
    {
        EditorGUI.BeginChangeCheck();
        editor.LightmapEmissionProperty();
        if (EditorGUI.EndChangeCheck())
        {
            foreach (Material m in editor.targets)
            {
                m.globalIlluminationFlags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }
    }

    /// <summary>
    /// ����float���͵Ĳ�������
    /// </summary>
    /// <param name="name">Property����</param>
    /// <param name="value">Ҫ�趨��ֵ</param>
	bool SetProperty(string name, float value)
    {
        MaterialProperty property = FindProperty(name, properties, false);
        if (property != null)
        {
            property.floatValue = value;
            return true;
        }
        return false;
    }

    /// <summary>
    /// ��ѡ�е����в�������shader�ؼ���
    /// </summary>
    /// <param name="keyword">�ؼ�������</param>
    /// <param name="enabled">�Ƿ���</param>
    void SetKeyword(string keyword, bool enabled)
    {
        if (enabled)
        {
            foreach (Material m in materials)
            {
                m.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach (Material m in materials)
            {
                m.DisableKeyword(keyword);
            }
        }
    }

    /// <summary>
    /// �ú����жϵ�ǰ�����Ƿ����������
    /// </summary>
    /// <param name="name">��������</param>
    /// <returns></returns>
    bool HasProperty(string name) => FindProperty(name, properties, false) != null;

    private bool HasPremultiplyAlpha => HasProperty("_PremulAlpha");

    /// <summary>
    /// ��Ϊ����֮ǰ��Lit.shader��ʹ��Toggle��ǩ���������л��ؼ��֣������ͨ�����뿪�عؼ���ʱҲҪ��Toggle������ͬ��
    /// </summary>
    /// <param name="name">�ؼ��ֶ�ӦToggle����</param>
    /// <param name="keyword">�ؼ�������</param>
    /// <param name="value">�Ƿ񿪹�</param>
    void SetProperty(string name, string keyword, bool value)
    {
        if (SetProperty(name, value ? 1f : 0f))
        {
            SetKeyword(keyword, value);
        }
    }

    private bool Clipping
    {
        set => SetProperty("_Clipping", "_CLIPPING", value);
    }

    private bool PremultiplyAlpha
    {
        set => SetProperty("_PremulAlpha", "_PREMULTIPLY_ALPHA", value);
    }

    private BlendMode SrcBlend
    {
        set => SetProperty("_SrcBlend", (float)value);
    }

    private BlendMode DstBlend
    {
        set => SetProperty("_DstBlend", (float)value);
    }

    private bool ZWrite
    {
        set => SetProperty("_ZWrite", value ? 1f : 0f);
    }

    enum ShadowMode
    {
        On, Clip, Dither, Off
    }

    ShadowMode Shadows
    {
        set
        {
            if (SetProperty("_Shadows", (float)value))
            {
                SetKeyword("_SHADOWS_CLIP", value == ShadowMode.Clip);
                SetKeyword("_SHADOWS_DITHER", value == ShadowMode.Dither);
            }
        }
    }

    RenderQueue RenderQueue
    {
        set
        {
            foreach (Material m in materials)
            {
                m.renderQueue = (int)value;
            }
        }
    }

    /// <summary>
    /// ������Ԥ��ֵǰ��ΪButtonע�᳷�ز���
    /// </summary>
    /// <param name="name">ButtonҪ���õ���Ⱦģʽ</param>
    /// <returns></returns>
    bool PresetButton(string name)
    {
        if (GUILayout.Button(name))
        {
            editor.RegisterPropertyChangeUndo(name);
            return true;
        }

        return false;
    }

    /// <summary>
    /// ����ΪOpaque����Ԥ��ֵ
    /// </summary>
    void OpaquePreset()
    {
        if (PresetButton("Opaque"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.Geometry;
        }
    }

    /// <summary>
    /// ����ΪAlpha Clip����Ԥ��ֵ
    /// </summary>
    void ClipPreset()
    {
        if (PresetButton("Clip"))
        {
            Clipping = true;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.SrcAlpha;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = true;
            RenderQueue = RenderQueue.AlphaTest;
        }
    }

    /// <summary>
    /// ����ΪFade(Alpha Blend,�߹ⲻ��ȫ����)����Ԥ��ֵ
    /// </summary>
    void FadePreset()
    {
        if (PresetButton("Fade"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.SrcAlpha;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }

    /// <summary>
    /// ����ΪTransparent(����Premultiply Alpha)����Ԥ��ֵ
    /// </summary>
    void TransparentPreset()
    {
        if (HasPremultiplyAlpha && PresetButton("Transparent"))
        {
            Clipping = false;
            PremultiplyAlpha = true;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }

    void SetShadowCasterPass()
    {
        MaterialProperty shadows = FindProperty("_Shadows", properties, false);
        if (shadows == null || shadows.hasMixedValue)
        {
            return;
        }
        bool enabled = shadows.floatValue < (float)ShadowMode.Off;
        foreach (Material m in materials)
        {
            m.SetShaderPassEnabled("ShadowCaster", enabled);
        }
    }

    void CopyLightMappingProperties()
    {
        MaterialProperty mainTex = FindProperty("_MainTex", properties, false);
        MaterialProperty baseMap = FindProperty("_BaseMap", properties, false);
        if (mainTex != null && baseMap != null)
        {
            mainTex.textureValue = baseMap.textureValue;
            mainTex.textureScaleAndOffset = baseMap.textureScaleAndOffset;
        }
        MaterialProperty color = FindProperty("_Color", properties, false);
        MaterialProperty baseColor = FindProperty("_BaseColor", properties, false);
        if (color != null && baseColor != null)
        {
            color.colorValue = baseColor.colorValue;
        }
    }
}
