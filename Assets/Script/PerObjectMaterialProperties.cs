using UnityEngine;

//���ԣ�������ͬһ����Ҷ�������
[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    //��ȡ��Ϊ"_BaseColor"��Shader���ԣ�ȫ�֣�
    static int baseColorId = Shader.PropertyToID("_BaseColor");
    static int cutoffId = Shader.PropertyToID("_Cutoff");

    //ÿ�������Լ�����ɫ
    [SerializeField] Color baseColor = Color.white;

    [SerializeField, Range(0f, 1f)]
    float cutoff = 0.5f;

    //MaterialPropertyBlock���ڸ�ÿ���������ò������ԣ���������Ϊ��̬����������ʹ��ͬһ��block
    private static MaterialPropertyBlock block;

    //ÿ�����ýű�������ʱ������� OnValidate��Editor�£�
    private void OnValidate()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
        }

        //����block�е�baseColor����(ͨ��baseCalorId����)ΪbaseColor
        block.SetColor(baseColorId, baseColor);
        block.SetFloat(cutoffId, cutoff);
        //�������Renderer�е���ɫ����Ϊblock�е���ɫ
        GetComponent<Renderer>().SetPropertyBlock(block);
    }

    //RuntimeʱҲִ��
    private void Awake()
    {
        OnValidate();
    }
}
