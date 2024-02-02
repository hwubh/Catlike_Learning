using UnityEngine;

//���ԣ�������ͬһ����Ҷ�������
[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    //��ȡ��Ϊ"_BaseColor"��Shader���ԣ�ȫ�֣�
    private static int baseColorId = Shader.PropertyToID("_BaseColor");

    //ÿ�������Լ�����ɫ
    [SerializeField] Color baseColor = Color.white;

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
        //�������Renderer�е���ɫ����Ϊblock�е���ɫ
        GetComponent<Renderer>().SetPropertyBlock(block);
    }

    //RuntimeʱҲִ��
    private void Awake()
    {
        OnValidate();
    }
}
