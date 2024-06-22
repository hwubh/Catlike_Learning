- 1:Color Adjustments: 在传统的影视领域，color adjustments通常分为三步, 分别是color correction，color grading 和 tone mapping。color correction 用于修正图像使之接近真实的景象；color grading 用于调整场景的色调成我们希望的效果；tone mapping则将HDR color 映射到 显示范围内。
P.S:（unity中我们一般将color adjustment与color grading合成一步color garding）
  - 1.1：Color Grading Before Tone Mapping：在开始Tone mapping之前对输入的颜色进行color grading
  - 1.2：Settings：添加color grading相关配置到后处理堆上，参数有：*Post Exposure* ，*Contrast* ，*Color Filter* ，*Hue Shift* ，*Saturation*
  - 1.3：Post Exposure：模拟相机的曝光（光通量？），实现是通过 $color*2^{exposure}$.
  - 1.4: Contrast: 改变画面整体的对比度；实现：$(color - ACEScc_MIDGRAY) * contrast + ACEScc_MIDGRAY$, 相当于将color的颜色与色域的中间值做了根据contrast的数值进行scale，调整整体的光暗对比。 
         P.S.： ACEScc：ACES的对数子集，采用AP1色域
         ![v2-891afa21fe7be1acade71b829cdfe709_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-891afa21fe7be1acade71b829cdfe709_r.png) 
  - 1.5：Color Filter： 根据输入的颜色整体做偏移；实现：$color * colorfilter$
  - 1.6: Hue Shift(色相偏移): 将颜色RGB转入**HSV**, 对**H**项进行偏移，再转回RGB格式。![v2-e9f9c843e7d60e8f7aa7de1cd61d1818_720w](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-e9f9c843e7d60e8f7aa7de1cd61d1818_720w.webp)
  - 1.7：Saturation：调整画面的饱和度。实现：$(color - luminance) * Saturation + luminance$， 相当于将color的颜色与color的luminance（*灰阶值*）做了根据Saturation的数值进行scale，调整整体的颜色饱和度。

- 2：More Controls：
  - 2.1：White Balance：用于调整颜色的**色温**（*temperature*）和**色调**（*tint*），因为不同*色温*的光源发出的光有着不同的*色调*![v2-4a60b2673db6313fbcb889e581538863_720w](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-4a60b2673db6313fbcb889e581538863_720w.webp)
         *Temperature*可以调整图像偏向暖/冷色调：
         *Tint* 可以调整图像对于 绿色与品红 色之间的色偏（color casts？）；
  - 2.2：Split Toning：根据亮度值对图像的不同区域（亮，暗）进行着色，分别传入*highlight* 和 *shadows* 用于着色。然后根据亮度与传入的*balance*值 对场景偏向*highlight*，*shadows*之间做权重？![20240622230206](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240622230206.png) P.S.另外需要注意的是我们传入的*highlight*，*shadows*颜色不是sRGB空间下的，需要进行Gamma矫正？？。
  - 2.3：Channel Mixer： 可以根据传入的RGB值通过*矩阵*变换为另一个RGB值。
  - 2.4：Shadows Midtones Highlights：类似“Split Toning”，但基于亮度（灰阶度）将场景划分（通过smoothstep）为“亮”，“中间”，“暗”三个区域，并分别对应*shadows, midtones, highlights*三种传入的颜色进行着色。![20240622233849](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240622233849.png)
  - 2.5：ACES Color Spaces：在使用ACES Tone mapping时，一些Color grading需要转换到ACES色域中已取得更好的效果（为啥？？）。包含Contrast，SplitToning，ShadowsMidtonesHighlights，Saturation以及最后的ToneMapping。为此我们需要做相应的判断，并将颜色转到ACEScc色域中，luminance（灰阶度）的计算也需要使用对应的函数“AcesLuminance”，

- 3：LUT: 相较于运行时在后处理中进行Color Grading等一系列全屏处理，将对应的映射关系离线烘焙成一张贴图是更为性能友好的方式。Look-up table(LUT)便是其中一种常见的方式。LUT一般是一张32\*32\*32大小的3D贴图，（但也可以是2D的长条贴图）。
  - 3.1：LUT Resolution： 在pipelineAsset上添加LUT的配置，设置LUT的分辨率
  - 3.2：Rendering to a 2D LUT Texture： 因为通常shader无法3D Texture，我们可以将第三轴沿着x轴展开，变换为2D的长条贴图
  - 3.3：LUT Color Matrix：为了创建合适的LUT，我们需要用颜色转换矩阵填充它。可以通过GetLutStripValue函数找到LUT输入颜色。它需要UV坐标和我们需要发送到GPU的颜色分级lut参数向量。![20240623023104](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240623023104.png)
  - 3.4：Log C LUT：在线形空间中得到的LUT的映射空间只包含了0~1, 为了支持HDR，我们需要将输入的颜色转换到 LogC空间 将映射空间扩展至0~60![20240623023503](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240623023503.png)
  - 3.5：Final Pass： 最后添加一个pass将输入的图像通过LUT进行映射。
  - 3.6：LUT Banding：因为LUT的精度限制以及采样时采用的双线性插值，一些极端情况下，我们映射出来的结果的不同颜色间出现明显的边界。![20240623024303](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240623024303.png)
                      另外如果使用sampler_point_clamp，当采样到LUT上各个色块的边界也会导致映射的结果存在一些问题。![20240623024814](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240623024814.png)
                      P.S.:注意事项：
                      1.取消Mipmap设置
                      2.Format格式要改为RGB24
                      3.2D方式 贴图要把 anisolevel 等级设置为0
                      4.3D方式 打开Read/Write enabled
                      5.贴图的sRGB关闭，否则线性空间会有问题




参考文献：https://blog.csdn.net/weixin_46884197/article/details/120736980 ； https://zhuanlan.zhihu.com/p/98834866 ；https://zhuanlan.zhihu.com/p/98835300 ； https://www.red.com/red-101/color-cast-tutorial