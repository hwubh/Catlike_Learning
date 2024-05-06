using UnityEngine;

//�������������Ӱ����ѡ�������
[System.Serializable]
public class ShadowSettings
{
    //maxDistance������Ұ�ڶ��Χ�ᱻ��Ⱦ����Ӱ��ͼ�ϣ����������������maxDistance�����岻�ᱻ��Ⱦ����Ӱ��ͼ��
    //������߼��²����£�
    //1.����maxDistance�����������Զƽ�棩�õ�һ��BoundingBox��Ҳ�����Ǹ����ͣ������BoundingBox����������Ҫ��Ⱦ��Ӱ������
    //2.�������BoundingBox��Ҳ�����Ǹ����ͣ��ͷ����Դ�ķ���ȷ����Ⱦ��Ӱ��ͼ�õ��������������׶�壬��Ⱦ��Ӱ��ͼ
    [Min(0.001f)] 
    public float maxDistance = 100f;

    [Range(0.001f, 1f)]
    public float distanceFade = 0.1f;

    //��Ӱ��ͼ�����гߴ磬ʹ��ö�ٷ�ֹ����������ֵ����ΧΪ256-8192��
    public enum TextureSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096,
        _8192 = 8192
    }

    public enum FilterMode
    {
        PCF2x2, PCF3x3, PCF5x5, PCF7x7
    }

    //���巽���Դ����Ӱ��ͼ����
    [System.Serializable]
    public struct Directional
    {
        public TextureSize atlasSize;

        public FilterMode filter;

        [Range(1, 4)]
        public int cascadeCount;

        [Range(0f, 1f)]
        public float cascadeRatio1, cascadeRatio2, cascadeRatio3;

        public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);

        [Range(0.001f, 1f)]
        public float cascadeFade;

        public enum CascadeBlendMode
        {
            Hard, Soft, Dither
        }

        public CascadeBlendMode cascadeBlend;
    }

    //����Ƿ����Դ����Ӱ��ͼ����
    [System.Serializable]
    public struct Other
    {
        public TextureSize atlasSize;
        public FilterMode filter;
    }

    public Other other = new Other
    {
        atlasSize = TextureSize._1024,
        filter = FilterMode.PCF2x2
    };

    //����һ��1024��С��Directional Shadow Map
    public Directional directional = new Directional()
    {
        atlasSize = TextureSize._1024,
        filter = FilterMode.PCF2x2,
        cascadeCount = 4,
        cascadeRatio1 = 0.1f,
        cascadeRatio2 = 0.25f,
        cascadeRatio3 = 0.5f,
        cascadeFade = 0.1f,
        cascadeBlend = Directional.CascadeBlendMode.Hard
    };
}
