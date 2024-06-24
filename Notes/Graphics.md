- 1：#Normal #transform #Object_Space #World_Space Stop Using Normal Matrix: https://lxjk.github.io/2017/10/01/Stop-Using-Normal-Matrix.html
    *Tips* :![20240213203944](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240213203944.png) The "M" should be "M<sup>'</sup>"

- 2：Texture Compression： https://zhuanlan.zhihu.com/p/634020434; https://zhuanlan.zhihu.com/p/237940807
  - ETC: 人眼对亮度而不是色度更敏感这一事实。 因此，每个子块中仅存储一种基色 (ETC1/ETC2 由两个子块组成) ，但亮度信息是按每个纹素存储的。子块由1个基本颜色值和4个修饰值可以确定出4种新的颜色值。
    - 2个分块*16bit: 存储1个RGB基色（12bit）, 1bit “diff”， 3bit 修饰位； 16个2位选择器，从四个颜色中选出一个。
  - DXTC：https://en.wikipedia.org/wiki/S3_Texture_Compression
    - DXT1: 用于RGB或只有1bit Alpha的贴图 
      - 4*4*64bit 为一个单位，前32bit存贮颜色的两个极端值(c0,c1)，后32bit分为4*4的lookup page，每个page对应一个pixel和2bit状态符（0:c0; 1: c1; 2:c2(插值的颜色)；3：c3（插值的颜色或transparent, if c0 <= c1））
    - DXT2/3：在DXT1的基础上多出64bit来描述alpha信息，每个pixel的alpha 4bit存储
      - DXT2：color: Premultiplied by alpha
      - DXT3：独立
    - DXT4/5: 在DXT1的基础上多出64bit来描述alpha信息，alpha 以类似color的方式存贮，64bit 包含2个4bit 极端值，16个3bit 状态符。
      - if c0> c1, c2~7 插值； if c0 <= c1, c2~5插值，c6=0, c7=255
  - PVRTC:
    - 不同于DXT和ETC这类基于块的算法，而将整张纹理分为了高频信号和低频信号，低频信号由两张低分辨率的图像A和B表示，这两张图在两个维度上都缩小了4倍，高频信号则是全分辨率但低精度的调制图像M，M记录了每个像素混合的权重。要解码时，A和B图像经过双线性插值（bilinearly）宽高放大4倍，然后与M图上的权重进行混合。
  - ASTC: https://zhuanlan.zhihu.com/p/158740249
    - 每块固定使用128bit，块size：4*4~12*12

- 3：Color Space：https://zhuanlan.zhihu.com/p/548826041 ; https://zhuanlan.zhihu.com/p/66558476 ; https://zhuanlan.zhihu.com/p/609569101
  ![20240610133007](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240610133007.png)
  - Gamma：2.2，屏幕输出时会将颜色变换到Gamma2.2空间中：$l = u^2.2, (l,u \in (0,1))$
  - Gamma矫正：$\frac 1 {2.2}$, 在屏幕输出前转到Gamma0.45，使屏幕最终输出转为Gamma1.0：$u_0 = u_i^{\frac{1}{2.2}}$
  - sRBG: Gamma0.45 Color Space
    - Why: <!-- 1: 存储时进行Gamma矫正；2： -->人眼对暗部更敏感，用更大的数据范围来存暗色，用较小的数据范围来存亮色。（下注）
           - Physically Linear（物理）: 以物理光子数量描述的线性数值空间 
             Perceptually Linear(感知): 以光子进入人眼产生的感知亮度描述的线性数值空间![v2-c3b18b218328d622be8a647b41b9c523_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-c3b18b218328d622be8a647b41b9c523_r.png)
             二者为幂律关系：Vphysically = （Vperceptual）^ gamma
             如果（相机/贴图）用**物理亮度**来记录**感知亮度**，则会有**精度**问题：当感知亮度为0.5时，对应的物理亮度只占据$\frac{1}{4}$的记录空间。用物理空间的亮度值来做为图像texel值的话，会使得保存或描述暗部颜色的bit位数不足，而人眼恰好善长分辨暗的颜色，这会让很多暗的颜色丢失。![v2-943fd8197c308e924e4cbc954f260741_720w](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-943fd8197c308e924e4cbc954f260741_720w.webp)
             因此，通常（相机/贴图）实际记录的是感知亮度。将接收的的物理亮度转化为感知亮度的过程称为**gamma encode**或**Image File gamma**。 将记录的感知亮度转化为物理亮度并发射称为**gamma decode**或**display gamma**。将前两者的乘积（多为*1*），称为**System gamma**。
    - Shader中的处理： 实际运算需现将**感知亮度**（sRGB贴图中的texel值）通过^2.2(**Remove Gamma Correction**)转换成**物理亮度**再实际进行。计算结束后需将结果再通过^0.45(**Gamma Correction**)转化为**感知亮度**。
    - 贴图：一般Diffuse（albedo）为sRBG, 而specular maps、normal maps，light maps，一些HDR格式的图片为线形物理空间（物理亮度）的贴图，以节省转换。
  - Unity：如果选择了Gamma，那Unity不会对输入和输出做任何处理，换句话说，Remove Gamma Correction 、Gamma Correction都不会发生，除非你自己手动实现；而Linear则对Shaderlab中的*颜色*输入，有[Gamma]前缀的Property变量（如*金属度*）以及在*sRGB Texture*采样前进行Remove Gamma Correction。
  - Gamma空间：使用非sRGB diffuse图时可以节省一步Remove Gamma Correction运算。
  - Linear空间：使用sRGB diffuse时美术查看效果方便，shader中可以不用写Remove Gamma Correction。但Remove Gamma Correction必不可少。

- 4：卷积：两个函数（输入函数：f(x), 权值函数：g(x)）的卷积，本质上就是先将一个函数翻转，然后进行滑动叠加。
     卷积的本质就是加权积分, 对于（输入函数：f(x), 权值函数：g(x)）来说，g是f的权值函数，表示输入f各个点对输出结果的影响大小。数学定义∑f(x)g(n-x)中的n-x表示x的权值和什么相关，也可以理解为一种约束。![20240616182256](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616182256.png)
  - 卷：函数的翻转：为“积”施加约束，指定参考（如信号分享中的在特定的时间段的前后进行“积”）
  - 积：积分/加权求和：是**全局**概念，把两个函数在时间或者空间上进行混合
  - ![v2-847a8d7c444508862868fa27f2b4c129_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-847a8d7c444508862868fa27f2b4c129_r.jpg)

- 5: 采样定理，频谱混叠和傅里叶变换：https://zhuanlan.zhihu.com/p/74736706 https://zhuanlan.zhihu.com/p/627793196
  - 采样：把模拟信号转换为计算机可以处理的数字信号的过程；采样定理：只有当采样频率fs.max > 最高频率fmax的2倍时，才能比较好的保留原始信号的信息。（实践中倍率多为介于2.56~4）
  - 狄拉克函数：在时域和频域都是脉冲状的；
    时域：周期为$T_s$![v2-2b3c294a40466b50571b0d905b34cb63_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-2b3c294a40466b50571b0d905b34cb63_r.jpg)
    频域：周期为$\frac{2\pi}{T_s}$![20240616200427](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616200427.png)
  - 时域的乘积等于频域的卷积（反之亦然）：采样相当于在频域在冲激函数的各频率处重复目标信号的频谱![v2-057fdc41813a61dae12dae44dcd49cd9_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-057fdc41813a61dae12dae44dcd49cd9_r.jpg)
  - 频域与时域：![20190513004552862](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20190513004552862.gif)
  - 频谱的混叠：在时域上采样如果不够快，也就是采样函数的频率过低，那么频域上频率重复的就会变得过快，最终会造成频谱的混叠![v2-914d0b3b671270340c5c872663f89b09_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-914d0b3b671270340c5c872663f89b09_r.jpg)
    当混叠发生时，可用使用*低通滤波*过滤到低频信息（图像上表现为模糊）![v2-12a2df5bc1b0d2fa13163f340f5a28ee_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-12a2df5bc1b0d2fa13163f340f5a28ee_r.jpg)

- FXAA与Sharpening：https://zhuanlan.zhihu.com/p/431384101 https://catlikecoding.com/unity/tutorials/custom-srp/fxaa/#3.7 https://wingstone.github.io/posts/2021-03-01-fxaa/
  - FXAA：Quality：
    - 边缘判断：梯度计算，采样5次，![20240616232605](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616232605.png)
    - 基于亮度的混合系数计算：采样9次，通过计算目标像素和周围像素点的平均亮度的差值，我们来确定将来进行颜色混合时的权重；![20240616232920](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616232920.png)
    - 计算混合方向：取梯度最大的方向，向上为正，向下为负，向右为正，向左为负：![20240616233142](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616233142.png)
    - 混合：将当前像素点的 uv ，沿着偏移的方向，按照偏移权重偏移；![20240616233334](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616233334.png)
    - 边界混合系数：针对斜边，要得到得到正确的混合系数，就需要扩大采样范围。判断边界的方式是计算两侧的亮度值的差，是否和当前的亮度变化梯度值符合。![20240616233628](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616233628.png)![20240616233702](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616233702.png)
  - FXAA: Console：简化版本
    -  边缘判断：梯度计算，采样5次，同Quality
    -  方向判断：计算当前亮度变化的梯度值，即亮度变化最快的方向，就是锯齿边界的法线方向。![20240616234222](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616234222.png)
    -  混合：沿着切线方向分别向正负方向偏移 UV ，进行两次采样，再平均后作为抗锯齿的结果。![20240616234250](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616234250.png)
    -  边界混合：因为对水平和垂直方向的锯齿不友好，故将偏移距离延伸至更远处。做法是用Dir 向量分量的最小值的倒数，将 Dir1 进行缩放。![20240616234723](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616234723.png)![20240616234752](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240616234752.png)
  - 缺点：在光照高频(颜色变化很快)的地方不稳定（blend anything that has high enough contrast, including isolated pixels），移动摄影机时，会导致一些闪烁。
  - 可用于几何抗拒齿也可用于shading抗拒齿；使用一个pass即可实现FXAA，非常易于集成；与MSAA相比能节省大量内存；可用于延迟渲染；
  - 如何缓解FXAA带来模糊感？：https://gamedev.stackexchange.com/questions/104339/how-do-i-counteract-fxaa-blur
    - sharpending？/edge detection： 先用edge detection 计算出高频部分，然后乘以一个sharpness系数，加上FXAA处理后的图片。

- TAA：历史帧的数据来实现抗锯齿，每个像素点有多个采样点，但均摊到多个帧中。
  - 静态：只保留上一帧计算的结果与当前帧两帧。
    - 次采样点：就是在每帧采样时，将采样的点进行偏移，实现**抖动** (jitter)。 采样点的偏移与次序使用 *Halton* 序列![20240624194119](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240624194119.png)
             **抖动**：通过修改投影矩阵的$m_20 , m_21$项来偏移XY分量。![v2-143d0f5393f5c7b9d9b18eeba2ce66eb_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-143d0f5393f5c7b9d9b18eeba2ce66eb_r.png)
    - 混合：因为在HDR空间下作TAA效果抗锯齿效果不佳；在postprocessing后做TAA会影响需要在HDR中计算的bloom等效果；所以开启TAA时需要两次Tone mapping：（下图方案一）![v2-c4ccc37c5541f7a7fe166bc7fafc36b8_720w](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-c4ccc37c5541f7a7fe166bc7fafc36b8_720w.webp)
          最后将历史帧数据，和当前帧数据进行 lerp 混合。
  - 动态（相机移动，物体静止）： 
    - 重投影：当相机移动后，使用当前帧的深度信息，反算出世界坐标，使用上一帧的投影矩阵，在混合计算时做一次重投影。![v2-b68e86d6db5205544484fe1a6b910da0_r](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/v2-b68e86d6db5205544484fe1a6b910da0_r.png)
      - Reverse Reprojection（重投影）：记录上一帧的MVP矩阵，当前帧渲染时会使用上一帧的MVP矩阵对像素进行反向投影，看是否可以在上一帧的帧缓冲里面找到(此处判断是否找到：根据物体ID、深度等信息)。若找到则复用，未找到则标记为“遮蔽”。（如果是蒙皮mesh，还需要记录骨骼位置）
  - 动态（物体移动）：
    - Motion Vector/Velocity：像素在历史帧与当前帧在屏幕空间下的位移。存储在 Motion Vector/Velocity 贴图（RG16格式，对精度要求高）上。
      <!-- P.S.: UE中为了节省Velocity Buffer 的带宽，只计算运动物体的Motion Vector，  -->
    - 使用 Motion Vector：使用 Motion Vector 算出上一帧在屏幕空间的坐标（使用双线性模式进行采样，因为不一定在像素中心位置。可以对历史帧进行*锐化*处理）。
                          因为 Velocity buffer本身也有锯齿，采样几何体边缘可能引入新的锯齿。所以可以比较该像素周边3x3像素的深度，选用深度最小的那一个的velocity。
    - Ghosting（鬼影）：当新的像素出现时，如果前后帧采样的颜色差过大的情况下进行混合。解决方式：对比当前帧和历史帧（以及相邻的像素），将历史帧的颜色截断（clamp/clip）在合理的范围内。
      Flickering（闪烁）：抖动导致的不收敛，子采样点存在部分高频信息，混合后造成的闪烁。本质上是高频信息被离散的光栅化方法限制的问题。着色走样：假如历史帧存在高光，而当前帧却因为子采样点的抖动没有采样到高光信息，历史帧的高光信息就会被截断，就会导致这一高光“忽隐忽现”。 集合走样：当一个在屏幕空间极其细小的三角形经过光栅化时，谁都不能在看到显示结果时得知其是否被光栅化到了某一个像素上，这就是“薛定谔的光栅化”。
    - 解决方式：对采样的历史帧和当前帧数据进行对比，将历史帧数据 clamp/截断 在合理的范围内：读取当前帧数据目标像素周围 5 个或 9 个像素点的Max，Min值作为范围。然后：clamp或clip；在TAA之后进行一次滤波（低通），虽然可以有效减少闪烁，但是会让画面比较模糊。
    - 混合：使用一个可变化的混合系数值来平衡抖动和模糊的效果，当物体的 Motion Vector 值比较大时，就增大 blendFactor 的值，反之则减小![20240625015835](https://raw.githubusercontent.com/hwubh/hwubh_Pictures/main/20240625015835.png)
  - https://zhuanlan.zhihu.com/p/479530563；https://zhuanlan.zhihu.com/p/425233743；https://zhuanlan.zhihu.com/p/366494818