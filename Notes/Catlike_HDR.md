- 1：High Dynamic Range（HDR）: 在标准渲染（SDR）中，像素的红色、绿色和蓝色值均使用一个 0 到 1 范围内的 8 位值进行存储，其中 0 表示零强度，1 表示显示设备的最大强度。当fragment的计算结果大于1，输出到framebuffer时，实际上都是clamp到1来处理，即便这些数值本身可能并不一致。考虑到现实中光强实际上不存在一个固有的上线（如太阳光，多光源时），并且当存在非常亮或非常暗的元素时，笼统地将数值clamp到0~1之间，会导致图像不真实。 HDR buffer以浮点格式保存了数值大于1的像素颜色，可以较好的保留场景的明暗细节。
  - 1.1：reflection probe：反射探针可以启用HDR以获得更精细的效果![20240621232715](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240621232715.png)
  - 1.2：HDR Cameras：我们可以在pipeline asset 或相机上调整是否开启HDR![20240621233253](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240621233253.png)
  - 1.3：HDR Render Textures：开启HDR时，colorattachment的格式为R16G16B16A16_SFloat，通道是使用SDR时的两倍大小，而且储存的是**线形空间**下的signed float数值
  - 1.4：HDR Post Processing：将Bloom使用的贴图也调整为R16G16B16A16_SFloat，因为数值上限不再是1，所以当threshold调整到1时仍有效果。且因为数值不再局限在1以下，卷积的结果也比SDR下大（光晕范围扩大）
  - 1.5：Fighting Fireflies： 因为HDR会使一小块高数值的区域造成很大的光晕，当移动时，光晕会随着区域的面积变化而急剧变化，造成频繁抖动。（这种区域就是所谓的fireflies）。为了解决这个问题，我们可以扩大filter的范围，尽可能做到平均。另外引入Luminance-based weights，对亮度变化比较大的地方进行矫正（暗的地方权重大）![20240622002324](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240622002324.png)
- 2：Scattering Bloom：与之前的bloom效果（additive）相比，散射并没有在原图上加“光”（能量守恒），且有更多的随机性？。
  - 2.1：Bloom Mode：添加Scatter模式，上采样时根据scatter的数值在高分辨率和低分辨率的source图上之间进行插值。
  - 2.2：Scatter Limits ：限制intensity和scatter的范围。防止intensity大于1时，不考虑colorattachement的亮度信息。
  - 2.3：Threshold：scatter模式下，只有非常亮的光源有散射的效果。为了凸显bloom的效果，我们将threshold调高，但这也会时整个画面偏暗。为此我们在最后绘制时将损失的光添加进低分辨率图（上采样的最后结果图）中，然后再与colorattachment进行混合
- Tone mapping: 对于场景中过曝的区域（亮度大于1），除了用bloom来强调外，也可以将大于1的部分（如场景存在0~1.5）重新映射到0~1之间，通过对比确保过曝的区域的细节。
  - 3.1：Extra Post FX Step：存在bloom效果时，取用bloom处理过的colorattachment
  - 3.2：Tone Mapping Mode： 添加Tone Mapping Mode到后处理的设置中
  - 3.3：Reinhard： 映射时需要一个非线性转换，该转换不会减少很多暗值，但会减少很多高值。 ![20240622015100](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240622015100.png) 。 同时需要注意如果场景存在过强的光源时，会导致映射后的精度不足。所以最好在映射前对光源的光强的上线做限制。
  - 3.4：Neutral：Reinhard色调映射的白点在理论上是无限的，但可以对其进行调整，以便尽早达到最大值。一种可能的替代是![20240622020954](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240622020954.png)。 但《神秘海域2》中提到了一种新的计算方式可以使曲线在暗部斜率更大，而在亮部更为平缓![![20240622021203](httpsraw.githubusercontent.comhwubhhwubh_Picturesmain20240622021203.png)](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/!%5B20240622021203%5D(httpsraw.githubusercontent.comhwubhhwubh_Picturesmain20240622021203.png).png) 。 而在URP与HDRP中使用了其的变体，白点在4.035![20240622021401](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240622021401.png)
  - 3.5：ACES（Academy Color Encoding System）： ACES是用通用的tone mapping标准，该方式对亮部进行了色彩偏移，使之更明亮。另外对暗部也进行了一定的降低，突出了画面整体的对比度。![0149709ceeb67532d4202a1a450f3584_r-1](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/0149709ceeb67532d4202a1a450f3584_r-1.png)





- 参考：https://docs.unity3d.com/Manual/HDR.html；https://zhuanlan.zhihu.com/p/609569101；https://zhuanlan.zhihu.com/p/21983679